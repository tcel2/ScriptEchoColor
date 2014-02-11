#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

trap 'echo "(ctrl+c hit)";bAskReplaceKill=true;' INT
#trap 'FUNCaskCompizReplaceOrKill' INT #this crashes bash while read is active

################# init 
eval `secinit`

SECFUNCuniqueLock --daemonwait
secDaemonsControl.sh --register

bAskReplaceKill=false
selfName=`basename "$0"`

################## functions
function FUNCcompizReplace() {
	xdotool set_desktop_viewport 0 0 #to help not messing windows positioning
	sleep 1
	
	#xtermDetached.sh compiz --replace
	
	# no xterm to avoid log increasing cpu usage
	compiz --replace >"$SEC_TmpFolder/SEC.$selfName.compiz.$$.log" 2>&1&
};export -f FUNCcompizReplace

function FUNCaskCompizReplaceOrKill() {
	pidCompiz=`ps -A -o pid,command |grep compiz |grep -v grep |sed -r 's#^[ ]*([[:digit:]]*).*#\1#'`
	echoc -t 10 -Q "fix compiz@O_replace/_kill";case `secascii $?` in 
		r)FUNCcompizReplace;; 
		k)kill -SIGKILL $pidCompiz; echoc --info "wait a bit...";; 
	esac
}

function FUNCechoErr() {
	echo "$@" >&2
}

function FUNCwait() {
	#echoc -w -t 1 "$@" #too much cpu usage
	#echo -n "$@";read -s -t 2 -p "hit ctrl+c for options";echo
	echo -n "$@";echoc --info "hit ctrl+c for options"
	for((i=0;i<10;i++));do
		#if ! sleep 1; then break; fi #this breaks compiz also if you hit ctrl+c
		read -n 1 -t 1
		if $bAskReplaceKill;then
			break;
		fi
	done
#	echo -n "$@";read -s -n 1 -t 10 -p "options (y/...)?" resp;echo 
#	if [[ "$resp" == "y" ]];then
#		bAskReplaceKill=true
#	fi
	
	if $bAskReplaceKill;then
		FUNCaskCompizReplaceOrKill
		bAskReplaceKill=false
	fi
}

function FUNCisCompizRunning() {
	#if ps -A -o command |grep -q -x compiz; then
	FUNCechoErr "check if compiz is running..."
	if qdbus |grep -q org.freedesktop.compiz; then
		return 0
	fi
	return 1
}

function FUNCwindowForPid() {
	local pidXterm=${1-}
	shift
	local class=${1-}
	
	local listWindowId
	local windowId
	local windowIdTemp
	
	listWindowId=(`xdotool search --class $class`)
	FUNCechoErr "list = ${listWindowId[@]}"
	windowId=-1
	for windowIdTemp in ${listWindowId[@]}; do
		windowPid=`xdotool getwindowpid $windowIdTemp`
		FUNCechoErr "windowIdTemp=$windowIdTemp, windowPid=$windowPid"
		if((windowPid==pidXterm));then
			windowId=$windowIdTemp
			FUNCechoErr "windowId = $windowId"
			break
		fi
	done
	echo $windowId
}

function FUNCmoveWindow() {
	local pidXterm=${1-}
	shift
	local class=${1-}
	
	local windowId=`FUNCwindowForPid $pidXterm $class`
	local posX
	local posY
	local screenWidth
	
	if((windowId!=-1));then
		#move the xterm window to the viewport 0,1 on compiz
		posX=-1; posY=-1; eval `xdotool getwindowgeometry $windowId |grep Position |sed 's".*Position: \([0-9]*\),\([0-9]*\) .*"posX=\1;posY=\2;"'`
		screenWidth=`xdpyinfo |grep dimensions |sed 's".*dimensions: *\([0-9]*\)x.*"\1"'`
		((posX+=screenWidth))
		echoc -xR "wmctrl -i -r $windowId -e 0,$posX,$posY,-1,-1"
	fi
}

############### main
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--sleepandreplaceonce" ]];then #<delay> sleep for n seconds and replace once initially (good for startup)
		shift
		delay=$1
		if [[ -z "$delay" ]];then
			echoc -p "missing delay time"
			exit 1
		fi
		
		echoc --say "going to auto replace compiz in $delay seconds."
		export strDialogTitle="Dialog - $selfName"
		
		function FUNCtoggleDiagOnTop(){
#			while true; do
#				nWindowIdDialog=`xdotool search "$strDialogTitle" 2>/dev/null`
#				
#				if xdotool getwindowpid "$nWindowIdDialog" 2>/dev/null;then
#					while true; do
#						if ! xdotool getwindowpid "$nWindowIdDialog" 2>/dev/null;then
#							return # exit function
#						fi
#						#wmctrl -i -r $nWindowIdDialog -b add,above;
#						wmctrl -i -r $nWindowIdDialog -b toggle,above;
#						sleep 1
#					done
#				fi

#				sleep 1
#			done
			
			local lbAtLeastOnceOnTop=false
			while true; do
				nWindowIdDialog=`xdotool search "$strDialogTitle" 2>/dev/null`
				
				local lbHasPid=false
				if xdotool getwindowpid "$nWindowIdDialog" 2>/dev/null;then
					lbHasPid=true
				fi
				
				if $lbHasPid;then
					#wmctrl -i -r $nWindowIdDialog -b add,above;
					wmctrl -i -r $nWindowIdDialog -b toggle,above;
					xdotool windowactivate $nWindowIdDialog
					xdotool windowfocus $nWindowIdDialog
					xdotool windowraise $nWindowIdDialog
					lbAtLeastOnceOnTop=true
				fi
				
				if $lbAtLeastOnceOnTop && ! $lbHasPid;then
					return;
				fi
				
				sleep 1
			done
		}
		FUNCtoggleDiagOnTop&
		
		zenity --info --timeout $delay --title "$strDialogTitle" --text "hit OK to restart compiz now (or wait ${delay}s)..."
#		pidZen=$!;
#		windowList=`xdotool search --pid $pidZen 2>/dev/null`;
#		for windowId in ${windowList[@]}; do 
#			if xwininfo -id $windowId |grep -q "Map State: IsViewable";then 
#				wmctrl -ir $windowId -b add,above;
#				break
#			fi;
#		done
#		echoc -w -t $delay
		
		#bAskReplaceKill=true
		FUNCcompizReplace
	elif [[ "$1" == "--help" ]];then
		grep '" == "--' $0 |grep -v grep
		exit
	else
		echoc -wp "invalid option: $1"
		exit 1
	fi
	shift
done

FUNCechoErr "automatically replaces compiz in case it dies"

while true; do
	#echoc -c
	if FUNCisCompizRunning; then
		FUNCechoErr "compiz is running!"
	else
		FUNCechoErr "compiz is not running..."
		
#		xterm -e "echo \"TEMP xterm...\"; xterm -e \"FUNCcompizReplace\""&
#		# wait for the child to open
#		while ! ps --ppid $! 2>&1 >/dev/null; do
#			sleep 1
#		done;echo "by PID";ps --pid $!;echo "by PPID";ps --ppid $!
#		pidXterm=`ps --ppid $! -o pid --no-headers` #TODO improve this, is not working
#		kill -SIGINT $! #releases temp xterm
#		FUNCechoErr "xterm pid=$pidXterm"
		FUNCcompizReplace
		
		waitLimit=15
    count=0
		while true; do
			if FUNCisCompizRunning; then
				#FUNCmoveWindow $pidXterm xterm
				break;
			else
				FUNCechoErr "waiting for compiz to startup..."
				((count++))
				if((count>waitLimit));then
					FUNCechoErr "seems to have not started yet after ${waitLimit}s, trying again..."
					break
				fi
			fi
			sleep 1
		done
	fi

	FUNCwait #echoc -w -t 10 "hit ctrl+c for options" #sleep 10
done

