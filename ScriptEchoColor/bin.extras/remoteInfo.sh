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
selfName="`basename "$0"`"

SECFUNCcfgRead

FUNCworkVar() {
	eval "$1"
	if ps -p $pid >/dev/null 2>&1;then
		echo -e "$var:\t$value"
	fi
}

FUNCreadDBloop() {
	while true; do
		#TODO should remove variables of inactive PIDs...
		SECFUNCcfgRead
		SECFUNCdrawLine " RemoteInfo: `date +"%Y/%m/%d-%H:%M:%S.%N"`"
		
		# wont show variables that have no value
		grep "_RemoteInfo_[[:digit:]]*=" $SECcfgFileName \
			|grep -v '=""' \
			|sed -r 's|^(.*)_RemoteInfo_([[:digit:]]*)="(.*)"$|var=\1;pid=\2;value="\3";|' \
			|sort \
			|while read strLine;do FUNCworkVar "$strLine";done
		
		sleep 1
	done
}

nPidCaller="$PPID"
while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--set" ]];then #help <Variable> <Value>
		shift
		strVar="$1"
		shift
		strVal="$1"
		
		if [[ -z "$strVal" ]];then
			echoc -p "$selfName: value for '$strVar' is empty"
			exit 1
		fi
		
		strVar="${strVar}_RemoteInfo_${nPidCaller}"
		
		SECFUNCcfgWriteVar "${strVar}=${strVal}"
		exit
	elif [[ "$1" == "--unset" ]];then #help <Variable>
		#TODO should remove the variable from DB file
		shift
		strVar="${1}_RemoteInfo_${nPidCaller}"
		SECFUNCcfgWriteVar "${strVar}=\"\""
		exit
	elif [[ "$1" == "--infoloop" ]];then #help just read stored info in a loop
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

