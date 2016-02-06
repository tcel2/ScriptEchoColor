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
eval `secinit -i --ilog --novarchilddb` # --ilog because of the option '--checkhold' that is called by many scripts...

#if SECFUNCuniqueLock --isdaemonrunning;then
#	SECFUNCuniqueLock --setdbtodaemon
#else
#	SECFUNCechoBugtrackA "daemons monitor isnt running..."
#fi
if ! SECFUNCuniqueLock --isdaemonrunning;then
	SECFUNCechoBugtrackA "daemons monitor isnt running..."
fi

#echo $SECvarFile
#echo ">>>$SECnDaemonPid" >>/dev/stderr

strSelfName="`basename "$0"`"
declare -A aDaemonsPid
declare -a anDaemonsKeepRunning
export SEC_SAYVOL=20

#aDaemonsPid=()

#declare -p aDaemonsPid
#declare -p bHoldScripts
#type SECFUNCcfgReadDB
SECFUNCcfgReadDB
#declare -p aDaemonsPid
#declare -p bHoldScripts
if [[ -z "${bHoldScripts-}" ]];then
	SECFUNCcfgWriteVar bHoldScripts=false
fi

bReleaseAll=false
bHoldAll=false
bCheckHold=false
bList=false
bMonitorDaemons=false
bRegisterOnly=false
varset --default --allowuser bAutoHoldOnScreenLock=false
varset --default bOnHoldByExternalRequest=false
varset --default strCallerName=""

#################### FUNCTIONS
function FUNClist() {
	SECFUNCdbgFuncInA;
	SECFUNCcfgReadDB
	SECFUNCdrawLine "Daemons List at `SECFUNCdtFmt --pretty`:"
	echo -e "Index\tStatus\tPid\tName"
	nCount=0
	for strDaemonId in `echo ${!aDaemonsPid[@]} |tr ' ' '\n' |sort`;do
		nPid="${aDaemonsPid[$strDaemonId]-}"
		
		#if ps -p $nPid >/dev/null 2>&1;then
		if [[ -d "/proc/$nPid" ]];then
			strStatus=""
			if [[ "${anDaemonsKeepRunning[$nPid]-}" == "true" ]];then
				strStatus="Keep"
			else
				if $bHoldScripts;then
					strStatus="HOLD"
				else
					strStatus="run"					
				fi
			fi
			
			echo -e "$nCount\t$strStatus\t$nPid\t$strDaemonId";
			((nCount++))&&:
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
	local lnPidDaemon=$SECnDaemonPid
	if((lnPidDaemon==0));then
		lnPidDaemon=$PPID
	fi
	#SECFUNCexec --echo grep "$lnPidDaemon" $SEC_TmpFolder/.SEC.UniqueRun.*sh |SECFUNCexec --echo sed -r "s'^.*/[.]SEC[.]UniqueRun[.]([[:alnum:]_-]*)[._]sh:$lnPidDaemon$'\1'"
	#strPPidId=`grep "$lnPidDaemon" $SEC_TmpFolder/.SEC.UniqueRun.*sh |sed -r "s'^.*/[.]SEC[.]UniqueRun[.]([[:alnum:]_-]*)[._]sh:$lnPidDaemon$'\1'"`
	strPPidId=`grep "$lnPidDaemon" $SEC_TmpFolder/.SEC.UniqueRun.*sh |sed -r "s'^.*/[.]SEC[.]UniqueRun[.]([[:alnum:]_-]*)([._]sh|):$lnPidDaemon$'\1'"` # may or may not: end with .sh or _sh
	strPPidId=`SECFUNCfixId "$strPPidId"`
	if [[ -z "$strPPidId" ]];then
		strPPidId="pid$lnPidDaemon"
	fi
	if [[ "${aDaemonsPid[$strPPidId]-}" != $lnPidDaemon ]];then
		aDaemonsPid[$strPPidId]=$lnPidDaemon
		#declare -p aDaemonsPid
		SECFUNCcfgWriteVar aDaemonsPid
	fi
	SECFUNCdbgFuncOutA;
}

############################# OPTIONS ###############################
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--checkhold" || "$1" == "-c" ]];then #help the script executing this will hold/wait, prefer using 'SECFUNCdaemonCheckHold' on your script, is MUCH faster...
		bCheckHold=true
	elif [[ "$1" == "--caller" ]];then #help <strCallerName> sets name of who called this script
		shift
		varset strCallerName="${1-}"
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
	elif [[ "$1" == "--holdonlock" ]];then #help auto hold all scripts in case screen is locked
		varset --show bAutoHoldOnScreenLock=true
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

if ! $bCheckHold;then
	SECFUNCuniqueLock --setdbtodaemon # other options/commands can communicate with monitor daemon this way, if it is running...
fi

############################# MAIN ###############################
if $bMonitorDaemons;then
	SECFUNCuniqueLock --daemonwait
	#FUNCregisterOneDaemon
	while true;do
		#SECFUNCdaemonCheckHold #with a delay of 60 is not a problem so skip this
		SECFUNCvarShow bAutoHoldOnScreenLock
		if $bHoldScripts;then
			SECFUNCvarShow strCallerName
		fi
		FUNClist
		#sleep 10
		#read -n 1 -t 10 #allows hit enter to refresh now
		echoc -Q -t 60 "'Enter' to refresh?@O_hold all/_release all/_force hold all/toggle _keep pid running/_auto hold on screen lock"&&:; case "`secascii $?`" in 
			a)	SECFUNCvarToggle --show bAutoHoldOnScreenLock;; 
			f)  anDaemonsKeepRunning=(); SECFUNCcfgWriteVar anDaemonsKeepRunning;;
			h)	$strSelfName --holdall;; 
			r)	$strSelfName --releaseall;; 
			k)	nPidKeepRunning="`echoc -S "paste/type the pid to toggle 'keep running'"`";
					if SECFUNCisNumber -dn "$nPidKeepRunning";then
						if [[ -d "/proc/$nPidKeepRunning" ]];then
							if [[ "${anDaemonsKeepRunning[$nPidKeepRunning]-}" == "true" ]];then
								anDaemonsKeepRunning[$nPidKeepRunning]=false
							else
								anDaemonsKeepRunning[$nPidKeepRunning]=true
							fi
							SECFUNCcfgWriteVar anDaemonsKeepRunning
						else
							echoc -p "invalid nPidKeepRunning='$nPidKeepRunning'"
						fi
					else
						echoc -p "invalid nPidKeepRunning='$nPidKeepRunning'"
					fi
					;;
		esac
		
		SECFUNCvarReadDB
		if ! $bOnHoldByExternalRequest;then
			if $bAutoHoldOnScreenLock;then
				if secOpenNewX.sh --script isScreenLocked $DISPLAY ; then
					if ! $bHoldScripts;then #says on the 1st time bHoldScripts=true only
						echoc --info --say "screensaver is active"
					fi
					SECFUNCcfgWriteVar bHoldScripts=true
				else
					SECFUNCcfgWriteVar bHoldScripts=false
				fi
			fi
		fi
		
	done
	exit
elif $bRegisterOnly;then
	FUNCregisterOneDaemon
elif $bList;then
	FUNClist
elif $bCheckHold;then
	FUNCregisterOneDaemon
	
	: ${anDaemonsKeepRunning[$SECnDaemonPid]:=false}
	if ${anDaemonsKeepRunning[$SECnDaemonPid]};then
		SECFUNCcfgReadDB # to grant it is still to keep this one running
	fi
	: ${anDaemonsKeepRunning[$SECnDaemonPid]:=false} # a second time IS required as the array may be cleaned
	
	if ! ${anDaemonsKeepRunning[$SECnDaemonPid]};then
		if $bHoldScripts;then
			#echoc --info "$strSelfName: script on hold [`SECFUNCdtFmt --pretty`] (hit: 'y' to run once; 'r' to release all)..."
			echoc -t 0.1 -Q "This daemon pid SECnDaemonPid='$SECnDaemonPid' @Orun _once/_release all/_keep only this one running"&&:
		
			SECONDS=0
			while $bHoldScripts;do
				echo -ne "${SECONDS}s\r"
			
				#sleep 5
				read -n 1 -t 5 strResp&&:
				if [[ "$strResp" == "o" ]];then
					break
				elif [[ "$strResp" == "r" ]];then
					SECFUNCcfgWriteVar bHoldScripts=false
					break
				elif [[ "$strResp" == "k" ]];then
					anDaemonsKeepRunning[$SECnDaemonPid]=true
					SECFUNCcfgWriteVar anDaemonsKeepRunning
					break
				fi
			
				SECFUNCcfgReadDB #TODO explain: reads after why? because of the breaks?
			done
		
			echo
			echoc --info "$strSelfName: script continues [`SECFUNCdtFmt --pretty`]..."
		fi
	fi
elif $bHoldAll;then
	echoc --info "daemon scripts will hold execution"
	SECFUNCcfgWriteVar bHoldScripts=true
	varset bOnHoldByExternalRequest=true
	if [[ -z "$strCallerName" ]];then
		#varset strCallerName="`ps --no-headers -o cmd -p $PPID`"
		varset strCallerName="`ps --no-headers -o comm -p $(SECFUNCppidList) |tr "\n" " "`"
	fi
elif $bReleaseAll;then
	echoc --info "daemon scripts will continue execution"
	SECFUNCcfgWriteVar bHoldScripts=false
	varset bOnHoldByExternalRequest=false
fi

