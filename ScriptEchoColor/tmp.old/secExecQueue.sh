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

strFileCfg="$HOME/.`basename $0`.cfg"

bDaemon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help show this help
		eval `secinit`
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--daemon" ]];then #help run the daemon that keeps waiting for commands to execute
		bDaemon=true
	else
		echo "invalid option '$1'" >>/dev/stderr
		exit 1
	fi
	shift
done

if $bDaemon;then
	while true;do
		strExecCmd="`head -n 1 "$strFileCfg"`"
		echo "Exec: $strExecCmd"
		#eval "$strExecCmd" >>/tmp/ 2>&1 &
		eval "$strExecCmd" &
		sleep 5
	done
	exit
fi

strExecParams=""
for strParam in "$@";do
	strExecParams+="'$strParam' "
done
echo "ExecQueue: $strExecParams" >>/dev/stderr
echo "$strExecParams" >>"$strFileCfg"

