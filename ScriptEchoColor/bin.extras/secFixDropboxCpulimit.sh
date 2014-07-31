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

#strSelfName="`basename "$0"`"
#strLogFile="/tmp/.${strSelfName}.log"

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then
		echo "log at '$SECstrRunLogFile'"
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
done

if ! SECFUNCisShellInteractive;then
	exec 2>>"$SECstrRunLogFile"
	exec 1>&2
fi

SECFUNCuniqueLock --daemonwait

nPidDropbox=""
nCpuLimitPercentual=1
while true;do
	#nPidDropbox=`ps -A -o pid,comm |egrep " dropbox$" |sed -r "s'^ *([[:digit:]]*) .*'\1'"`
	nPidDropbox="`pgrep -f "/dropbox " |head -n 1`"&&:
	if [[ -n "$nPidDropbox" ]];then
		#ps -o pid,cmd -p `pgrep -f "/dropbox "`&&:
		renice -n 19 `ps --no-headers -L -p $nPidDropbox -o lwp |tr "\n" " "` # several pids, do not surround with "
		#echoc -x "cpulimit -v -p $nPidDropbox -l $nCpuLimitPercentual"
		echoc -x "cpulimit -p $nPidDropbox -l $nCpuLimitPercentual"&&:
	fi
	
	echoc -t 60 -w "waiting for dropbox to start"
done

