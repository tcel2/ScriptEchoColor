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

bParamsAreScrotOptions=false
nTimeLimit=3
bKeepAlways=false
bShowAfter=true
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Take screenshot after mouse stops moving for nTimeLimit='$nTimeLimit'."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--time" || "$1" == "-t" ]];then #help <nTimeLimit> set wait delay in seconds for mouse be kept without moving
		shift
		nTimeLimit="${1-}"
	elif [[ "$1" == "--keep" || "$1" == "-k" ]];then #help do not ask to delete screenshot
		bKeepAlways=true
	elif [[ "$1" == "--hidden" || "$1" == "-h" ]];then #help do not show the screenshot after taken
		bShowAfter=false
	elif [[ "$1" == "--" ]];then #help params after this are scrot options
		bParamsAreScrotOptions=true
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift
done

if ! SECFUNCisNumber -dn $nTimeLimit;then
	echoc -p "invalid nTimeLimit='$nTimeLimit'"
	exit 1
fi

astrParams=()
if $bParamsAreScrotOptions;then
	astrParams=("$@")	
	echoc --info "astrParams[\@]=(${astrParams[@]})"
fi

strSaveTo="$HOME/Pictures"
cd "$strSaveTo";echoc -x "pwd"

echoc --info "stop moving the mouse for $nTimeLimit seconds and the screenshot will be taken"
SECFUNCdelay strMouseStatus --init
while true;do
	strMouseStatus="`xdotool getmouselocation`"
	echo -en "strMouseStatus='$strMouseStatus', `SECFUNCdelay strMouseStatus --get`s\r"
	if [[ "${strMouseStatusPrevious-}" == "$strMouseStatus" ]];then
		if(( $(SECFUNCdelay strMouseStatus --getsec) >= nTimeLimit ));then
			break
		fi
	else
		SECFUNCdelay strMouseStatus --init
	fi
	strMouseStatusPrevious="$strMouseStatus"
	sleep 0.5
done

strFile="$strSaveTo/ScreenShot-`SECFUNCdtFmt --filename`.png"
astrParams+=("$strFile")
echoc --say "screenshot now"
SECFUNCexecA -c --echo scrot "${astrParams[@]}"

echoc -x "ls -l \"$strFile\""

echoc --info --say "screenshot taken"
if $bShowAfter;then
	echoc -x "eog '$strFile'"
fi

if ! $bKeepAlways;then
	if echoc -q "delete it?";then
		echoc -x "trash '$strFile'"
	fi
fi

