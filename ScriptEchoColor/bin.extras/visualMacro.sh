#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

########################### INIT CFG ###########################

eval `secLibsInit`
selfName=`basename "$0"`
basePath="$HOME/.ScriptEchoColor/$selfName"
mkdir -p "$basePath"

imgTmp="$basePath/SEC.VisualMacro.TMP.jpg"

########################### OPTIONS ###########################

varset --show --default nDisplay=:0
imgToCmp=""
varset nPid=0
varset nX=-1
varset nY=-1
varset --show --default nLoopDelay=1
varset strId=""
varset --show --default nCmpThreshold=200
bOptInitialize=false
bOptCmpLoop=false
while [[ "${1:0:1}" == "-" ]]; do
	if [[ "$1" == "--initialize" ]];then #help you must manually create the initial screenshot to be compared, provide an identifier (--id) for it.
		bOptInitialize=true
	elif [[ "$1" == "--id" ]];then #help <id> set screenshot identity
		shift
		varset --show strId="$1"
	elif [[ "$1" == "--checkid" ]];then #help <id> check if 'id' has already been initialized
		if [[ -f "$basePath/$1.jpg" ]];then
			exit 0
		fi
		exit 1
	elif [[ "$1" == "--display" ]];then #help set DISPLAY
		shift
		varset --show nDisplay=$1
	elif [[ "$1" == "--pid" ]];then #help <pid> to keep the compare loop active
		shift
		varset --show nPid=$1
#	elif [[ "$1" == "--xy" ]];then #help <x> <y> set upper left position for screenshot
#		shift
#		nX=$1
#		shift
#		nY=$1
	elif [[ "$1" == "--delay" ]];then #help <delayInSeconds> to sleep on the compare loop
		shift
		varset --show nLoopDelay=$1
	elif [[ "$1" == "--cmpthreshold" ]];then #help <nCmpThreshold> to use with perceptualdiff application
		shift
		varset --show nCmpThreshold=$1
	elif [[ "$1" == "--cmploop" ]];then #help a loop to take screenshots and compare to specified image 'id' (see --initialize), will only exit (0/true) when image matches or '--pid' exits!
		bOptCmpLoop=true
	elif [[ "$1" == "--help" ]];then
		echoc --info "Some options requires other options..."
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	
	shift
done

########################### MAIN ###########################

if [[ -z "$strId" ]];then
	echoc -p "requires --id to be set"
	exit 1
fi

if $bOptInitialize; then
	if ls "$basePath/$strId"*".jpg" 2>/dev/null;then
		if echoc -q "file for id '$strId' already exists, remove it";then
			if echoc -q "are you really sure";then
				rm -v "$basePath/$strId"*".jpg"
			else
				exit
			fi
		else
			exit
		fi
	fi
	
	echoc --alert "TAKE NOTE of (memorize) upper left point (x,y) as shutter does not output that on console yet (?)..."
	echoc -w
	
	if [[ "$DISPLAY" != "$nDisplay" ]];then
		echoc -t 10 --alert "change to the appropriate display NOW!!!"
	fi
	
	DISPLAY=$nDisplay shutter -C -n -e -s -o "$imgTmp"
	ls -l "$imgTmp"
	
	echoc -w "check the image that will be shown"
	eog "$imgTmp"
	
	if echoc -q "confirm it";then
		nX=`echoc -S "What was its upper left X position"`
		nY=`echoc -S "What was its upper left Y position"`
	fi
	
	#imgFinal="$basePath/$strId.nX=$nX.nY=$nY.jpg"
	imgFinal="$basePath/$strId.jpg"
	
	echo -n         >"$basePath/$strId.cfg"
	echo "nX=$nX;" >>"$basePath/$strId.cfg"
	echo "nY=$nY;" >>"$basePath/$strId.cfg"
	
	mv -v "$imgTmp" "$imgFinal"
	ls -l "$imgFinal"
elif $bOptCmpLoop;then
#	varset --show imgCmp `find "${basePath}/" -maxdepth 1 -name "${strId}.*.jpg"`
#	if [[ ! -f "$imgCmp" ]];then
#		echoc -p "invalid image file '$imgCmp'"
#		exit 1
#	fi
	varset --show imgCmp="${basePath}/${strId}.jpg"
	if [[ ! -f "$imgCmp" ]];then
		echoc -p "invalid image file '$imgCmp'"
		exit 1
	fi
	
	varset --show nX=`egrep "^nX=[[:digit:]]*;$" "$basePath/$strId.cfg" |sed -r 's"nX=([[:digit:]]*);"\1"'`
	varset --show nY=`egrep "^nY=[[:digit:]]*;$" "$basePath/$strId.cfg" |sed -r 's"nY=([[:digit:]]*);"\1"'`
#	eval `basename "$imgCmp" |sed 's"[.]";"g' |grep -o "\
#	varset --show nX=[[:digit:]]*;\
#	varset --show nY=[[:digit:]]*;"`
	
	eval `identify "$imgCmp" |sed -r 's"^.* JPEG ([[:digit:]]*)x([[:digit:]]*) .*$"\
	varset --show nWidth=\1;\
	varset --show nHeight=\2;"'`
	
	FUNCvalidate() {
		if [[ -z "${!1}" ]] || ! ((${!1}>0));then
			echoc -p "invalid $1=${!1}"
			exit 1
		fi
	}
	FUNCvalidate nX
	FUNCvalidate nY
	FUNCvalidate nWidth
	FUNCvalidate nHeight
	FUNCvalidate nPid
#	if ! ((nX>0))     ;then echoc -p "invalid nX=$nX"          ;exit 1;fi
#	if ! ((nY>0))     ;then echoc -p "invalid nY=$nY"          ;exit 1;fi
#	if ! ((nWidth>0)) ;then echoc -p "invalid nWidth=$nWidth"  ;exit 1;fi
#	if ! ((nHeight>0));then echoc -p "invalid nHeight=$nHeight";exit 1;fi
	
	#shutter seems to take the screenshot at x+1 and y+1 (compared to what we read when taking the screenshot), minimum upperleft is x=1,y=1 there!!!
	((nX--))
	((nY--))
	
	while ps -p $nPid >/dev/null 2>&1; do
		echoc -x "DISPLAY=$nDisplay shutter -e -n -s $nX,$nY,$nWidth,$nHeight -o \"$imgTmp\""
		ls -l "$imgTmp"
		identify "$imgTmp"
		if perceptualdiff -threshold $nCmpThreshold -verbose "$imgCmp" "$imgTmp"; then
			echoc --info "MATCHED!"
			exit 0 #success
		else
			echoc "waiting to match..."
		fi
		sleep $nLoopDelay
	done
	exit 1
fi

