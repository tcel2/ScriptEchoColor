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

bCheckHogs=false
strTimeLimit=""
bPrevious=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	#SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "log iotop to track system hog (needs improvements to track hog source..)"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--checkhogs" || "$1" == "-c" ]];then #help list all that can be hogging the system
		bCheckHogs=true
	elif [[ "$1" == "--timelimit" || "$1" == "-t" ]];then #help ex.: "14:49:28", filter out anything after this time. Important Obs.: the time must be an exact match! so run 1st without this option to find it.
		shift
		strTimeLimit="${1-}"
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

strLogFile="$SECstrUserHomeConfigPath/log/iotop.log"

if $bCheckHogs;then
	if $bPrevious;then
		strLogFile+=".old.log"
	fi
	
	echoc --info "strLogFile='$strLogFile'"
	
	regexKworker="\[kworker/[^]]*\]"
	
	strLogData="`cat "$strLogFile"`"
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
	SECONDS=0
	while true;do
		sleep 60;
		
		if [[ ! -f "$strLogFile" ]];then 
			continue;
		fi
		
		#if((`stat -c %s "$strLogFile"`>250000));then
		if((SECONDS>3600));then
#			if [[ -f "${strLogFile}.old.log" ]];then
#				trash "${strLogFile}.old.log"
#			fi

			# mv will not work, the file is not reached by name but by inode?
			cp -vf "$strLogFile" "${strLogFile}.old.log"
#			cp -vf "$strLogFile" "${strLogFile}.`SECFUNCdtFmt --filename`.log"
			echo >"$strLogFile" #to empty it, but a write may happen between the copy and this...
			SECONDS=0
		fi
	done
}
FUNCcycleLogChild&

SECFUNCexecA -c --echo sudo -k /usr/sbin/iotop --batch --accumulated --processes --time --only --delay=10 2>&1 |tee -a "$strLogFile"

