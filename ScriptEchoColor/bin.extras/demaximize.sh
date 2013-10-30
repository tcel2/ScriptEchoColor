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

########### INIT
eval `secLibsInit`
aWindowListToSkip=("Yakuake")

########### FUNCTIONS
function FUNCvalidateNumber() {
	local l_id=$1
	local l_value=${!l_id}
	if [[ -n "$l_value" ]] && [[ -n `echo "$l_value" |tr -d '[:digit:]'` ]];then
		echo "invalid number '$l_value' for $l_id" >/dev/stderr
		return 1
	elif [[ -z "$l_value" ]];then
		echoc -p "empty number at $l_id." >/dev/stderr
		return 1
	fi
	return 0
}

############### MAIN

while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help this help
		echoc --info "Params: nWidth nHeight nXpos nYpos nYposMin "
		echoc --info "Recomended for 1024x768: 1000 705 1 25 52"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--skiplist" ]];then #help skip windows names (you can collect with xwininfo) separated by comma
		shift
		aWindowListToSkip+=(`echo $1 |tr ',' ' '`)
		varset --show aWindowListToSkip
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

# make tests to your system, this works 'here' at 1024x768
varset --show nWidth=$1 #help width to resize the demaximized window
varset --show nHeight=$2 #help height to resize the demaximized window
varset --show nXpos=$3 #help X top left position to place the demaximized window
varset --show nYpos=$4 #help Y top left position to place the demaximized window
varset --show nYposMin=$5 #help Y minimum top position of non maximized windows to title do not stay behind the top panel/toolbar/globalmenubar/whateverbar

if	! FUNCvalidateNumber nWidth 	||
		! FUNCvalidateNumber nHeight 	||
		! FUNCvalidateNumber nXpos 		||
		! FUNCvalidateNumber nYpos 		||
		! FUNCvalidateNumber nYposMin ;
then
	exit 1
fi

while true; do 
	windowId=`xdotool getactivewindow`;
	windowName=`xdotool getwindowname $windowId`
	
	bDoIt=true
	for checkName in ${aWindowListToSkip[@]};do
		if [[ "$checkName" == "$windowName" ]];then
			bDoIt=false
			break
		fi
	done
	
	if $bDoIt;then
		if xwininfo -wm -id $windowId |tr -d '\n' |grep -q "Maximized Vert.*Horz";then
			wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz;
			xdotool windowsize $windowId $nWidth $nHeight;
			xdotool windowmove $windowId $nXpos $nYpos;
			xdotool getwindowname $windowId
		else
			curPosY=`xwininfo -metric -id $windowId |grep "Absolute upper-left Y:" |sed -r 's"[[:blank:]]*Absolute upper-left Y:[[:blank:]]*([[:digit:]]*)[[:blank:]]*.*"\1"'`
			if((curPosY<nYposMin));then
				xdotool windowmove $windowId $nXpos $nYpos;
			fi
		fi;
	else
		echo "skipped $windowName"
	fi
	
	sleep 0.5;
done

