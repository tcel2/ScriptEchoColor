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

export SEC_SAYVOL=20
#echo "SECstrRunLogFile=$SECstrRunLogFile" >>/dev/stderr

bForceLightWeight=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Works with xscreensaver."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--forcelightweight" || "$1" == "-f" ]];then #help force a lightweight screensaver to be set, even if screen was manually locked
		bForceLightWeight=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

SECFUNCuniqueLock --id "${SECstrScriptSelfName}_Display$DISPLAY" --daemonwait

function FUNCxscreensaverStatus() {
	xscreensaver-command -time&&:
	return 0
}

nLightweightHackId=1
bWasLockedByThisScript=false
bHackIdChecked=false
while true;do
	bIsLocked=false
	
	#strXscreensaverStatus="`xscreensaver-command -time`"&&: #it may not have been loaded yet..
	
	#if echo "$strXscreensaverStatus" |grep "screen locked since";then
	if FUNCxscreensaverStatus |grep "screen locked since";then
		bIsLocked=true
	else
		bWasLockedByThisScript=false #just to reset the value as screen is unlocked
	fi
	
	if ! $bIsLocked;then
		bOk=true
	
		if ! nActiveVirtualTerminal="$(SECFUNCexec --echo sudo fgconsole)";then bOk=false;fi
		if ! anXorgPidList=(`pgrep Xorg`);then bOk=false;fi
		if ! nRunningAtVirtualTerminal="`\
			ps --no-headers -o tty,cmd -p ${anXorgPidList[@]} \
			|grep $DISPLAY \
			|sed -r 's"^tty([[:digit:]]*).*"\1"'`";then bOk=false;fi
	#	if xscreensaver-command -time |grep "screen locked since";then bOk=false;fi
		if ! ((nRunningAtVirtualTerminal!=nActiveVirtualTerminal));then bOk=false;fi
	
		echo "nActiveVirtualTerminal=$nActiveVirtualTerminal;"
		echo "nRunningAtVirtualTerminal=$nRunningAtVirtualTerminal;"
		echo "anXorgPidList[@]=(${anXorgPidList[@]})"
	
		if $bOk;then
			if echoc -x "xscreensaver-command -lock";then #lock may fail, so will be retried
				echoc --say "locking t t y $nRunningAtVirtualTerminal"
				bIsLocked=true #update status
				bWasLockedByThisScript=true
				bHackIdChecked=false
				sleep 1 #TODO how to detect if xscreensaver can already accept other commands?
			fi
		fi
	fi
	
	if $bIsLocked;then
		if $bWasLockedByThisScript || $bForceLightWeight;then
			if ! $bHackIdChecked;then
				#nCurrentHackId="`echo "$strXscreensaverStatus" |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
				nCurrentHackId="`FUNCxscreensaverStatus |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
				if((nCurrentHackId!=nLightweightHackId));then
					echoc -x "xscreensaver-command -select $nLightweightHackId"&&:
				else
					bHackIdChecked=true
				fi
			fi
		else
			echo "Screen locked manually."
		fi
	fi
	
	echoc -w -t 10
done

