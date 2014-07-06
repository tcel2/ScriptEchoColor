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

cd "$HOME/Pictures";echoc -x "pwd"

nTimeLimit=3
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

strFile="ScreenShot-`SECFUNCdtFmt --filename`.png"
echoc -x "scrot '$strFile'"

ls -l "$strFile"

echoc --info --say "screenshot taken"
echoc -x "shotwell '$strFile'"

if echoc -q "delete it?";then
	echoc -x "trash '$strFile'"
fi

