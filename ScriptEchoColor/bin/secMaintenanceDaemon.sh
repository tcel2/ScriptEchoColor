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
strSymlinkToDaemonPidFile="/tmp/SEC.$strSelfName.DaemonPid"
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

eval `secinit --nomaintenancedaemon`
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
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--kill" ]];then #help kill the daemon, avoid using this...
		bKillDaemon=true
	elif [[ "$1" == "--restart" ]];then #help restart the daemon, avoid using this...
		bRestartDaemon=true
	elif [[ "$1" == "--logmon" ]];then #help log monitor
		bLogMonitor=true
	elif [[ "$1" == "--lockmon" ]];then #help file locks monitor
		bLockMonitor=true
		fMonitorDelay=1
	elif [[ "$1" == "--pidsmon" ]];then #help pids using SEC, monitor
		bPidsMonitor=true
		fMonitorDelay=30
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
		ps -p $nPidDaemon
		kill -SIGKILL $nPidDaemon
		
		# wait directory be actually removed
		while [[ -d "/proc/$nPidDaemon" ]];do
			sleep 0.1
		done
		
		FUNCcheckDaemonStarted # to update nPidDaemon
	fi
}

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
		strOutput="`ls --color -l "$SEC_TmpFolder/.SEC.FileLock."*".lock"* 2>/dev/null;`"
		echo "$strOutput"
		SECFUNCdrawLine " Total `echo "$strOutput" |wc -l` ";
		sleep $fMonitorDelay;
	done
	exit
elif $bPidsMonitor;then
	while true;do
		secMessagesControl.sh --list
		sleep $fMonitorDelay;
	done
fi

####################### MAIN CODE

function FUNCvalidateDaemon() {
	local lnPidDaemon="`cat "$strDaemonPidFile" 2>/dev/null`"
	if((lnPidDaemon==$$));then
		return
	fi
	if [[ -n "$lnPidDaemon" ]] && [[ -d "/proc/$lnPidDaemon" ]];then
		SECFUNCechoWarnA "(at $1) already running lnPidDaemon='$lnPidDaemon'"
		ps -p $lnPidDaemon >>/dev/stderr
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

nPidMaxNow=0
nPidWrapPrevious=0
nPidWrapCount=0
SECFUNCdelay MainLoop --init
while true;do
	FUNCvalidateDaemon "main loop"
	
	# release locks of dead pids
	strCheckId="LockFilesOfDeadPids"
	if SECFUNCdelay "$strCheckId" --checkorinit 3;then
		SECFUNCfileLock --list |while read lstrLockFileIntermediary;do
				#nPid="`echo "$lstrLockFileIntermediary" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
				nPid="`SECFUNCfileLock --pidof "$lstrLockFileIntermediary"`"
				if [[ ! -d "/proc/$nPid" ]];then
					if [[ -L "$lstrLockFileIntermediary" ]];then
						strFileReal="`readlink "$lstrLockFileIntermediary"`"
						if [[ -n "$strFileReal" ]];then
							echo " `SECFUNCdtTimePrettyNow` Remove $strCheckId: nPid='$nPid' lstrLockFileIntermediary='$lstrLockFileIntermediary' strFileReal='$strFileReal'"
							SECFUNCfileLock --pid $nPid --unlock "$strFileReal"
						fi
					fi
				fi
			done
	fi
	
	# clear temporary shared environment variable files of dead pids etc
	if SECFUNCdelay "EnvVarClearTmpFiles" --checkorinit 60;then
		SECFUNCvarClearTmpFiles
	fi
	
	# pid wraps count
	echo -n & nPidMaxNow=$!
	if((nPidMaxNow<nPidWrapPrevious));then
		((nPidWrapCount++))
	fi
	nPidWrapPrevious=$nPidMaxNow
	
	nTotPids="`ps -A -L -o lwp |sort  -n |wc -l`"
	
	echo -en "nPidWrapCount='$nPidWrapCount', nPidMaxNow='$nPidMaxNow', nTotPids='$nTotPids', active for `SECFUNCdelay MainLoop --getpretty`.\r"
#	if SECFUNCdelay "FlushEcho" --checkorinit 10;then
#		echo
#	fi
	
	sleep 1
done

