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
#strFullSelfCmd="`basename $0` $@"
strFullSelfCmd="`ps --no-headers -o cmd -p $$`"
#echo "strFullSelfCmd='$strFullSelfCmd'"

varset bCheckPoint=false
bWaitCheckPoint=false
nDelayAtLoops=1
bCheckPointDaemon=false
bCheckIfAlreadyRunning=true
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
		bCheckPointDaemon=true
	elif [[ "$1" == "--waitcheckpoint" || "$1" == "-w" ]];then #help (LOOP) after nDelayToExec, also waits checkpoint tmp file to be removed
		bWaitCheckPoint=true
	elif [[ "$1" == "--noalready" || "$1" == "-n" ]];then #help skip checking if this exactly same command is already running, otherwise, will wait the other command to end
		bCheckIfAlreadyRunning=false
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

if $bCheckPointDaemon;then
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

strWaitCheckPointIndicator=""
if $bWaitCheckPoint;then
	strWaitCheckPointIndicator="w+"
fi
strToLog="${strWaitCheckPointIndicator}${nDelayToExec}s;pid='$$';$strExecCmd"

function FUNClog() {
	local lstrLogging=" $1 -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog"
	local lstrComment="${2-}"
	
	if [[ -n "$lstrComment" ]];then
		lstrLogging+="; # $lstrComment"
	fi
	
	if [[ "$1" == "wrn" ]];then
		SEC_WARN=true SECFUNCechoWarnA "$lstrLogging"
	fi
	
	echo "$lstrLogging" >>/dev/stderr
	echo "$lstrLogging" >>"$strLogFile"
}

#echo " ini -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog" >>"$strLogFile"
FUNClog ini

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

if $bCheckIfAlreadyRunning;then
	while true;do
	#	if ! ps -A -o pid,cmd |grep -v "^[[:blank:]]*[[:digit:]]*[[:blank:]]*grep" |grep -q "$strFullSelfCmd";then
	#	if ! pgrep -f "$strFullSelfCmd";then
		nPidOther=""
		anPidList=(`pgrep -fx "${strFullSelfCmd}$"`)
		#echo "$$,${anPidList[@]}" >>/dev/stderr
		if anPidOther=(`echo "${anPidList[@]-}" |tr ' ' '\n' |grep -vw $$`);then #has not other pids than self
			bFound=false
			for nPidOther in ${anPidOther[@]-};do
				if grep -q "^ RUN -> .*;pid='$nPidOther';" "$strLogFile";then
					bFound=true
					break;
				fi
			done
			if ! $bFound;then
				break;
			fi
		else
			if ! echo "${anPidList[@]-}" |grep -qw "$$";then
				FUNClog wrn "could not find self! "
			fi
			break;
		fi
		#echo " wrn -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog; # ALREADY RUNNING..." >>"$strLogFile"
		FUNClog wrn "IT IS ALREADY RUNNING AT nPidOther='$nPidOther' !!! "
		#sleep 60
		if echoc -q -t 60 "skip check if already running?";then
			break
		fi
	done
fi

#echo " RUN -> `date "+%Y%m%d+%H%M%S.%N"`;${strWaitCheckPointIndicator}${nDelayToExec}s;$strExecCmd" >>"$strLogFile"
#echo " RUN -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog" >>"$strLogFile"
FUNClog RUN
SECFUNCcleanEnvironment #nothing related to SEC will run after this unless if reinitialized, also `env -i bash -c "$strExecCmd"` did not fully work as vars like TERM have not required value (despite this is expected)
"$@"

