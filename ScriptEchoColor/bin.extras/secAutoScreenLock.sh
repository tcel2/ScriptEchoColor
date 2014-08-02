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
bGnomeMode=false
bDPMSon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Works with xscreensaver and gnome-screensaver."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--forcelightweight" || "$1" == "-f" ]];then #help force a lightweight screensaver to be set, even if screen was manually locked (only for xscreensaver)
		bForceLightWeight=true
	elif [[ "$1" == "--gnome" ]];then #help use gnome-screensaver-command to lock the screen
		bGnomeMode=true
	elif [[ "$1" == "--monitoron" ]];then #help force keep the monitor on
		bDPMSon=true
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

function FUNCscreensaverStatus() {
	if $bGnomeMode;then
		gnome-screensaver-command --query
	else
		xscreensaver-command -time&&:
	fi
	return 0
}

nLightweightHackId=1
bWasLockedByThisScript=false
bHackIdChecked=false
while true;do
	bIsLocked=false
	
	#strXscreensaverStatus="`xscreensaver-command -time`"&&: #it may not have been loaded yet..
	
	#if echo "$strXscreensaverStatus" |grep "screen locked since";then
	if $bGnomeMode;then
		# this one is not prompty and may fail...
		if FUNCscreensaverStatus |grep "The screensaver is active";then
			bIsLocked=true
		fi
	else
		if FUNCscreensaverStatus |grep "screen locked since";then
			bIsLocked=true
		fi
	fi
	
	if $bIsLocked;then
		bWasLockedByThisScript=false #just to reset the value as screen is unlocked
		bHackIdChecked=false #just to reset the value as screen is unlocked
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
			#if echoc -x "xscreensaver-command -lock";then #lock may fail, so will be retried
			nScreensaverRet=0
			if $bGnomeMode;then
				gnome-screensaver-command --lock&&:
				nScreensaverRet=$?
			else
				echoc -x "xscreensaver-command -select $nLightweightHackId"&&:
				nScreensaverRet=$?
			fi
			
			if((nScreensaverRet==0));then #lock may fail, but will be retried; -select may lock also depending on user xscreensaver-demo configuration; -select is good as the lightweight one is promptly chosen, in case user has an opengl one by default..
				if ! $bGnomeMode;then
					echoc -x "xscreensaver-command -lock"&&: #to help on really locking if -select didnt
					bHackIdChecked=false
				fi
				echoc --say "locking t t y $nRunningAtVirtualTerminal"
				bIsLocked=true #update status
				bWasLockedByThisScript=true
				sleep 1 #TODO how to detect if xscreensaver can already accept other commands?
			fi
		fi
	fi
	
	if $bIsLocked;then
		if $bDPMSon;then
			echoc -x "xset dpms force on"
		fi
		
		if $bWasLockedByThisScript || $bForceLightWeight;then
			if ! $bGnomeMode;then
				if ! $bHackIdChecked;then
					#nCurrentHackId="`echo "$strXscreensaverStatus" |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
					nCurrentHackId="`FUNCscreensaverStatus |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
					if((nCurrentHackId!=nLightweightHackId));then
						echoc -x "xscreensaver-command -select $nLightweightHackId"&&:
					else
						bHackIdChecked=true
					fi
				fi
			fi
		else
			echo "Screen locked manually."
		fi
	fi
	
	echoc -w -t 10
done

