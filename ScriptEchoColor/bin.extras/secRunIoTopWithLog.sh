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

SECFUNCuniqueLock --daemonwait

bCheckHogs=false
strTimeLimit=""
bPrevious=false
nDelay=5
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "log iotop to track system hog (needs improvements to track hog source..)"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--checkhogs" || "$1" == "-c" ]];then #help list all that can be hogging the system
		bCheckHogs=true
	elif [[ "$1" == "--timelimit" || "$1" == "-t" ]];then #help ex.: "14:49:28", filter out anything after this time. Important Obs.: the time must be an exact match! so run 1st without this option to find it.
		shift
		strTimeLimit="${1-}"
	elif [[ "$1" == "--delay" ]];then #help <nDelay> between gathering info
		shift
		nDelay="${1-}"
	elif [[ "$1" == "--checkprevious" || "$1" == "-p" ]];then #help check but using previous log file (older one)
		bCheckHogs=true
		bPrevious=true
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

strLogFileIotop="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/iotop.log"
strLogFileIostat="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/iostat.log"
strLogFileMisc="$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/misc.log"
SECFUNCexecA -c --echo mkdir -p "$SECstrUserHomeConfigPath/log/$SECstrScriptSelfName/"

if $bCheckHogs;then
	if $bPrevious;then
		strLogFileIotop+=".old.log"
	fi
	
	echoc --info "strLogFileIotop='$strLogFileIotop'"
	
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
	
	exit 0
fi

function FUNCcycleLogChild() {
	function FUNCcycle_doIt(){
		local lbDoIt="$1"
		local lstrFile="$2"
		if [[ -f "$lstrFile" ]];then 
			if $lbDoIt;then
				# mv will not work, the file is not reached by name but by inode?
				SECFUNCexecA -c --echo cp -vf "$lstrFile" "${lstrFile}.old.log"
				echo >"$lstrFile" #to empty it, but a write may happen between the copy and this...
			fi
		fi
	}
	
	SECONDS=0
	while true;do
		sleep 60;
		
		local bTruncNow=false
		if((SECONDS>3600));then
			bTruncNow=true
			SECONDS=0
		fi
		
		FUNCcycle_doIt $bTruncNow "$strLogFileIotop"
		FUNCcycle_doIt $bTruncNow "$strLogFileIostat"
		FUNCcycle_doIt $bTruncNow "$strLogFileMisc"
		
#		if [[ -f "$strLogFileIotop" ]];then 
#			#if((`stat -c %s "$strLogFileIotop"`>250000));then
#			if $bTruncNow;then
#	#			if [[ -f "${strLogFileIotop}.old.log" ]];then
#	#				trash "${strLogFileIotop}.old.log"
#	#			fi

#				# mv will not work, the file is not reached by name but by inode?
#				SECFUNCexecA -c --echo cp -vf "$strLogFileIotop" "${strLogFileIotop}.old.log"
#	#			cp -vf "$strLogFileIotop" "${strLogFileIotop}.`SECFUNCdtFmt --filename`.log"
#				echo >"$strLogFileIotop" #to empty it, but a write may happen between the copy and this...
#			fi
#		fi
#		
#		if [[ -f "$strLogFileIostat" ]];then 
#			if $bTruncNow;then
#				# mv will not work, the file is not reached by name but by inode?
#				SECFUNCexecA -c --echo cp -vf "$strLogFileIostat" "${strLogFileIostat}.old.log"
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

(SECFUNCexecA -c --echo iostat -xm $nDelay 2>&1 >>"$strLogFileIostat")&
FUNClogMisc&
# last one shows also on current output
SECFUNCexecA -c --echo sudo -k /usr/sbin/iotop --batch --accumulated --processes --time --only --delay=$nDelay 2>&1 |tee -a "$strLogFileIotop"

echoc -p "ended why?"

