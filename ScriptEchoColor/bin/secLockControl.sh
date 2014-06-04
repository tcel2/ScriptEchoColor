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

eval `secinit`

# THIS FILE IS BASE TO THE FILE LOCK SYSTEM
strSelfName="`basename "$0"`"
nPidOldest="`pgrep -fo "/$strSelfName"`"
if(($$!=$nPidOldest));then
	exit
fi

#this now comes from funcMisc.sh: SECstrLockControlId="`echo -n "$strSelfName" |tr '.' '_'`"

#TODO requests with md5sum of the real file to be locked and the pid on each line like: md5sum,pid
#TODO AllowedPid file be named with the md5sum and containing the pid

bShowLog=true
# check requests
while true;do
	astrRequests=()
	if [[ -f "$SECstrLockFileAllowedPid" ]];then
		# if this script is restarted, wont break last pid already granted lock rights
		astrRequests+=(`cat "$SECstrLockFileAllowedPid"`)
	fi
	
	# updated requests removing dups and currently allowed one
	strRequests=""
	if [[ -f "$SECstrLockFileRequests" ]];then
		strRequests="`cat "$SECstrLockFileRequests"`"
	fi
	if [[ -n "$strRequests" ]];then
		rm "$SECstrLockFileRequests"
	fi

	astrRequests+=(`echo "$strRequests" |awk ' !x[$0]++'`)
	if((`SECFUNCarraySize astrRequests`>0));then
		for nAllowedPid in ${astrRequests[@]};do
			if [[ -n "$nAllowedPid" ]] && [[ -d "/proc/$nAllowedPid" ]];then
				# set allowed pid
				echo -n "$nAllowedPid" >"$SECstrLockFileAllowedPid"
			
				if $bShowLog;then #TODO kill sigusr1 to show this log
					echo "Allowed Pid at `date`: $nAllowedPid"
				fi

				# check if allowed pid is active
				while [[ -d "/proc/$nAllowedPid" ]];do
					# check if allowed pid file was removed (by allowed pid)
					if [[ ! -f "$SECstrLockFileAllowedPid" ]];then
						break
					fi
					sleep 0.1;
				done
			fi
		done
	fi
	
	sleep 0.1;
done

