#!/bin/bash
# Copyright (C) 2015 by Henrique Abdalla
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

eval `secinit`
SECFUNCcheckActivateRunLog --restoredefaultoutputs

SECFUNCcfgReadDB

strTimeLimit=""
bCheckHogs=false
bCheckPrevious=false
nDelay=5
bLvmInfo=false
strOldLogSuffix=".old.log"
strLogFileIotop="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/iotop.log"
strLogFileIostat="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/iostat.log"
strLogFileMisc="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/misc.log"
nCycleLogTime=60
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "log iotop to track system hog (needs improvements to track hog source..)"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--checkhogs" || "$1" == "-c" ]];then #help list all that can be hogging the system
		bCheckHogs=true
	elif [[ "$1" == "--timelimit" || "$1" == "-t" ]];then #help ex.: "14:49:28", filter out anything after this time. Important Obs.: the time must be an exact match! so run 1st without this option to find it. Only working for iotop log.
		shift
		strTimeLimit="${1-}"
	elif [[ "$1" == "--delay" ]];then #help <nDelay> between gathering info
		shift
		nDelay="${1-}"
	elif [[ "$1" == "--checkprevious" || "$1" == "-p" ]];then #help check but using previous log file (previous one)
		bCheckHogs=true
		bCheckPrevious=true
	elif [[ "$1" == "--getlvminfo" ]];then #help better check report info, but requires sudo, shall be used everytime you update your devices as it will store that information on a cfg variable
		bLvmInfo=true
	elif [[ "$1" == "--dbgIostatLogFile" ]];then #help <strLogFileIostat> for this script development mainly
		shift
		strLogFileIostat="${1-}"
	elif [[ "$1" == "--cyclelogtime" ]];then #help <nCycleLogTime> time in minutes to cycle the log.
		shift
		nCycleLogTime="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if ! SECFUNCisNumber -dn "$nDelay";then
	echoc -p "invalid nDelay='$nDelay'"
	exit 1
fi
if ! SECFUNCisNumber -dn "$nCycleLogTime";then
	echoc -p "invalid nCycleLogTime='$nCycleLogTime'"
	exit 1
fi

SECFUNCexecA -c --echo mkdir -p "$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/"

function FUNCcheckHogs() {
	if $bCheckPrevious;then
		strLogFileIotop+="${strOldLogSuffix}"
		strLogFileIostat+="${strOldLogSuffix}"
		strLogFileMisc+="${strOldLogSuffix}"
	fi
	
	# physical volumes info
	bLvmAlert=false
	if $bLvmInfo;then
		strLvmPVInfo="`SECFUNCexecA -c --echo sudo -k pvdisplay -m`"
		IFS=$'\n' read -r -d '' -a astrLvmPvInfoList < <(
			echo "$strLvmPVInfo" \
				|egrep "PV Name|Logical volume" \
				|sed -r -e 's"PV Name(.*)";\1\t"' -e 's"Logical volume""' -e 's"/dev/""' -e 's"/"-"' -e 's"[[:blank:]]+""g' \
				|tr '\n;' '\t\n'
		)
		declare -Ag astrLvmPvInfoListA
		#for strLvmPvInfo in "${astrLvmPvInfoList[@]}";do
		for((iLvmPVIndex=0;iLvmPVIndex<${#astrLvmPvInfoList[@]};iLvmPVIndex++));do
			strLvmPvInfo="${astrLvmPvInfoList[iLvmPVIndex]}"
			strDevId="`echo "$strLvmPvInfo" |cut -f1`"
			
			# removing dups and emptys
			astrLvmPvInfoListA[$strDevId]="`
				echo "$strLvmPvInfo" \
					|cut -f2- \
					|tr '\t' '\n' \
					|sort -u \
					|sed '/^$/ d' \
					|tr '\n' ','
			`"
		done
		#declare -p astrLvmPvInfoListA
		SECFUNCcfgWriteVar astrLvmPvInfoListA
	else
		# may have been read from cfg file
		if SECFUNCvarIsArray astrLvmPvInfoListA;then
			bLvmAlert=true
			bLvmInfo=true
		fi
	fi
	
	function FUNCiotopCheckHogs() {
		#echoc --info "strLogFileIotop='$strLogFileIotop'"
		echoc --info "iotop log"
		
		regexKworker="\[kworker/[^]]*\]"
	
		strLogData="`cat "$strLogFileIotop"`"
		nLimitLineNumber="`echo "$strLogData" |wc -l`"
	
		# limit log data by time stamp
		if [[ -n "$strTimeLimit" ]];then
			read -rd '' strLineText < <(\
				echo "$strLogData" \
					|cat -n \
					|egrep "[[:blank:]]$strTimeLimit[[:blank:]]" \
					|tail -n 1\
			)&&:
			nLimitLineNumber=$(echo "$strLineText" |cut -f1) #is TAB delimiter
			if((nLimitLineNumber==0));then
				echoc -p "possibly invalid/non-existant strTimeLimit='$strTimeLimit'"
				exit 1
			fi
			((nLimitLineNumber++))&&:
			echo "nLimitLineNumber='$nLimitLineNumber'"
			strLogData="`echo "$strLogData" |head -n $nLimitLineNumber`"
			#echo "strLogData='$strLogData'";exit
		fi
	
		# not kworker info
		read -rd '' strLineText < <(echo "$strLogData" |cat -n |grep "DISK READ" |tail -n 1)&&:
		nLastHeaderLineNumber=$(echo "$strLineText" |cut -f1) #is TAB delimiter
		((nLastHeaderLineNumber-=1000))&&:
		if((nLastHeaderLineNumber<=0));then nLastHeaderLineNumber=0;fi
	#	head -n $nLimitLineNumber \
		#set -x
		echo "$strLogData" \
			|tail -n +$nLastHeaderLineNumber \
			|cut -c -`tput cols` \
			|egrep -v "$regexKworker" \
			|egrep --color " M | G |DISK READ|M/s"
		#set +x
	
		# kworker summary
		astrKworkerList=(`echo "$strLogData" |egrep "$regexKworker" -o |sort -u`);
		for strKworkerId in "${astrKworkerList[@]}";do 
			SECFUNCdrawLine "$strKworkerId"; 
			strKworkerId="`echo "$strKworkerId" |sed -e 's"\["\\\["' -e 's"\]"\\\]"'`"
			#echo "strKworkerId=$strKworkerId"
	#		head -n $nLimitLineNumber
			echo "$strLogData" \
				|egrep " G .* $strKworkerId" \
				|tail -n 5;
		done
	}
	FUNCiotopCheckHogs
	
	function FUNCiostatCheckHogs() {
		echoc --info "iostat log, all high I/O waits"
	
		astrDevList=(`iostat -p |egrep -o "^sd[^ ]*|^dm-[^ ]*"`)
		astrDevListPretty=(`iostat -pN |egrep "^Device:" -A1000 |tail -n +2 |sed -r 's" +"\t"g' |cut -f1`)
		#2015-05-10T17:07:22-0300
		strDateFormat="....-..-..T..:..:..-...." #is regex BUT MUST be simple, MUST match in size of real date output
		strDeviceColumnTitle="Device: " #DO NOT CHANGE!
		sedSpacesToTab='s" +"\t"g' #or or more spaces become a single tab to separate columns
		sedJoinNextLine="/^${strDateFormat}$/{N;s'\n'\t'g}" #creates the 1st column with datetime info, may create a bug of one line with two ore more datetime columns
		sedFixDoubleDatetime="/\t${strDateFormat}$/ s'.*\t([^ \t]*)$'\1'g" #a line with two or more datetime columns will keep only the last datetime
		#sedPrettyDate="s'(....)-(..)-(..)T(..:..:..)-....'\1/\2/\3-\4'" #good looking date and time
		sedPrettyDate="s'(....)-(..)-(..)T(..:..:..)-....'\4'" #only the time
		regexHighNumber="[[:digit:]]{3,}[.]" #numbers >= 100 (3+ digits).
		awkMatchColumns="match(\$11,/$regexHighNumber/)||match(\$12,/$regexHighNumber/)||match(\$13,/$regexHighNumber/)" #For iowait columns 10,11,12 only BUT here there is one more column with date/time
		
		strColumnsNames="`grep "^${strDeviceColumnTitle}" "$strLogFileIostat" |head -n 1 |sed -r "$sedSpacesToTab" |cut -f2-`"
		#strColumnsNames="${strColumnsNames:${#strDeviceColumnTitle}}"
		
		#for strDev in "${astrDevList[@]}";do
		for((iDevIndex=0;iDevIndex<${#astrDevList[@]};iDevIndex++));do
			strDev="${astrDevList[iDevIndex]}"
			
			strTips=""
			
			strLvm="${astrDevListPretty[iDevIndex]}"
			if [[ "$strLvm" == "$strDev" ]];then
				strLvm=""
			else
				strLvm=";lvm='$strLvm'"
			fi
			
			strMatchData=""
			bFixedMode=true
			if $bFixedMode;then
				#fully fixed, better to understand later on again
				IFS=$'\n' read -r -d '' -a astrMatchDataLineList < <(
					egrep "^$strDev |^${strDateFormat}$" "$strLogFileIostat" \
						|sed -r "$sedSpacesToTab" \
						|sed -r "$sedPrettyDate"
				)
				#for strMatchDataLine in "${astrMatchDataLineList[@]}";do
				for((iLineIndex=0;iLineIndex<${#astrMatchDataLineList[@]};iLineIndex++));do
					strMatchDataLine="${astrMatchDataLineList[iLineIndex]}"
					strMatchDataLineNext="${astrMatchDataLineList[iLineIndex+1]-}"
					#echo "strDev='$strDev';strMatchDataLine='$strMatchDataLine'"
					if [[ "$strMatchDataLineNext" =~ ^${strDev}${SECcharTab}.* ]];then
						strMatchData+="${strMatchDataLine}${SECcharTab}${strMatchDataLineNext}${SECcharNL}"
						((iLineIndex++))&&:
					fi
				done
				#echo "strMatchData=${strMatchData}";exit 0
				strMatchData="`echo "$strMatchData" |awk "$awkMatchColumns"`"
			else
				# sedFixDoubleDatetime requires the fixed line to be sedJoinNextLine again as it will have only datetime on it
				read -r -d '' strMatchData < <(
					egrep "^$strDev |^${strDateFormat}$" "$strLogFileIostat" \
						|sed -r -e "$sedJoinNextLine" -e "$sedFixDoubleDatetime" -e "$sedJoinNextLine" \
						|sed -r "$sedSpacesToTab" \
						|sed -r "$sedPrettyDate" \
						|awk "$awkMatchColumns"
				)
			fi
			
#			strMatchData="$(egrep "^$strDev |^${strDateFormat}$" "$strLogFileIostat" \
#				|sed -r "$sedJoinNextLine" \
#				|sed -r "$sedSpacesToTab" \
#				|awk "match(\$11,/$regexHighNumber/)||match(\$12,/$regexHighNumber/)||match(\$13,/$regexHighNumber/)")"
			#echo "`printf "Device: %0${#strDateFormat}s" $strDev` $strColumnsNames"
			
			strMountPoint="`mount |grep -w "${astrDevListPretty[iDevIndex]}" |sed -r 's".* on (.*) type .*"\1"'`"
			if [[ -n "$strMountPoint" ]];then
				strMountPoint=";mnt='$strMountPoint'"
			fi
			#if [[ -n "$strMatchData" ]];then
				if [[ -z "$strMountPoint" ]];then
					strLvmInfo=""
					if $bLvmInfo;then
						strLvmInfo="${astrLvmPvInfoListA[$strDev]-}"
					fi
					
					if [[ -n "$strLvmInfo" ]];then
						strMountPoint=";mnt='LVM:$strLvmInfo'"
					else
						if ! $bLvmInfo;then
							strTips+=' try adding --getlvminfo;'
						fi
					fi
				fi
			#fi
			
			if [[ -n "$strTips" ]];then
				strTips="#TIPS: $strTips"
			fi
			SECFUNCdrawLine --left "=== [dev='$strDev'${strLvm}${strMountPoint}] $strTips " "="
			
			if [[ -n "$strMatchData" ]];then
				(
					echo -e "Time\tdev=$strDev\t$strColumnsNames" |sed -r "$sedSpacesToTab"
					echo "$strMatchData"
				) |column -t |egrep --color=always "await|$regexHighNumber"&&:
			fi
		done
		#declare -p astrLvmPvInfoListA
	}
	FUNCiostatCheckHogs
	
	if $bLvmAlert;then
		echoc --info "Using stored physical volumes info on the report, may require update with --getlvminfo."
	fi
	
	SECFUNCdrawLine
	echoc --info "processes probably waiting for I/O"
	SECFUNCexecA -c --echo tail -n 25 "$strLogFileMisc"
	
	echoc --info "log files:"
	echo "$strLogFileIotop"
	echo "$strLogFileIostat"
	echo "$strLogFileMisc"
}
if $bCheckHogs;then
	FUNCcheckHogs
	exit 0
fi

######################################## DAEMON PART
SECFUNCuniqueLock --daemonwait

function FUNCcycleLogChild() {
	function FUNCcycle_doIt(){
		local lbDoIt="$1"
		local lstrFile="$2"
		if [[ -f "$lstrFile" ]];then 
			if $lbDoIt;then
				# mv will not work, the file is not reached by name but by inode?
				SECFUNCexecA -c --echo cp -vf "$lstrFile" "${lstrFile}${strOldLogSuffix}"
				echo >"$lstrFile" #to empty it, but a write may happen between the copy and this...
			fi
		fi
	}
	
	SECONDS=0
	while true;do
		sleep 60;
		
		local bTruncNow=false
		if((SECONDS>(nCycleLogTime*60)));then
			bTruncNow=true
			SECONDS=0
		fi
		
		FUNCcycle_doIt $bTruncNow "$strLogFileIotop"
		FUNCcycle_doIt $bTruncNow "$strLogFileIostat"
		FUNCcycle_doIt $bTruncNow "$strLogFileMisc"
		
#		if [[ -f "$strLogFileIotop" ]];then 
#			#if((`stat -c %s "$strLogFileIotop"`>250000));then
#			if $bTruncNow;then
#	#			if [[ -f "${strLogFileIotop}${strOldLogSuffix}" ]];then
#	#				trash "${strLogFileIotop}${strOldLogSuffix}"
#	#			fi

#				# mv will not work, the file is not reached by name but by inode?
#				SECFUNCexecA -c --echo cp -vf "$strLogFileIotop" "${strLogFileIotop}${strOldLogSuffix}"
#	#			cp -vf "$strLogFileIotop" "${strLogFileIotop}.`SECFUNCdtFmt --filename`.log"
#				echo >"$strLogFileIotop" #to empty it, but a write may happen between the copy and this...
#			fi
#		fi
#		
#		if [[ -f "$strLogFileIostat" ]];then 
#			if $bTruncNow;then
#				# mv will not work, the file is not reached by name but by inode?
#				SECFUNCexecA -c --echo cp -vf "$strLogFileIostat" "${strLogFileIostat}${strOldLogSuffix}"
#				echo >"$strLogFileIostat" #to empty it, but a write may happen between the copy and this...
#			fi
#		fi
		
	done
}
FUNCcycleLogChild&

function FUNClogMisc() {
	while true;do
		echo >>"$strLogFileMisc"
		SECFUNCdtFmt --pretty >>"$strLogFileMisc"
		
		# misc info
		
		# "^D" means "uninterruptable sleep". that is probably the case of a process waiting for IO
		ps -A -o state,pid,cmd | grep "^D" >>"$strLogFileMisc"
		
		sleep $nDelay
	done
}

(export S_TIME_FORMAT=ISO;SECFUNCexecA -c --echo iostat -txmpzy $nDelay 2>&1 >>"$strLogFileIostat")& #TODO get 'tps' info from iostat?
FUNClogMisc&
# last one shows also on current output
SECFUNCexecA -c --echo sudo -k /usr/sbin/iotop --batch --accumulated --processes --time --only --delay=$nDelay 2>&1 |tee -a "$strLogFileIotop"

echoc -p "ended why?"

