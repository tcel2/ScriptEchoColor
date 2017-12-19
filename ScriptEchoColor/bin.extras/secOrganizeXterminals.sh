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

############### INIT/CFG

renice -n 19 -p $$
source <(secinit)

#bAskNow=false
#trap 'bAskNow=true;' INT #WHY the trap is not working!?!??!?!

############### PARAMS

#SECFUNCvarSet --default basePosX=0
#SECFUNCvarSet --default basePosY=0
bDaemon=false
nViewPortAskedX=0
nViewPortAskedY=0
bDaemonHold=true
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "append '#skipOrganize' to commands like: xterm -e \"ls #skipOrganize\", so such terminals wont be organized!"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--daemon" ]]; then #help keep running in a loop
		bDaemon=true
	elif [[ "$1" == "--nodaemonhold" ]]; then #help prevent being hold by daemon hold functionality
		bDaemonHold=false
	elif [[ "$1" == "--viewport" ]]; then #help <nViewPortAskedX> <nViewPortAskedY> what compiz viewport to place terminals?
		shift
		nViewPortAskedX="${1-}"
		shift
		nViewPortAskedY="${1-}"
#		if [[ -z "$1" ]]; then echoc -p "missing base position [$1]."; exit 1; fi
#		SECFUNCvarSet --show basePosX=`echo "$1" |sed -r 's"([[:digit:]]*)x.*"\1"'`
#		SECFUNCvarSet --show basePosY=`echo "$1" |sed -r 's"[[:digit:]]*x([[:digit:]]*)"\1"'`
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help MISSING DESCRIPTION
		echo "#your code goes here"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

###################### FUNCTIONS

function FUNCpidList() {
	#ps -A -o pid,comm |grep "xterm\|rxvt" |sed -r "s;^([ ]*[[:digit:]]*) .*;\1;"
	ps -A -o pid,comm,command |grep "^[ ]*[[:digit:]]* \(xterm\|rxvt\)" |grep -v "#skipOrganize" |sed -r "s;^([ ]*[[:digit:]]*) .*;\1;"
}

function FUNCwindowList() {
	# sort is a trick to help prevent windows change position too often!
	#xdotool search --class xterm |sort
	
	local windowId=""
	local listWindowIds=(`(xdotool search --class xterm;xdotool search --class rxvt) |sort -n`)&&:

	local lnSystemPidMax=`cat /proc/sys/kernel/pid_max`
	local listWindowIdsSorted=()
	if((`SECFUNCarraySize listWindowIds`>0));then
		for windowId in ${listWindowIds[@]};do
			local windowPid="`xdotool getwindowpid $windowId`"&&:
			if [[ -n "$windowPid" ]] && ! ps --no-headers -o command -p $windowPid |grep -q "#skipOrganize";then
				local elapsedPidTime="`ps --no-headers -o etimes -p $windowPid`"&&:
				if((elapsedPidTime==0));then elapsedPidTime=1;fi #rare case: dirty workaround to avoid invalid "octal number" creation problem
				local lnWindowPidFixedSize="`printf "%0${#lnSystemPidMax}d" ${windowPid}`"
				# sort like in the newests are the last ones
				local lnIndex="${elapsedPidTime}${lnWindowPidFixedSize}"
				listWindowIdsSorted[lnIndex]="$windowId" 
			fi
		done
	fi
	
	#`tac` will make newest windows be ordered at last slots on screen
	listWindowIdsSorted=(`echo "${listWindowIdsSorted[@]-}" |tr ' ' '\n' |tac`)
	
	#echo "listWindowIdsSorted[@]=(${listWindowIdsSorted[@]-})" >&2
	echo "${listWindowIdsSorted[@]-}" #this output will be captured
	
	return 0
}

###################### MAIN CODE
if ! SECFUNCisNumber -dn "$nViewPortAskedX";then
	echoc -p "invalid nViewPortAskedX='$nViewPortAskedX'"
	exit 1
fi
if ! SECFUNCisNumber -dn "$nViewPortAskedY";then
	echoc -p "invalid nViewPortAskedY='$nViewPortAskedY'"
	exit 1
fi
nViewPortX=$nViewPortAskedX
nViewPortY=$nViewPortAskedY

if $bDaemon;then
#	if SECFUNCuniqueLock; then
#		SECFUNCvarSetDB -f
#	else
#		echoc -p "already running..."
#		exit 1
#	fi
	SECFUNCuniqueLock --daemonwait
	#secDaemonsControl.sh --register
fi

###### CONFIG 

maxRows=5
maxCols=4

nScreenWidth=-1
nScreenHeight=-1
nScreenWidthWork=-1
nScreenHeightWork=-1
screenStatusBarHeight=25
#@@@TODO make these variables automatic someday..
windowTitleHeight=25
windowBorderSize=5 #2 #5

function FUNCupdateScreenGeometryData(){
	anGeom=(`xrandr |grep "Screen" |egrep "current[^,]*," -o |tr -d " " |egrep "[[:digit:]]+x[[:digit:]]+" -o |tr "x" " "`)
#	anGeom=(`wmctrl -d |grep "[*]" |grep "WA:.*" -o |egrep "[[:digit:]]*x[[:digit:]]*" -o |tr 'x' ' '`)
#	anGeom=(`xrandr |grep "[*]" |gawk '{printf $1}' |tr 'x' ' '`)
	declare -g nScreenWidth="${anGeom[0]}"
	declare -g nScreenHeight="${anGeom[1]}"
	echoc --info "nScreenWidth='$nScreenWidth'"
	echoc --info "nScreenHeight='$nScreenHeight'"

	nScreenWidthWork=$nScreenWidth
	nScreenHeightWork=$((nScreenHeight-screenStatusBarHeight)) #workable area
	echo "nScreenWidthWork='$nScreenWidthWork'"
	echo "nScreenHeightWork='$nScreenHeightWork'"
	
	anViewportGeom=(`wmctrl -d |gawk '{printf $4}' |tr 'x' ' '`)
	nViewPortMaxX=$(( (${anViewportGeom[0]}/nScreenWidth ) -1 )) #index begin on 0
	nViewPortMaxY=$(( (${anViewportGeom[1]}/nScreenHeight) -1 )) #index begin on 0
	#if((basePosX>=${anViewportGeom[0]}));then
	if((nViewPortAskedX>nViewPortMaxX));then
		#SEC_WARN=true SECFUNCechoWarnA "nViewPortX='$nViewPortX' makes basePosX='$basePosX' beyond anViewportGeom[0]='${anViewportGeom[0]}', so terminals wouldnt be visible; fixing it."
		SEC_WARN=true SECFUNCechoWarnA "nViewPortAskedX='$nViewPortAskedX' would put terminals beyond anViewportGeom[0]='${anViewportGeom[0]}'; fixing it."
		nViewPortX=$nViewPortMaxX
	else
		nViewPortX=$nViewPortAskedX
	fi
	#if((basePosY>=${anViewportGeom[1]}));then
	if((nViewPortY>nViewPortMaxY));then
		#SEC_WARN=true SECFUNCechoWarnA "nViewPortY='$nViewPortY' makes basePosY='$basePosY' beyond anViewportGeom[1]='${anViewportGeom[1]}', so terminals wouldnt be visible; fixing it."
		SEC_WARN=true SECFUNCechoWarnA "nViewPortY='$nViewPortY' would put terminals beyond anViewportGeom[1]='${anViewportGeom[1]}'; fixing it."
		nViewPortY=$nViewPortMaxY
	else
		nViewPortY=$nViewPortAskedY
	fi
	echo "nViewPortX='$nViewPortX'"
	echo "nViewPortY='$nViewPortY'"

	basePosX=$((nViewPortX*nScreenWidth))
	basePosY=$((nViewPortY*nScreenHeight))
	echo "basePosX='$basePosX'"
	echo "basePosY='$basePosY'"
}
FUNCupdateScreenGeometryData

############## DAEMON LOOP

function FUNCorganize() {
	###### AUTO SETUP
	#@@@R FUNCwindowList
	aWindowList=(`FUNCwindowList`)
	if((`SECFUNCarraySize aWindowList`==0));then
		echoc --alert "$FUNCNAME: aWindowList is empty"
		return
	fi
	
	#@@@R for asdfasdf in ${aWindowList[@]};do echo "<$asdfasdf>";done;echo "<${aWindowList[@]}>";exit #@@@R
	windowCount=${#aWindowList[@]}
	#if(( (windowCount%2)==1 ));then
	#	((windowCount++))&&:
	#fi
	echo "window list: ${aWindowList[@]}"

	columns=$((windowCount/maxRows))
	if(( (windowCount%maxRows)>0 ));then
		((columns++))&&:
	fi
	if((columns>maxCols));then
		columns=$maxCols
	fi

	remainingCols=$((windowCount%columns))
	windowCountAdd=0
	if((remainingCols>0));then
		windowCountAdd=$((columns-(windowCount%columns))) #this is usefull to last row remain on current viewport with empty slots
	fi

	windowWidth=$(( (nScreenWidthWork/columns)-windowBorderSize ))
	windowHeight=$(( nScreenHeightWork/((windowCount+windowCountAdd)/columns) ))
	windowHeight=$((windowHeight-windowTitleHeight-(windowBorderSize*2)))
#	SEC_DEBUG=true;SECFUNCechoDbgA "windowHeight=\$(( nScreenHeightWork/((windowCount+windowCountAdd)/columns) ))";SEC_DEBUG=false
#	SEC_DEBUG=true;SECFUNCechoDbgA "windowHeight=\$(( $nScreenHeightWork/(($windowCount+$windowCountAdd)/$columns) ))";SEC_DEBUG=false
#	SEC_DEBUG=true;SECFUNCechoDbgA "windowHeight=\$((windowHeight-windowTitleHeight-(windowBorderSize*2)))";SEC_DEBUG=false
#	SEC_DEBUG=true;SECFUNCechoDbgA "windowHeight=\$(($windowHeight-$windowTitleHeight-($windowBorderSize*2)))";SEC_DEBUG=false

	x=0
	y=$screenStatusBarHeight
	addX=0
	addY=$((windowHeight+windowTitleHeight+windowBorderSize)) #windowTitleHeight
	#for windowId in ${aWindowList[@]}; do 
	countSkips=0
	for((i=0;i<${#aWindowList[@]};i++));do
		windowId=${aWindowList[i]}
		bDoAddY=true
	
		echo "windowId=$windowId"
	
		# skipOrganize
		nWindowPid="`xdotool getwindowpid $windowId`"&&:
		#echo "nWindowPid='$nWindowPid'"
		if [[ -z "$nWindowPid" ]];then
			continue
		fi
		xtermCmd="`ps --no-headers -p $nWindowPid -o command`"&&:
		#echo "xtermCmd='$xtermCmd'"
		if [[ -z "$xtermCmd" ]];then
			continue
		fi
		if echo "$xtermCmd" |grep -q "#skipOrganize";then
			echo "skipping $windowId cmd: $xtermCmd"
			((countSkips++))&&:
			continue
		fi
	
		# window at column
		colIndex=$(( (i-countSkips)%columns ))
		x=$(( (windowWidth+windowBorderSize)*colIndex))
		if(( colIndex < (columns-1) ));then
				bDoAddY=false
		fi
	
		echo
	
		if ! xdotool getwindowname $windowId;then	continue;fi
		if ! xdotool getwindowgeometry $windowId |grep "Geometry:";then continue;fi
	
		if ! xwininfo -all -id $windowId |grep "Maximized" -q; then
			# adjust size
			if ! eval `xdotool getwindowgeometry $windowId |grep "Geometry:" |sed -r 's"^.*Geometry: ([[:digit:]]*)x([[:digit:]]*).*$"\
				windowWidthCurrent=\1;\
				windowHeightCurrent=\2;"'`;then continue;fi #skip on fail
			#@@@TODO after size is set, the collected size always differ from the asked one...
			if((windowWidthCurrent!=windowWidth)) || ((windowHeightCurrent!=windowHeight));then
				if ! SECFUNCexecA --echo xdotool windowsize $windowId $windowWidth $windowHeight;then continue;fi #skip if fail
				xdotool getwindowgeometry $windowId |grep "Geometry:"&&:
			fi
	
			# adjust position
			# xdotool fails to dethermine viewport, use wmctrl
			# metacity will output 4 lines, filter by the current (*) even if it actually does nothing yet
			# TODO support metacity mode (workspaces instead of viewports)
			eval `wmctrl -d |grep "[*] DG" |sed -r 's".*VP: ([[:digit:]]*),([[:digit:]]*).*"\
				viewportX=\1;\
				viewportY=\2;"'`
			SECFUNCexecA --echo xdotool windowmap $windowId &&:	#why some windows get unmapped?
			SECFUNCexecA --echo xdotool windowmove --sync $windowId \
				$(( (basePosX-viewportX)+x )) \
				$(( (basePosY-viewportY)+y )) &&: 2>/dev/null; # this can return error, but may not fail on next run...
		fi
		
		((x+=addX))&&: 
		if $bDoAddY; then
			((y+=addY))&&: 
		fi
	
		#if ! sleep 3;then exit 1;fi
	done
}

bOrganizeNow=true #first time will organize, also is set at INT trap
strPidListPrevious=""
if $bDaemon; then
	echoc -x "renice -n 19 -p $$"
	while true; do 
		FUNCupdateScreenGeometryData
		
		strPidList=`FUNCpidList`
		if $bOrganizeNow || [[ "$strPidList" != "$strPidListPrevious" ]];then
			strPidListPrevious="$strPidList"
			#$0 #call self to do the organization
			FUNCorganize
			bOrganizeNow=false
		fi
		
		if $bDaemonHold && SECFUNCdelay daemonHold --checkorinit 5;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		fi
		
		if echoc -n -q -t 60 "\rtile now";then
			bOrganizeNow=true
		fi
	done
	exit 0
else
	FUNCorganize
fi

