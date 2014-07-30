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

export SEC_SAYVOL=20

echo "SECstrRunLogFile=$SECstrRunLogFile" >>/dev/stderr
echo "works with xscreensaver" >>/dev/stderr

if ! SECFUNCisShellInteractive;then
	exec 1>"$SECstrRunLogFile"
	exec 2>"$SECstrRunLogFile"
fi

SECFUNCuniqueLock --id "${SECstrScriptSelfName}_Display$DISPLAY" --daemonwait

nLightweightHackId=1
while true;do
	strXscreensaverStatus="`xscreensaver-command -time`"
	
	bIsLocked=false
	if echo "$strXscreensaverStatus" |grep "screen locked since";then
		bIsLocked=true
	fi
	
	if ! $bIsLocked;then
		bOk=true
	
		if ! nActiveVirtualTerminal="$(SECFUNCexec --echo sudo fgconsole)";then bOk=false;fi
		if ! anXorgPidList=(`pgrep Xorg`);then bOk=false;fi
		if ! nRunningAtVirtualTerminal="`\
			ps --no-headers -o tty,cmd -p ${anXorgPidList[@]} \
			|grep $DISPLAY \
			|sed -r 's"^tty([[:digit:]]*).*"\1"'`";then bOk=false;fi
	#	if xscreensaver-command -time |grep "screen locked since";then bOk=false;fi
		if ! ((nRunningAtVirtualTerminal!=nActiveVirtualTerminal));then bOk=false;fi
	
		echo "nActiveVirtualTerminal=$nActiveVirtualTerminal;"
		echo "nRunningAtVirtualTerminal=$nRunningAtVirtualTerminal;"
		echo "anXorgPidList[@]=(${anXorgPidList[@]})"
	
		if $bOk;then
			if echoc -x "xscreensaver-command -lock";then #lock may fail, so will be retried
				echoc --say "locking t t y $nRunningAtVirtualTerminal"
				bIsLocked=true #update status
				sleep 1 #TODO how to detect if xscreensaver can already accept other commands?
			fi
		fi
	fi
	
	if $bIsLocked;then
		nCurrentHackId="`echo "$strXscreensaverStatus" |sed -r 's".*\(hack #([[:digit:]]*)\)$"\1"'`"
		if((nCurrentHackId!=nLightweightHackId));then
			echoc -x "xscreensaver-command -select $nLightweightHackId"&&:
		fi
	fi
	
	echoc -w -t 10
done

