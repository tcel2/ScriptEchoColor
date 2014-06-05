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

trap 'bShowLogToggle=true;' USR1

eval `secinit`

bDoSomething=false
bCheckHasOtherPids=false
nPidSkip="-1"
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--hasotherpids" ]];then #help <skipPid>
		shift
		nPidSkip="${1-}"
		
		bCheckHasOtherPids=true
		
		bDoSomething=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

# THIS FILE IS BASE TO THE FILE LOCK SYSTEM
varset --show strSelfName="`basename "$0"`"
varset --show nPidOldest="`pgrep -fo "/$strSelfName"`"
varset --show nSelfPid="$$"
if(($$!=$nPidOldest));then
	if $bDoSomething;then
		SECFUNCvarSetDB $nPidOldest
		
		if $bCheckHasOtherPids;then
			if((`SECFUNCarraySize astrRequests`>0));then
				nCount="`echo "${astrRequests[@]}" |tr ' ' '\n' |grep -wv "$nPidSkip" |wc -l`"
				if((nCount>0));then
					exit 0
				fi
			fi
			exit 1
		fi
		
	fi
	
	exit
fi

#this now comes from funcMisc.sh: SECstrLockControlId="`echo -n "$strSelfName" |tr '.' '_'`"

#TODO requests with md5sum of the real file to be locked and the pid on each line like: md5sum,pid
#TODO AllowedPid file be named with the md5sum and containing the pid

function SECFUNCremoveRequest() {
	SECFUNCdbgFuncInA;
	local lnToRemove="$1"

	if grep -qx "$lnToRemove" "$SECstrLockFileRemoveRequests" 2>/dev/null;then
		local lnTotal=`SECFUNCarraySize astrRequests`
		for((i=0;i<lnTotal;i++))do
			if [[ "${astrRequests[i]}" == "$lnToRemove" ]];then
				astrRequests[i]=""
			fi
		done
		
		if grep -qx "$lnToRemove" "$SECstrLockFileRequests" 2>/dev/null;then
			sed -i "/^${lnToRemove}$/d" "$SECstrLockFileRequests"
		fi
		
		#if [[ -f "$SECstrLockFileAllowedPid" ]] && ((lnToRemove==`cat "$SECstrLockFileAllowedPid"`));then
		if SECFUNCallowedPid --cmp $lnToRemove;then
			rm "$SECstrLockFileAllowedPid"
		fi
		
		# last thing. this informs the QuickLock to proceed..
		sed -i "/^${lnToRemove}$/d" "$SECstrLockFileRemoveRequests" 2>/dev/null
		SECFUNCdbgFuncOutA;return 0
	else
		SECFUNCdbgFuncOutA;return 1
	fi
	SECFUNCdbgFuncOutA;
}

bShowLog=true
bShowLogToggle=false
# check requests
while true;do
	astrRequests=()
	
	astrRemoveRequests=(`cat "$SECstrLockFileRemoveRequests" 2>/dev/null`)
	if((`SECFUNCarraySize astrRemoveRequests`>0));then
		for strRemoveRequest in ${astrRemoveRequests[@]};do
			SECFUNCremoveRequest $strRemoveRequest
		done
	fi
	
	#if [[ -f "$SECstrLockFileAllowedPid" ]];then
		# if this script is restarted, wont break last pid already granted lock rights
		#astrRequests+=(`cat "$SECstrLockFileAllowedPid"`)
		astrRequests+=(`SECFUNCallowedPid`);
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
	varset astrRequests
	if((`SECFUNCarraySize astrRequests`>0));then
		for nAllowedPid in ${astrRequests[@]};do
			if ! SECFUNCallowedPid --check $nAllowedPid 2>/dev/null;then
				continue
			fi
			
			if [[ -n "`echo "$nAllowedPid" |tr -d "[:digit:]"`" ]];then
				SECFUNCechoErrA "invalid nAllowedPid='$nAllowedPid'"
			fi
			if [[ -n "$nAllowedPid" ]] && [[ -d "/proc/$nAllowedPid" ]];then
				# set allowed pid
				#echo -n "$nAllowedPid" >"$SECstrLockFileAllowedPid"
				SECFUNCallowedPid --write "$nAllowedPid"
				
				if $bShowLogToggle;then
					if $bShowLog;then
						bShowLog=false
					else
						bShowLog=true
					fi
					bShowLogToggle=false
				fi
				
				if $bShowLog;then #TODO kill sigusr1 to show this log
					echo "$nAllowedPid,`SECFUNCdtTimePrettyNow`,`ps -o cmd --no-headers -p $nAllowedPid`" |tee -a "$SECstrLockFileLog"
				fi

				# check if allowed pid is active
				while [[ -d "/proc/$nAllowedPid" ]];do
					if SECFUNCdelay "nAllowedPid" --checkorinit 1;then
#						# keep removing current from the requests queue
#						if grep -qx "$nAllowedPid" "$SECstrLockFileRequests" 2>/dev/null;then
#							# nAllowedPid has been already consumed from astrRequests
#							sed -i "/^${nAllowedPid}$/d" "$SECstrLockFileRequests"
#						fi
#					
#						if grep -qx "$nAllowedPid" "$SECstrLockFileRemoveRequests";then
#							# accept the removal request and inform it will be done
#							sed -i "/^${nAllowedPid}$/d" "$SECstrLockFileRemoveRequests"
#							# remove the request
#							rm "$SECstrLockFileAllowedPid"
#						fi
						
						SECFUNCremoveRequest $nAllowedPid
#						if SECFUNCremoveRequest $nAllowedPid;then
#							rm "$SECstrLockFileAllowedPid"
#						fi
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

