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

astrNewTabs=("$@")

if ! nPidNautilus=`pgrep nautilus`;then
	echoc -p "nautilus is not running"
	exit 1
fi

echoc --info "Optional parameters can be a tab locations to be added to a running nautilus."
echoc --info "Unexpectedly it is usefull to mix all nautilus windows in a single multi-tabs window!"
echoc --alert "WARNING: This is extremely experimental code, the delays are blind, if nautilus cannot attend to the commands, things may go wrong..."
echoc --alert "WARNING: the window typing is blind, if another window pops up the typing will happen on that window and not at nautilus!"

function FUNCnautilusFocus() {
	#the last ones seems the right one, still a blind guess anyway...
	#xdotool windowactivate `xdotool search "^nautilus$" |tail -n 1` 
	xdotool windowactivate `xdotool search --pid $nPidNautilus 2>/dev/null |tail -n 1` 2>/dev/null 
}

function FUNCaddTab() {
	local lnSafeDelay="1.0"
	local lbSkipTab=false
	if [[ "$1" == "--SkipAddTab" ]];then
		lbSkipTab=true
		shift
	fi
	local lstrOpenLocation="$1"
	
	if [[ ! -d "$lstrOpenLocation" ]];then
		SECFUNCexec --echo ls -ld "$lstrOpenLocation"
		SECFUNCexec --echo stat -c %F "$lstrOpenLocation"
		echoc -p "invalid location '$lstrOpenLocation'"
		return 1
	fi

	echoc --info "Working With: '$lstrOpenLocation'";
	
	if ! $lbSkipTab;then
		FUNCnautilusFocus
		xdotool key "ctrl+t" 2>/dev/null;sleep $lnSafeDelay
	fi

	FUNCnautilusFocus
	xdotool key "ctrl+l" 2>/dev/null;sleep $lnSafeDelay
	
	#xdotool type --delay 300 "$lstrOpenLocation" 2>/dev/null;sleep 1
	echo -n "$lstrOpenLocation" |xclip -selection "clip-board" -in
	FUNCnautilusFocus
	xdotool key "ctrl+v" 2>/dev/null;sleep $lnSafeDelay

	FUNCnautilusFocus
	xdotool key Return 2>/dev/null;sleep $lnSafeDelay
}

sedUrlDecoder='s"%"\\x"g'

astrOpenLocations=()
bJustAddTab=false
if [[ -n "${astrNewTabs[0]-}" ]];then
	bJustAddTab=true
	for strNewTab in "${astrNewTabs[@]}";do
		astrOpenLocations+=("$strNewTab")
		#FUNCaddTab "$strNewTab"
	done
	#exit 0
else
	astrOpenLocationsTmp=(`qdbus org.gnome.Nautilus /org/freedesktop/FileManager1 org.freedesktop.FileManager1.OpenLocations |tac`);
	for strOpenLocation in "${astrOpenLocationsTmp[@]}"; do 
		astrOpenLocations+=("`echo "$strOpenLocation" \
			|sed -r 's@^file://(.*)@\1@' \
			|sed "$sedUrlDecoder" \
			|sed 's;.*;"&";' \
			|xargs printf`")
	done
fi

varset --show astrOpenLocations
for strOpenLocation in "${astrOpenLocations[@]}"; do 
	echo "$strOpenLocation"
done

if ! echoc -q "continue at your own risk?";then
	exit
fi

strClipboardBkp="`xclip -selection "clip-board" -out`"
if((${#astrOpenLocations[@]}>0));then
	SECFUNCdelay --init
	echoc --say --alert "wait script finish its execution as commands will be typed on the top window..." #could find no workaround that could type directly on specified window id ...
	
	if ! $bJustAddTab;then
		echoc -x "nautilus -q"
		echoc -w -t 3 #TODO alternatively check it stop running
		echoc -x "nautilus >/tmp/nautilus.log 2>&1 &"
		nPidNautilus=`pgrep nautilus`
		echoc -w -t 3 #TODO check it is running
	fi

	FUNCnautilusFocus
	bFirst=true
	if $bJustAddTab;then
		bFirst=false
	fi
	for strOpenLocation in "${astrOpenLocations[@]}"; do 
		#echo "$strOpenLocation" |sed -r 's@^file://(.*)@\1@' |sed "$sedUrlDecoder" |xargs printf;echo
#		strOpenLocation=`echo "$strOpenLocation" |sed -r 's@^file://(.*)@\1@'`
#		strOpenLocation=`echo "$strOpenLocation" |sed "$sedUrlDecoder"`
#		strOpenLocation=`echo "$strOpenLocation" |xargs printf`
#		strOpenLocation=`echo "$strOpenLocation" \
#			|sed -r 's@^file://(.*)@\1@' \
#			|sed "$sedUrlDecoder" \
#			|sed 's;.*;"&";' \
#			|xargs printf`
		
		strSkipAddTab=""
		if $bFirst;then
			strSkipAddTab="--SkipAddTab"
			bFirst=false
		fi
		
		#echo "$strOpenLocation"
		FUNCaddTab $strSkipAddTab "$strOpenLocation"&&:
		
#		if $bFirst;then
#			bFirst=false
#		else
#			FUNCnautilusFocus
#			xdotool key "ctrl+t";sleep 1
#		fi

#		FUNCnautilusFocus
#		xdotool key "ctrl+l";sleep 1
#		
#		#xdotool type --delay 300 "$strOpenLocation";sleep 1
#		echo -n "$strOpenLocation" |xclip -selection "clip-board" -in
#		FUNCnautilusFocus
#		xdotool key "ctrl+v";sleep 1

#		xdotool key Return
	
#		sleep 1
	done
	
	echoc --info --say "Finished restoring nautilus tabs, it took `SECFUNCdelay --getsec` seconds."
fi
echo "$strClipboardBkp" |xclip -selection "clip-board" -in

