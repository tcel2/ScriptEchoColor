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

strSelfName="`basename $0`"
strFileCfg="$HOME/.$strSelfName.PidQueue.cfg"

if [[ ! -f "$strFileCfg" ]];then
	echo -n >>"$strFileCfg"
fi

bDaemon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "<pid> [<pid> <pid> ...] pid or pids to be controlled with SIGSTOP and SIGCONT, it is immediately SIGSTOP"
		echo
		SECFUNCshowHelp --colorize 'Use it like: sleep 10 & '"$strSelfName"'$!'
		SECFUNCshowHelp --colorize "Alternatively you can register any pid like: $strSelfName $$"
		echo
		SECFUNCshowHelp --colorize "Finally run the daemon to slowly release the pids"
		echo
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--daemon" ]];then #help run the daemon that keeps waiting for commands to SIGCONT
		bDaemon=true
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

function FUNCpidChildsGet() {
	pstree -pn $1 |grep -o "([[:digit:]]*)" |grep -o "[[:digit:]]*"
}

function FUNCactOnPid(){
	local lstrSignal="$1"
	local lnPid="$2"
	
	local lanPids=()
	local lnTot=1
	
	if [[ "$lstrSignal" == "SIGSTOP" ]];then
		lnTot=2 # a second time to avoid missing spawned childs inbetween above commands
	fi
	
	local lstrPidsPrevious=""
	for((i=0;i<lnTot;i++));do
		lanPids+=(`FUNCpidChildsGet $lnPid`)
		lanPids=(`echo "${lanPids[@]}" |tr ' ' '\n' |sort -un`)
		if [[ "$lstrPidsPrevious" != "${lanPids[@]}" ]];then
			pstree -p $lnPid
			echoc -x "kill -$lstrSignal ${lanPids[@]} @b#`ps --no-headers -o cmd -p $nPid`"
		fi
		lstrPidsPrevious="${lanPids[@]}"
	done
}

if $bDaemon;then
	SECFUNCuniqueLock --waitbecomedaemon
	while true;do
		SECFUNCfileLock "$strFileCfg"
		
		nPid="`head -n 1 "$strFileCfg"`"
		
		if [[ -n "$nPid" ]];then
			if SECFUNCpidChecks --active --check "$nPid";then
				#echo "Releasing nPid='$nPid'"
				#echoc -x "ps --no-headers -o pid,cmd -p $nPid"
				#echoc -x "kill -SIGCONT $nPid @b#`ps --no-headers -o cmd -p $nPid`"
				FUNCactOnPid SIGCONT $nPid
			else
				SECFUNCechoWarnA "invalid nPid='$nPid'"
			fi
		else
			echo -ne "waiting for pids...\r" >&2
		fi

		strNewData="`tail -n +2 "$strFileCfg"`" #removes 1st line
		echo "$strNewData" >"$strFileCfg"
		
		SECFUNCfileLock --unlock "$strFileCfg"
		sleep 5
	done
	exit
fi

while ! ${1+false};do
	nPid="${1-}"
	if ! SECFUNCpidChecks --active --check "$nPid";then
		exit 1
	fi

	SECFUNCfileLock "$strFileCfg"
	echo "$nPid" >>"$strFileCfg"
	#echoc -x "kill -SIGSTOP $nPid @b#`ps --no-headers -o cmd -p $nPid`"
	FUNCactOnPid SIGSTOP $nPid
	SECFUNCfileLock --unlock "$strFileCfg"
	
	shift
done

