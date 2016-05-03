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
eval `secinit --extras`
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

bUseXterm=true
bReactivateWindow=false
strReactWindNamesRegex=""
bWaitResquestFixAllOnly=false
bForcedHold=true
bFixCompiz=false
bFixCairoDock=false
fDefaultDelay=60
bListUnmappedWindows=false
bFixYakuake=false
bActivateUnmappedWindow=false
strActivateUnmappedWindowNameId=""
bActivateUnmappedAskAndWait=false #TODO find a better way to set this default as it will be overriden at boolean check...
bFixPSensor=false
bKeepNumlockOn=false
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
	elif [[ "$1" == "--waitrequest" ]];then #help wait request and fix all windows at once, this prevents endless fixing window with focus
		bWaitResquestFixAllOnly=true
	elif [[ "$1" == "--nohold" ]];then #help intensive loop execution is prevented by default, use this to allow it.
		bForcedHold=false
	elif [[ "$1" == "--delay" ]];then #help <fDefaultDelay> delay at main loop, beware that too low value may cause trouble/problems, can be float.
		shift
		fDefaultDelay="${1-}"
	elif [[ "$1" == "--fixcompiz" ]];then #help Fix compiz and exit, as compiz may startup ignoring corners. Also, yakuake may stop working by simply directly replacing compiz, so this method workaround these issues.
		bFixCompiz=true
	elif [[ "$1" == "--fixcairodock" ]];then #help to fix cairo-dock (if it stops responding to mouse clicks) by properly replacing it.
		bFixCairoDock=true
	elif [[ "$1" == "--fixyakuake" ]];then #help to fix yakuake (if its hotkey stops working) by properly replacing it.
		bFixYakuake=true
	elif [[ "$1" == "--fixpsensor" ]];then #help to fix psensor window (on system startup, its maximized state may be ignored).
		bFixPSensor=true
	elif [[ "$1" == "--keepnumlockon" ]];then #help will check if numlock is off and turn it on
		bKeepNumlockOn=true
	elif [[ "$1" == "--noxterm" ]];then #help whenever a new xterm would be used, now will not
		bUseXterm=false
	elif [[ "$1" == "--listunmapped" ]];then #help list all unmapped windows and exit.
		bListUnmappedWindows=true
	elif [[ "$1" == "--activateunmapped" ]];then #help ~daemon <bActivateUnmappedAskAndWait> <strActivateUnmappedWindowNameId> some windows may not be listed, so when you select the terminal running this, that application window will be activated. Uses --delay value on loop.
		shift&&:
		bActivateUnmappedAskAndWait="${1-}"
		if [[ "$bActivateUnmappedAskAndWait" != "true" ]];then bActivateUnmappedAskAndWait=false;fi
		shift&&:
		strActivateUnmappedWindowNameId="${1-}"
		
		bActivateUnmappedWindow=true
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

if ! SECFUNCisNumber -n $fDefaultDelay;then
	echoc -p "invalid fDefaultDelay='$fDefaultDelay'"
	exit 1
fi

#if ! secAutoScreenLock.sh --islocked;then	SEC_WARN=true SECFUNCechoWarnA "test!";fi #@@@R

function FUNCxterm(){
	if $bUseXterm;then
		secXtermDetached.sh --skipchilddb --daemon "$@"
	else
		SECFUNCexecA -ce "$@"
	fi
}

# run these and exit
if $bFixCompiz;then
	if secAutoScreenLock.sh --islocked;then
		echoc -p --say "cant fix compiz, screen is locked..."
		SEC_WARN=true SECFUNCechoWarnA "screen must NOT be locked to fix compiz!"
		
		SECFUNCCwindowCmd --ontop "^$SECstrScriptSelfName$"
		if ! zenity --question --title "$SECstrScriptSelfName" --text="screen was locked, fix compiz now?";then
			echoc -w -t 3
			exit 1
		fi
	fi
	
	FUNCxterm metacity --replace;
	sleep 3; #this blind delay helps on properly fixing
	FUNCxterm compiz --replace
	
  exit 0
elif $bActivateUnmappedWindow;then
	if [[ -z "$strActivateUnmappedWindowNameId" ]];then
		echoc -p "invalid strActivateUnmappedWindowNameId='$strActivateUnmappedWindowNameId'"
		exit 1
	fi
	if ((fDefaultDelay>5));then
		echoc --alert "fDefaultDelay='$fDefaultDelay' > 5, suggested is 3, less may cause trouble."	
	fi
	
	# only one per window match
	SECFUNCuniqueLock --waitbecomedaemon --id "$strActivateUnmappedWindowNameId"
	
	#nPPID="`ps --no-headers -o ppid -p $PPID`"
	#ps -o pid,cmd -p $nPPID
	#ps -o pid,ppid,comm,cmd -A |egrep --color=always -C 10 "$$|$PPID|$nPPID"
	while true;do
		bDoItNow=false
		strInfo="to the window matching '@s@g$strActivateUnmappedWindowNameId@S' be activated."
		if $bActivateUnmappedAskAndWait;then
			echoc -w "Hit a key $strInfo"
			bDoItNow=true
		else
			echoc --info "Activate this terminal $strInfo"
			#if [[ $(xdotool getwindowpid $(xdotool getactivewindow)) == $nPPID ]];then 
			nPidCheck=$(xdotool getwindowpid $(xdotool getactivewindow))&&:
			if [[ -n "$nPidCheck" ]];then
				if SECFUNCppidList --checkpid $nPidCheck;then
					bDoItNow=true
				fi
			fi
		fi
		
		if $bDoItNow;then
			xdotool windowactivate $(xdotool search "$strActivateUnmappedWindowNameId")&&:
		fi;
		
		if ! $bActivateUnmappedAskAndWait;then
			echoc -w -t $fDefaultDelay "do it now";
		fi
	done
	exit 0
elif $bFixYakuake;then
 	SECFUNCexecA -ce killall -9 yakuake&&:
	SECFUNCexecA -ce sleep 5 # does this really help?
	FUNCxterm yakuake --nofork
	exit 0
elif $bFixCairoDock;then
	SECFUNCexecA -ce pkill cairo-dock&&:
	SECFUNCexecA -ce pkill cairo-dock-unity-bridge&&:
	
	while SECFUNCexecA -ce pgrep cairo-dock;do
		sleep 1
	done
	
	#cairo-dock --log message
	#cairo-dock >>/tmp/".`basename "$0"`.log"&disown
	FUNCxterm cairo-dock
	exit 0
elif $bFixPSensor;then
	SECFUNCexecA -ce SECFUNCCwindowCmd --maximize "Psensor - Temperature Monitor"
	exit 0
elif $bKeepNumlockOn;then
	function SECFUNCkeepNumlockOn(){
		while true;do 
			if numlockx status |grep off;then 
				SECFUNCexecA -ce numlockx on;
			fi;
			sleep 1;
		done
	};export -f SECFUNCkeepNumlockOn
#		secXtermDetached.sh --daemon SECFUNCkeepNumlockOn
	SECFUNCkeepNumlockOn
	exit 0
elif $bListUnmappedWindows;then
	anWindowIdList=(`xdotool search ".*"`);
	echo -e "pid\twindowId\ttitle\tcmd";
	for nWindowId in "${anWindowIdList[@]}";do 
		if xwininfo -id $nWindowId |grep -q IsUnMapped;then 
			nWindowPid=`xdotool getwindowpid $nWindowId 2>/dev/null`;
			if [[ -n "$nWindowPid" ]];then 
				echo -e "$nWindowPid\t$nWindowId\t`xdotool getwindowname $nWindowId`\t`ps --no-headers -o cmd -p $nWindowPid`";
			fi;
		fi;
	done |sort -n
  exit 0
fi

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

# just creating globals
nWindowX= 
nWindowY= 
nWindowWidth=
nWindowHeight=
function FUNCwindowGeom() {
	local lnWindowId=$1
	
	local lstrToEval=""
	if lstrToEval="`xwininfo -id $lnWindowId`";then
		lstrToEval="`echo "$lstrToEval" |egrep -a "^[[:blank:]]*((Absolute upper-left [XY]:)|(Width:)|(Height:))[[:blank:]]*[[:digit:]-]*$"`"
		lstrToEval="`echo "$lstrToEval" |sed -r 's".*(X|Y|Width|Height):[[:blank:]]*(-?[0-9]+)"nWindow\1=\2;"'`" # defines: nWindowX nWindowY nWindowWidth nWindowHeight
		lstrToEval="`echo "$lstrToEval" |tr -d "\n"`"
	else
		return 1
	fi
	
	echo "$lstrToEval"
	return 0
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
alias ContAftErrA="echo \" Err:L\${LINENO}:WindowUnavailable?(windowId='${windowId-}')\" >>/dev/stderr;continue" # THIS alias WILL ONLY WORK PROPERLY if the failing command is in the same line of it!

function FUNCisOnCurrentViewport(){ 
	# actually checks if window is outside of current viewport,
	# and if not, means it is on current!
	
	if((nWindowX+nWindowWidth < 0)) || ((nWindowY+nWindowHeight <0));then
		return 1
	fi
	if((nWindowX>nScreenWidth)) || ((nWindowY>nScreenHeight));then
		return 1
	fi
	return 0
}

function FUNCgetViewport(){
	wmctrl -d |awk '{print $6}' |tr ',' '\t'
}

strLastSkipped=""
declare -A aWindowGeomBkp
declare -A aWindowPseudoMaximizedGeomBkp
SECFUNCdelay RefreshData --init
SECFUNCdelay bReactivateWindow --init
while true; do 
	fDelay=$fDefaultDelay
	
	if SECFUNCdelay RefreshData --checkorinit1 10;then
		FUNCupdateScreenGeometryData
		FUNCvalidateAll
	fi
	
	if $bForcedHold;then
		echoc -w "run once"
	elif SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	anWindowList=(`xdotool getactivewindow`)&&:
	bFixAllWindowsOnce=false
	if $bWaitResquestFixAllOnly || SECFUNCdelay fixAllWindowsOnce --checkorinit1 10;then
		echoc --info "Fix all windows once: warning, viewport must be changed for each window it is on, so you have to wait a bit..."
		nWait=3;if $bWaitResquestFixAllOnly;then nWait=1800;fi
		if echoc -q -t $nWait "fix all windows independently of focus, once?";then
			anWindowList=(`wmctrl -l |cut -d' ' -f1`)&&:
			bFixAllWindowsOnce=true
			fDelay=0.25 #to go very fast, once
		else
			if $bWaitResquestFixAllOnly;then
				continue
			fi
		fi
	fi
	
	bBigDelay=`SECFUNCbcPrettyCalcA --cmp "$fDelay>2.0"`
	for windowId in "${anWindowList[@]}";do
		if $bBigDelay;then
			echoc -w -t "$fDelay"
		else
			sleep $fDelay;
		fi
		
		#if ! windowId="`xdotool getactivewindow`";then ContAftErrA;fi
		if ! windowName="`xdotool getwindowname $windowId 2>"$strLogFile"`";then
			xdotool windowactivate `xdotool search --sync "^Desktop$"`&&: #this way desktop shortcut keys work again!
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
					echo "INFO: Skipped: $windowName ($windowId)"
					strLastSkipped="$windowName"
				fi
				break
			fi
		done
		if $bContinue;then continue;fi # is NOT an error...
	
		############################### DO IT ###############################
		function FUNCupdateViewportInfo() {
			declare -g anViewPortPos=(`FUNCgetViewport`)
			declare -g nViewPortPosX=${anViewPortPos[0]}
			declare -g nViewPortPosY=${anViewPortPos[1]}
			declare -g strVpMsg="(vp:$nViewPortPosX,$nViewPortPosY)"
		}
		FUNCupdateViewportInfo
		
		echo "Working with: $windowName ($windowId)"
		
		function FUNCatuWindowInfo() {
			# atu window geom info
			if ! strWindowGeom="`FUNCwindowGeom $windowId`";then ContAftErrA;fi
			eval "$strWindowGeom"
			declare -g nWindowMiddleX=$(( nWindowX+(nWindowWidth/2) ))
			declare -g nWindowMiddleY=$(( nWindowY+(nWindowHeight/2) ))
		}
		FUNCatuWindowInfo
		
		if $bFixAllWindowsOnce;then
			nNewViewPortPosX=$nViewPortPosX
			nNewViewPortPosY=$nViewPortPosY
			
			bChangeViewport=false
			
			if((nWindowMiddleX<0));then
				((nNewViewPortPosX=nViewPortPosX-nScreenWidth))&&:
				if((nNewViewPortPosX<0));then nNewViewPortPosX=0;fi
				bChangeViewport=true
			elif((nWindowMiddleX>nScreenWidth));then
				((nNewViewPortPosX=nViewPortPosX+nScreenWidth))&&:
				bChangeViewport=true
			fi
			
			if((nWindowMiddleY<0));then
				((nNewViewPortPosY=nViewPortPosY-nScreenHeight))&&:
				if((nNewViewPortPosY<0));then nNewViewPortPosY=0;fi
				bChangeViewport=true
			elif((nWindowMiddleY>nScreenHeight));then
				((nNewViewPortPosY=nViewPortPosY+nScreenHeight))&&:
				bChangeViewport=true
			fi
			
			if $bChangeViewport;then
				SECFUNCexec -c --echo xdotool set_desktop_viewport $nNewViewPortPosX $nNewViewPortPosY
				#sleep 3 #just for safety
			
				FUNCupdateViewportInfo
				
				FUNCatuWindowInfo
			fi
		fi

	#	bDesktopIsAtViewport0=false
	#	if wmctrl -d |grep -q " VP: 0,0 ";then
	#		bDesktopIsAtViewport0=true
	#	fi
		
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
	
	#	# skip windows outside of current viewport
	#	if((nWindowX+nWindowWidth < 0)) || ((nWindowY+nWindowHeight <0));then
	#		continue
	#	fi
	#	if((nWindowX>nScreenWidth)) || ((nWindowY>nScreenHeight));then
	#		continue
	#	fi
		if ! FUNCisOnCurrentViewport;then # skip windows outside of current viewport
			continue
		fi
	
		if $bReactivateWindow;then
			if SECFUNCdelay bReactivateWindow --checkorinit 1.5;then
				if echo "$windowName" |egrep -q "$strReactWindNamesRegex";then
					xdotool windowactivate $windowId;
					echo "Activated: $windowName $strVpMsg"
				fi
			fi
		fi
	
		bPseudoMaximized=false
		if [[ -n "${aWindowPseudoMaximizedGeomBkp[$windowId]-}" ]];then
			bPseudoMaximized=true
		fi
	
		if FUNCisMaximized $windowId;then
			# demaximize
			if ! codeGeomMax="`FUNCwindowGeom $windowId`";then ContAftErrA;fi
			wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz;
			# wait new geometry be effectively applied
			bErrCont=false
			while true;do
				if ! strCodeGeomCurrent="`FUNCwindowGeom $windowId`";then bErrCont=true;break;fi
				if [[ "$codeGeomMax" != "$strCodeGeomCurrent" ]];then
					break;
				fi
				#echo "wait..."
				sleep 0.1
			done
			if $bErrCont;then ContAftErrA;fi
		
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
				if ! aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`";then ContAftErrA;fi
				echo "Safe backup: ${aWindowGeomBkp[$windowId]} $strVpMsg"
				#xwininfo -id $windowId #@@@R
			fi
		
			if $bPseudoMaximized;then
				eval "${aWindowGeomBkp[$windowId]}" #restore variables
				if ! xdotool windowsize $windowId $nWindowWidth $nWindowHeight;then ContAftErrA;fi
				if ! xdotool windowmove $windowId $((nWindowX-nRestoreFixXpos)) $((nWindowY-nRestoreFixYpos));then ContAftErrA;fi
			
				aWindowPseudoMaximizedGeomBkp[$windowId]=""
			
				echo "Restored non-maximized size and position: $windowName $strVpMsg"
			else
				# pseudo-mazimized
				if ! xdotool windowsize $windowId $nPseudoMaxWidth $nPseudoMaxHeight;then ContAftErrA;fi
				if ! xdotool windowmove $windowId $nXpos $nYpos;then ContAftErrA;fi
			
				#xdotool getwindowname $windowId
				if ! aWindowPseudoMaximizedGeomBkp[$windowId]="`FUNCwindowGeom $windowId`";then ContAftErrA;fi
			
				echo "Pseudo Maximized: $windowName $strVpMsg"
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
				if ! aWindowGeomBkp[$windowId]="`FUNCwindowGeom $windowId`";then ContAftErrA;fi
				aWindowPseudoMaximizedGeomBkp[$windowId]=""
			fi
	
			#if((nWindowY>0 && nWindowX>0));then #will skip windows outside of current viewport
				bFixWindowPos=false
				if $bWindowIsMissplaced;then
					echo "Missplaced: $strVpMsg"
					bFixWindowPos=true
				fi
			
				if FUNCisOnCurrentViewport;then
					if(( nWindowY < 0 ));then
						echo "Missplaced: Y<0 $strVpMsg"
						bFixWindowPos=true
					fi
					if(( nWindowX < 0 ));then
						echo "Missplaced: X<0 $strVpMsg"
						bFixWindowPos=true
					fi
				fi
			
				# less than the systray top panel
				if(( nWindowY < nYposMinReadPos ));then
					echo "Missplaced: Y<Min $strVpMsg"
					bFixWindowPos=true
				fi

				if(( nWindowX < nScreenWidth ));then
					if(( (nWindowX+nWindowWidth) > nScreenWidth ));then
						echo "Missplaced: X+W beyond Screen $strVpMsg"
						bFixWindowPos=true
					fi
				fi
				if(( nWindowY < nScreenHeight ));then
					if(( (nWindowY+nWindowHeight) > nScreenHeight ));then
						echo "Missplaced: Y+H beyond Screen $strVpMsg"
						bFixWindowPos=true
					fi
				fi
			
				############ veto ##################
				anViewPortPosDoubleCheck=(`FUNCgetViewport`)
				if((nViewPortPosX!=${anViewPortPosDoubleCheck[0]})) || ((nViewPortPosY!=${anViewPortPosDoubleCheck[1]}));then
					echo "Veto: viewport changed nViewPortPosX='$nViewPortPosX' vs '${anViewPortPosDoubleCheck[0]}', nViewPortPosY='$nViewPortPosY' vs '${anViewPortPosDoubleCheck[1]}'"
					bFixWindowPos=false;
				fi
			
				if((nWindowMiddleX<0 || nWindowMiddleY<0 || nWindowMiddleX>nScreenWidth || nWindowMiddleY>nScreenHeight));then
					echo "Veto: window is balanced to other viewport. nWindowMiddleX='$nWindowMiddleX', nWindowMiddleY='$nWindowMiddleY'"
					bFixWindowPos=false;
				fi
				
				if ! $bFixAllWindowsOnce;then
					if ! windowIdCheck="`xdotool getactivewindow`";then ContAftErrA;fi
					if((windowId!=windowIdCheck));then
						echo "Veto: window changed."
						bFixWindowPos=false;
					fi
				fi
			
				if $bFixWindowPos;then
					if ! xdotool windowmove $windowId $nXpos $nYpos;then ContAftErrA;fi
					echo "Fixing (placement): $windowName $strVpMsg"
				fi
			#fi
		fi;
	done
	if $bFixAllWindowsOnce;then
		strMsgFixEnd="fixing windows batch ended"
		echoc --say "$strMsgFixEnd"
		
		SECFUNCCwindowCmd --ontop --delay 1 "^$SECstrScriptSelfName$"
		SECFUNCexecA -c --echo zenity --timeout 3 --info --title "$SECstrScriptSelfName" --text "$strMsgFixEnd"&&:
	fi
	
done

