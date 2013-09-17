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
#trap 'FUNCreplaceCompiz' INT #this crashes bash while read is active

################# init 
eval `echoc --libs-init`
bAskReplaceKill=false

################## functions
function FUNCreplaceCompiz() {
	pidCompiz=`ps -A -o pid,command |grep compiz |grep -v grep |sed -r 's#^[ ]*([[:digit:]]*).*#\1#'`
	echoc -t 10 -Q "fix compiz@O_replace/_kill";case `secascii $?` in 
		r)xtermDetached.sh compiz --replace;; 
		k)kill -SIGKILL $pidCompiz; echoc --info "wait a bit...";; 
	esac
}

function FUNCechoErr() {
	echo "$@" >&2
}

function FUNCwait() {
	#echoc -w -t 1 "$@" #too much cpu usage
	#echo -n "$@";read -s -t 2 -p "hit ctrl+c for options";echo
	echo -n "$@";echo "hit ctrl+c for options"
	for((i=0;i<10;i++));do
		if ! sleep 1; then break; fi
		if $bAskReplaceKill;then
			break;
		fi
	done
#	echo -n "$@";read -s -n 1 -t 10 -p "options (y/...)?" resp;echo 
#	if [[ "$resp" == "y" ]];then
#		bAskReplaceKill=true
#	fi
	
	if $bAskReplaceKill;then
		FUNCreplaceCompiz
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
	local pidXterm=$1
	local class=$2
	
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
	local pidXterm=$1
	local class=$2
	
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
while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--sleepandreplaceonce" ]];then #<delay> sleep for n seconds and replace once initially (good for startup)
		shift
		delay=$1
		if [[ -z "$delay" ]];then
			echoc -p "missing delay time"
			exit 1
		fi
		echoc --say "going to auto replace in $delay seconds."
		echoc -w -t $delay
		#bAskReplaceKill=true
		xtermDetached.sh compiz --replace
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
		
#		xterm -e "echo \"TEMP xterm...\"; xterm -e \"compiz --replace\""&
#		# wait for the child to open
#		while ! ps --ppid $! 2>&1 >/dev/null; do
#			sleep 1
#		done;echo "by PID";ps --pid $!;echo "by PPID";ps --ppid $!
#		pidXterm=`ps --ppid $! -o pid --no-headers` #TODO improve this, is not working
#		kill -SIGINT $! #releases temp xterm
#		FUNCechoErr "xterm pid=$pidXterm"
		xtermDetached.sh compiz --replace
		
		waitLimit=15
    count=0
		while true; do
			if FUNCisCompizRunning; then
				FUNCmoveWindow $pidXterm xterm
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

