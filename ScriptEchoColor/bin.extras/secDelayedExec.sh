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

eval `secinit --base` #it should be as fast as possible

strSelfName="`basename "$0"`"
strLogFile="/tmp/.$strSelfName.`id -un`.log"

bSetCheckPoint=false
bReleaseCheckPoint=false
bWaitCheckPoint=false
nDelayAtLoops=1
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "[options] <nDelayToExec> <command> [command params]..."
		SECFUNCshowHelp --colorize "Sleep for nDelayToExec seconds before executing the command with its params."
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--setcheckpoint" ]];then #help creates a checkpoint tmp file
		bSetCheckPoint=true
	elif [[ "$1" == "--delay" ]];then #help set a delay (can be float) to be used at LOOPs
		shift
		nDelayAtLoops="${1-}"
	elif [[ "$1" == "--releasecheckpoint" ]];then #help "<command> <params>..." (LOOP) when the custom command return true (0), removes the checkpoint tmp file, use as "true" to promptly remove it.
		shift
		strCustomCommand="${1-}"
		bReleaseCheckPoint=true
	elif [[ "$1" == "--waitcheckpoint" || "$1" == "-w" ]];then #help (LOOP) after nDelayToExec, also waits checkpoint tmp file to be removed
		bWaitCheckPoint=true
	else
		echo "invalid option '$1'" >>/dev/stderr
	fi
	shift
done

if [[ -z "`echo "$nDelayAtLoops" |tr -d "[:digit:]"`" ]];then #if only digits
	if((nDelayAtLoops<1));then
		SEC_WARN=true SECFUNCechoWarnA "nDelayAtLoops='$nDelayAtLoops', setting to 1";
		nDelayAtLoops=1
	fi
else
	if ! SECFUNCisNumber -n "$nDelayAtLoops";then
		echoc -p "invalid nDelayAtLoops='$nDelayAtLoops'"
		exit 1
	else
		if SECFUNCbcPrettyCalc --cmpquiet "$nDelayAtLoops<1.0";then
			SEC_WARN=true SECFUNCechoWarnA "nDelayAtLoops='$nDelayAtLoops' may be too cpu intensive..."
		fi
		
		if SECFUNCbcPrettyCalc --cmpquiet "$nDelayAtLoops<0.1";then
			SEC_WARN=true SECFUNCechoWarnA "nDelayAtLoops='$nDelayAtLoops' is too low, setting minimum 0.1"
			nDelayAtLoops="0.1"
		fi
	fi
fi

strCheckpointTmpFile="/tmp/.SEC.$strSelfName.`id -un`.checkpoint"
if $bSetCheckPoint;then
	echo -n >>"$strCheckpointTmpFile"
	ls -l "$strCheckpointTmpFile"
	exit
elif $bReleaseCheckPoint;then
	echo "see log at: $strLogFile" >>/dev/stderr
	
	exec 2>>"$strLogFile"
	exec 1>&2
	
	if [[ -z "$strCustomCommand" ]];then
		echoc -p "invalid empty strCustomCommand"
		exit 1
	fi
	
	SECONDS=0
	echo "Conditional command to remove checkpoint: $strCustomCommand"
	while true;do
		echo "Check at `date "+%Y%m%d+%H%M%S.%N"` (${SECONDS}s)"
		if bash -c "$strCustomCommand";then
			break
		fi
		sleep $nDelayAtLoops
	done
	
	rm -v "$strCheckpointTmpFile"
	
	exit
fi

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

echo "Going to exec: $@"
sleep $nDelayToExec

if $bWaitCheckPoint;then
	SECONDS=0
	while [[ -f "$strCheckpointTmpFile" ]];do
		echo -ne "$strSelfName: waiting checkpoint tmp file be released (${SECONDS}s)...\r"
		sleep $nDelayAtLoops
	done
	echo
fi

#echo " -> `date "+%Y%m%d+%H%M%S.%N"`;nDelayToExec='$nDelayToExec';$@" >>"/tmp/.`basename "$0"`.`SECFUNCgetUserNameOrId`.log" #keep SECFUNCgetUserNameOrId to know when the name becomes available!!!
echo " -> `date "+%Y%m%d+%H%M%S.%N"`;nDelayToExec='$nDelayToExec';$@" >>"$strLogFile"
"$@"

