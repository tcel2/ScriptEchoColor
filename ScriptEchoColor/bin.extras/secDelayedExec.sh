#!/bin/bash
# Copyright (C) 2013-2014 by Henrique Abdalla
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

#TODO check at `info at` if the `at` command can replace this script?

eval `secinit --nochild`

strSelfName="`basename "$0"`"
strLogFile="/tmp/.$strSelfName.`id -un`.log"

varset bCheckPoint=false
bWaitCheckPoint=false
nDelayAtLoops=1
bDaemon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "[options] <nDelayToExec> <command> [command params]..."
		SECFUNCshowHelp --colorize "Sleep for nDelayToExec seconds before executing the command with its params."
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--delay" ]];then #help set a delay (can be float) to be used at LOOPs
		shift
		nDelayAtLoops="${1-}"
	elif [[ "$1" == "--checkpointdaemon" ]];then #help "<command> <params>..." (LOOP) when the custom command return true (0), allows waiting instances to run
		shift
		strCustomCommand="${1-}"
		bDaemon=true
	elif [[ "$1" == "--waitcheckpoint" || "$1" == "-w" ]];then #help (LOOP) after nDelayToExec, also waits checkpoint tmp file to be removed
		bWaitCheckPoint=true
	else
		echo "invalid option '$1'" >>/dev/stderr
	fi
	shift
done

if ! SECFUNCisNumber -dn "$nDelayAtLoops";then
	echoc -p "invalid nDelayAtLoops='$nDelayAtLoops'"
	exit 1
elif((nDelayAtLoops<1));then
	nDelayAtLoops=1
fi

if $bDaemon;then
	echo "see log at: $strLogFile" >>/dev/stderr
	
	exec 2>>"$strLogFile"
	exec 1>&2
	
	if [[ -z "$strCustomCommand" ]];then
		echoc -p "invalid empty strCustomCommand"
		exit 1
	fi
	
	SECFUNCuniqueLock --waitbecomedaemon
	
	SECONDS=0
	echo "Conditional command to activate checkpoint: $strCustomCommand"
	while true;do
		if ! $bCheckPoint;then
			echo "Check at `date "+%Y%m%d+%H%M%S.%N"` (${SECONDS}s)"
			if bash -c "$strCustomCommand";then
				varset bCheckPoint=true
			fi
		fi
		sleep $nDelayAtLoops
	done
	
	exit
fi

####################### EXEC A COMMAND ##########################

nDelayToExec="${1-}"
if [[ -z "$nDelayToExec" ]] || [[ -n "`echo "$nDelayToExec" |tr -d "[:digit:]"`" ]];then
	echo "invalid nDelayToExec='$nDelayToExec'" >>/dev/stderr
	exit 1
fi

shift

if [[ -z "$@" ]];then
	echo "invalid command '$@'" >>/dev/stderr
	exit 1
fi

strExecCmd="`SECFUNCparamsToEval "$@"`"

echo " ini -> `date "+%Y%m%d+%H%M%S.%N"`;nDelayToExec='$nDelayToExec';$strExecCmd" >>"$strLogFile"

#if $bWaitCheckPoint;then
#	SECONDS=0
#	while ! SECFUNCuniqueLock --isdaemonrunning;do
#		echo -ne "$strSelfName: waiting daemon (${SECONDS}s)...\r"
#		sleep $nDelayAtLoops
#	done
#	
#	SECFUNCuniqueLock --setdbtodaemon
#	
#	SECONDS=0
#	while true;do
#		SECFUNCvarReadDB
#		if $bCheckPoint;then
#			break
#		fi
#		echo -ne "$strSelfName: waiting checkpoint be activated at daemon (${SECONDS}s)...\r"
#		sleep $nDelayAtLoops
#	done
#	
#	echo
#fi
if $bWaitCheckPoint;then
	SECFUNCdelay bWaitCheckPoint --init
	while true;do
		if SECFUNCuniqueLock --isdaemonrunning;then
			SECFUNCuniqueLock --setdbtodaemon	#SECFUNCvarReadDB
			if $bCheckPoint;then
				break
			fi
		fi
		echo -ne "$strSelfName: waiting checkpoint be activated at daemon (`SECFUNCdelay bWaitCheckPoint --getsec`s)...\r"
		sleep $nDelayAtLoops
	done
	echo
fi

sleep $nDelayToExec #timings are adjusted against each other, the checkpoint is actually a starting point

echo " RUN -> `date "+%Y%m%d+%H%M%S.%N"`;nDelayToExec='$nDelayToExec';$strExecCmd" >>"$strLogFile"
"$@" #TODO seems impossible to make it fully work this way `env -i bash -c "$strExecCmd"` so the environment has nothing from secinit?

