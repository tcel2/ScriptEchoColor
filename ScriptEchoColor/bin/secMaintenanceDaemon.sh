#!/bin/bash
# Copyright (C) 2004-2016 by Henrique Abdalla
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

strUser=${USER-}
if [[ -z "$strUser" ]];then
	strUser="`id -un`"
	echo "`date "+%Y%m%d+%H%M%S.%N"`,$$,\$USER is empty,`ps`" >>"/tmp/.${strSelfName}.BugTrack.${strUser}.log"
fi

strSymlinkToDaemonPidFile="/tmp/SEC.$strSelfName.${strUser}.DaemonPid" #id -un required as no secinit available yet..

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

source <(secinit --novarchilddb --nomaintenancedaemon) 
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
bErrorsMonitorOnlyTraps=false
bLogsList=false
bShowErrors=false
bListPids=false
bShowCriticalErrors=false
nPidToDump=0
bPidDump=false
#bSetStatusLine=false
varset --default bShowStatusLine=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --nosort
		exit 0
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
	elif [[ "$1" == "--dump" ]];then #help <nPidToDump> show info and dump log about pid
		shift
		nPidToDump="${1-}"
		
		bPidDump=true
	elif [[ "$1" == "--logmon" ]];then #help log monitor for activities of this script and also shows a status line
		bLogMonitor=true
	elif [[ "$1" == "--lockmon" ]];then #help file locks monitor
		bLockMonitor=true
		fMonitorDelay=10
	elif [[ "$1" == "--pidmon" ]];then #help pids using SEC, monitor
		bPidsMonitor=true
		fMonitorDelay=30
	elif [[ "$1" == "--errmon" ]];then #help easy to read errors list
		bErrorsMonitor=true
	elif [[ "$1" == "--trapmon" ]];then #help easy to read errors list (shows only trapped errors)
		bErrorsMonitorOnlyTraps=true
	elif [[ "$1" == "--pidlist" ]];then #help list pids that are detected as using sec functions
		bListPids=true
	elif [[ "$1" == "--errors" ]];then #help show all errors (not only last ones)
		bShowErrors=true
	elif [[ "$1" == "--criticals" ]];then #help show all critical errors
		bShowCriticalErrors=true
	elif [[ "$1" == "--loglist" ]];then #help list all log files for running pids
		bLogsList=true
	elif [[ "$1" == "--delay" ]];then #help delay used on monitors, can be float, MUST come after the monitor option to take effect
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
   ||   SECFUNCbcPrettyCalcA --cmpquiet "$fMonitorDelay<$fMinDelay";
then
	SECFUNCechoErrA "invalid fMonitorDelay='$fMonitorDelay'"
	fMonitorDelay="$fMinDelay"
fi

function FUNCcheckDaemonStarted() {
	if [[ -d "/proc/$nPidDaemon" ]];then
		return 0
	else
		rm "$strDaemonPidFile" 2>/dev/null
		#rm "$strDaemonLogFile" 2>/dev/null
		nPidDaemon="-1"
#		echo ">>>ABC" >&2
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
		
		FUNCcheckDaemonStarted&&: # to update nPidDaemon
	fi
	return 0
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
	eval "ls --color -l \"$SEC_TmpFolder/.SEC.FileLock.\"*\".lock$lstrIntermediaryOnly\"$lstrAll 2>/dev/null"&&:
}

function FUNClistSecPids() {
	local lanPidList=(`ls -1 "$SEC_TmpFolder/SEC."*"."*".vars.tmp" |sed -r 's".*/SEC[.][[:alnum:]_]*[.]([[:digit:]]*)[.]vars[.]tmp"\1"' |sort -un`)
	local lnPidsCount=0
	local lnPid
	echo "PID,PPID,CMD"
	local lanActivePids=()
	local lstrOutput=$(
		for lnPid in ${lanPidList[@]};do
			if [[ -d "/proc/$lnPid" ]];then
				if [[ "`cat /proc/$lnPid/comm`" != "echoc" ]];then # just skip it...
#					ps --no-headers --forest -o pid,ppid,cmd -p "$lnPid"
					lanActivePids+=($lnPid)
					((lnPidsCount++))&&:
				fi
			fi
		done
		if [[ -n "${lanActivePids[@]-}" ]];then
			ps --no-headers --forest -o pid,ppid,cmd -p ${lanActivePids[@]}
		fi
		SECFUNCdrawLine " `SECFUNCdtFmt --pretty`, Total=$lnPidsCount "
	)
	echo "$lstrOutput"
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
strFileErrorLog="${SEC_TmpFolder}/.SEC.Error.log"
if $bKillDaemon;then
	FUNCkillDaemon
	exit 0
elif $bRestartDaemon;then
	echoc --info "this pid is $$"
	
	FUNCkillDaemon
	
	# stdout must be redirected or the terminal wont let it be child...
	# nohup or disown alone did not work...
	$0 >&2 & # it may NOT be able to become the maintenance daemon from here, it can happen from any other running script...
	sleep 3 #wait a bit just to try to avoid messing the terminal output...
	exit 0
elif $bLogMonitor;then
	echo "Maintenance Daemon Pid: $nPidDaemon, log file '$strDaemonLogFile'"
	tail -F "$strDaemonLogFile" --pid=$$
	exit 0
elif $bLockMonitor;then
	while true;do
		strAllLocks="`FUNClocksList --all`"
		echo "$strAllLocks" |egrep "FileLock.*" -o |egrep -v "[.]lock "
		nLocks="`FUNClocksList |wc -l`"
		nLocksI="`FUNClocksList --intermediaryOnly |wc -l`"
		SECFUNCdrawLine " nLocks='$nLocks' nLocksI='$nLocksI' ";
		#~ sleep $fMonitorDelay;
		echoc -w -t $fMonitorDelay
	done
	exit 0
elif $bListPids;then
	FUNClistSecPids
	exit 0
elif $bPidsMonitor;then
	while true;do
#		secMessagesControl.sh --list
		FUNClistSecPids
		#sleep $fMonitorDelay;
		echoc -w -t $fMonitorDelay
	done
	exit 0
elif $bShowCriticalErrors;then
	#`less` requires log to be deactivated
	SECFUNCcheckActivateRunLog --restoredefaultoutputs
	while ! echoc -x "less '$SECstrFileCriticalErrorLog'"&&:;do
		echoc -w -t 60 "No critical errors on log."
	done
	exit 0
elif $bShowErrors;then
	#`less` requires log to be deactivated
	SECFUNCcheckActivateRunLog --restoredefaultoutputs
	grep --color "unbound variable" `find "/run/shm/.SEC.$USER/log/" -maxdepth 1 -type f -xtype f`&&:
	echoc -w "see run log next"
	while ! SECFUNCexecA -ce less "$strFileErrorLog"&&:;do
		echoc -w -t 60 "No errors on log."
	done
	exit 0
elif $bErrorsMonitor || $bErrorsMonitorOnlyTraps;then
	strTrapToken="SECERROR='trap'"
	#tail -F "$strFileErrorLog"
	echoc --info "strFileErrorLog='$strFileErrorLog'"
	nLineCount=0
	while true;do
		if [[ -f "$strFileErrorLog" ]];then
			nLineCountCurrent=$(cat "$strFileErrorLog" |wc -l)
		
			#tail -n $((nLineCountCurrent-nLineCount)) "$strFileErrorLog" |sed -r -e 's";";\n\t"g' -e 's".*"&\n"'
			strErrsToOutput="`tail -n $((nLineCountCurrent-nLineCount)) "$strFileErrorLog"`"&&:
			if $bErrorsMonitorOnlyTraps;then
				strErrsToOutput="`echo "$strErrsToOutput" |grep "$strTrapToken" -w`"&&:
			fi
			if [[ -n "$strErrsToOutput" ]];then # split the line into several easily readable lines!
				echo "$strErrsToOutput" \
					|sed -r \
						-e "s@';@';\n\t@g" \
						-e "s@${strTrapToken}@${SECcolorRed}&${SECcolorCancel}@"
	#					-e 's".*"&\n"' \
			fi
		
			nLineCount=$nLineCountCurrent
		else
			echoc --info "error log is empty!"
		fi
		
		echoc -w "Log for SECERROR(s), `SECFUNCdtFmt --pretty`"
	done
	exit 0
elif $bLogsList;then
#	bRunningPidsOnly=true
#	if echoc -q -t 3 "show log files for all pids (default is only running pids)?";then
#		bRunningPidsOnly=false
#	fi
	echoc --info "Logs at: '$SECstrTmpFolderLog'"
	echoc --info "LogFile, CommandLine"
	strSedOnlyPid='s".*[.]([[:digit:]]*)[.]log$"\1"'
	anLogPidList=(`ls -1 "$SECstrTmpFolderLog/" |sed -r "$strSedOnlyPid"`)
	for nLogPid in ${anLogPidList[@]};do
		if [[ -d "/proc/$nLogPid" ]];then
			echo " log='`ls -1 "$SECstrTmpFolderLog/"*"${nLogPid}.log"`';cmd='`ps --no-headers -o cmd -p $nLogPid`';"
		fi
	done
	exit 0
elif $bPidDump;then
	if ! SECFUNCisNumber -dn "$nPidToDump";then
		SECFUNCechoErrA "invalid nPidToDump='$nPidToDump'"
		exit 1
	fi
	
	function FUNCcat(){
		echoc --info "@s@r DumpLog:@S '$1'"
		cat "$1"
	};export -f FUNCcat
	
	SECFUNCexecA -ce grep "pid='${nPidToDump}'" "/tmp/.secDelayedExec.sh.$USER.log"&&:
	
	SECFUNCdrawLine " begin dump log "
	# files at top log folder have a symlink at the pid tree. Will only dump these symlink ones to avoid duplicity.
	SECFUNCexecA -ce find "/run/shm/.SEC.$USER/log/" -mindepth 2 -iname "*.${nPidToDump}.log" -exec bash -c "FUNCcat '{}'" \;
	echo
	SECFUNCdrawLine " end dump log "
	
	SECFUNCexecA -ce find "/run/shm/.SEC.$USER/log/" -iname "*.${nPidToDump}.log" -exec ls --color -ld '{}' \;
	SECFUNCexecA -ce find "/run/shm/.SEC.$USER/log/" -iname "${nPidToDump}_*" -exec tree -asC --noreport --timefmt "%Y%m%d-%H%M%S" '{}' \;
  echoc --info "Newest:"
  find "/run/shm/.SEC.$USER/log/" -type d -iname "${nPidToDump}_*" |while read strPath;do find "$strPath/" -iname "*.log" -exec stat -c "%Y %y %N" '{}' ';';done |sort #|tail -n 3
  echoc --info "Newest w/o secEnvDev:"
  find "/run/shm/.SEC.$USER/log/" -type d -iname "${nPidToDump}_*" |while read strPath;do find "$strPath/" -iname "*.log" -exec stat -c "%Y %y %N" '{}' ';';done |sort |egrep -v "/[^/]*secEnvDev"&&:
	
	if [[ -d "/proc/$nPidToDump" ]];then
		SECFUNCexecA -ce ps --forest -p `SECFUNCppidList -a --pid $nPidToDump`
		echoc --info "nPidToDump='$nPidToDump' still running!"
	fi
	
	exit 0
fi

####################### MAIN CODE

function FUNCvalidateDaemon() {
	local lnPidDaemon="`cat "$strDaemonPidFile" 2>/dev/null`"&&:
	if((lnPidDaemon==$$));then
		return
	fi
	if [[ -n "$lnPidDaemon" ]] && [[ -d "/proc/$lnPidDaemon" ]];then
		SECFUNCechoWarnA "(at $1) already running lnPidDaemon='$lnPidDaemon'"
		#ps -p $lnPidDaemon >&2
		exit 1
	fi
}

FUNCvalidateDaemon "startup"
echo -n "$$" >"$strDaemonPidFile"
FUNCvalidateDaemon "after writting pid"

# this symlink is to be known by everyone, it is necessary because SEC_TmpFolder may vary and secLibsInit has not access to that variable when it calls this script with --isdaemonstarted
ln -sf "$strDaemonPidFile" "$strSymlinkToDaemonPidFile"

nPidDaemon=$$
echo "ScriptEchoColor Maintenance Daemon started, nPidDaemon='$nPidDaemon', PPID='$PPID', strDaemonLogFile='$strDaemonLogFile'." >&2

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

	##########################################################################
	################### RELEASE LOCKS OF DEAD PIDS ###########################
	##########################################################################
	function FUNCreleaseLocksOfDeadPids() { # for easy browsing on IDE
		strCheckId="LockFilesOfDeadPids"
		#if SECFUNCdelay "$strCheckId" --checkorinit1 $nMinDelayMainLoop;then
			#echo ">>>A" >&2
			IFS=$'\n' read -d '' -r -a astrFileLockList < <(SECFUNCfileLock --list)&&:
			#echo ">>>B" >&2
			#SECFUNCfileLock --list |while read lstrLockFileIntermediary;do
			if((`SECFUNCarraySize astrFileLockList`>0));then 
				for lstrLockLink in "${astrFileLockList[@]}";do
					if [[ "${lstrLockLink}" == *.lock ]];then
						SECFUNCfileLock --revalidate "${lstrLockLink}"&&:
						#~ if [[ ! -L "${lstrLockLink}" ]];then # broken link
							#~ SECFUNCechoWarnA "should be a symlink lstrLockLink='${lstrLockLink}'"
						#~ elif [[ ! -a "${lstrLockLink}" ]];then # broken link
							#~ local lstrMissingTarget="`readlink "${lstrLockLink}"`"
							#~ if [[ ! -f "$lstrMissingTarget" ]];then
								#~ SECFUNCechoWarnA "removing broken lock link lstrLockLink='${lstrLockLink}', lstrMissingTarget='$lstrMissingTarget'"
								#~ rm -vf "${lstrLockLink}"
							#~ else
								#~ SECFUNCechoWarnA "TODO:IMPOSSIBLE? lstrMissingTarget='$lstrMissingTarget' exists?"
							#~ fi
						#~ fi
					else
						local lstrLockFileIntermediary="$lstrLockLink" # is the link to the real file, but is not the lock per se
						#nPid="`echo "$lstrLockFileIntermediary" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
						nPid="`SECFUNCfileLock --pidof "$lstrLockFileIntermediary"`"
						if [[ ! -d "/proc/$nPid" ]];then
							if [[ -L "$lstrLockFileIntermediary" ]];then
								strFileReal="`readlink "$lstrLockFileIntermediary"`"
								if [[ -n "$strFileReal" ]];then #safety? but empty symlinks arent possible..
									echo " `SECFUNCdtFmt --pretty` Remove $strCheckId: nPid='$nPid' lstrLockFileIntermediary='$lstrLockFileIntermediary' strFileReal='$strFileReal'"
									if ! SECFUNCfileLock --pidOverride $nPid --unlock "$strFileReal";then
										SECFUNCechoWarnA "unable to unlock lstrLockFileIntermediary='$lstrLockFileIntermediary', strFileReal='$strFileReal'"
									fi
								fi
							else
								if [[ -f "$lstrLockFileIntermediary" ]];then
									SECFUNCechoWarnA "TODO:IMPOSSIBLE? lstrLockFileIntermediary='$lstrLockFileIntermediary' should be a symlink..."
								fi
							fi
						fi
					fi
				done
			fi
		#fi
	};FUNCreleaseLocksOfDeadPids
	
	##########################################################################
	############### RELEASE UNIQUE DAEMON FILES OF DEAD PIDS #################
	##########################################################################
#	echo "Validate daemon unique files:"
	SECFUNCuniqueLock --quiet --listclean #must come after locks cleaning to generate less log possible as it warns about missing real file on unlock attempt
	
	##########################################################################
	### CLEAR TEMPORARY SHARED ENVIRONMENT VARIABLE FILES OF DEAD PIDS ETC ###
	##########################################################################
	if SECFUNCdelay "EnvVarClearTmpFiles" --checkorinit1 60;then
		SECFUNCvarClearTmpFiles
	fi

	##########################################################################
	######################### SHRINK DB FILES ################################
	##########################################################################
	# to speed up Var DB writting, variables are only appended to file, so shrink by keeping only one entry per variable
	if SECFUNCdelay "ShrinkVarDBFiles" --checkorinit1 600;then
		ls "$SEC_TmpFolder/SEC."*".vars.tmp" -S1 |while read strVarDBFile;do
			if [[ -L "$strVarDBFile" ]];then continue;fi;
			nPidVarDbSize=$(stat -c %s "$strVarDBFile")
			if((nPidVarDbSize<10000));then continue;fi;
			nPidVarDbToShrink=$(SECFUNCvarGetPidOfFileDB "$strVarDBFile");
			bash -c 'source <(secinit --vars);SECFUNCvarSetDB '$nPidVarDbToShrink';SECFUNCvarWriteDB;';
			nPidVarDbSizeNew=$(stat -c %s "$strVarDBFile")
			echo "Shrinked '$strVarDBFile' from '$nPidVarDbSize' to '$nPidVarDbSizeNew'."
		done
	fi
	
	############################ PID WRAP COUNT ##############################
	if SECFUNCdelay "nPidWrapCount" --checkorinit1 60;then
		# pid wraps count
		echo -n & nPidLast=$!
		if((nPidLast<nPidWrapPrevious));then
			((nPidWrapCount++))&&:
		fi
		nPidWrapPrevious=$nPidLast
	fi
	
	################################# STATUS LINE ############################
	if $bShowStatusLine;then
		if SECFUNCdelay "Totals" --checkorinit1 10;then
			nTotPids="`ps -A -L -o lwp |sort  -n |wc -l`"
#			nTotSecPids=$((`secMessagesControl.sh --list |wc -l`-1))
			nTotSecPids=$((`FUNClistSecPids |wc -l`-1))
			nTotLocks="`FUNClocksList |wc -l`"
		fi
	
		echo -en "Pids(Wrap=$nPidWrapCount,Last=$nPidLast,Tot=$nTotPids,SEC=$nTotSecPids),nTotLocks='$nTotLocks',Active for '`SECFUNCdelay MainLoop --getpretty`'.\r"
	#	if SECFUNCdelay "FlushEcho" --checkorinit 10;then
	#		echo
	#	fi
		
		if ! pgrep -U `SECFUNCgetUserNameOrId` -f "secMaintenanceDaemon.sh --logmon" >>/dev/null;then
			varset bShowStatusLine=false
		fi
	else
		SECFUNCdrawLine --stay "" " "
		#echo -en "\r"
		
		if pgrep -U `SECFUNCgetUserNameOrId` -f "secMaintenanceDaemon.sh --logmon" >>/dev/null;then
			varset bShowStatusLine=true
		fi
	fi
	
	sleep $nMinDelayMainLoop
done

