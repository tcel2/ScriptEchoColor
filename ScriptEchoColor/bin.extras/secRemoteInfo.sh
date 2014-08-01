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

eval `secinit --ilog` # --ilog as this script may be called very often
selfName="`basename "$0"`"

SECFUNCcfgRead

FUNCworkVar() {
	#echo ">>$1"
	eval "$1"
	#echo "strVar=${strVar-};nPid=${nPid-};strValue=${strValue-}"
	if ps -p ${nPid-} >/dev/null 2>&1;then
		echo -e "$strVar:\t$strValue"
		return 0
	fi
	return 1
}

FUNCreadDBloop() {
	while true; do
		#TODO should remove variables of inactive PIDs...
		SECFUNCcfgRead
		#echo $SECcfgFileName
		SECFUNCdrawLine " RemoteInfo: `date +"%Y/%m/%d-%H:%M:%S.%N"`"
		
		# wont show variables that have no value
		#|sed -r 's|^(.*)_RemoteInfo_([[:digit:]]*)="(.*)"$|strVar=\1;nPid=\2;strValue="\3";|' \
		grep "_RemoteInfo_[[:digit:]]*=" $SECcfgFileName \
			|grep -v '=""' \
			|sed -r 's|(.*)_RemoteInfo_(.*)="(.*)";|strVar=\1;nPid=\2;strValue="\3";|' \
			|sort \
			|while read strLine;do 
				if ! FUNCworkVar "$strLine";then
					SECFUNCcfgWriteVar --remove "$strLine";
				fi;
			done
		
		sleep 1
	done
}

nPidCaller="$PPID"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--set" ]];then #help <Variable> <Value>
		shift
		strVar="${1-}"
		shift
		strVal="${1-}"
		
		if [[ -z "$strVal" ]];then
			echoc -p "$selfName: value for '$strVar' is empty"
			exit 1
		fi
		
		strVar="${strVar}_RemoteInfo_${nPidCaller}"
		
		SECFUNCcfgWriteVar "${strVar}=${strVal}"
		exit
	elif [[ "$1" == "--unset" ]];then #help <Variable>
		shift
		strVar="${1-}"
		if [[ -z "$strVar" ]];then
			echoc -p "$selfName: strVar='$strVar' is empty"
			exit 1
		fi
		strVar+="_RemoteInfo_${nPidCaller}"
		SECFUNCcfgWriteVar --remove "${strVar}"
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

