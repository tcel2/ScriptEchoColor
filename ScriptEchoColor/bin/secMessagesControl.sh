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

eval `secinit --base`

#export SEC_WARN=true
#export SEC_DEBUG=true
#export SEC_BUGTRACK=true

bWarn=false
bDebug=false
bBugtrack=false
bOn=false
bOff=false
nPid=""
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	eval "set -- `SECFUNCsingleLetterOptionsA "$@"`"
	if [[ "$1" == "--help" ]];then #help show this help
		echo "[options] <pid>; in this case such pid will have its messages toggled or forced."
		echo "[options] <custom params to be run>; in this case, messages can be optionally turned ON only."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--on" ]];then #help will force enable all requested messages overhidding toggle mode
		bOn=true
	elif [[ "$1" == "--off" ]];then #help will force disable all requested messages overhidding toggle mode
		bOff=true
#	elif [[ "$1" == "--pid" || "$1" == "-p" ]];then #help <pid> pid to deal with instead of running a command
#		shift
#		nPid="${1-}"
	elif [[ "$1" == "--warn" || "$1" == "-w" ]];then #help
		bWarn=true
	elif [[ "$1" == "--debug" || "$1" == "-d" ]];then #help
		bDebug=true
	elif [[ "$1" == "--bugtrack" || "$1" == "-b" ]];then #help
		bBugtrack=true
	elif [[ "$1" == "--all" || "$1" == "-a" ]];then #help all messages at once
		bWarn=true
		bDebug=true
		bBugtrack=true
	else
		echoc -p "invalid option '$1'"
		exit 1 
	fi
	shift
done

if [[ -z "${1-}" ]];then
	echoc -p "<pid> or <commandsToBeRun> expected..."
	exit 1
fi

if [[ -z "`echo "$1" |tr -d "[:digit:]"`" ]];then
	# has only digits
	nPid="$1"
fi

if((nPid>0));then
	if ! SECFUNClockFileAllowedPid --active --check "$nPid";then
		echoc -p "invalid nPid='$nPid'"
		exit 1
	fi

	strForce=""
	if $bOn;then
		strForce="on"
	elif $bOff;then
		strForce="off"
	fi
	
	if $bWarn;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.WARN.$nPid"
	fi
	if $bDebug;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.DEBUG.$nPid"
	fi
	if $bBugtrack;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.BUGTRACK.$nPid"
	fi
else
	strExec=`SECFUNCparamsToEval "$@"`
	if $bWarn;then
			export SEC_WARN=true
	fi
	if $bDebug;then
			export SEC_DEBUG=true
	fi
	if $bBugtrack;then
			export SEC_BUGTRACK=true
	fi
	eval "$strExec"
fi

