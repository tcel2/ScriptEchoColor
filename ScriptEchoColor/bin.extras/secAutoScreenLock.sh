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

echo "SECstrRunLogFile=$SECstrRunLogFile"

if ! SECFUNCisShellInteractive;then
	exec 1>"$SECstrRunLogFile"
	exec 2>"$SECstrRunLogFile"
fi

while true;do
	bOk=true
	
	if ! nActiveVirtualTerminal="$(sudo fgconsole)";then bOk=false;fi
	if ! anXorgPidList=(`pgrep Xorg`);then bOk=false;fi
	if ! nRunningAtVirtualTerminal="`ps --no-headers -o tty,cmd -p ${anXorgPidList[@]} |grep $DISPLAY |sed -r 's"^tty([[:digit:]]*).*"\1"'`";then bOk=false;fi
	
	echo "nActiveVirtualTerminal=$nActiveVirtualTerminal;nRunningAtVirtualTerminal=$nRunningAtVirtualTerminal;anXorgPidList[@]=(${anXorgPidList[@]})"
	
	if $bOk;then
		if((nRunningAtVirtualTerminal!=nActiveVirtualTerminal));then
			echoc --say "locking t t y $nRunningAtVirtualTerminal"
			echoc -x "xscreensaver-command -lock";
		fi
	fi
	
	echoc -w -t 10
done

