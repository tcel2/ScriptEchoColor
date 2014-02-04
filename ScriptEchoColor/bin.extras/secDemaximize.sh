#!/bin/bash

# Copyright (C) 2013-2014 by Henrique Abdalla
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

SECFUNCuniqueLock --daemonwait

eval `xrandr |grep '*' |sed -r 's"^[[:blank:]]*([[:digit:]]*)x([[:digit:]]*)[[:blank:]]*.*"nScreenWidth=\1;nScreenHeight=\2;"'`
varset --show nScreenWidth=$nScreenWidth # to ease find code
varset --show nScreenHeight=$nScreenHeight # to ease find code
varset --show nPseudoMaxWidth=$((nScreenWidth-25)) #help width to resize the demaximized window
varset --show nPseudoMaxHeight=$((nScreenHeight-70)) #help height to resize the demaximized window
varset --show nXpos=1 #help X top left position to place the demaximized window
varset --show nYpos=25 #help Y top left position to place the demaximized window
varset --show nRestoreFixXpos=5 #help restoring to non maximized window X displacement fix...
varset --show nRestoreFixYpos=27 #help restoring to non maximized window Y displacement fix...
varset --show nYposMinReadPos=52 #help Y minimum top position of non maximized window that shall be read by xwininfo, it is/seems messy I know...

selfName=`basename "$0"`
strLogFile="$SEC_TmpFolder/SEC.$selfName.log"

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

function FUNCwindowGeom() { #@@@helper nWindowX nWindowY nWindowWidth nWindowHeight
	local lnWindowId=$1
	#eval `xwininfo -id $lnWindowId 2>"$strLogFile" |grep "Absolute\|Width\|Height" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2"'`
	xwininfo -id $lnWindowId 2>"$strLogFile" |grep -a "Absolute\|Width\|Height" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2;"' |tr -d "\n"
}

function FUNCdebugShowVars() {
	while [[ -n "$1" ]];do
		eval "echo -n \"$1=\$$1;\""
		shift
	done
	echo
}

function FUNCisMaximized() {
	local lnWindowId=$1
	if ! xwininfo -wm -id $lnWindowId 2>"$strLogFile" |tr -d '\n' |grep -q "Maximized Vert.*Horz";then
		return 1
	fi
}		

############### MAIN

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help this help
		echoc --info "Params: nPseudoMaxWidth nPseudoMaxHeight nXpos nYpos nYposMinReadPos "
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

if	! FUNCvalidateNumber nPseudoMaxWidth		||
		! FUNCvalidateNumber nPseudoMaxHeight	||
		! FUNCvalidateNumber nXpos		||
		! FUNCvalidateNumber nYpos		||
		! FUNCvalidateNumber nYposMinReadPos ;
then
	exit 1
fi

strLastSkipped=""
declare -A aWindowGeomBkp
declare -A aWindowPseudoMaximizedGeomBkp
while true; do 
	windowId=`xdotool getactivewindow`;
	windowName=`xdotool getwindowname $windowId 2>"$strLogFile" `

	bOk=true

	# check empty window name
	if [[ -z "$windowName" ]];then
		bOk=false
	fi

	# SKIP check
	if $bOk;then
		for checkName in ${aWindowListToSkip[@]};do
			#if [[ "$checkName" == "$windowName" ]];then
			if((`expr match "$windowName" "$checkName"`>0));then
				bOk=false
				if [[ "$strLastSkipped" != "$windowName" ]];then
					echo "INFO: Skipped: $windowName"
					strLastSkipped="$windowName"
				fi
				break
			fi
		done
	fi
	
	# Do it
	if $bOk;then
		bPseudoMaximized=false
		if [[ -n "${aWindowPseudoMaximizedGeomBkp[$windowId]-}" ]];then
			bPseudoMaximized=true
		fi
		
		if FUNCisMaximized $windowId;then
			# demaximize
			codeGeomMax="`FUNCwindowGeom $windowId`"
			wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz;
			# wait new geometry be effectively applied
			while [[ "$codeGeomMax" == "`FUNCwindowGeom $windowId`" ]];do
				#echo "wait..."
				sleep 0.1
			done
			
			#xwininfo -wm -id $windowId
#			while xwininfo -wm -id $windowId 2>"$strLogFile" |tr -d '\n' |grep -q "Maximized Vert.*Horz";do
#				echo "wait..."
#				sleep 0.1
#			done
			#sleep 1
			
			# in case user clicked directly on maximize button
			#echo "zzz: ${aWindowGeomBkp[$windowId]}" #@@@R
			if [[ -z "${aWindowGeomBkp[$windowId]-}" ]];then
#				aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
#				while true;do
#					codeGeomTmp="`FUNCwindowGeom $windowId`"
#					if [[ "$codeGeomTmp" != "${aWindowGeomBkp[$windowId]}" ]];then
#						aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
#						break
#					fi
#				done
				aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
				echo "Safe backup: ${aWindowGeomBkp[$windowId]}"
				#xwininfo -id $windowId #@@@R
			fi
			
			if $bPseudoMaximized;then
				eval "${aWindowGeomBkp[$windowId]}" #restore variables
				xdotool windowsize $windowId $nWindowWidth $nWindowHeight;
				xdotool windowmove $windowId $((nWindowX-nRestoreFixXpos)) $((nWindowY-nRestoreFixYpos));
				
				aWindowPseudoMaximizedGeomBkp[$windowId]=""
				
				echo "Restored non-maximized size and position: $windowName"
			else
				# pseudo-mazimized
				xdotool windowsize $windowId $nPseudoMaxWidth $nPseudoMaxHeight;
				xdotool windowmove $windowId $nXpos $nYpos;
				
				#xdotool getwindowname $windowId
				aWindowPseudoMaximizedGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
				
				echo "Pseudo Maximized: $windowName"
			fi
		else
			#eval `xwininfo -id $windowId |grep -vi "geometry\|window id\|^$" |tr ":" "=" |tr -d " -" |sed -r 's;(.*)=(.*);_\1="\2";' |grep "_AbsoluteupperleftX\|_AbsoluteupperleftY\|_Width\|_Height"`
			#aWindowGeomBkp[$windowId]=("`xwininfo -id $windowId |grep "Absolute upper-left X:\|Absolute upper-left Y:\|Width:\|Height:" |tr -d "[:alpha:]- \n"`")
			#aWindowGeomBkp[$windowId]=("`xwininfo -id $windowId |grep "Absolute upper-left X:\|Absolute upper-left Y:\|Width:\|Height:" |sed -r 's"(.*):(.*)"_\1=\2;"' |tr -d "\n -"`")
			if $bPseudoMaximized;then
				eval "${aWindowPseudoMaximizedGeomBkp[$windowId]}"
				nPMGWindowX=$nWindowX
				nPMGWindowY=$nWindowY
				nPMGWindowWidth=$nWindowWidth
				nPMGWindowHeight=$nWindowHeight
			fi
			eval `FUNCwindowGeom $windowId`
			
			# backup size and pos if NOT pseudo-maximized
			#if ((nWindowWidth<nPseudoMaxWidth)) || ((nWindowHeight<nPseudoMaxHeight)) ;then
			#FUNCdebugShowVars nWindowWidth nWindowHeight nPMGWindowWidth nPMGWindowHeight
			if	! $bPseudoMaximized || 
					((nWindowWidth<nPMGWindowWidth)) ||
					((nWindowHeight<nPMGWindowHeight));
			then
				#aWindowGeomBkp[$windowId]="nWindowX=$nWindowX;nWindowY=$nWindowY;nWindowWidth=$nWindowWidth;nWindowHeight=$nWindowHeight"
				aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
				aWindowPseudoMaximizedGeomBkp[$windowId]=""
			fi
		
			#if((nWindowY>0 && nWindowX>0));then #will skip windows outside of current viewport
				bFixWindowPos=false
				if(( nWindowY < nYposMinReadPos ));then
					bFixWindowPos=true
				fi
				if(( nWindowX < nScreenWidth ));then
					if(( (nWindowX+nWindowWidth) > nScreenWidth ));then
						bFixWindowPos=true
					fi
				fi
				if(( nWindowY < nScreenHeight ));then
					if(( (nWindowY+nWindowHeight) > nScreenHeight ));then
						bFixWindowPos=true
					fi
				fi
				if $bFixWindowPos;then
					xdotool windowmove $windowId $nXpos $nYpos;
					echo "Fixing (placement): $windowName"
				fi
			#fi
		fi;
	fi
	
	if SECFUNCdelay daemonHold --checkorinit 5;then
		secDaemonsControl.sh --checkhold
	fi
	
	sleep 0.25;
done

