#!/bin/bash
# Copyright (C) 2020-2020 by Henrique Abdalla
#
# This file is part of ScriptEchoColor.
#
# ScriptEchoColor simplifies Linux terminal text colorizing, formatting 
# and several steps of script coding.
#
# ScriptEchoColor is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# ScriptEchoColor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ScriptEchoColor. If not, see <http://www.gnu.org/licenses/>.
#
# Homepage: http://scriptechocolor.sourceforge.net/
# Project Homepage: https://sourceforge.net/projects/scriptechocolor/

source <(secinit)

strCfgFile="`SECFUNCcfgFileName --get`"

#strPrettyDT=""
#function FUNCupdDT() {
	#echo "$FUNCNAME $@" >&2
	#local lstrTmp="${1-}"
	#strPrettyDT="`SECFUNCdtFmt --universal --nonano --nodate --nosec "${lstrTmp}"`"
	#if [[ -z "$lstrTmp" ]];then lstrTmp="$strPrettyDT";fi
	#nDT="$(date --date "${lstrTmp}" +%s)"
#}

declare -A anNotifIdList=()
function FUNCnotifyCmd() {
	local lstrKey="$1";shift
	local lstrTitle="$1";shift
	local lstrContent="${1-}";shift
	
	local lstrMyAppName="$lstrTitle"
	gdbus call \
		--session \
		--dest org.freedesktop.Notifications \
		--object-path /org/freedesktop/Notifications \
		--method org.freedesktop.Notifications.Notify \
		"$lstrMyAppName" 0 dummy "$lstrTitle" "$lstrContent" "[]" "{}" 0
	return 0
}
function FUNCnotify() { # <lstrKey>
	local lstrKey="$1";shift
	local lstrTitle="$1";shift
	local lstrContent="${1-}";shift&&:
	
	anNotifIdList[$lstrKey]="$(FUNCnotifyCmd "$lstrKey" "$lstrTitle" "$lstrContent" |awk '{print $2}' |tr -d ",)" )";
	
	return 0
}
function FUNCnotifyDelLast() { #<lnNotifID>
	local lnNotifID="$1"
	if [[ -n "$lnNotifID" ]];then
		gdbus call \
			--session \
			--dest org.freedesktop.Notifications \
			--object-path /org/freedesktop/Notifications \
			--method org.freedesktop.Notifications.CloseNotification \
			$lnNotifID	
	fi
	return 0
}

bIsScreenLocked=false
function FUNCreportDelay(){ #<lstrKey> <lnDelay> <lstrExtraComment>
	local lstrKey="$1";shift
	local lnDelay="$1";shift
	local lstrExtraComment="$1";shift
	
	#strInfo="Ate at `SECFUNCdtFmt --alt --nonano --nodate  --nosec "@${nDT}"`,"
	#strInfo+="interval of `SECFUNCdtFmt --delay --alt --nonano --nodate  --nosec "${lnDelay}"`"
	local lstrDelay="`SECFUNCdtFmt --delay --nozero --alt --nonano --nosec "${lnDelay}"`"
	local lstrPKey="`echo "$lstrKey" |tr -d "_"`"
	local lstrComment="${CFGastrKeyComment[$lstrKey]-}"
	local lstrInfoFmt="@{lg}${lstrDelay} @{w}ago, @{lyK}${lstrPKey}, \"$lstrComment\""
	local lstrInfo="`echoc -u "$lstrInfoFmt"`"
  #declare -p bForceNotificationUpdate bIsScreenLocked&&:
  if $bIsScreenLocked || $bForceNotificationUpdate;then
		bUsePythonNotif=false 
		if $bUsePythonNotif;then
			secNotifyOnLockToo.py "${lstrInfo}" "$lstrExtraComment" #TODO delete a notification using python, how?
		else
			FUNCnotifyDelLast "${anNotifIdList[$lstrKey]-}"
			FUNCnotify "$lstrKey" "${lstrInfo} `date +%H:%M`" "$lstrExtraComment"
		fi
	else
		local lstrReport="${CFGastrKeyHist[$lstrKey]-}"
		if [[ -n "$lstrReport" ]];then
			#echo "((( $lstrKey )))"
			local lnAvailLines=$(tput lines)
			(( lnAvailLines -= 1 ))&&: # the question line
			#(( lnAvailLines -= (${#CFGastrKeyHist[*]} * 2) ))&&: # each type has a title and a current entry info line, so: * 2
			(( lnAvailLines -= ${#CFGastrKeyHist[*]} ))&&: # each type has a current entry info line
			lnAvailLines=$((lnAvailLines/${#CFGastrKeyHist[*]})) # how much for each type will be left
			#echo -n "types=${#CFGastrKeyHist[*]},lines=`tput lines`,`declare -p lnAvailLines`" #@@@R
			echo -e "$lstrReport" |tail -n -${lnAvailLines}
		fi
		echoc "@s@{Blc} ${lstrExtraComment} @S@w, ${lstrInfoFmt}"
	fi
}		

strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
CFGnLastAteAt=0
declare -A CFGastrKeyValue=()
declare -A CFGastrKeyComment=()
declare -A CFGastrKeyHist=()
astrOptMaint=(_fixLastTime _commentOnLast _history _notifUpd);declare -p astrOptMaint
astrOptMaintChars=(`echo "${astrOptMaint[@]}" |egrep "_." -o |tr -d "_"`);declare -p astrOptMaintChars

SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above, and BEFORE the skippable ones!!!

declare -p CFGastrKeyValue

: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
: ${strEnvVarUserCanModify:="test"}
bExitAfterConfig=false
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-a" || "$1" == "--addkey" ]];then #help <strKey> add a new key (must not conflict with astrOptMaint array's keys)
		shift;strKey="${1}"
		#strKey="$(echo "$strKey" |tr -d "_")"
		if [[ -z "${CFGastrKeyValue[$strKey]-}" ]];then
			CFGastrKeyValue[$strKey]=-1;
		else
			echoc --info "already added strKey='$strKey'"
		fi
		bExitAfterConfig=true;
	elif [[ "$1" == "-s" || "$1" == "--setvalue" ]];then #help <strKey> <strValue> set a key value (this also adds a key)
		shift;strKey="${1}"
		shift;strValue="${1}"
		CFGastrKeyValue[$strKey]="$strValue";
		bExitAfterConfig=true;
	#elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #help MISSING DESCRIPTION
		#bExample=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams. TODO explain how it will be used
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift&&: #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
if $bWriteCfgVars;then SECFUNCcfgAutoWriteAllVars;fi #this will also show all config vars
if $bExitAfterConfig;then exit 0;fi

function FUNCreportHist() { 
	echo
	SECFUNCdrawLine "HIST-BEGIN"
	for strKey in "${!CFGastrKeyHist[@]}";do 
		SECFUNCdrawLine --left " $strKey ";
		echo "${CFGastrKeyHist[$strKey]}" |sed "s'[\]n'\n'g" |tr "['" "\n\n" |egrep "^" -n;
	done
	SECFUNCdrawLine "HIST-END"
	echo
}

function FUNCfindKey() { #<lstrRetChar>
	local lstrRetChar="$1";shift
	if [[ -z "$lstrRetChar" ]];then
    return 1
  fi
	
	local lstrMatchKey="_($lstrRetChar|$(echo "$lstrRetChar" |tr "[:lower:]" "[:upper:]"))"
	local lstrKey="$(echo "${!CFGastrKeyValue[@]}" |tr " " "\n" |egrep "${lstrMatchKey}")"&&:
	if [[ -z "$lstrKey" ]];then
    return 1
  fi
  
	echo "$lstrKey"
  return 0
}

function FUNCupdateArrayDT(){ #<lstrRetChar> <lstrNewDT>
	local lbFix=false;if [[ "$1" == "--fix" ]];then lbFix=true;shift;fi
	local lstrRetChar="$1";shift
	local lstrNewDT="$1";shift
	declare -p lstrRetChar lstrNewDT
	
	if [[ -z "$lstrNewDT" ]];then return 1;fi # just ignore
	
	if ! lstrNewDT="`date --date="$lstrNewDT" +%s`";then
		echoc -p "invalid date input"
		return 1
	fi
	
	echo "keys: ${!CFGastrKeyValue[@]}" >&2
	#local lstrMatchKey="_($lstrRetChar|$(echo "$lstrRetChar" |tr "[:lower:]" "[:upper:]"))"
	#local lstrKey="$(echo "${!CFGastrKeyValue[@]}" |tr " " "\n" |egrep "${lstrMatchKey}")"
	local lstrKey="`FUNCfindKey "${lstrRetChar}"`"
	declare -p lstrRetChar CFGastrKeyValue lstrNewDT strKey lstrKey >&2
	
	CFGastrKeyValue[$lstrKey]="$lstrNewDT"
	SECFUNCcfgWriteVar CFGastrKeyValue
	
	#FUNCreportHist
	local lnLnCount=0
	if $lbFix;then
		lnLnCount="`echo -e "${CFGastrKeyHist[$lstrKey]-}" |wc -l`"
		if((lnLnCount>0));then
			if((lnLnCount==1));then
				CFGastrKeyHist[$lstrKey]="";
			else
				# always remove the last history entry (to re-add it updated just after)
				CFGastrKeyHist[$lstrKey]="`echo "${CFGastrKeyHist[$lstrKey]}" |head -n $((lnLnCount-1))`"
			fi
		fi
	fi
	local lstrLastHist="`echo "${CFGastrKeyHist[$lstrKey]}" |tail -n 1 |cut -d "," -f1`";declare -p lstrLastHist
	local lnLastHTimeS="`date --date="$lstrLastHist" +%s&&:`"&&:;declare -p lnLastHTimeS
	local lstrLastAgo=""
	if [[ -n "$lnLastHTimeS" ]];then
		lnLastDelay="$((`date --date="@${lstrNewDT}" +%s`-$lnLastHTimeS))"&&:;declare -p lnLastDelay
		if [[ -n "$lnLastDelay" ]];then
			lstrLastAgo=", -`SECFUNCdtFmt --delay --nozero --alt --nonano --nosec $lnLastDelay`^"&&:;declare -p lstrLastAgo
		fi
	fi
	local lstrComment="${CFGastrKeyComment[$lstrKey]-}"
	if [[ -n "$lstrComment" ]];then
		lstrComment=", \"$lstrComment\""
	fi
	if [[ -n "${CFGastrKeyHist[$lstrKey]-}" ]];then CFGastrKeyHist[$lstrKey]+="\n";fi
	local lstrCurrent="`SECFUNCdtFmt --universal --nonano --nosec $lstrNewDT`"
	CFGastrKeyHist[$lstrKey]+="${lstrCurrent}${lstrLastAgo}${lstrComment}" # add updated current entry
	: ${nLimitHist:=100} #help
	CFGastrKeyHist[$lstrKey]="`echo -e "${CFGastrKeyHist[$lstrKey]}" |tail -n $nLimitHist`" # limit
	#FUNCreportHist
	declare -p lnLnCount lbFix lstrKey lstrNewDT
	SECFUNCcfgWriteVar CFGastrKeyHist
	
	SECFUNCdelay "$lstrKey" --initset "$lstrNewDT"
	
	declare -p FUNCNAME lstrKey lstrNewDT
	
	return 0
}	

function FUNCshowReport() {
  bIsScreenLocked=false
	if secAutoScreenLock.sh --gnome --islocked;then #TODO implement --autodetect instead of --gnome
    bIsScreenLocked=true
  fi
	for strKey in "${!CFGastrKeyValue[@]}";do
		nValue="${CFGastrKeyValue[$strKey]}"
		if((nValue>-1));then
			nDelay="`SECFUNCdelay "$strKey" --getsec`"
			FUNCreportDelay "$strKey" "$nDelay" "`SECFUNCdtFmt --universal --nonano  --nosec "@${nValue}"`"
		fi
	done
}

SECFUNCexecA -ce cp -vf "$strCfgFile" "${strCfgFile}-`SECFUNCdtFmt --filename`.bkp"

for strKey in "${!CFGastrKeyValue[@]}";do
	nValue="${CFGastrKeyValue[$strKey]}"
	if((nValue>-1));then
		SECFUNCdelay "$strKey" --initset "${CFGastrKeyValue[$strKey]}"
		echo "init strKey='$strKey' nValue='$nValue'"
	fi
done
declare -p CFGastrKeyValue
strOptions="$(echo "${!CFGastrKeyValue[@]}" |tr " " "/")";declare -p strOptions
strOptionsXtra="${strOptions}/[$(echo "${astrOptMaint[@]}" |tr " " "|")]" # these end up being reserved keys 'f' and 'c' ...
bReportOnce=true
bForceNotificationUpdate=false
while true;do
	bFixMode=false
	#SECFUNCexecA -ce tput lines
	if ! $bReportOnce;then
		while true;do
			: ${nDelayMins:=20} #help
			echoc -t $((60*nDelayMins)) -Q "Now @s@{-Ly} `SECFUNCdtFmt --pretty --nosec --nonano --nodate` @S, did you?@O${strOptionsXtra}"&&:;nRet=$?;strRetChar="`secascii $nRet`"; #declare -p strRetChar
			#if [[ "$strRetChar" == "c" || "$strRetChar" == "f" || "$strRetChar" == "h" ]];then #TODO !!!!!!!!! IMPORTANT UPDATE THIS WITH astrOptMaint KEYS !!!!!!!!!!
      if SECFUNCarrayContains astrOptMaintChars "$strRetChar";then
        if [[ "$strRetChar" == "c" || "$strRetChar" == "f" ]];then
          echoc -Q "What key?@O${strOptions}"&&:;nRet=$?;strRetCharWork="`secascii $nRet`"; #declare -p strRetChar
        fi
        case "$strRetChar" in
          c) # commenting work
            declare -p CFGastrKeyComment
            if strKey="`FUNCfindKey "${strRetCharWork}"`";then
              if [[ -n "$strKey" ]];then
                if strNewComment="`echoc -S "@D${CFGastrKeyComment[$strKey]-}"`";then
                  CFGastrKeyComment[$strKey]="$strNewComment"
                  SECFUNCcfgWriteVar CFGastrKeyComment
                fi
              fi
            fi
            declare -p CFGastrKeyComment
            ;;
          f) # fixing time work
            strNewDT="`echoc -S "Type the time [%Y/%m/%d] <%H:%M>, but if it is just a negative number will be 'now - minutes'"`"
            if [[ "${strNewDT:0:1}" == "-" ]];then
              if ! SECFUNCisNumber -d "$strNewDT";then
                echoc -p "invalid input value"
                continue;
              fi
              declare -i iLessMin="$strNewDT"
              strNewDT="@$(( $(date +%s)+(iLessMin*60) ))"
            fi
            if FUNCupdateArrayDT --fix "$strRetCharWork" "$strNewDT";then
              bReportOnce=true
              strRetChar=""
              break
            else
              continue;
            fi
            ;;
          h)
            FUNCreportHist
            ;;
          n)
            bReportOnce=true
            bForceNotificationUpdate=true
            #strRetChar=""
            break
            ;;
          *) : ;;
        esac
        
				continue
			fi
			break;
		done
	fi
	
	#if [[ -n "${strRetChar-}" ]] || [[ -n "${CFGastrKeyValue[$strRetChar]-}" ]];then
  #declare -p CFGastrKeyValue strRetChar&&:
	#if [[ -n "${CFGastrKeyValue[${strRetChar-}]-}" ]];then
  if FUNCfindKey "${strRetChar-}";then
	#if [[ -n "${strRetChar-}" ]];then
		FUNCupdateArrayDT "$strRetChar" "@`date +%s`"
		#strKey="$(echo "${!CFGastrKeyValue[@]}" |tr " " "\n" |grep "_${strRetChar}")"; declare -p strKey
		#CFGastrKeyValue[$strKey]="`date +%s`"
		#SECFUNCcfgWriteVar CFGastrKeyValue
		#SECFUNCdelay "$strKey" --init;
	fi
	
  FUNCshowReport
  #bIsScreenLocked=false
	#if secAutoScreenLock.sh --gnome --islocked;then #TODO implement --autodetect instead of --gnome
    #bIsScreenLocked=true
  #fi
	#for strKey in "${!CFGastrKeyValue[@]}";do
		#nValue="${CFGastrKeyValue[$strKey]}"
		#if((nValue>-1));then
			#nDelay="`SECFUNCdelay "$strKey" --getsec`"
			#FUNCreportDelay "$strKey" "$nDelay" "`SECFUNCdtFmt --universal --nonano  --nosec "@${nValue}"`"
		#fi
	#done
	
	bReportOnce=false
  bForceNotificationUpdate=false
done
