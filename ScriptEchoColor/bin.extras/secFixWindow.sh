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
eval `secinit`
aWindowListToSkip=(
	"^cairo-dock$"
	"^Desktop$"
	"^Hud$"
	"^unity-dash$"
	"^unity-launcher$"
	"^unity-panel$"
	".*VMware Player.*"
	"^Yakuake$"
	"^Conky .*"
)

#TODO initially read all windows status, and also detect new windows and read their status too, if not too cpu encumbering...

bReactivateWindow=false
strReactWindNamesRegex=""
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
	elif [[ "$1" == "--reactivate" ]];then #help <strReactWindNamesRegex> re-activates only windows that match this regex ex.: "^windowA.*|^windowB.*". A window may be active, but have no keyboard input focus, this will fix that.
		shift
		strReactWindNamesRegex="${1-}"
		bReactivateWindow=true
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

SECFUNCuniqueLock --daemonwait
#secDaemonsControl.sh --register

nScreenWidth=-1
nScreenHeight=-1
nPseudoMaxWidth=-1
nPseudoMaxHeight=-1
function FUNCupdateScreenGeometryData(){
#	declare -g nScreenWidth="` xdotool getdisplaygeometry |cut -d' ' -f1`"
#	declare -g nScreenHeight="`xdotool getdisplaygeometry |cut -d' ' -f2`"
	#anGeom=(`xrandr |grep "[*]" |gawk '{printf $1}' |tr 'x' ' '`)
	anGeom=(`xdotool getdisplaygeometry`)
	declare -g nScreenWidth="${anGeom[0]}"
	declare -g nScreenHeight="${anGeom[1]}"
	nPseudoMaxWidth=$((nScreenWidth-25)) #help width to resize the demaximized window
	nPseudoMaxHeight=$((nScreenHeight-70)) #help height to resize the demaximized window
}
FUNCupdateScreenGeometryData
nXpos=1 #help X top left position to place the demaximized window
nYpos=25 #help Y top left position to place the demaximized window
nRestoreFixXpos=5 #help restoring to non maximized window X displacement fix...
nRestoreFixYpos=27 #help restoring to non maximized window Y displacement fix...
nYposMinReadPos=52 #help Y minimum top position of non maximized window that shall be read by xwininfo, it is/seems messy I know...

#selfName=`basename "$0"`
strLogFile="$SEC_TmpFolder/SEC.$SECstrScriptSelfName.log"

########### FUNCTIONS
function FUNCvalidateNumber() {
	local l_id=$1
	local l_value=${!l_id}
	if [[ -n "$l_value" ]] && [[ -n `echo "$l_value" |tr -d '[:digit:]'` ]];then
		echo "invalid number '$l_value' for $l_id" >>/dev/stderr
		return 1
	elif [[ -z "$l_value" ]];then
		echoc -p "empty number at $l_id." >>/dev/stderr
		return 1
	fi
	return 0
}

function FUNCwindowGeom() { #@@@helper nWindowX nWindowY nWindowWidth nWindowHeight
	local lnWindowId=$1
	#eval `xwininfo -id $lnWindowId 2>"$strLogFile" |grep "Absolute\|Width\|Height" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2"'`
#	xwininfo -id $lnWindowId 2>"$strLogFile" |grep -a "Absolute\|Width\|Height" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2;"' |tr -d "\n"
#	echo "lnWindowId='$lnWindowId'" >>/dev/stderr
#	xwininfo -id $lnWindowId |grep "upper-left" >>/dev/stderr
	
#	xwininfo -id $lnWindowId 2>"$strLogFile" \
#		|egrep -a "^[[:blank:]]*((Absolute upper-left [XY]:)|(Width:)|(Height:))[[:blank:]]*[[:digit:]]*$" \
#		|sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2;"' \
#		|tr -d "\n"
	local lstrToEval="`xwininfo -id $lnWindowId`"
	#echo "lstrToEval='$lstrToEval'" >>/dev/stderr
	lstrToEval="`echo "$lstrToEval" |egrep -a "^[[:blank:]]*((Absolute upper-left [XY]:)|(Width:)|(Height:))[[:blank:]]*[[:digit:]-]*$"`"
#	echo "lstrToEval='$lstrToEval'" >>/dev/stderr
	lstrToEval="`echo "$lstrToEval" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2;"'`"
#	echo "lstrToEval='$lstrToEval'" >>/dev/stderr
	lstrToEval="`echo "$lstrToEval" |tr -d "\n"`"
	#echo "lstrToEval='$lstrToEval'" >>/dev/stderr
	
	echo "$lstrToEval"
		
#		strHexaWindowId="`printf "0x%08x" $windowId`"
#		#xdotool getwindowgeometry $nWindowId
#		strPosition="`wmctrl -lG |grep "^$strHexaWindowId "`"
#		#echo "$strPosition"
#		strPosition="`echo "$strPosition" |awk '{print $3 "\t" $4}'`"
#		nX="`echo "$strPosition" |cut -f1`"
#		nY="`echo "$strPosition" |cut -f2`"
#		echo "$nX $nY"
	
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

function FUNCvalidateAll() {
	if	! FUNCvalidateNumber nPseudoMaxWidth		||
			! FUNCvalidateNumber nPseudoMaxHeight	||
			! FUNCvalidateNumber nXpos		||
			! FUNCvalidateNumber nYpos		||
			! FUNCvalidateNumber nYposMinReadPos ;
	then
		exit 1 #there already has a problem message
	fi
}
FUNCvalidateAll

#alias ContAftErrA="SECFUNCechoErrA \"code='\`sed -n \"\${LINENO}p\" \"$0\"\`';\";continue" # THIS alias WILL ONLY WORK PROPERLY if the failing command is in the same line of it!
alias ContAftErrA="echo \" Err:L\${LINENO}:WindowUnavailable?\" >>/dev/stderr;continue" # THIS alias WILL ONLY WORK PROPERLY if the failing command is in the same line of it!

strLastSkipped=""
declare -A aWindowGeomBkp
declare -A aWindowPseudoMaximizedGeomBkp
SECFUNCdelay RefreshData --init
SECFUNCdelay bReactivateWindow --init
while true; do 
	sleep 0.25;
	
	if SECFUNCdelay RefreshData --checkorinit1 10;then
		FUNCupdateScreenGeometryData
		FUNCvalidateAll
	fi
	
	if SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	if ! windowId="`xdotool getactivewindow`";then ContAftErrA;fi
	if ! windowName="`xdotool getwindowname $windowId 2>"$strLogFile"`";then
		xdotool windowactivate `xdotool search --sync "^Desktop$"` #this way desktop shortcut keys work again!
#		while ! xdotool windowactivate `xdotool search --sync "^Desktop$"`;do #this way desktop shortcut keys work again!
#			echo "Err: unable to find 'Desktop'"
#			sleep 0.5
#		done
		ContAftErrA;
	fi
	
	# SKIP check
	bContinue=false
	for checkName in "${aWindowListToSkip[@]}";do
		#if [[ "$checkName" == "$windowName" ]];then
		if((`expr match "$windowName" "$checkName"`>0));then
			bContinue=true
			if [[ "$strLastSkipped" != "$windowName" ]];then
				echo "INFO: Skipped: $windowName"
				strLastSkipped="$windowName"
			fi
			break
		fi
	done
	if $bContinue;then continue;fi # is NOT an error...
	
	############################### DO IT ###############################
	strWindowGeom="`FUNCwindowGeom $windowId`"
	eval "$strWindowGeom"

#	bDesktopIsAtViewport0=false
#	if wmctrl -d |grep -q " VP: 0,0 ";then
#		bDesktopIsAtViewport0=true
#	fi
	anViewPortPos=(`wmctrl -d |awk '{print $6}' |tr ',' '\t'`)
	nViewPortPosX=${anViewPortPos[0]}
	nViewPortPosY=${anViewPortPos[1]}
	
	bWindowIsMissplaced=false
##	if $bDesktopIsAtViewport0;then
#	if((nViewPortPosX==0 && nWindowX<0));then
#		echo "Missplaced: X0"
#		bWindowIsMissplaced=true
#	fi
#	if((nViewPortPosY==0 && nWindowY<0));then
#		echo "Missplaced: Y0"
#		bWindowIsMissplaced=true
#	fi
#	
#	if ! $bWindowIsMissplaced;then
#		# window must be at current viewport otherwise skip it
#		if ! ((nWindowX>=0 && nWindowY>=0 && nWindowX<nScreenWidth && nWindowY<nScreenHeight));then
#			continue
#		fi
#	fi
#	#echo "strWindowGeom='$strWindowGeom',windowName='$windowName',bWindowIsMissplaced='$bWindowIsMissplaced'" >>/dev/stderr
	
	# skip windows outside of current viewport
	if((nWindowX+nWindowWidth < 0)) || ((nWindowY+nWindowHeight <0));then
		continue
	fi
	if((nWindowX>nScreenWidth)) || ((nWindowY>nScreenHeight));then
		continue
	fi
	
	if $bReactivateWindow;then
		if SECFUNCdelay bReactivateWindow --checkorinit 1.5;then
			if echo "$windowName" |egrep -q "$strReactWindNamesRegex";then
				xdotool windowactivate $windowId;
				echo "Activated: $windowName"
			fi
		fi
	fi
	
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
			if ! xdotool windowsize $windowId $nWindowWidth $nWindowHeight;then ContAftErrA;fi
			if ! xdotool windowmove $windowId $((nWindowX-nRestoreFixXpos)) $((nWindowY-nRestoreFixYpos));then ContAftErrA;fi
			
			aWindowPseudoMaximizedGeomBkp[$windowId]=""
			
			echo "Restored non-maximized size and position: $windowName"
		else
			# pseudo-mazimized
			if ! xdotool windowsize $windowId $nPseudoMaxWidth $nPseudoMaxHeight;then ContAftErrA;fi
			if ! xdotool windowmove $windowId $nXpos $nYpos;then ContAftErrA;fi
			
			#xdotool getwindowname $windowId
			aWindowPseudoMaximizedGeomBkp[$windowId]="`FUNCwindowGeom $windowId`"
			
			echo "Pseudo Maximized: $windowName"
		fi
	else ################## NOT MAXIMIZED ########################
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
		#eval `FUNCwindowGeom $windowId`
		
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
			if $bWindowIsMissplaced;then
				bFixWindowPos=true
			fi

			if(( nWindowY < 0 ));then
				echo "Missplaced: Y<0"
				bFixWindowPos=true
			fi
			if(( nWindowX < 0 ));then
				echo "Missplaced: X<0"
				bFixWindowPos=true
			fi
			
			# less than the systray top panel
			if(( nWindowY < nYposMinReadPos ));then
				echo "Missplaced: Y<Min"
				bFixWindowPos=true
			fi

			if(( nWindowX < nScreenWidth ));then
				if(( (nWindowX+nWindowWidth) > nScreenWidth ));then
					echo "Missplaced: X+W beyond Screen"
					bFixWindowPos=true
				fi
			fi
			if(( nWindowY < nScreenHeight ));then
				if(( (nWindowY+nWindowHeight) > nScreenHeight ));then
					echo "Missplaced: Y+H beyond Screen"
					bFixWindowPos=true
				fi
			fi

			if $bFixWindowPos;then
				if ! xdotool windowmove $windowId $nXpos $nYpos;then ContAftErrA;fi
				echo "Fixing (placement): $windowName"
			fi
		#fi
	fi;
done

