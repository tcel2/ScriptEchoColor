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

eval `secLibsInit`

SECFUNCdaemonUniqueLock
SECFUNCcfgRead

FUNCexitIfDaemonNotRunning() {
	if ! ps -p $daemonPid >/dev/null 2>&1;then
		varset --show bDaemonRunning=false
	fi
	if ! $bDaemonRunning;then 
		echoc -p " `basename $0` daemon is not running";
		exit 1;
	fi
}

FUNCreadDBloop() {
	while true; do
		varreaddb
		FUNCexitIfDaemonNotRunning
		SECFUNCdrawLine " RemoteInfo: `date +"%Y/%m/%d-%H:%M:%S.%N"`"
		#echo "# RemoteInfo: `date +"%Y/%m/%d-%H:%M:%S.%N"`"
		#date +"@(%H:%M:%S.%N)"
		grep "_RemoteInfo=" $SECvarFile \
			|sed -r 's;^(.*)_RemoteInfo="(.*)"$;\1:\t\2;' \
			|sort
		
		if SECFUNCdelay daemonHold --checkorinit 5;then
			secDaemonsControl.sh --checkhold
		fi
		
		sleep 1
	done
}

varset --default bDaemonRunning=false
while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--set" ]];then #help <Variable> <Value>
		FUNCexitIfDaemonNotRunning
		shift
		strVar="${1}_RemoteInfo"
		shift
		strVal="$1"
		varset --show "$strVar" "$strVal"
		varwritedb #to clean/remove dups from db file
		exit
	elif [[ "$1" == "--unset" ]];then #help <Variable>
		FUNCexitIfDaemonNotRunning
		shift
		strVar="${1}_RemoteInfo"
		SECFUNCvarUnset "$strVar"
		varwritedb #to clean/remove dups from db file
		exit
	elif [[ "$1" == "--daemon" ]];then #help must be running to other commands work
		while $SECisDaemonRunning;do
			if SECFUNCuniqueLock --quiet; then
				SECFUNCvarSetDB -f
				break
			fi
			echoc --alert "daemon requires unique lock, waiting it be released..."
			sleep 1
		done
		# default is daemon
		varset --show bDaemonRunning=true
		varset --show daemonPid=$$
		SECFUNCcfgWriteVar dtDaemonLastStartup="`SECFUNCdtTimePrettyNow`"
		FUNCreadDBloop
		exit
	elif [[ "$1" == "--infoloop" ]];then #help just read stored info in a loop
		FUNCexitIfDaemonNotRunning
		FUNCreadDBloop
		exit
	elif [[ "$1" == "--help" ]];then
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

