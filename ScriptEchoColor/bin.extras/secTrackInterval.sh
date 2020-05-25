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

SECFUNCcfgFileName --show

strPrettyDT=""
function FUNCupdDT() {
	echo "$FUNCNAME $@" >&2
	local lstrTmp="${1-}"
	strPrettyDT="`SECFUNCdtFmt --pretty --nonano --nodate "${lstrTmp}"`"
	if [[ -z "$lstrTmp" ]];then lstrTmp="$strPrettyDT";fi
	nDT="$(date --date "${lstrTmp}" +%s)"
}

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

function FUNCreportDelay(){ #<lstrKey> <lnDelay>
	local lstrKey="$1";shift
	local lnDelay="$1";shift
	
	#strInfo="Ate at `SECFUNCdtFmt --alt --nonano --nodate "@${nDT}"`,"
	#strInfo+="interval of `SECFUNCdtFmt --delay --alt --nonano --nodate "${lnDelay}"`"
	local lstrInfo="`echo "$lstrKey" |tr -d "_"` `SECFUNCdtFmt --delay --alt --nonano --nodate "${lnDelay}"` ago."
	if secAutoScreenLock.sh --gnome --islocked;then #TODO implement --autodetect instead of --gnome
		bUsePythonNotif=false #TODO delete a notification using python
		if $bUsePythonNotif;then
			secNotifyOnLockToo.py "$lstrInfo"
		else
			FUNCnotifyDelLast "${anNotifIdList[$lstrKey]-}"
			FUNCnotify "$lstrKey" "$lstrInfo"
		fi
	else
		echo "$lstrInfo"
	fi
}		

strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
CFGnLastAteAt=0
declare -A CFGastrKeyValue=()

SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above, and BEFORE the skippable ones!!!

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
	elif [[ "$1" == "-a" || "$1" == "--addkey" ]];then #help <strKey> add a new key
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

for strKey in "${!CFGastrKeyValue[@]}";do
	nValue="${CFGastrKeyValue[$strKey]}"
	if((nValue>-1));then
		SECFUNCdelay "$strKey" --initset "${CFGastrKeyValue[$strKey]}"
		echo "init strKey='$strKey' nValue='$nValue'"
	fi
done
strOptions="$(echo "${!CFGastrKeyValue[@]}" |tr " " "/")"
while true;do
	echoc -t $((60*10)) -Q "Now, did you?@O${strOptions}"&&:; nRet=$?; strRetChar="`secascii $nRet`"; declare -p strRetChar
	if [[ -n "$strRetChar" ]];then
		strKey="$(echo "${!CFGastrKeyValue[@]}" |tr " " "\n" |grep "_${strRetChar}")"; declare -p strKey
		CFGastrKeyValue[$strKey]="`date +%s`"
		SECFUNCcfgWriteVar CFGastrKeyValue
		SECFUNCdelay "$strKey" --init;
	else
		for strKey in "${!CFGastrKeyValue[@]}";do
			nValue="${CFGastrKeyValue[$strKey]}"
			if((nValue>-1));then
				nDelay="`SECFUNCdelay "$strKey" --getsec`"
				FUNCreportDelay "$strKey" "$nDelay"
			fi
		done
	fi
done
