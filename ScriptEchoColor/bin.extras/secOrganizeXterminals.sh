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
eval `secinit`

#bAskNow=false
#trap 'bAskNow=true;' INT #WHY the trap is not working!?!??!?!

############### PARAMS

SECFUNCvarSet --default basePosX=0
SECFUNCvarSet --default basePosY=0
bDaemon=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	if [[ "$1" == "--daemon" ]]; then
		bDaemon=true
	elif [[ "$1" == "--viewport" ]]; then
		shift
		if [[ -z "$1" ]]; then echoc -p "missing base position [$1]."; exit 1; fi
		SECFUNCvarSet --show basePosX=`echo "$1" |sed -r 's"([[:digit:]]*)x.*"\1"'`
		SECFUNCvarSet --show basePosY=`echo "$1" |sed -r 's"[[:digit:]]*x([[:digit:]]*)"\1"'`
	elif [[ "$1" == "--help" ]]; then
		echo "options: [--viewport <basePosX>x<basePosY>] [--daemon]"
		echo "ex.: $0 --viewport 1024x0 #so windows are placed at 2nd viewport/face on unity/compiz"
		echo "append '#skipCascade' to commands like: xterm -e \"ls #skipCascade\", so such terminals wont be cascaded!"
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	
	shift
done

###################### FUNCTIONS

function FUNCpidList() {
	#ps -A -o pid,comm |grep "xterm\|rxvt" |sed -r "s;^([ ]*[[:digit:]]*) .*;\1;"
	ps -A -o pid,comm,command |grep "^[ ]*[[:digit:]]* \(xterm\|rxvt\)" |grep -v "#skipCascade" |sed -r "s;^([ ]*[[:digit:]]*) .*;\1;"
}

function FUNCwindowList() {
	# sort is a trick to help prevent windows change position too often!
	#xdotool search --class xterm |sort
	
	local windowId=""
	local listWindowIds=(`(xdotool search --class xterm;xdotool search --class rxvt) |sort -n`)

#	for((i=0;i<${#listWindowIds[@]};i++));do
#		windowId=${listWindowIds[i]}
#		#echo "windowId=$windowId" >>/dev/stderr
#		local windowPid=`xdotool getwindowpid $windowId`
#		if [[ -z "$windowPid" ]] || ps -o command -p $windowPid |grep -q "#skipCascade";then
#			listWindowIds[i]=""
#		fi
#	done
#	listWindowIds=(${listWindowIds[@]}) #recreates the array so empty entries will be ignored
#	#echo "${listWindowIds[@]}" |sort >>/dev/stderr
#	
#	#str=`xdotool search --class xterm;xdotool search --class rxvt`
#	#echo "$str" |sort
#	echo "${listWindowIds[@]}" |sort -n

	local lnSystemPidMax=`cat /proc/sys/kernel/pid_max`
	local listWindowIdsSorted=()
	for windowId in ${listWindowIds[@]};do
		local windowPid=`xdotool getwindowpid $windowId`
		if [[ -n "$windowPid" ]] && ! ps -o command -p $windowPid |grep -q "#skipCascade";then
			local elapsedPidTime=`ps --no-headers -o etimes -p $windowPid`
			local lnWindowPidFixedSize=`printf "%0${#lnSystemPidMax}d" ${windowPid}`
			local lnIndex="${elapsedPidTime}${lnWindowPidFixedSize}"
			listWindowIdsSorted[lnIndex]="$windowId" 
		fi
	done
	
	#`tac` will make newest windows be ordered at last slots on screen
	listWindowIdsSorted=(`echo "${listWindowIdsSorted[@]}" |tr ' ' '\n' |tac`)
	
	echo "${listWindowIdsSorted[@]}"
}

###################### MAIN CODE

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

#@@@TODO make these variables automatic someday..
screenStatusBarHeight=25
screenWidth=1024
screenHeight=768
windowTitleHeight=25
windowBorderSize=5 #2 #5

############## DAEMON LOOP

bCascadeForceNow=false #set at INT trap
strPidListPrevious=""
if $bDaemon; then
	echoc -x "renice -n 19 -p $$"
	while true; do 
		strPidList=`FUNCpidList`
		if $bCascadeForceNow || [[ "$strPidList" != "$strPidListPrevious" ]];then
			strPidListPrevious="$strPidList"
			$0 #call self to do the organization
			bCascadeForceNow=false
		fi
		
		#if ! sleep 5; then break; fi; 
		#echo -ne "wait: ctrl+c for options..\r"
		#read -t 1 #sleep 1 #`read` caused trouble with ctrl+c?
		#if $bAskNow;then
			if echoc -n -q -t 60 "\rtile now";then
				bCascadeForceNow=true
			fi
			#bAskNow=false
		#fi
		
		if SECFUNCdelay daemonHold --checkorinit 5;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		fi
	done
	exit 0
fi

###### AUTO SETUP
screenHeight=$((screenHeight-screenStatusBarHeight)) #workable area

#@@@R FUNCwindowList
aWindowList=(`FUNCwindowList`)
#@@@R for asdfasdf in ${aWindowList[@]};do echo "<$asdfasdf>";done;echo "<${aWindowList[@]}>";exit #@@@R
windowCount=${#aWindowList[@]}
#if(( (windowCount%2)==1 ));then
#	((windowCount++))
#fi
echo "window list: ${aWindowList[@]}"

columns=$((windowCount/maxRows))
if(( (windowCount%maxRows)>0 ));then
	((columns++))
fi
if((columns>maxCols));then
	columns=$maxCols
fi

remainingCols=$((windowCount%columns))
windowCountAdd=0
if((remainingCols>0));then
	windowCountAdd=$((columns-(windowCount%columns))) #this is usefull to last row remain on current viewport with empty slots
fi

windowWidth=$(( (screenWidth/columns)-windowBorderSize ))
windowHeight=$(( screenHeight/((windowCount+windowCountAdd)/columns) ))
windowHeight=$((windowHeight-windowTitleHeight-(windowBorderSize*2)))

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
	
	# skipCascade
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
	if echo "$xtermCmd" |grep -q "#skipCascade";then
		echo "skipping $windowId cmd: $xtermCmd"
		((countSkips++))
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
		eval `xdotool getwindowgeometry $windowId |grep "Geometry:" |sed -r 's"^.*Geometry: ([[:digit:]]*)x([[:digit:]]*).*$"\
			SECFUNCvarSet --showdbg windowWidthCurrent=\1;\
			SECFUNCvarSet --showdbg windowHeightCurrent=\2;"'`
		#@@@TODO after size is set, the collected size always differ from the asked one...
		if((windowWidthCurrent!=windowWidth)) || ((windowHeightCurrent!=windowHeight));then
			SECFUNCexecA --echo xdotool windowsize $windowId $windowWidth $windowHeight
			xdotool getwindowgeometry $windowId |grep "Geometry:"
		fi
	
		# adjust position
		#xdotool fails to dethermine viewport, use wmctrl
		eval `wmctrl -d |sed -r 's".*VP: ([[:digit:]]*),([[:digit:]]*).*"\
			SECFUNCvarSet --showdbg viewportX=\1;\
			SECFUNCvarSet --showdbg viewportY=\2;"'`
		SECFUNCexecA --echo xdotool windowmove --sync $windowId \
			$(( (basePosX-viewportX)+x )) \
			$(( (basePosY-viewportY)+y )) 2>/dev/null; 
	fi
		
	((x+=addX))&&: 
	if $bDoAddY; then
		((y+=addY))&&: 
	fi
	
	#if ! sleep 3;then exit 1;fi
done


