#!/bin/bash

# Copyright (C) 2013-2013 by Henrique Abdalla
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

echo "Params: width height Xpos Ypos"
echo "Recomended for 1024x768: 1005 710 1 22"

function FUNCvalidateNumber() {
	if [[ -n "$1" ]] && [[ -n `echo "$1" |tr -d '[:digit:]'` ]];then
		echo "invalid number '$1'" >/dev/stderr
		return 1
	elif [[ -z "$1" ]];then
		echo "empty number." >/dev/stderr
		return 1
	fi
	return 0
}

# make tests to your system, this works 'here' at 1024x768
nWidth=$1
nHeight=$2
nXpos=$3
nYpos=$4

if	! FUNCvalidateNumber $nWidth	||
		! FUNCvalidateNumber $nHeight	||
		! FUNCvalidateNumber $nXpos		||
		! FUNCvalidateNumber $nYpos;
then
	exit 1
fi

while true; do 
	windowId=`xdotool getactivewindow`;
	if xwininfo -wm -id $windowId |tr -d '\n' |grep -q "Maximized Vert.*Horz";then
		wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz;
		xdotool windowsize $windowId $nWidth $nHeight;
		xdotool windowmove $windowId $nXpos $nYpos;
		xdotool getwindowname $windowId
	fi; 
	sleep 0.5;
done

