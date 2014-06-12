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

strSelfName="`basename "$0"`"
nSelfPid="$$"
strSymlinkToDaemonPidFile="/tmp/SEC.$strSelfName.DaemonPid"
#nPidDaemon="`pgrep -fo "/$strSelfName"`"
#nPidDaemon="`cat "$SECstrLockFileDaemonPid" 2>/dev/null`"
nPidDaemon="`cat "$strSymlinkToDaemonPidFile" 2>/dev/null`"
if [[ -z "$nPidDaemon" ]];then
	nPidDaemon="-1"
fi
if [[ "$1" == "--isdaemonstarted" ]];then #help check if daemon is running, return true (0) if it is (This is actually a quick option that runs very fast before any other code on this script, so this parameter must come alone)
	if [[ -d "/proc/$nPidDaemon" ]];then
		exit 0
	fi
	exit 1
fi

# secinit must come before functions so its aliases are expanded!
# can only have access to base functions as the file locks begin from misc up...
eval `secinit --nofilelockdaemon --base`

#################### Functions
function FUNCcheckDaemonStarted() {
	if [[ -d "/proc/$nPidDaemon" ]];then
		return 0
	else
		rm "$SECstrLockFileDaemonPid" 2>/dev/null
		rm "$SECstrLockFileLog" 2>/dev/null
		nPidDaemon="-1"
		return 1
	fi
}

function FUNCkillDaemon() {
	if FUNCcheckDaemonStarted;then
		ps -p $nPidDaemon
		kill -SIGKILL $nPidDaemon
#		ps -p $nPidDaemon
		while [[ -d "/proc/$nPidDaemon" ]];do
			sleep 0.1
		done
		FUNCcheckDaemonStarted # to update nPidDaemon
	fi
}

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
bDaemon=false
bGetDaemonPid=false
#bIsDaemonStarted=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--daemon" ]];then #help start the daemon
		bDaemon=true
	elif [[ "$1" == "--nolog" ]];then #help start without logging
		bShowLog=false
	elif [[ "$1" == "--togglelog" ]];then #help toggle logging
		bToggleLog=true
	elif [[ "$1" == "--kill" ]];then #help kill the daemon, avoid using this...
		bKillDaemon=true
	elif [[ "$1" == "--restart" ]];then #help restart the daemon, avoid using this...
		bRestartDaemon=true
	elif [[ "$1" == "--logmon" ]];then #help log monitor
		bLogMonitor=true
	elif [[ "$1" == "--getdaemonpid" ]];then #help get daemon pid
		bGetDaemonPid=true
#	elif [[ "$1" == "--isdaemonstarted" ]];then #help check if daemon is running, return true (0) if it is (This is actually a quick option that runs very fast before any other code on this script)
#		bIsDaemonStarted=true
		echo "DUMMY"
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

FUNCcheckDaemonStarted #to clean files

if $bGetDaemonPid;then
	echo "$nPidDaemon"
	exit
#elif $bIsDaemonStarted;then
#	if FUNCcheckDaemonStarted;then
#		exit 0
#	fi
#	exit 1
elif $bToggleLog;then
	if FUNCcheckDaemonStarted;then
		kill -SIGUSR1 $nPidDaemon
	else
		echo "Daemon is not running..." >>/dev/stderr
	fi
elif $bKillDaemon;then
	FUNCkillDaemon
elif $bRestartDaemon;then
	FUNCkillDaemon
	
	# stdout must be redirected or the terminal wont let it be child...
	# nohup or disown alone did not work...
	$0 --daemon >>/dev/stderr &
	exit
elif $bLogMonitor;then
	#TODO pgrep will find logmon running, find a workaround!
	echo "Daemon Pid: $nPidDaemon, log file '$SECstrLockFileLog'"
	tail -F "$SECstrLockFileLog"
fi

# MUST BE LAST CHECK BEFORE MAIN CODE!
#if ! $bIsMain ;then
if ! $bDaemon || FUNCcheckDaemonStarted; then
	echo "$strSelfName: nSelfPid='$nSelfPid', nPidDaemon='$nPidDaemon'" >>/dev/stderr
	exit
fi

#################### MAIN - DAEMON LOOP
echo -n "$$" >"$SECstrLockFileDaemonPid"
ln -sf "$SECstrLockFileDaemonPid" "$strSymlinkToDaemonPidFile"
nPidDaemon="$$"
echo "Lock Control Daemon started, pid='$nSelfPid'." >>/dev/stderr
exec 2>>"$SECstrLockFileLog"
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
				SECFUNCdelay "$strAcceptDelayId" --init # reinit timer just after so the time to the next one be allowed is precisely measured
				
				if $bShowLog;then #TODO kill sigusr1 to show this log
					# at secinit this is redirected to /dev/stderr
					echo " ->$nAllowedPid,`SECFUNCdtTimePrettyNow`,`ps -o pid,ppid,cmd --no-headers -p $nAllowedPid`" #|tee -a "$SECstrLockFileLog"
				fi

				# check if allowed pid is active
				nLastSECONDS=$SECONDS
				while [[ -d "/proc/$nAllowedPid" ]];do
					FUNCToggleLogCheck
					
					#if((nLastSECONDS<$SECONDS));then # check once per second
						# MAINTENANCE VALIDATIONS HERE
						FUNCremoveRequestsByInactivePids
						FUNCvalidateRequest $nAllowedPid
					#	nLastSECONDS=$SECONDS;
					#fi
					
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

