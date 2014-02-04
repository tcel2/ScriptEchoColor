#!/bin/bash

# Copyright (C) 2013-2014 by Henrique Abdalla
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

############################# INIT ###############################
eval `secinit`

strSelfName="`basename "$0"`"
declare -A aDaemonsPid

#aDaemonsPid=()

#declare -p aDaemonsPid
#declare -p bHoldScripts
#type SECFUNCcfgRead
SECFUNCcfgRead
#declare -p aDaemonsPid
#declare -p bHoldScripts
if [[ -z "${bHoldScripts-}" ]];then
	SECFUNCcfgWriteVar bHoldScripts=false
fi

############################# OPTIONS ###############################
bReleaseAll=false
bHoldAll=false
bCheckHold=false
bList=false
bDaemon=false
bRegisterOnly=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--checkhold" || "$1" == "-c" ]];then #help the script executing this will hold/wait
		bCheckHold=true
	elif [[ "$1" == "--holdall" || "$1" == "-h" ]];then #help will request all scripts to hold execution
		bHoldAll=true
	elif [[ "$1" == "--releaseall" || "$1" == "-r" ]];then #help will request all scripts to continue execution
		bReleaseAll=true
	elif [[ "$1" == "--list" || "$1" == "-l" ]];then #help list all active daemons
		bList=true
	elif [[ "$1" == "--daemon" ]];then #help loop --list
		bDaemon=true
	elif [[ "$1" == "--register" ]];then #help register the daemon to be listed, not controlled.
		bRegisterOnly=true
	elif [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	
	shift
done

#################### FUNCTIONS
function FUNClist() {
	SECFUNCcfgRead
	#cat "$SECcfgFileName"
	SECFUNCdrawLine "Daemons List at `SECFUNCdtTimePrettyNow`:"
	echo -e "Index\tPid\tName"
#		declare -p aDaemonsPid
#		SECFUNCcfgRead
	#declare -p aDaemonsPid
	nCount=0
	#echo "${!aDaemonsPid[@]}" |sort
	for strDaemonId in `echo ${!aDaemonsPid[@]} |tr ' ' '\n' |sort`;do
		#echo ">>>$strDaemonId"
		nPid="${aDaemonsPid[$strDaemonId]-}"
		if ps -p $nPid >/dev/null 2>&1;then
			echo -e "$nCount\t$nPid\t$strDaemonId";
			((nCount++))
		else
			unset aDaemonsPid[$strDaemonId]
			SECFUNCcfgWriteVar aDaemonsPid
		fi
	done
	echo -e "Total=$nCount"
}

function FUNCregisterDaemon() {
	#strPPidId=`ps --no-headers -p $PPID -o comm`
	nPidDaemon=$SECnPidDaemon
	if((nPidDaemon==0));then
		nPidDaemon=$PPID
	fi
	strPPidId=`grep "$nPidDaemon" $SEC_TmpFolder/.SEC.UniqueRun.*sh |sed -r "s'^.*/[.]SEC[.]UniqueRun[.]([[:alnum:]_-]*)[._]sh:$nPidDaemon$'\1'"`
	strPPidId=`SECFUNCfixId "$strPPidId"`
	if [[ -z "$strPPidId" ]];then
		strPPidId="pid$nPidDaemon"
	fi
	if [[ "${aDaemonsPid[$strPPidId]-}" != $nPidDaemon ]];then
		aDaemonsPid[$strPPidId]=$nPidDaemon
		#declare -p aDaemonsPid
		SECFUNCcfgWriteVar aDaemonsPid
	fi
}

############################# MAIN ###############################
if $bRegisterOnly;then
	FUNCregisterDaemon
	exit
fi

if $bList;then
	FUNClist
	exit
fi

if $bDaemon;then
	SECFUNCuniqueLock --daemonwait
	FUNCregisterDaemon
	while true;do
		secDaemonsControl.sh --checkhold
		FUNClist
		#sleep 10
		read -n 1 -t 10 #allows hit enter to refresh now
	done
	exit
fi

if $bCheckHold;then
	FUNCregisterDaemon
	if $bHoldScripts;then
		echoc --info "$strSelfName: script on hold (hit: 'y' to run once; 'r' to release all)..."
		
		SECONDS=0
		while $bHoldScripts;do
			echo -ne "${SECONDS}s\r"
		
			#sleep 5
			read -n 1 -t 5 strResp
			if [[ "$strResp" == "y" ]];then
				break
			elif [[ "$strResp" == "r" ]];then
				SECFUNCcfgWriteVar bHoldScripts=false
				break
			fi
		
			SECFUNCcfgRead
		done
		
		echo
		echoc --info "$strSelfName: script continues..."
	fi
elif $bReleaseAll;then
	echoc --info "scripts will continue execution"
	SECFUNCcfgWriteVar bHoldScripts=false
elif $bHoldAll;then
	echoc --info "scripts will hold execution"
	SECFUNCcfgWriteVar bHoldScripts=true
fi

