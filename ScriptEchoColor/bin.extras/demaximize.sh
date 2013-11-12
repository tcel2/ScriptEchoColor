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
aWindowListToSkip=("^Yakuake$" ".*VMware Player.*" "^Desktop$" "^unity-launcher$")

eval `xrandr |grep '*' |sed -r 's"^[[:blank:]]*([[:digit:]]*)x([[:digit:]]*)[[:blank:]]*.*"nScreenWidth=\1;nScreenHeight=\2;"'`
varset --show nScreenWidth=$nScreenWidth # to ease find code
varset --show nScreenHeight=$nScreenHeight # to ease find code
varset --show nWidth=$((nScreenWidth-25)) #help width to resize the demaximized window
varset --show nHeight=$((nScreenHeight-70)) #help height to resize the demaximized window
varset --show nXpos=1 #help X top left position to place the demaximized window
varset --show nYpos=25 #help Y top left position to place the demaximized window
varset --show nYposMinReadPos=52 #help Y minimum top position of non maximized window that shall be read by xwininfo, it is/seems messy I know...

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
		echoc --info "Params: nWidth nHeight nXpos nYpos nYposMinReadPos "
		echoc --info "Recomended for 1024x768: 1000 705 1 25 52"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--skiplist" ]];then #help skip windows names (you can collect with xwininfo) that can be a regexp, separated by blank space
		shift
		while [[ -n "$1" ]] && [[ "${1:0:1}" != "-" ]];do
			aWindowListToSkip+=("$1")
			shift
		done
		varset --show aWindowListToSkip
	elif [[ "$1" == "--secvarsset" ]];then #help sets variables at SEC DB, use like: var=value var=value ...
		shift
		sedVarValue="^([[:alnum:]]*)=(.*)"
		while((`expr match "$1" "^[[:alnum:]]*="`>0));do
			secVar=`  echo "$1" |sed -r "s'$sedVarValue'\1'"`
			secValue=`echo "$1" |sed -r "s'$sedVarValue'\2'"`
			if ! varset --show $secVar $secValue;then
				echoc -p "invalid var [$secVar] value [$secValue]"
				exit 1
			fi
			shift
		done
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if	! FUNCvalidateNumber nWidth		||
		! FUNCvalidateNumber nHeight	||
		! FUNCvalidateNumber nXpos		||
		! FUNCvalidateNumber nYpos		||
		! FUNCvalidateNumber nYposMinReadPos ;
then
	exit 1
fi

strLastSkipped=""
while true; do 
	windowId=`xdotool getactivewindow`;
	windowName=`xdotool getwindowname $windowId`
	
	bDoIt=true
	for checkName in ${aWindowListToSkip[@]};do
		#if [[ "$checkName" == "$windowName" ]];then
		if((`expr match "$windowName" "$checkName"`>0));then
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
			#@@@FindCodeHelper nWindowX nWindowY nWindowWidth nWindowHeight
			eval `xwininfo -id $windowId |grep "Absolute\|Width\|Height" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2"'`
			
			#if((nWindowY>0 && nWindowX>0));then #will skip windows outside of current viewport
				if(( nWindowY                 < nYposMinReadPos )) ||
					(( (nWindowX+nWindowWidth ) > nScreenWidth     )) ||
					(( (nWindowY+nWindowHeight) > nScreenHeight    ));
				then
					xdotool windowmove $windowId $nXpos $nYpos;
				fi
			#fi
		fi;
	else
		if [[ "$strLastSkipped" != "$windowName" ]];then
			echo "INFO: Skipped: $windowName"
			strLastSkipped="$windowName"
		fi
	fi
	
	sleep 0.5;
done

