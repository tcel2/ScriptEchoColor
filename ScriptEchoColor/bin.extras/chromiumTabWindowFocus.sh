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

eval `secLibsInit.sh`

waitStart=3
delayRaiseTabOutliner=0.1
screenLeftMarginOpen=10
screenLeftMarginClose=200
bUseScreenLeftMarginClose=false
bGoToChromiumWhenTablinkIsDoubleClicked=true

SECFUNCdelay --init
SECFUNCdelay checkIfRunning --init

#function FUNCparent() {
#	xwininfo -tree -id $1 |grep "Parent window id"
#};export -f FUNCparent
#function FUNCparentest() {
#	local check=`printf %d $1`
#	local parent=-1
#	local parentest=-1
#	
#	if [[ -z "$check" ]]; then
#		echoc -p "invalid check=$check"
#		exit 1
#	fi
#	
#	#echo "Child is: $check" >&2
#	
#	while ! FUNCparent $check |grep -q "(the root window)"; do
#	  #echo "a $check" >&2 #DEBUG info
#		xwininfo -id $check |grep "Window id" >&2 #report
#		parent=`FUNCparent $check |egrep -o "0x[^ ]* "`
#		parent=`printf %d $parent`
#		check=$parent
#		echoc -w -t 1
#	done
#	if((parent!=-1));then
#		parentest=$parent
#	fi
#	
#	if((parentest!=-1));then
#		echo $parentest
#		#echo "Parentest is: $check" >&2
#	else
#		echo $1
#		#echo "Child has no parent." >&2
#	fi
#};export -f FUNCparentest

echoc -x "renice -n 19 -p $$"

function FUNCwait() {
	#echoc -w -t 1 "$@" #too much cpu usage
	echo -n "$@";read -s -t $waitStart -p "[`date`] press a key to continue..";echo #helps with ctrl+c
}

function FUNCwindowAtMouse() {
	# info about window below mouse (even if have not focus)
	eval `xdotool getmouselocation --shell 2>/dev/null`
	windowId=$WINDOW
	mouseX=$X
	mouseY=$Y
}

bDebugInfo=false
while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--debug" ]];then
		bDebugInfo=true
	fi
	shift
done

while true; do
	chromiumWindowId=""
#	list=(`xdotool search Chromium 2>/dev/null`)
#	for windowId in `echo ${list[*]}`; do 
#		if xwininfo -id $windowId |grep "Window id" |egrep -oq " - Chromium\"$"; then
#			SECFUNCvarSet --show chromiumWindowId=$windowId
#			xwininfo -id $chromiumWindowId |grep "Window id" #report
#			break;
#		fi
#	done
	while true; do 
		FUNCwindowAtMouse;
		if xwininfo -id $windowId -all |grep -q '"chromium-browser"'; then
			SECFUNCvarSet --show chromiumWindowId=$windowId
			xwininfo -id $chromiumWindowId |grep "Window id" #report
			break;
		fi
		sleep 1;
	done
	if [[ -z "$chromiumWindowId" ]]; then
		FUNCwait #echoc -w -t $waitStart
		continue;
	fi
	
	list=(`xdotool search "Tabs Outliner" 2>/dev/null`)
	tabsOutlinerWindowId=""
	tabsOutlinerWindowIdMoveable=""
	for windowId in `echo ${list[*]}`; do 
		if xwininfo -id $windowId |grep "Window id" |egrep -oq "\"Tabs Outliner\"$"; then
			SECFUNCvarSet --show tabsOutlinerWindowIdMoveable=$windowId
#			echo ">a> $windowId"
#			echo ">b> `FUNCparentest $windowId`"
#			SECFUNCvarSet --show tabsOutlinerWindowId=`FUNCparentest $windowId`
#			echo -n ">a>";GetParentestWindow.sh $windowId
#			echo -n ">b>";str=`GetParentestWindow.sh $windowId`;echo $str
			SECFUNCvarSet --show tabsOutlinerWindowId=`GetParentestWindow.sh $windowId`
			xwininfo -id $tabsOutlinerWindowId |grep "Window id" #report
			break;
		fi
	done
	if [[ -z "$tabsOutlinerWindowId" ]]; then
		FUNCwait #echoc -w -t $waitStart
		continue;
	fi
	
	#unityLauncherWindowId=`xdotool search unity-launcher`

	list=(`xdotool search "unity-launcher" 2>/dev/null`)
	for windowId in `echo ${list[*]}`; do 
		if xwininfo -id $windowId |grep "Window id" |egrep -oq "\"unity-launcher\"$"; then
			SECFUNCvarSet --show unityLauncherWindowId=$windowId
			xwininfo -id $unityLauncherWindowId |grep "Window id" #report
			break;
		fi
	done
	if [[ -z "$unityLauncherWindowId" ]]; then
		FUNCwait #echoc -w -t $waitStart
		continue;
	fi
	
	# move once only
	echoc -x "xdotool windowmove $tabsOutlinerWindowIdMoveable 0 0"
	#echoc -x "xdotool windowmove $tabsOutlinerWindowIdMoveable 3 0"

	previousWindowId=-1
	previousChromeTabName=""
	while true; do
		#if SECFUNCbcPrettyCalc --cmpquiet "`SECFUNCdelay checkIfRunning` > 10";then
		if SECFUNCdelay checkIfRunning --checkorinit 10;then
			echoc --info "check if chromium is still running"
			if ! xdotool getwindowname $chromiumWindowId; then # 2>&1 >/dev/null
				#echoc -p "chromiumWindowId"
				break;
			fi
			if ! xdotool getwindowname $tabsOutlinerWindowId; then
				#echoc -p "tabsOutlinerWindowId"
				break;
			fi
			if ! xdotool getwindowname $tabsOutlinerWindowIdMoveable; then
				#echoc -p "tabsOutlinerWindowIdMoveable"
				break;
			fi
			if ! xdotool getwindowname $unityLauncherWindowId; then
				#echoc -p "unityLauncherWindowId"
				break;
			fi
			SECFUNCdelay checkIfRunning --init
		fi
		
		#xdotool windowmove $tabsOutlinerWindowIdMoveable 0 0
		
		FUNCwindowAtMouse
		
# not working yet...		
		# must work only if over chromium application windows
		#activeWindow=`xdotool getactivewindow`
		#activeWindow=`FUNCparentest $activeWindow`
		
		#echo "windowId=$windowId, chromiumWindowId=$chromiumWindowId, tabsOutlinerWindowId=$tabsOutlinerWindowId, previousWindowId=$previousWindowId, activeWindow=$activeWindow" #DEBUG info

# not working yet...		
		# only allowed to work if chromium windows has focus
#		if((activeWindow!=chromiumWindowId && activeWindow!=tabsOutlinerWindowId));then
#			sleep $delayRaiseTabOutliner
#			continue
#		fi
		#echo "Chromium app is active."
		
		# from chromium to tabs outliner!
		bActivate=false
		if((windowId==chromiumWindowId));then
			bActivate=true
		fi
		if((windowId==unityLauncherWindowId && previousWindowId==chromiumWindowId));then
			bActivate=true
		fi
		if $bActivate;then
			if((mouseX<screenLeftMarginOpen));then
				xdotool windowactivate $tabsOutlinerWindowId
				echo "activate TabOutliner (`date`)"
			fi
		fi
		
		# from tabs outliner to chromium
		bActivatedChromium=false
		# when a tabs outliner tab is double clicked, it changes chromium window current tab!
		if $bGoToChromiumWhenTablinkIsDoubleClicked; then
			if((windowId==tabsOutlinerWindowId));then
				currentChromeTabName=`xprop -id $chromiumWindowId |grep "^WM_NAME(STRING) = \""`
				if [[ -z "$previousChromeTabName" ]]; then
					previousChromeTabName="$currentChromeTabName"
				fi
				if [[ "$currentChromeTabName" != "$previousChromeTabName" ]]; then
					xdotool windowactivate $chromiumWindowId
					bActivatedChromium=true
				fi
				previousChromeTabName="$currentChromeTabName"
			fi
		fi
		
		if $bUseScreenLeftMarginClose;then
			if((windowId==tabsOutlinerWindowId));then
				if((mouseX>screenLeftMarginClose));then
					xdotool windowactivate $chromiumWindowId
					bActivatedChromium=true
				fi
			fi
		else
			if
				((previousWindowId==tabsOutlinerWindowId)) ||
			  ((previousWindowId==unityLauncherWindowId));
			then
				if((windowId==chromiumWindowId));then
					xdotool windowactivate $chromiumWindowId
					bActivatedChromium=true
				fi
			fi
		fi
		
		if $bActivatedChromium; then
			echo "activate Chromium (`date`)"
		fi
		
		if $bDebugInfo;then
			echo "previousWindowId=$previousWindowId"
			echo "windowId=$windowId"
			echo "chromiumWindowId=$chromiumWindowId"
			echo "tabsOutlinerWindowId=$tabsOutlinerWindowId"
			echo "tabsOutlinerWindowIdMoveable=$tabsOutlinerWindowIdMoveable"
			echo "unityLauncherWindowId=$unityLauncherWindowId"
		fi
		
		previousWindowId=$windowId
		
		if 
			((windowId==tabsOutlinerWindowId)) ||
			((windowId==tabsOutlinerWindowIdMoveable)) ||
			((windowId==chromiumWindowId)) ||
			((windowId==unityLauncherWindowId));
		then
			if ! sleep $delayRaiseTabOutliner;then exit 1;fi
			SECFUNCdelay --init
		else
			# wait 60s before increasing the delay
			if SECFUNCbcPrettyCalc --cmpquiet "`SECFUNCdelay` < 60";then
				if ! sleep $delayRaiseTabOutliner;then exit 1;fi
			else
				FUNCwait #echoc -w -t 5
			fi
		fi
	done
done

