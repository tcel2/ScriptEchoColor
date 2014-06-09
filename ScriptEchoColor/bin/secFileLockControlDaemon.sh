#!/bin/bash
# Copyright (C) 2004-2014 by Henrique Abdalla
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

#############################################
# THIS FILE IS BASE TO THE FILE LOCK SYSTEM #
#############################################

#################### Init
trap 'bShowLogToggle=true;' USR1
bShowLogToggle=false
bShowLog=true

# secinit must come before functions so its aliases are expanded!
# can only have access to base functions as the file locks begin from misc up...
eval `secinit --nofilelockdaemon --base`

strSelfName="`basename "$0"`"
nPidDaemon="`pgrep -fo "/$strSelfName"`"
nSelfPid="$$"
bIsMain=false
if((nSelfPid==nPidDaemon));then
	bIsMain=true
fi

#################### Functions
function FUNCupdateAceptedRequests() {
	#if ! ${astrAceptedRequests+false};then
	if((`SECFUNCarraySize astrAceptedRequests`>0));then
		echo "${astrAceptedRequests[@]}" |tr ' ' '\n' >"$SECstrLockFileAceptedRequests"
	fi
}

function FUNCToggleLogCheck() {
	if $bShowLogToggle;then
		if $bShowLog;then
			bShowLog=false
			echo "Log disabled." >>/dev/stderr
		else
			bShowLog=true
			echo "Log enabled." >>/dev/stderr
		fi
		bShowLogToggle=false
	fi
}

function FUNCremoveRequestsByInactivePids() {
	#set -x;SECFUNCechoBugtrackA "$LINENO: is alias working?";set +x #alias NOT WORKING here :(
	local lastrRequestsToValidate=()
	#if ! ${astrAceptedRequests+false};then
	if((`SECFUNCarraySize astrAceptedRequests`>0));then
		lastrRequestsToValidate+=(${astrAceptedRequests[@]})
	fi
	lastrRequestsToValidate+=(`cat "$SECstrLockFileRequests" 2>/dev/null`)
	
	local lstrRequest
	#if ! ${lastrRequestsToValidate+false};then
	if((`SECFUNCarraySize lastrRequestsToValidate`>0));then
		for lstrRequest in ${lastrRequestsToValidate[@]};do
			if [[ ! -d "/proc/$lstrRequest" ]];then
				echo "$lstrRequest" >>"$SECstrLockFileRemoveRequests"
				FUNCvalidateRequest "$lstrRequest"
			fi
		done
	fi
}

function FUNCvalidateRequest() {
	local lnToRemove="$1"
	
	local lstrBUGFIX=""
	if [[ "$lnToRemove" == "-1" ]];then
#		set -x
#		alias SECFUNCechoErrA >>/dev/stderr
#		shopt -s expand_aliases >>/dev/stderr
#		shopt -p expand_aliases	>/dev/stderr	
		SECFUNCechoErrA "BUG: lnToRemove='$lnToRemove'"
#		set +x
		lstrBUGFIX='\'
	fi
	
	if grep -qx "${lstrBUGFIX}${lnToRemove}" "$SECstrLockFileRemoveRequests" 2>/dev/null;then
		local lnTotal=`SECFUNCarraySize astrAceptedRequests`
		for((i=0;i<lnTotal;i++))do
			if [[ "${astrAceptedRequests[i]}" == "$lnToRemove" ]];then
				astrAceptedRequests[i]=""
			fi
		done
		FUNCupdateAceptedRequests
		
		if grep -qx "${lstrBUGFIX}${lnToRemove}" "$SECstrLockFileRequests" 2>/dev/null;then
			sed -i "/^${lnToRemove}$/d" "$SECstrLockFileRequests"
		fi
		
		if [[ -f "$SECstrLockFileAllowedPid" ]] && ((lnToRemove==`cat "$SECstrLockFileAllowedPid"`));then
			rm "$SECstrLockFileAllowedPid"
		fi
		
		# last thing. this informs the QuickLock to proceed..
		sed -i "/^${lnToRemove}$/d" "$SECstrLockFileRemoveRequests" 2>/dev/null
		return 0
	else
		return 1
	fi
}

#################### Options
nPidSkip="-1"
bCheckHasOtherPids=false
bKillDaemon=false
bRestartDaemon=false
bLogMonitor=false
bToggleLog=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--nolog" ]];then #help do not show the log
		bShowLog=false
	elif [[ "$1" == "--togglelog" ]];then #help toggle log monitor at daemon (if it has tty)
		bToggleLog=true
	elif [[ "$1" == "--kill" ]];then #help kill the daemon, avoid using this...
		bKillDaemon=true
	elif [[ "$1" == "--restart" ]];then #help restart the daemon, avoid using this...
		bKillDaemon=true
		bRestartDaemon=true
	elif [[ "$1" == "--logmon" ]];then #help log monitor
		bLogMonitor=true
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bToggleLog;then
	kill -SIGUSR1 $nPidDaemon
fi

if $bKillDaemon;then
	pgrep -f $strSelfName
	if $bIsMain;then
		SEC_WARN=true SECFUNCechoWarnA "killing self nSelfPid=$nSelfPid, nPidDaemon=$nPidDaemon..."
	fi
	kill -SIGKILL $nPidDaemon
fi
	
if $bRestartDaemon;then
	secFileLockControlDaemon.sh >>/dev/stderr &
fi

if $bLogMonitor;then
	echo "Daemon Pid: $nPidDaemon"
	tail -f "$SECstrLockFileLog"
fi

# MUST BE LAST CHECK BEFORE MAIN CODE!
if ! $bIsMain ;then
	echo "$strSelfName: nSelfPid='$nSelfPid', Daemon Pid '$nPidDaemon'" >>/dev/stderr
	exit
fi

#################### MAIN
echo "Lock Control Daemon started, pid='$nSelfPid'." >>/dev/stderr
exec 2>> "$SECstrLockFileLog"
exec 1>&2                   

#TODO requests with md5sum of the real file to be locked and the pid on each line like: md5sum,pid?
#TODO AllowedPid file be named with the md5sum and containing the pid?

strAcceptDelayId="TimeTakenToAcceptRequest"

# check requests
while true;do
	SECFUNCdelay "$strAcceptDelayId" --init
	FUNCToggleLogCheck
	astrAceptedRequests=()
	
	astrRemoveRequests=(`cat "$SECstrLockFileRemoveRequests" 2>/dev/null`)
	if((`SECFUNCarraySize astrRemoveRequests`>0));then
		for strRemoveRequest in ${astrRemoveRequests[@]};do
			FUNCvalidateRequest $strRemoveRequest
		done
	fi
	
	#if [[ -f "$SECstrLockFileAllowedPid" ]];then
		# if this script is restarted, wont break last pid already granted lock rights
		#astrAceptedRequests+=(`cat "$SECstrLockFileAllowedPid"`)
		astrAceptedRequests+=(`SECFUNClockFileAllowedPid`);
	#fi
	
	# updated requests removing dups and currently allowed one
	astrRequests=()
	if [[ -f "$SECstrLockFileRequests" ]];then
		astrRequests+=(`cat "$SECstrLockFileRequests" 2>/dev/null |awk ' !x[$0]++'`)
		rm "$SECstrLockFileRequests"
		#if((${#astrRequests[@]}>0));then
		if((`SECFUNCarraySize astrRequests`>0));then
			for strRequest in ${astrRequests[@]};do
				if SECFUNClockFileAllowedPid --check "$strRequest";then
					astrAceptedRequests+=($strRequest)
				fi
			done
		fi
	fi
	FUNCupdateAceptedRequests
	if((`SECFUNCarraySize astrAceptedRequests`>0));then
		for nAllowedPid in ${astrAceptedRequests[@]};do
			FUNCupdateAceptedRequests
			
			if ! SECFUNClockFileAllowedPid --check $nAllowedPid 2>/dev/null;then
				continue
			fi
			
			if [[ -n "`echo "$nAllowedPid" |tr -d "[:digit:]"`" ]];then
				SECFUNCechoErrA "invalid nAllowedPid='$nAllowedPid'"
			fi
			if [[ -n "$nAllowedPid" ]] && [[ -d "/proc/$nAllowedPid" ]];then
				# set allowed pid
				#echo -n "$nAllowedPid" >"$SECstrLockFileAllowedPid"
				SECFUNClockFileAllowedPid --allow "$nAllowedPid"
				echo "$strAcceptDelayId='`SECFUNCdelay "$strAcceptDelayId" --get`'" >>/dev/stderr
				
				if $bShowLog;then #TODO kill sigusr1 to show this log
					# at secinit this is redirected to /dev/stderr
					echo " ->$nAllowedPid,`SECFUNCdtTimePrettyNow`,`ps -o cmd --no-headers -p $nAllowedPid`" #|tee -a "$SECstrLockFileLog"
				fi

				# check if allowed pid is active
				nLastSECONDS=$SECONDS
				while [[ -d "/proc/$nAllowedPid" ]];do
					FUNCToggleLogCheck
					
					if((nLastSECONDS<$SECONDS));then # check once per second
						# MAINTENANCE VALIDATIONS HERE
						FUNCremoveRequestsByInactivePids
						FUNCvalidateRequest $nAllowedPid
						nLastSECONDS=$SECONDS;
					fi
					
					# check if allowed pid file was removed (by itself or here)
					if [[ ! -f "$SECstrLockFileAllowedPid" ]];then
						SECFUNCechoDbgA "was removed SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid'"
						break
					fi
					
					sleep 0.1;
				done
			fi
		done
	fi
	
	sleep 0.1;
done

