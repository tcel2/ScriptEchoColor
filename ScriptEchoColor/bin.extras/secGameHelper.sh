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

function GAMEFUNCcheckIfGameIsRunning() { #<lstrFileExecutable>
	local lstrFileExecutable="$1"
	pgrep "$lstrFileExecutable" 2>&1 >/dev/null
}

function GAMEFUNCwaitGameStartRunning() { #<lstrFileExecutable>
	local lstrFileExecutable="$1"
	while true;do
		if GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";then
			break
		fi
		sleep 3
	done
}

SECFUNCdelay GAMEFUNCexitIfGameExits --init
function GAMEFUNCexitIfGameExits() { #<lstrFileExecutable>
	local lstrFileExecutable="$1"
	echo -en "check if game is running for `SECFUNCdelay $FUNCNAME --getpretty`\r"
	if ! GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";then
		echoc --info "game exited..."
		exit 0
	fi
}

function GAMEFUNCexitWhenGameExitsLoop() { #<lstrFileExecutable>
	local lstrFileExecutable="$1"
	while ! GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";do
		if echoc -q -t 3 "waiting lstrFileExecutable='$lstrFileExecutable' start, exit?";then
			exit 0
		fi
	done
	while true;do
		GAMEFUNCexitIfGameExits "$lstrFileExecutable"
		sleep 10
	done
}

function GAMEFUNCcheckIfThisScriptCmdIsRunning() { #obrigatory params: "$@" (all params that were passed to the script) (useful to help on avoiding dup instances)
	# check if there is other pids than self tree
	SECFUNCdelay $FUNCNAME --init
	while true;do
		echoc --info "check if this script is already running for `SECFUNCdelay $FUNCNAME --getpretty`"
		anPidList=(`pgrep -f "$SECstrScriptSelfName $@"`) #all pids with this script command, including self
		if ps --no-headers -o pid,ppid  -p "${anPidList[@]}" |egrep -v "$$|$PPID";then
			echoc -pw -t 10 "script '$SECstrScriptSelfName $@' already running, waiting other exit"
			#exit 1
		else
			break;
		fi
		
		#sleep 60
	done
}

if [[ "$0" == */secGameHelper.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #help
			SECFUNCshowHelp --colorize "use this script as source at other scripts"
			SECFUNCshowHelp
			exit 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help MISSING DESCRIPTION
#			echo "#your code goes here"
		elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
			shift
			break
		else
			echoc -p "invalid option '$1'"
			exit 1
		fi
		shift
	done
fi

