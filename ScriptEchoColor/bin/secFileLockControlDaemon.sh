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

#################### Functions
function FUNCupdateActiveRequests() {
	if ! ${astrRequests+false};then
		echo "${astrRequests[@]}" |tr ' ' '\n' >"$SECstrLockFileAceptedRequests"
	fi
}

function FUNCToggleLogCheck() {
	if $bShowLogToggle;then
		if $bShowLog;then
			bShowLog=false
			echo "Log disabled." >/dev/stderr
		else
			bShowLog=true
			echo "Log enabled." >/dev/stderr
		fi
		bShowLogToggle=false
	fi
}

function FUNCremoveRequest() {
	local lnToRemove="$1"

	if grep -qx "$lnToRemove" "$SECstrLockFileRemoveRequests" 2>/dev/null;then
		local lnTotal=`SECFUNCarraySize astrRequests`
		for((i=0;i<lnTotal;i++))do
			if [[ "${astrRequests[i]}" == "$lnToRemove" ]];then
				astrRequests[i]=""
			fi
		done
		FUNCupdateActiveRequests
		
		if grep -qx "$lnToRemove" "$SECstrLockFileRequests" 2>/dev/null;then
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

#################### Init
trap 'bShowLogToggle=true;' USR1
bShowLogToggle=false
bShowLog=true

# can only have access to base functions as the file locks begin from misc up...
eval `secinit --nofilelockdaemon --base`

strSelfName="`basename "$0"`"
nPidDaemon="`pgrep -fo "/$strSelfName"`"
nSelfPid="$$"
bIsMain=false
if((nSelfPid==nPidDaemon));then
	bIsMain=true
fi

#################### Options
# "Do" variables are used at 'NonMain code area' and so have access to secinit
bDoSomething=false
nPidSkip="-1"
bCheckHasOtherPids=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--nolog" ]];then #help do not show the log
		bShowLog=false
	elif [[ "$1" == "--togglelog" ]];then #help toggle log monitor at daemon (if it has tty)
		kill -SIGUSR1 $nPidDaemon
		exit
	elif [[ "$1" == "--logmon" ]];then #help log monitor
		while true;do
			cat "$SECstrLockFileLog"
			sleep 1
		done
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

#################### NonMain code area, secinit ONLY ALLOWED HERE!!!
if ! $bIsMain ;then
	echo "nSelfPid='$nSelfPid', Daemon Pid '$nPidDaemon'" >/dev/stderr
	
	if $bDoSomething;then
		eval `secinit` # can communicate with the main process
		#echo "Libs Initialized." >/dev/stderr
		if((nSelfPid!=nPidDaemon));then
			SECFUNCvarSetDB $nPidDaemon
		fi
		
	fi

	exit
fi

#################### MAIN
echo "Lock Control Daemon started, pid='$nSelfPid'." >/dev/stderr

#TODO requests with md5sum of the real file to be locked and the pid on each line like: md5sum,pid?
#TODO AllowedPid file be named with the md5sum and containing the pid?

# check requests
while true;do
	FUNCToggleLogCheck
	astrRequests=()
	
	astrRemoveRequests=(`cat "$SECstrLockFileRemoveRequests" 2>/dev/null`)
	if((`SECFUNCarraySize astrRemoveRequests`>0));then
		for strRemoveRequest in ${astrRemoveRequests[@]};do
			FUNCremoveRequest $strRemoveRequest
		done
	fi
	
	#if [[ -f "$SECstrLockFileAllowedPid" ]];then
		# if this script is restarted, wont break last pid already granted lock rights
		#astrRequests+=(`cat "$SECstrLockFileAllowedPid"`)
		astrRequests+=(`SECFUNClockFileAllowedPid`);
	#fi
	
	# updated requests removing dups and currently allowed one
	strRequests=""
	if [[ -f "$SECstrLockFileRequests" ]];then
		strRequests="`cat "$SECstrLockFileRequests"`"
	fi
	if [[ -n "$strRequests" ]];then
		rm "$SECstrLockFileRequests"
	fi

	astrRequests+=(`echo "$strRequests" |awk ' !x[$0]++'`)
	FUNCupdateActiveRequests
	if((`SECFUNCarraySize astrRequests`>0));then
		for nAllowedPid in ${astrRequests[@]};do
			FUNCupdateActiveRequests
			
			if ! SECFUNClockFileAllowedPid --check $nAllowedPid 2>/dev/null;then
				continue
			fi
			
			if [[ -n "`echo "$nAllowedPid" |tr -d "[:digit:]"`" ]];then
				SECFUNCechoErrA "invalid nAllowedPid='$nAllowedPid'"
			fi
			if [[ -n "$nAllowedPid" ]] && [[ -d "/proc/$nAllowedPid" ]];then
				# set allowed pid
				#echo -n "$nAllowedPid" >"$SECstrLockFileAllowedPid"
				SECFUNClockFileAllowedPid --write "$nAllowedPid"
				
				if $bShowLog;then #TODO kill sigusr1 to show this log
					echo "$nAllowedPid,`SECFUNCdtTimePrettyNow`,`ps -o cmd --no-headers -p $nAllowedPid`" |tee -a "$SECstrLockFileLog"
				fi

				# check if allowed pid is active
				nLastSECONDS=$SECONDS
				while [[ -d "/proc/$nAllowedPid" ]];do
					FUNCToggleLogCheck
					
					if((nLastSECONDS<$SECONDS));then
						# check once per second
						FUNCremoveRequest $nAllowedPid
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

