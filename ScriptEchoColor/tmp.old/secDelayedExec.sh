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

################# INIT
#export SEC_BUGTRACK=true
export SECnLockRetryDelay=3000 #helps easy on cpu with loads (50+) of concurrent executions
eval `secinit`
strLogFile="$SEC_TmpFolder/SEC.$SECscriptSelfName.log"

################### OPTIONS
bShowLog=false
bCheckCpu=false
bCheckLoad=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		echo "All instances of this script will be executed one per time, not concurrently. Can wait the cpu can breath before running the command."
		echo "This script can be tested with: "'for((i=0;i<20;i++));do secDelayedExec.sh ls $i & done'
		echo "This script is actually too heavy on many simultaneous calls, so it is more for tests and as an example of concurrency than actually useful..."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--showlog" ]];then #help
		bShowLog=true
	elif [[ "$1" == "--checkcpu" ]];then #help check cpu usage before command being allowed to run
		bCheckCpu=true
	elif [[ "$1" == "--checkload" ]];then #help check cpu load before command being allowed to run
		bCheckLoad=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bShowLog;then
	echoc -x "cat \"$strLogFile\""
	exit
fi

######################### MAIN
sleep "`SECFUNCbcPrettyCalc "$((RANDOM%SECnLockRetryDelay))/1000"`" #counting on luck to put concurrent calls less concurrent on checks for locks :P
SECFUNCuniqueLock --daemonwait #allow only one to be run per time like in a queue

echo "ToExec.: `SECFUNCdtTimePrettyNow`, BASHPID=$BASHPID, cmd='$@'" >>"$strLogFile"

nCPUs="`lscpu |grep "^CPU(s):" |tr ':' '\n' |tr -d ' ' |tail -n 1`"
nRetry=3
fRetryDelay=0.25
strRunning=""
while true; do
	bContinueMainLoop=false
	echo "pid=$$"
	sleep 1
	
	if $bCheckCpu;then
		for((i=0;i<nRetry;i++));do
			echo -n "$$;";varset --show fCPUsPercIddle="`mpstat |tail -n 1 |tr ' ,' '\n.' |tail -n 1`"
			if SECFUNCbcPrettyCalc --cmpquiet "$fCPUsPercIddle < 10.0";then
				echo "BASHPID=$BASHPID, fCPUsPercIddle=$fCPUsPercIddle" >>"$strLogFile"
				bContinueMainLoop=true
				break
			fi
			sleep $fRetryDelay
		done
		if $bContinueMainLoop;then
			continue
		fi
	fi
	
	if $bCheckLoad;then
		for((i=0;i<nRetry;i++));do
			echo -n "$$;";varset --show fLoadAvg="`cat /proc/loadavg |tr ' ' '\n' |head -n 1`"
			if SECFUNCbcPrettyCalc --cmpquiet "$fLoadAvg > ($nCPUs*2)";then
				echo "BASHPID=$BASHPID, fLoadAvg=$fLoadAvg" >>"$strLogFile"
				bContinueMainLoop=true
				break
			fi
			sleep $fRetryDelay
		done
		if $bContinueMainLoop;then
			continue
		fi
	fi
	
	break
done

echo -n "pid=$$; ";"$@" & nCmdPid=$!
echo "Started: `SECFUNCdtTimePrettyNow`, BASHPID='$BASHPID', nCmdPid='$nCmdPid', cmd='$@'" |tee -a "$strLogFile"

