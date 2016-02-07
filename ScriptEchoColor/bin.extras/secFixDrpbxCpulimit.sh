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

nCpuLimitPercentual=1
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		echo "log at '$SECstrRunLogFile'"
		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--perc" ]];then #help <nCpuLimitPercentual> set percentual
		shift
		nCpuLimitPercentual="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if ! SECFUNCisShellInteractive;then
	exec 2>>"$SECstrRunLogFile"
	exec 1>&2
fi

if ! SECFUNCisNumber -dn "$nCpuLimitPercentual";then
	echoc -p "invalid nCpuLimitPercentual='$nCpuLimitPercentual'"
	exit 1
fi

nPidCurrent="`pgrep -fx "cpulimit -p $(pgrep dropbox) -l .*"`"&&:
if [[ -n "$nPidCurrent" ]];then
	ps -p "$nPidCurrent"&&:
fi

SECFUNCuniqueLock --daemonwait

nPidDropbox=""
while true;do
	#nPidDropbox=`ps -A -o pid,comm |egrep " dropbox$" |sed -r "s'^ *([[:digit:]]*) .*'\1'"`
	nPidDropbox="`pgrep -f "/dropbox$|/dropbox /newerversion$" |head -n 1`"&&:
	if [[ -n "$nPidDropbox" ]];then
		#ps -o pid,cmd -p `pgrep -f "/dropbox "`&&:
		renice -n 19 `ps --no-headers -L -p $nPidDropbox -o lwp |tr "\n" " "` # several pids, do not surround with "
		#echoc -x "cpulimit -v -p $nPidDropbox -l $nCpuLimitPercentual"
		strCmd="cpulimit -p $nPidDropbox -l $nCpuLimitPercentual"
		echoc -x "$strCmd"&&:&
		while ! nCpuLimitPid="`pgrep -fx "$strCmd"`";do echoc -w -t 1;done
		SECFUNCexecA -ce ps -o ppid,pid,cmd -p `pgrep cpulimit`
		if echoc -q "suspend limitation?";then
			SECFUNCexecA -ce kill -SIGKILL "$nCpuLimitPid"
			SECFUNCexecA -ce ps -o ppid,pid,cmd -p `pgrep cpulimit`
			if echoc -q "resume limitation?";then
				continue;
			fi
		fi
	fi
	
	echoc -t 60 -w "waiting for dropbox to start"
done

