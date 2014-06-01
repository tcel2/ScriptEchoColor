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

if ! nPidNautilus=`pgrep nautilus`;then
	echoc -p "nautilus is not running"
	exit 1
fi

echoc --alert "WARNING: This is extremely experimental code, the delays are blind, if nautilus cannot attend to the commands, things may go wrong..."
echoc --alert "WARNING: the window typing is blind, if another window pops up the typing will happen on that window and not at nautilus!"
if ! echoc -q "continue?";then
	exit
fi

sedUrlDecoder='s % \\\\x g'
astrOpenLocations=(`qdbus org.gnome.Nautilus /org/freedesktop/FileManager1 org.freedesktop.FileManager1.OpenLocations |tac`);

strClipboardBkp="`xclip -selection "clip-board" -out`"
if((${#astrOpenLocations[@]}>0));then
	SECFUNCdelay --init
	echoc --say --alert "wait script finish its execution as commands will be typed on the top window..." #could find no workaround for that to type directly on specified window id ...
	
	echo "astrOpenLocations=(${astrOpenLocations[@]})"

	echoc -x "nautilus -q"
	echoc -w -t 3
	echoc -x "nautilus&"
	nPidNautilus=`pgrep nautilus`
	echoc -w -t 3
	
	function FUNCnautilusFocus() {
		#the last ones seems the right one, still a blind guess anyway...
		#xdotool windowactivate `xdotool search "^nautilus$" |tail -n 1` 
		xdotool windowactivate `xdotool search --pid $nPidNautilus |tail -n 1` 
	}
	
	FUNCnautilusFocus
	
	bFirst=true
	for strOpenLocation in "${astrOpenLocations[@]}"; do 
		#echo "$strOpenLocation" |sed -r 's@^file://(.*)@\1@' |sed "$sedUrlDecoder" |xargs printf;echo
		strOpenLocation=`echo "$strOpenLocation" |sed -r 's@^file://(.*)@\1@'`
		strOpenLocation=`echo "$strOpenLocation" |sed "$sedUrlDecoder"`
		strOpenLocation=`echo "$strOpenLocation" |xargs printf`
		echoc --info "Working With: '$strOpenLocation'";
		
		if $bFirst;then
			bFirst=false
		else
			FUNCnautilusFocus
			xdotool key "ctrl+t";sleep 1
		fi

		FUNCnautilusFocus
		xdotool key "ctrl+l";sleep 1
		
		#xdotool type --delay 300 "$strOpenLocation";sleep 1
		echo -n "$strOpenLocation" |xclip -selection "clip-board" -in
		FUNCnautilusFocus
		xdotool key "ctrl+v";sleep 1

		xdotool key Return
	
		sleep 1
	done
	
	echoc --info --say "Finished restoring nautilus tabs, it took `SECFUNCdelay --getsec` seconds."
fi
echo "$strClipboardBkp" |xclip -selection "clip-board" -in

