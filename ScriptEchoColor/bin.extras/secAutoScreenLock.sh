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
bDPMSmonitorOn=false
bMovieCheck=false
nMovieCheckDelay=60
bHoldToggle=false
nDelay=10
bDebugging=false
bMouseTrickMode=false
astrSimpleCommandRegex=(
	"^chromium-browser .*flashplayer.so"
	"^/usr/bin/vlc "
	"^totem "
)
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		#SECFUNCshowHelp --colorize "Works with unity, xscreensaver and gnome-screensaver."
		SECFUNCshowHelp
		echoc --info "\tVideo players detection: "
		echo -en "\t";declare -p astrSimpleCommandRegex
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
		bDPMSmonitorOn=true
	elif [[ "$1" == "--holdtoggle" ]];then #help command a running daemon, per screen, to toggle holding execution, ex.: `DISPLAY=:1 secAutoScreenLock.sh --holdtoggle`
		bHoldToggle=true
	elif [[ "$1" == "--moviecheck" || "$1" == "-m" ]];then #help <nMovieCheckDelay> check if you are watching a movie in fullscreen and prevent screensaver from being activated
		shift
		nMovieCheckDelay="${1-}"
		
		bMovieCheck=true
	elif [[ "$1" == "--delay" ]];then #help <nDelay> main loop sleep delay
		shift
		nDelay=${1-}
	elif [[ "$1" == "--addregex" ]];then #help <strCmdRegex> when watching a movie, append a regex to match pid command for the current window being checked to prevent screensaver activation
		shift
		astrSimpleCommandRegex+=("${1-}");
	elif [[ "$1" == "--mousetrickmode" ]];then #help simulate mouse activity what will expectedly work with all screensavers but may have some side effects..
		bMouseTrickMode=true
	elif [[ "$1" == "--debug" ]];then #help to help on debugging by changing a few things... :(
		bDebugging=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

echoc --info "THESE regex will be checked:"
for strSimpleCommandRegex in "${astrSimpleCommandRegex[@]}";do
	echoc --info "\tstrSimpleCommandRegex='$strSimpleCommandRegex'"
done

if ! SECFUNCisNumber -dn "$nDelay";then
	echoc -p "invalid nDelay='$nDelay'"
	exit 1
fi

bHoldExecution=false
if $bHoldToggle;then
	if ! SECFUNCuniqueLock --id "${SECstrScriptSelfName}_Display$DISPLAY" --setdbtodaemononly;then
		echoc -p "daemon is not running."
		exit 1
	fi
	echo "SECvarFile='$SECvarFile'"
	SECFUNCvarToggle --show bHoldExecution
	exit 0
fi

if ! SECFUNCisNumber -dn $nMovieCheckDelay || ((nMovieCheckDelay==0));then
	echoc -p "invalid nMovieCheckDelay='$nMovieCheckDelay'"
	exit 1
fi

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

strDBusUnityDestination="com.canonical.Unity.Launcher"
strDBusUnityObjPath="/com/canonical/Unity/Session"
strUnityLog="$SECstrTmpFolderLog/.$SECstrScriptSelfName.UnitySession.$$.log"
gdbus monitor -e -d "$strDBusUnityDestination" -o "$strDBusUnityObjPath" >"$strUnityLog"&

nLightweightHackId=1
bWasLockedByThisScript=false
bHackIdChecked=false
while true;do
	SECFUNCvarReadDB
	
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
		
		bAllowScreenLock=true
	
		if ! nActiveVirtualTerminal="$(SECFUNCexec --echo sudo fgconsole)";then bAllowScreenLock=false;fi
		
		if ! anXorgPidList=(`pgrep Xorg`);then bAllowScreenLock=false;fi
		
		nRunningAtVirtualTerminal="`\
			ps --no-headers -o tty,cmd -p ${anXorgPidList[@]} \
			|grep $DISPLAY \
			|sed -r 's"^tty([[:digit:]]*).*"\1"'`"&&:
		if ! SECFUNCisNumber -dn "$nRunningAtVirtualTerminal";then 
			echoc -t 60 -p "invalid nRunningAtVirtualTerminal='$nRunningAtVirtualTerminal'";
			continue;
#			bAllowScreenLock=false;
		fi
			
	#	if xscreensaver-command -time |grep "screen locked since";then bAllowScreenLock=false;fi
		if((nRunningAtVirtualTerminal==nActiveVirtualTerminal));then bAllowScreenLock=false;fi
		if $bHoldExecution;then bAllowScreenLock=false;fi
	
		echo "nActiveVirtualTerminal=$nActiveVirtualTerminal;"
		echo "nRunningAtVirtualTerminal=$nRunningAtVirtualTerminal;"
		echo "anXorgPidList[@]=(${anXorgPidList[@]})"
	
		if $bAllowScreenLock;then
			#if echoc -x "xscreensaver-command -lock";then #lock may fail, so will be retried
			nScreensaverRet=0
			if $bModeUnity;then
#				qdbus com.canonical.Unity "$strDBusUnityObjPath" com.canonical.Unity.Session.Lock&&:
				qdbus "$strDBusUnityDestination" "$strDBusUnityObjPath" com.canonical.Unity.Session.Lock&&:
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
		if $bDPMSmonitorOn;then
			#echoc -x "xset dpms force on" #this would activate energy saving and turn off monitor?
			if ! xset -q |grep -q "DPMS is Disabled";then
				echoc -x "xset -dpms" #this prevents energy saving (turn off) from working!
			fi
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
	
	if ! $bIsLocked && $bMovieCheck;then 
		nActiveWindowId=-1
		strActiveWindowName=""
		bSimulateActivity=false
		for((nMovieCheck=0;nMovieCheck<1;nMovieCheck++));do #fake loop just to use break functionality
			if ! $bDebugging;then
				if ! SECFUNCdelay bMovieCheck --checkorinit1 $nMovieCheckDelay;then	
					break;
				fi
			fi
			
			if ! nActiveWindowId="`xdotool getactivewindow`";then
				break;
			fi
			echo "nActiveWindowId='$nActiveWindowId'"
			
			if ! xprop -id $nActiveWindowId |grep "_NET_WM_STATE_FULLSCREEN";then
				break;
			fi
			################### FULLSCREEN WINDOW CHECK GRANTED FROM HERE
			
			if ! strActiveWindowName="`xdotool getwindowname $nActiveWindowId`";then
				SEC_WARN=true SECFUNCechoWarn "unable to get strActiveWindowName for nActiveWindowId='$nActiveWindowId'"
				break;
			fi
			echo "strActiveWindowName='$strActiveWindowName'"
			
			if ! nActiveWindowPid="`xdotool getwindowpid $nActiveWindowId`";then
				SEC_WARN=true SECFUNCechoWarn "unable to get nActiveWindowPid for nActiveWindowId='$nActiveWindowId'"
				break;
			fi
			echo "nActiveWindowPid='$nActiveWindowPid'"
			
			nActiveWindowPPid="`ps --no-headers -o ppid -p $nActiveWindowPid`"
			echo "nActiveWindowPPid='$nActiveWindowPPid'"
			
			strActiveWindowCmd="`ps --no-headers -o cmd -p $nActiveWindowPid`"
			echo "strActiveWindowCmd='$strActiveWindowCmd'"
			
			# check what player 
			if [[ "$strActiveWindowCmd" =~ "firefox ".*"www.netflix.com" ]];then # Netflix Desktop
				if SECFUNCppidList --pid "$nActiveWindowPid" --checkpid "`pgrep netflix-desktop`";then
					bSimulateActivity=true
				fi
#			elif [[ "$strActiveWindowCmd" =~ ^"chromium-browser ".*"flashplayer.so" ]];then # Chromium Flash player
#				bSimulateActivity=true
#			elif [[ "$strActiveWindowCmd" =~ ^"/usr/bin/vlc " ]];then # VLC
#				bSimulateActivity=true
#			elif [[ "$strActiveWindowCmd" =~ ^"totem " ]];then # VLC
#				bSimulateActivity=true
			else
				bFound=false
				for strSimpleCommandRegex in "${astrSimpleCommandRegex[@]}";do
					#echo "strActiveWindowCmd='$strActiveWindowCmd'"
					if echo "$strActiveWindowCmd" |egrep "$strSimpleCommandRegex";then
						bSimulateActivity=true
						bFound=true
					fi
				done
				if ! $bFound;then
					echoc --info "Maximized window not identified."
				fi
			fi
			
			if $bSimulateActivity;then
				if pgrep xscreensaver;then
					echoc --info "some video seems to be playing, simulating screensaver activity"
					xscreensaver-command -deactivate
				fi
				
				if $bMouseTrickMode;then
					xdotool mousemove_relative -- 10 10
					sleep 0.25
					xdotool mousemove_relative -- -10 -10
				fi
			else
				SEC_WARN=true SECFUNCechoWarnA "extra info to debug below..."
#				echoc -x "xprop -id $nActiveWindowId"
#				echoc -x "xwininfo -id $nActiveWindowId"
				echoc -x "ps --no-headers -p $nActiveWindowPid"
				echoc -x "ps --no-headers -p $nActiveWindowPPid"
			fi
		done
	fi
	
	if $bHoldExecution || echoc -q -t $nDelay "hold execution?";then
		varset --show bHoldExecution=true
		if echoc -q -t $nDelay "HOLDING EXECUTION, release?";then
			varset --show bHoldExecution=false
		fi
	fi
done

