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

echo " SECstrRunLogFile='$SECstrRunLogFile'" >>/dev/stderr
echo " \$@='$@'" >>/dev/stderr

strExecGlobalLogFile="/tmp/.$SECstrScriptSelfName.`id -un`.log" #all exec thru this script will have a log entry here
#strFullSelfCmd="`basename $0` $@"
strFullSelfCmd="`ps --no-headers -o cmd -p $$`"
#echo "strFullSelfCmd='$strFullSelfCmd'"

varset bCheckPoint=false
bWaitCheckPoint=false
nDelayAtLoops=1
bCheckPointDaemon=false
bCheckIfAlreadyRunning=true
nSleepFor=0
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "[options] <command> [command params]..."
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--sleep" || "$1" == "-s" ]];then #help <nSleepFor> seconds before executing the command with its params.
		shift
		nSleepFor="${1-}"
	elif [[ "$1" == "--delay" ]];then #help set a delay (can be float) to be used at LOOPs
		shift
		nDelayAtLoops="${1-}"
	elif [[ "$1" == "--checkpointdaemon" ]];then #help "<command> <params>..." (LOOP) when the custom command return true (0), allows waiting instances to run; so must return non 0 to keep holding them.
		shift
		strCustomCommand="${1-}"
		bCheckPointDaemon=true
	elif [[ "$1" == "--waitcheckpoint" || "$1" == "-w" ]];then #help (LOOP) after nSleepFor, also waits checkpoint tmp file to be removed
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

strWaitCheckPointIndicator=""
if $bWaitCheckPoint;then
	strWaitCheckPointIndicator="w+"
fi
strToLog="${strWaitCheckPointIndicator}${nSleepFor}s;pid='$$';`SECFUNCparamsToEval "$@"`"

function FUNClog() { #help <type with 3 letters> [comment]
	local lstrType="$1"
	local lstrLogging=" $lstrType -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog"
	local lstrComment="${@:2}" #"${2-}" fails to '$@' as param when calling this function
	
	if [[ -n "$lstrComment" ]];then
		lstrLogging+="; # $lstrComment"
	fi
	
	case "$lstrType" in
		"wrn"|"Err"|"ini"|"RUN"|"end");; #recognized ok
		*)
			echoc -p "invalid lstrType='$lstrType'" >>/dev/stderr;
			_SECFUNCcriticalForceExit;;
	esac
	
	if [[ "$lstrType" == "wrn" ]];then
		SEC_WARN=true SECFUNCechoWarnA "$lstrLogging"
	fi
	
	echo "$lstrLogging" >>/dev/stderr
	echo "$lstrLogging" >>"$strExecGlobalLogFile"
}

if $bCheckPointDaemon;then
	echo "see Global Exec log for '`id -un`' at: $strExecGlobalLogFile" >>/dev/stderr
	
	exec 2>>"$strExecGlobalLogFile"
	exec 1>&2
	
	if [[ -z "$strCustomCommand" ]];then
		FUNClog Err "invalid empty strCustomCommand"
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

####################### MAIN CODE ##########################

if ! SECFUNCisNumber -dn $nSleepFor;then
	FUNClog Err "invalid nSleepFor='$nSleepFor'"
	exit 1
fi

if [[ -z "$@" ]];then
	FUNClog Err "invalid command '$@'"
	exit 1
fi

#echo " ini -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog" >>"$strExecGlobalLogFile"
FUNClog ini

#if $bWaitCheckPoint;then
#	SECONDS=0
#	while ! SECFUNCuniqueLock --isdaemonrunning;do
#		echo -ne "$SECstrScriptSelfName: waiting daemon (${SECONDS}s)...\r"
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
#		echo -ne "$SECstrScriptSelfName: waiting checkpoint be activated at daemon (${SECONDS}s)...\r"
#		sleep $nDelayAtLoops
#	done
#	
#	echo
#fi
if $bWaitCheckPoint;then
	SECFUNCdelay bWaitCheckPoint --init
	while true;do
		echo -ne "$SECstrScriptSelfName: waiting checkpoint be activated at daemon (`SECFUNCdelay bWaitCheckPoint --getsec`s)...\r"
		if SECFUNCuniqueLock --isdaemonrunning;then
			SECFUNCuniqueLock --setdbtodaemon	#SECFUNCvarReadDB
			if $bCheckPoint;then
				break
			fi
		fi
		sleep $nDelayAtLoops
	done
	echo
fi

sleep $nSleepFor #timings are adjusted against each other, the checkpoint is actually a starting point

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
				if grep -q "^ RUN -> .*;pid='$nPidOther';" "$strExecGlobalLogFile";then
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
		#echo " wrn -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog; # ALREADY RUNNING..." >>"$strExecGlobalLogFile"
		FUNClog wrn "IT IS ALREADY RUNNING AT nPidOther='$nPidOther' !!! "
		#sleep 60
		if echoc -q -t 60 "skip check if already running?";then
			break
		fi
	done
fi

# do RUN
FUNClog RUN
SECFUNCdelay RUN --init
# also `env -i bash -c "\`SECFUNCparamsToEval "$@"\`"` did not fully work as vars like TERM have not required value (despite this is expected)
# nothing related to SEC will run after SECFUNCcleanEnvironment unless if reinitialized
strRunLogFile="$SECstrRunLogFile" #all SEC environment will be cleared
#nRet=0;if (SECFUNCcleanEnvironment;"$@" 2>&1 >>"$strRunLogFile");then : ;else nRet=$?;fi
nRet=0;if (
	SECFUNCcleanEnvironment;
	#exec 2>&1;exec  >>"$strRunLogFile"; #did not work
	#exec 1>&2;exec 2>>"$strRunLogFile"; #did not work
	exec 1>>"$strRunLogFile";exec 2>>"$strRunLogFile"; #worked! :/
	"$@";
);then :; # ':' is a dummy "do nothing" example!
else nRet=$?;fi
if((nRet!=0));then
	FUNClog Err "RUN command '$@' failed, nRet='$nRet'"
fi

# end Log
FUNClog end "delay `SECFUNCdelay RUN --getpretty`"

