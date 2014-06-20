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
strSelfName="`basename "$0"`"
strSymlinkToDaemonPidFile="/tmp/SEC.$strSelfName.${USER-`id -un`}.DaemonPid" #id -un required as no secinit available yet..
nPidDaemon="`cat "$strSymlinkToDaemonPidFile" 2>/dev/null`"
if [[ -z "$nPidDaemon" ]];then
	nPidDaemon="-1"
fi
if [[ "$1" == "--isdaemonstarted" ]];then #help check if daemon is running, return true (0) if it is (This is actually a quick option that runs very fast before any other code on this script, so this parameter must come alone)
	if [[ -d "/proc/$nPidDaemon" ]];then
		exit 0
	fi
	exit 1
fi

eval `secinit --novarchilddb --nomaintenancedaemon`
if [[ "$nPidDaemon" != "-1" ]];then
	if [[ -d "/proc/$nPidDaemon" ]];then
		SECFUNCvarSetDB $nPidDaemon
	fi
fi
export SEC_WARN=true

strDaemonPidFile="$SEC_TmpFolder/.SEC.MaintenanceDaemon.pid"
strDaemonLogFile="$SEC_TmpFolder/.SEC.MaintenanceDaemon.log"

#################### Options
bKillDaemon=false
bRestartDaemon=false
bLogMonitor=false
bLockMonitor=false
bPidsMonitor=false
fMonitorDelay="3.0"
bErrorsMonitor=false
bShowErrors=false
#bSetStatusLine=false
varset --default bShowStatusLine=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--kill" ]];then #help kill the daemon, avoid using this...
		bKillDaemon=true
	elif [[ "$1" == "--restart" ]];then #help restart the daemon, avoid using this...
		bRestartDaemon=true
#	elif [[ "$1" == "--showstatus" ]];then #help at --logmon, show the status line
#		bSetStatusLine=true
#		varset --show bShowStatusLine=true
#	elif [[ "$1" == "--hidestatus" ]];then #help at --logmon, hide the status line
#		bSetStatusLine=true
#		varset --show bShowStatusLine=false
	elif [[ "$1" == "--logmon" ]];then #help log monitor
		bLogMonitor=true
	elif [[ "$1" == "--lockmon" ]];then #help file locks monitor
		bLockMonitor=true
		fMonitorDelay=1
	elif [[ "$1" == "--pidsmon" ]];then #help pids using SEC, monitor
		bPidsMonitor=true
		fMonitorDelay=30
	elif [[ "$1" == "--errmon" ]];then #help errors monitor
		bErrorsMonitor=true
	elif [[ "$1" == "--errors" ]];then #help show all errors (not only last ones)
		bShowErrors=true
	elif [[ "$1" == "--delay" ]];then #help delay used on monitors, can be float, MUST come before the monitor option to take effect
		shift
		fMonitorDelay="${1-}"
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

fMinDelay="0.1" #0.1 just for safety
if    ! SECFUNCisNumber --notnegative "$fMonitorDelay" \
   ||   SECFUNCbcPrettyCalc --cmpquiet "$fMonitorDelay<$fMinDelay";
then
	SECFUNCechoErrA "invalid fMonitorDelay='$fMonitorDelay'"
	fMonitorDelay="$fMinDelay"
fi

function FUNCcheckDaemonStarted() {
	if [[ -d "/proc/$nPidDaemon" ]];then
		return 0
	else
		rm "$strDaemonPidFile" 2>/dev/null
		rm "$strDaemonLogFile" 2>/dev/null
		nPidDaemon="-1"
		return 1
	fi
}

function FUNCkillDaemon() {
	if FUNCcheckDaemonStarted;then
		echo -n "Kill currently running Daemon: ";ps --no-headers -o pid,cmd -p $nPidDaemon
		kill -SIGKILL $nPidDaemon
		
		# wait directory be actually removed
		while [[ -d "/proc/$nPidDaemon" ]];do
			sleep 0.1
		done
		
		FUNCcheckDaemonStarted # to update nPidDaemon
	fi
}

function FUNClocksList(){
	local lstrAll=""
	local lstrIntermediaryOnly=""
	if [[ "${1-}" == "--all" ]];then
		lstrAll="*"
	fi
	if [[ "${1-}" == "--intermediaryOnly" ]];then
		lstrIntermediaryOnly="."
		lstrAll="*"
	fi
	#ls --color -l "$SEC_TmpFolder/.SEC.FileLock."*".lock"* 2>/dev/null;
	eval "ls --color -l \"$SEC_TmpFolder/.SEC.FileLock.\"*\".lock$lstrIntermediaryOnly\"$lstrAll 2>/dev/null";
}

# shall exit if not daemon...

#if $bSetStatusLine;then
#	if((nPidDaemon==-1));then
#		SECFUNCechoErrA "daemon must be started first..."
#		exit 1
#	else
#		SECFUNCvarShow bShowStatusLine
#		SECFUNCvarSetDB --skipreaddb $nPidDaemon
#		varset --show bShowStatusLine
#		SECFUNCvarShow bShowStatusLine
#	fi
#	exit
#elif $bKillDaemon;then
if $bKillDaemon;then
	FUNCkillDaemon
	exit
elif $bRestartDaemon;then
	FUNCkillDaemon
	
	# stdout must be redirected or the terminal wont let it be child...
	# nohup or disown alone did not work...
	$0 >>/dev/stderr &
	sleep 3 #wait a bit just to try to avoid messing the terminal output...
	exit
elif $bLogMonitor;then
	echo "Maintenance Daemon Pid: $nPidDaemon, log file '$strDaemonLogFile'"
	tail -F "$strDaemonLogFile"
	exit
elif $bLockMonitor;then
	while true;do
		FUNClocksList --all
		nLocks="`FUNClocksList |wc -l`"
		nLocksI="`FUNClocksList --intermediaryOnly |wc -l`"
		SECFUNCdrawLine " nLocks='$nLocks' nLocksI='$nLocksI' ";
		sleep $fMonitorDelay;
	done
	exit
elif $bPidsMonitor;then
	while true;do
		secMessagesControl.sh --list
		#sleep $fMonitorDelay;
		echoc -w -t $fMonitorDelay
	done
	exit
elif $bShowErrors;then
	echoc -x "less '${SEC_TmpFolder}/.SEC.Error.log'"
	exit
elif $bErrorsMonitor;then
	tail -F "${SEC_TmpFolder}/.SEC.Error.log"
	exit
fi

####################### MAIN CODE

function FUNCvalidateDaemon() {
	local lnPidDaemon="`cat "$strDaemonPidFile" 2>/dev/null`"
	if((lnPidDaemon==$$));then
		return
	fi
	if [[ -n "$lnPidDaemon" ]] && [[ -d "/proc/$lnPidDaemon" ]];then
		SECFUNCechoWarnA "(at $1) already running lnPidDaemon='$lnPidDaemon'"
		#ps -p $lnPidDaemon >>/dev/stderr
		exit 1
	fi
}

FUNCvalidateDaemon "startup"
echo -n "$$" >"$strDaemonPidFile"
FUNCvalidateDaemon "after writting pid"

# this symlink is to be known by everyone, it is necessary because SEC_TmpFolder may vary and secLibsInit has not access to that variable when it calls this script with --isdaemonstarted
ln -sf "$strDaemonPidFile" "$strSymlinkToDaemonPidFile"

nPidDaemon=$$
echo "ScriptEchoColor Maintenance Daemon started, nPidDaemon='$nPidDaemon'." >>/dev/stderr

exec 2>>"$strDaemonLogFile"
exec 1>&2

nKernelBits=`getconf LONG_BIT`
nMaxPid=`cat /proc/sys/kernel/pid_max`
if((nKernelBits==64 && nMaxPid<4194304));then
	SECFUNCechoWarnA "Just a TIP: nKernelBits='$nKernelBits' nMaxPid='$nMaxPid': consider increasing '/proc/sys/kernel/pid_max' to '4194304' as your system (probably) can handle it and the pid's calculations will work better..."
fi

nPidLast=0
nPidWrapPrevious=0
nPidWrapCount=0
SECFUNCdelay MainLoop --init
nTotPids=0
nTotSecPids=0
nTotLocks=0
nMinDelayMainLoop="5"
while true;do
	#if SECFUNCdelay "ValidateDaemon" --checkorinit1 "$((nMinDelayMainLoop*2))";then
	if SECFUNCdelay "ValidateDaemon" --checkorinit1 60;then
		FUNCvalidateDaemon "main loop"
	fi
	SECFUNCvarReadDB

	# release locks of dead pids
	strCheckId="LockFilesOfDeadPids"
	#if SECFUNCdelay "$strCheckId" --checkorinit1 $nMinDelayMainLoop;then
		SECFUNCfileLock --list |while read lstrLockFileIntermediary;do
				#nPid="`echo "$lstrLockFileIntermediary" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
				nPid="`SECFUNCfileLock --pidof "$lstrLockFileIntermediary"`"
				if [[ ! -d "/proc/$nPid" ]];then
					if [[ -L "$lstrLockFileIntermediary" ]];then
						strFileReal="`readlink "$lstrLockFileIntermediary"`"
						if [[ -n "$strFileReal" ]];then #safety? but empty symlinks arent possible..
							echo " `SECFUNCdtTimePrettyNow` Remove $strCheckId: nPid='$nPid' lstrLockFileIntermediary='$lstrLockFileIntermediary' strFileReal='$strFileReal'"
							SECFUNCfileLock --pid $nPid --unlock "$strFileReal"
						fi
					else
						if [[ -f "$lstrLockFileIntermediary" ]];then
							SECFUNCechoWarnA "lstrLockFileIntermediary='$lstrLockFileIntermediary' should be a symlink..."
						fi
					fi
				fi
			done
	#fi
	
	# clear temporary shared environment variable files of dead pids etc
	if SECFUNCdelay "EnvVarClearTmpFiles" --checkorinit1 60;then
		SECFUNCvarClearTmpFiles
	fi
	
	if $bShowStatusLine;then
		if SECFUNCdelay "nPidWrapCount" --checkorinit1 60;then
			# pid wraps count
			echo -n & nPidLast=$!
			if((nPidLast<nPidWrapPrevious));then
				((nPidWrapCount++))
			fi
			nPidWrapPrevious=$nPidLast
		fi
	
		if SECFUNCdelay "Totals" --checkorinit1 10;then
			nTotPids="`ps -A -L -o lwp |sort  -n |wc -l`"
			nTotSecPids=$((`secMessagesControl.sh --list |wc -l`-1))
			nTotLocks="`FUNClocksList |wc -l`"
		fi
	
		echo -en "Pids(Wrap=$nPidWrapCount,Last=$nPidLast,Tot=$nTotPids,SEC=$nTotSecPids),nTotLocks='$nTotLocks',Active for `SECFUNCdelay MainLoop --getpretty`.\r"
	#	if SECFUNCdelay "FlushEcho" --checkorinit 10;then
	#		echo
	#	fi
		
		if ! pgrep -U `SECFUNCgetUserName` -f "secMaintenanceDaemon.sh --logmon" >>/dev/null;then
			varset bShowStatusLine=false
		fi
	else
		SECFUNCdrawLine --stay "" " "
		#echo -en "\r"
		
		if pgrep -U `SECFUNCgetUserName` -f "secMaintenanceDaemon.sh --logmon" >>/dev/null;then
			varset bShowStatusLine=true
		fi
	fi
	
	sleep $nMinDelayMainLoop
done

