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
eval `secinit --novarchilddb`

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
bMonitorDaemons=false
bRegisterOnly=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--checkhold" || "$1" == "-c" ]];then #help the script executing this will hold/wait, prefer using 'SECFUNCdaemonCheckHold' on your script, is MUCH faster...
		bCheckHold=true
	elif [[ "$1" == "--holdall" || "$1" == "-h" ]];then #help will request all scripts to hold execution
		bHoldAll=true
	elif [[ "$1" == "--releaseall" || "$1" == "-r" ]];then #help will request all scripts to continue execution
		bReleaseAll=true
	elif [[ "$1" == "--list" || "$1" == "-l" ]];then #help list all active daemons
		bList=true
	elif [[ "$1" == "--daemon" ]];then
		SECFUNCechoErrA "deprecated option '$1', use --mondaemons instead"
		_SECFUNCcriticalForceExit
	elif [[ "$1" == "--mondaemons" ]];then #help monitor running daemons
		bMonitorDaemons=true
	elif [[ "$1" == "--register" ]];then #help register the daemon (to be listed).
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
	SECFUNCdbgFuncInA;
	SECFUNCcfgRead
	SECFUNCdrawLine "Daemons List at `SECFUNCdtTimePrettyNow`:"
	echo -e "Index\tPid\tName"
	nCount=0
	for strDaemonId in `echo ${!aDaemonsPid[@]} |tr ' ' '\n' |sort`;do
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
	SECFUNCdbgFuncOutA;
}

function FUNCregisterOneDaemon() {
	SECFUNCdbgFuncInA;
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
	SECFUNCdbgFuncOutA;
}

############################# MAIN ###############################
if ! $bMonitorDaemons;then
	# other options/commands can communicate with monitor daemon this way, if it is running...
	SECFUNCuniqueLock --setdbtodaemon
	if ! $SECbDaemonWasAlreadyRunning;then
		SECFUNCechoBugtrackA "'$strSelfName' daemons monitor isnt running..."
	fi
fi

if $bMonitorDaemons;then
	SECFUNCuniqueLock --daemonwait
	#FUNCregisterOneDaemon
	while true;do
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		FUNClist
		#sleep 10
		#read -n 1 -t 10 #allows hit enter to refresh now
		echoc -Q -t 60 "'Enter' to refresh?@O_hold all/_release all"; case "`secascii $?`" in 
			h)$strSelfName --holdall;; 
			r)$strSelfName --releaseall;; 
		esac
	done
	exit
elif $bRegisterOnly;then
	FUNCregisterOneDaemon
elif $bList;then
	FUNClist
elif $bCheckHold;then
	FUNCregisterOneDaemon
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

