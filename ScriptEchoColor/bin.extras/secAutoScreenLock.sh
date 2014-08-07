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
bModeUnity=false
bModeGnome=false
bModeXscreensaver=false
bDPMSon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		#SECFUNCshowHelp --colorize "Works with unity, xscreensaver and gnome-screensaver."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--unity" ]];then #help use Unity to lock the screen
		bModeUnity=true
	elif [[ "$1" == "--gnome" ]];then #help use gnome-screensaver to lock the screen
		bModeGnome=true
	elif [[ "$1" == "--xscreensaver" ]];then #help use xscreensaver to lock the screen
		bModeXscreensaver=true
	elif [[ "$1" == "--forcelightweight" || "$1" == "-f" ]];then #help force a lightweight screensaver to be set, even if screen was manually locked (only for xscreensaver)
		bForceLightWeight=true
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

nModeCount=0
if $bModeUnity;then ((nModeCount++))&&:;fi
if $bModeGnome;then ((nModeCount++))&&:;fi
if $bModeXscreensaver;then ((nModeCount++))&&:;fi
if((nModeCount==0));then
	echoc -p "one screensaver mode is required..."
	exit 1
elif((nModeCount>1));then
	echoc -p "only one screensaver mode can be selected..."
	exit 1
fi

if $bModeGnome;then
	echoc --alert "Bug: at development time 'gnome-screensaver-command --query' has reported being active while it was not..."
fi

SECFUNCuniqueLock --id "${SECstrScriptSelfName}_Display$DISPLAY" --daemonwait

strUnityLog="$SECstrTmpFolderLog/.$SECstrScriptSelfName.UnitySession.$$.log"
gdbus monitor -e -d com.canonical.Unity -o /com/canonical/Unity/Session >"$strUnityLog"&

nLightweightHackId=1
bWasLockedByThisScript=false
bHackIdChecked=false
while true;do
	bIsLocked=false
	
	#strXscreensaverStatus="`xscreensaver-command -time`"&&: #it may not have been loaded yet..
	
	# The lock may happen by other means than this script...
	if ! $bIsLocked && grep ".Locked ()\|.Unlocked ()" "$strUnityLog" |tail -n 1 |grep -q ".Locked ()";then #only locked and unlocked signals and get the last one
		bIsLocked=true
	fi
	if ! $bIsLocked && xscreensaver-command -time |grep -q "screen locked since";then
		bIsLocked=true
	fi
	if $bModeGnome;then #gnome is bugged, so only check if its option was actually chosen
		if ! $bIsLocked && gnome-screensaver-command --query |grep -q "The screensaver is active";then
			# on ubuntu, it actually uses unity to lock, and gnome only activates after screen is blanked...
			bIsLocked=true
		fi
	fi
	
	if ! $bIsLocked;then
		bWasLockedByThisScript=false #just to reset the value as screen is unlocked
		bHackIdChecked=false #just to reset the value as screen is unlocked
		
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
			if $bModeUnity;then
#				qdbus com.canonical.Unity /com/canonical/Unity/Session com.canonical.Unity.Session.Lock&&:
				qdbus com.canonical.Unity.Launcher /com/canonical/Unity/Session com.canonical.Unity.Session.Lock&&:
				nScreensaverRet=$?
			elif $bModeGnome;then
				gnome-screensaver-command --lock&&:
				nScreensaverRet=$?
			elif $bModeXscreensaver;then
				echoc -x "xscreensaver-command -select $nLightweightHackId"&&: #lock may fail, but will be retried; -select may lock also depending on user xscreensaver-demo configuration; -select is good as the lightweight one is promptly chosen, in case user has an opengl one by default..
				nScreensaverRet=$?
			fi
			
			if((nScreensaverRet==0));then
				if $bModeXscreensaver;then
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
			#echoc -x "xset dpms force on" #this would activate energy saving and turn off monitor?
			echoc -x "xset -dpms" #this prevents energy saving (turn off) from working!
		fi
		
		if $bWasLockedByThisScript || $bForceLightWeight;then
			if $bModeXscreensaver;then
				echo "bHackIdChecked=$bHackIdChecked;"
				if ! $bHackIdChecked;then
					#nCurrentHackId="`echo "$strXscreensaverStatus" |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
					nCurrentHackId="`xscreensaver-command -time |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
					if SECFUNCisNumber -nd "$nCurrentHackId";then
						echo "nCurrentHackId='$nCurrentHackId';nLightweightHackId='$nLightweightHackId';"
						if((nCurrentHackId!=nLightweightHackId));then
							echoc -x "xscreensaver-command -select $nLightweightHackId"&&:
						else
							bHackIdChecked=true
						fi
					else
						SEC_WARN=true SECFUNCechoWarnA "invalid number, waiting xscreensaver init properly: nCurrentHackId='$nCurrentHackId';"
					fi
				fi
			fi
		else
			echo "Screen locked manually."
		fi
	fi
	
	echoc -w -t 10
done

