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

# TOP CODE
if ${SECinstallPath+false};then export SECinstallPath="`secGetInstallPath.sh`";fi; #to be faster
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcMisc.sh") #no need for the array to be previously set empty
source "$SECinstallPath/lib/ScriptEchoColor/utils/funcBase.sh";
###############################################################################

# MAIN CODE

################ VARS

# PUT ALL AT funcBase.sh

################ FUNCTIONS

function SECFUNCfileLock() { #help Waits until the specified file is unlocked/lockable.\n\tCreates a lock file for the specified file.\n\t<realFile> cannot be a symlink or a directory
	SECFUNCdbgFuncInA;
	local lbUnlock=false
	local lbCheckIfIsLocked=false
	local lbNoWait=false
	local lnPid=$$
	local lbListLocksWithPids=false
	local lbPidOfLockFile=false
	local lstrLockFile=""
	local lfSleepDelay="`SECFUNCbcPrettyCalcA --scale 3 "$SECnLockRetryDelay/1000.0"`"
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfileLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--unlock" ]];then #SECFUNCfileLock_help releases the lock for the specified file.
			lbUnlock=true
		elif [[ "$1" == "--delay" ]];then #SECFUNCfileLock_help sleep delay between lock attempts to easy on cpu usage
			shift
			lfSleepDelay="${1-}"
		elif [[ "$1" == "--islocked" ]];then #SECFUNCfileLock_help check if is locked and, if so, outputs the locking pid.
			lbCheckIfIsLocked=true
		elif [[ "$1" == "--nowait" ]];then #SECFUNCfileLock_help will not wait for lock to be freed and will return 1 if cannot get the lock
			lbNoWait=true
		elif [[ "$1" == "--pid" ]];then #SECFUNCfileLock_help DO NOT USE THIS. Only used at maintenance daemon.
			shift
			lnPid=${1-}
		elif [[ "$1" == "--list" ]];then #SECFUNCfileLock_help list of lock files with pids
			lbListLocksWithPids=true
		elif [[ "$1" == "--pidof" ]];then #SECFUNCfileLock_help <lockfilename> extracts the pid of the filename
			shift
			lstrLockFile="${1-}"
			
			lbPidOfLockFile=true
		else
			SECFUNCechoErrA "invalid option: $1"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	if $lbPidOfLockFile;then
		local lnPidOfLockFile="`echo "$lstrLockFile" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
		if [[ -z "$lnPidOfLockFile" ]] || [[ -n "`echo "$lnPidOfLockFile" |tr -d "[:digit:]"`" ]];then
			SECFUNCechoErrA "invalid lnPidOfLockFile='$lnPidOfLockFile' for lstrLockFile='$lstrLockFile'"
			SECFUNCdbgFuncOutA; return 1;
		fi
		echo "$lnPidOfLockFile"
		SECFUNCdbgFuncOutA; return 0;
	fi
	
	if $lbListLocksWithPids;then
		ls -1 "$SEC_TmpFolder/.SEC.FileLock."*".lock."* &&: 2>/dev/null		
		SECFUNCdbgFuncOutA; return 0;
	fi
	
	local lfile="${1-}" #can be with full path
	local lbFileExist=true
	if [[ ! -f "$lfile" ]];then
		local lstrMsgNotExist="file='$lfile' does not exist (if symlink must point to a file)"
		if $lbCheckIfIsLocked || $lbUnlock;then
			SECFUNCechoWarnA "$lstrMsgNotExist"
		else
			SECFUNCechoErrA "$lstrMsgNotExist"
			SECFUNCdbgFuncOutA;return 1
		fi
		lbFileExist=false
	else
		# canonical full pathname and filename
		lfile=`readlink -f "$lfile"`
	fi
	
	local lsedMd5sumOnly='s"([[:alnum:]]*) .*"\1"'
	local lmd5sum="`echo "$lfile" |md5sum |sed -r "$lsedMd5sumOnly"`"
	if [[ -z "$lmd5sum" ]];then
		#TODO I have no idea how this could happen but it happened... try to simulate again?
		SECFUNCechoErrA "lmd5sum='$lmd5sum'"
		SECFUNCdbgFuncOutA;return 1
	fi
	local lfileLock="$SEC_TmpFolder/.SEC.FileLock.$lmd5sum.lock"	
	local lfileLockPid="${lfileLock}.$lnPid"	
	
	if $lbCheckIfIsLocked;then
		if [[ ! -L "$lfileLock" ]] || ! $lbFileExist;then
			SECFUNCdbgFuncOutA;return 1;
		else
			local lfileLockPidOther="`readlink "$lfileLock"`"
			local lnLockingPid="`echo "$lfileLockPidOther" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
			echo "$lnLockingPid"
		fi
	elif $lbUnlock;then
#				rm -v "$lstrLockFileIntermediary"
#				strLockFile="${lstrLockFileIntermediary%.$nPid}"
#				if [[ "$lstrLockFileIntermediary" == "`readlink "$strLockFile"`" ]];then
#					rm -v "$strLockFile"
#				fi
		rm "$lfileLockPid"
		local lfileLockPointsTo="`readlink "$lfileLock"`"
		if [[ "$lfileLockPointsTo" == "$lfileLockPid" ]];then
			rm "$lfileLock"
		else # unable to unlock, lock owned by other pid...
			SECFUNCechoWarnA "lfileLockPointsTo='$lfileLockPointsTo'"
			SECFUNCdbgFuncOutA;return 1
		fi
	else
		# get the lock
		if ! ln -s "$lfile" "$lfileLockPid" 2>/dev/null;then
			SECFUNCechoWarnA "already locked lfile='$lfile' with lfileLockPid='$lfileLockPid'"
			SECFUNCdbgFuncOutA;return 0;
		fi
		
		if SECFUNCbcPrettyCalcA --cmpquiet "$lfSleepDelay<0.001";then
			SECFUNCechoBugtrackA "SECnLockRetryDelay='$SECnLockRetryDelay' but lfSleepDelay='$lfSleepDelay'"
			#lfSleepDelay="0.001"
			lfSleepDelay="0.1" #seems something went wrong so use default
		fi
		
		while true;do
			if ln -s "$lfileLockPid" "$lfileLock" 2>/dev/null;then
				break;
			fi
		
			if $lbNoWait;then
				SECFUNCdbgFuncOutA; return 1;
			fi
		
			if SECFUNCdelay "${FUNCNAME}_lock" --checkorinit 3;then
				SECFUNCechoWarnA "waiting to get lock for lfile='$lfile'"
			fi
				
			sleep $lfSleepDelay
		done
	fi
	
	SECFUNCdbgFuncOutA; return 0;
}

function SECFUNCrequest() { #help <lstrId> simple requests
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	local lbWait=false
	local lbListen=false;
	local lstrBaseId="`SECFUNCfixIdA -f "$SECstrScriptSelfName"`"
	local lstrId=""
	local lbRequest=false
	local	lbSpeak=false;
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCrequest_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--listen" || "$1" == "-l" ]];then #SECFUNCrequest_help
			lbListen=true;
		elif [[ "$1" == "--request" || "$1" == "-r" ]];then #SECFUNCrequest_help
			lbRequest=true;
		elif [[ "$1" == "--wait" || "$1" == "-w" ]];then #SECFUNCrequest_help only returns after successful
			lbWait=true;
		elif [[ "$1" == "--speak" || "$1" == "-p" ]];then #SECFUNCrequest_help about requests
			lbSpeak=true;
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCrequest_help <lstrExample> MISSING DESCRIPTION
			shift
			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCrequest_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	#validate params here
	if [[ -n "${1-}" ]];then
		lstrId="$1"
	fi
	if [[ -z "$lstrId" ]];then
		SECFUNCechoErrA "invalid lstrId='$lstrId'"
		return 1
	fi
	lstrId="`SECFUNCfixIdA -f "$lstrId"`"
	
	local lstrPrefixMsg="$FUNCNAME:$lstrBaseId:"
	
	# code here
	SECFUNCcfgReadDB
	
	local lbCfgReq="CFGb${lstrBaseId}${lstrId}"
	if ${!lbCfgReq+false};then SECFUNCcfgWriteVar "$lbCfgReq"=false;fi #set default
	
	if $lbListen;then
		local lbAccepted=false
		local lnSECONDS=$SECONDS
		while true;do
			SECFUNCcfgReadDB
			if ${!lbCfgReq};then 
				if $lbSpeak;then secSayStack.sh --showtext "$lstrId request accepted";fi
				SECFUNCcfgWriteVar "$lbCfgReq"=false # accepted, reset
				lbAccepted=true
				break
			else
				echo -en "${lstrPrefixMsg} Waiting '$lstrId' request for $((SECONDS-lnSECONDS))s\r" >>/dev/stderr
			fi # to break this loop
			
			if ! $lbWait;then break;fi
			sleep 1
		done
		
		if $lbAccepted;then	return 0;else return 1;fi
	elif $lbRequest;then
		SECFUNCcfgWriteVar "$lbCfgReq"=true
		if $lbSpeak;then secSayStack.sh --showtext  "$lstrId requested";fi
		local lnSECONDS=$SECONDS
		while true;do
			SECFUNCcfgReadDB
			if ! ${!lbCfgReq};then
				break;
			else
				echo -en "${lstrPrefixMsg} Waiting request '$lstrId' be accepted for $((SECONDS-lnSECONDS))s\r" >>/dev/stderr
			fi # after accepted it will be set to false
			
			if ! $lbWait;then break;fi
			sleep 1
		done
	fi
		
	return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCsyncStopContinue() { #help [lstrBaseId] help on synchronizing scripts (or self calling script)
	# var init here
	local lstrExample="DefaultValue"
	local lbStop=false
	local lbContinue=false
	local lbCheckHold=false
	local lstrBaseId="`SECFUNCfixIdA -f "$SECstrScriptSelfName"`"
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	local lbSpeak=false;
	local lbWait=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCsyncStopContinue_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--stop" || "$1" == "-s" ]];then #SECFUNCsyncStopContinue_help request
			lbStop=true
		elif [[ "$1" == "--continue" || "$1" == "-c" ]];then #SECFUNCsyncStopContinue_help request
			lbContinue=true
		elif [[ "$1" == "--nowaitrequest" || "$1" == "-W" ]];then #SECFUNCsyncStopContinue_help do not wait for requests be accepted
			lbWait=false
		elif [[ "$1" == "--checkhold" || "$1" == "-h" ]];then #SECFUNCsyncStopContinue_help will check and hold, if requested will return true, otherwise false
			lbCheckHold=true
		elif [[ "$1" == "--speak" || "$1" == "-p" ]];then #SECFUNCsyncStopContinue_help about requests
			lbSpeak=true;
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCsyncStopContinue_help <lstrExample> MISSING DESCRIPTION
			shift
			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCsyncStopContinue_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	if [[ -n "${1-}" ]];then
		lstrBaseId="$1"
	fi
	if [[ -z "$lstrBaseId" ]];then
		SECFUNCechoErrA "invalid lstrBaseId='$lstrBaseId'"
		return 1
	fi
	lstrBaseId="`SECFUNCfixIdA -f "$lstrBaseId"`"
	
	local lstrPrefixMsg="$FUNCNAME:$lstrBaseId:"
	
	# code here
	SECFUNCcfgReadDB
	
	local lbCfgStopReq="CFGb${lstrBaseId}StopRequest"
	if ${!lbCfgStopReq+false};then SECFUNCcfgWriteVar "$lbCfgStopReq"=false;fi #set default
	
	local lbCfgContinueReq="CFGb${lstrBaseId}ContinueRequest"
	if ${!lbCfgContinueReq+false};then SECFUNCcfgWriteVar "$lbCfgContinueReq"=false;fi #set default
	
	if $lbStop;then
		SECFUNCcfgWriteVar "$lbCfgStopReq"=true
		if $lbSpeak;then secSayStack.sh --showtext  "stop requested";fi
		if $lbWait;then
			local lnSECONDS=$SECONDS
			while ${!lbCfgStopReq};do
				SECFUNCcfgReadDB
				echo -en "${lstrPrefixMsg} Waiting stop request '$lstrBaseId' be accepted for $((SECONDS-lnSECONDS))s\r" >>/dev/stderr
				sleep 1
			done
		fi
	elif $lbContinue;then
		SECFUNCcfgWriteVar "$lbCfgContinueReq"=true
		if $lbSpeak;then secSayStack.sh --showtext  "continue requested";fi
		if $lbWait;then
			local lnSECONDS=$SECONDS
			while ${!lbCfgContinueReq};do
				SECFUNCcfgReadDB
				echo -en "${lstrPrefixMsg} Waiting continue request '$lstrBaseId' be accepted for $((SECONDS-lnSECONDS))s\r" >>/dev/stderr
				sleep 1
			done
		fi
	elif $lbCheckHold;then
		local lbStopWasRequested=false
		
		if ${!lbCfgStopReq};then
			lbStopWasRequested=true
			if $lbSpeak;then secSayStack.sh --showtext  "stop request accepted";fi
			local lnSECONDS=$SECONDS
			while ! ${!lbCfgContinueReq};do
				SECFUNCcfgReadDB
				SECFUNCcfgWriteVar "$lbCfgStopReq"=false # put here to keep accepting stop requests in case they happen more than one time...
				echo -en "${lstrPrefixMsg} Holding execution '$lstrBaseId' for $((SECONDS-lnSECONDS))s\r" >>/dev/stderr
				sleep 1
			done
			if $lbSpeak;then secSayStack.sh --showtext  "continue request accepted";fi
			SECFUNCcfgWriteVar "$lbCfgContinueReq"=false
		fi
		
		if ! $lbStopWasRequested;then return 1;fi
	fi
	
	return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCuniqueLock() { #help Creates a unique lock that help the script to prevent itself from being executed more than one time simultaneously. If lock exists, outputs the pid holding it and return 1.
	SECFUNCdbgFuncInA;
	#set -x
	local l_bRelease=false
	local l_pid=$$
	local lbQuiet=false
	local lbDaemon=false
	local lbWaitDaemon=false
	local lbOnlyCheckIfDaemonIsRunning=false
	local lbListAndCleanUniqueFiles=false
	local lbGetDaemonPid=false
	local lbGetUniqueFile=false
	local lbSetDBtoDaemonOnly=false
	
	#local lstrId="`basename "$0"`"
	local lstrCanonicalFileName="`readlink -f "$0"`"
	local lstrId="`basename "$lstrCanonicalFileName"`"
	
#	declare -g SECnDaemonPid=0
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--quiet" ]];then #SECFUNCuniqueLock_help prevent all output to /dev/stdout
			lbQuiet=true
		elif [[ "$1" == "--notquiet" ]];then #SECFUNCuniqueLock_help allow output to /dev/stdout
			lbQuiet=false
		elif [[ "$1" == "--id" ]];then #SECFUNCuniqueLock_help <lstrId> set the lock id, if not set, the 'id' defaults to `basename $0`
			shift
			lstrId="$1"
		elif [[ "$1" == "--pid" ]];then #SECFUNCuniqueLock_help <l_pid> force pid to be related to the lock, mainly to acquire (default) and --release the lock
			shift
			l_pid=$1
			#if ! ps -p $l_pid >/dev/null 2>&1;then
			#if [[ -n "$l_pid" && ! -d "/proc/$l_pid" ]];then
			if ! SECFUNCpidChecks --active --check "$l_pid";then
				SECFUNCechoErrA "invalid pid: '$l_pid'"
				SECFUNCdbgFuncOutA;return 1
			fi
		elif [[ "$1" == "--release" ]];then #SECFUNCuniqueLock_help release the lock
			l_bRelease=true
		elif [[ "$1" == "--daemon" ]];then
			SECFUNCechoErrA "deprecated option, use '--setdbtodaemon' instead"
			_SECFUNCcriticalForceExit
		elif [[ "$1" == "--setdbtodaemon" ]];then #SECFUNCuniqueLock_help auto set the DB to the daemon DB if it is already running, or create a new DB and become the daemon; Also sets this variable: SECbDaemonWasAlreadyRunning.
			lbDaemon=true
		elif [[ "$1" == "--setdbtodaemononly" ]];then #SECFUNCuniqueLock_help like --setdbtodaemon, but return 1 (false) in case daemon is NOT already running, and do NOT become the daemon.
			lbSetDBtoDaemonOnly=true
		elif [[ "$1" == "--daemonwait" || "$1" == "--waitbecomedaemon" ]];then #SECFUNCuniqueLock_help will wait for the other daemon to exit, and then will become the daemon
			lbDaemon=true
			lbWaitDaemon=true
		elif [[ "$1" == "--isdaemonrunning" ]];then #SECFUNCuniqueLock_help check if daemon is running
			lbOnlyCheckIfDaemonIsRunning=true
		elif [[ "$1" == "--getdaemonpid" ]];then #SECFUNCuniqueLock_help output the value of SECnDaemonPid, 0 if daemon is not running
			lbGetDaemonPid=true
		elif [[ "$1" == "--getuniquefile" ]];then #SECFUNCuniqueLock_help output the unique full path filename where the daemon pid can be stored (even if that file does not exist yet)
			lbGetUniqueFile=true
		elif [[ "$1" == "--listclean" ]];then #SECFUNCuniqueLock_help list unique files, and clean invalid ones (of dead pids)
			lbListAndCleanUniqueFiles=true
		else
			SECFUNCechoErrA "invalid option: $1"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	lstrId="`SECFUNCfixIdA --justfix "$lstrId"`"
#	if ! SECFUNCvalidateIdA "$lstrId";then
#		SECFUNCdbgFuncOutA;return 1
#	fi
	
	local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$lstrId"
	if $lbGetUniqueFile;then
		echo "$l_runUniqueFile"
		SECFUNCdbgFuncOutA;return 0
	fi
	
	if $lbOnlyCheckIfDaemonIsRunning;then
		if [[ -f "$l_runUniqueFile" ]];then
			SECFUNCdbgFuncOutA;return 0
		else
			SECFUNCdbgFuncOutA;return 1
		fi
	fi
	
#	function SECFUNCuniqueLock_setDbToOtherThatIsDaemon(){
#		#SECnDaemonPid="`SECFUNCuniqueLock --id "$lstrId"`"
#		if [[ -f "$l_runUniqueFile" ]];then
#			local lnDaemonPidCheck="`cat "$l_runUniqueFile" 2>/dev/null &&:`"
#			if SECFUNCisNumber -dn "$lnDaemonPidCheck";then
#				if [[ -d "/proc/$lnDaemonPidCheck" ]];then
#					SECnDaemonPid=$lnDaemonPidCheck
#					SECFUNCvarSetDB $SECnDaemonPid #allows intercommunication between proccesses started from different parents
#					return 0
#				fi
#			fi
#		fi
#		
#		return 1
#	}
	
	if $lbSetDBtoDaemonOnly;then
		if [[ -f "$l_runUniqueFile" ]];then
			local lnDaemonPidCheck="`cat "$l_runUniqueFile" 2>/dev/null &&:`"
			if SECFUNCisNumber -dn "$lnDaemonPidCheck";then
				if [[ -d "/proc/$lnDaemonPidCheck" ]];then
					SECnDaemonPid=$lnDaemonPidCheck
					SECFUNCvarSetDB $SECnDaemonPid
					SECFUNCdbgFuncOutA;return 0
				fi
			fi
		fi
		
		SECFUNCdbgFuncOutA;return 1
	fi
	
	if ${lbDaemon:?};then #will call this self function, beware..
		SECONDS=0
		local lbBecameDaemon=false
		while true;do
			SECbDaemonWasAlreadyRunning=false #global NOT to export #TODO EXPLAIN WHY?!
			if SECFUNCuniqueLock --quiet --id "$lstrId"; then
				SECFUNCvarSetDB -f
				SECnDaemonPid=$$ # ONLY after the lock has been acquired!
			else
				#SECFUNCuniqueLock_setDbToOtherThatIsDaemon
				if ! SECnDaemonPid="`SECFUNCuniqueLock --id "$lstrId"`";then
					SECFUNCvarSetDB $SECnDaemonPid # set DB to other that is daemon
					SECbDaemonWasAlreadyRunning=true
				fi
			fi
			
			if((SECnDaemonPid==$$));then
				lbBecameDaemon=true
			fi
			
#			if SECFUNCuniqueLock_setDbToOtherThatIsDaemon;then
#				SECbDaemonWasAlreadyRunning=true
#			else
#				if SECFUNCuniqueLock --quiet --id "$lstrId"; then
#					SECFUNCvarSetDB -f # make DB file be real (prevent it being a symlink)
#					SECnDaemonPid=$l_pid # ONLY after the lock has been acquired!
#				else
#					SECbDaemonWasAlreadyRunning=true
#				fi				
#			fi
		
			if ${lbWaitDaemon:?};then
				if $lbBecameDaemon;then
					break;
				else
#				if $SECbDaemonWasAlreadyRunning;then
					echo -ne "$FUNCNAME: Wait other ($SECnDaemonPid) Daemon '$lstrId': ${SECONDS}s...\r" >>/dev/stderr
					sleep 1 #keep trying to become the daemon
#				else
#					break #has become the daemon, breaks loop..
				fi
			else
				break; #always break, because DB is always set (child or master)
			fi
		done
		SECFUNCdbgFuncOutA;return 0 # to prevent endless recursiveness
	fi
	
	# clean unique but invalid files
	if $lbListAndCleanUniqueFiles;then
		ls -1 "$SEC_TmpFolder/.SEC.UniqueRun."* |while read lstrUniqueFile;do
			local lnPidCheck=$(cat "$lstrUniqueFile")
			#if [[ ! -d "/proc/$lnPidCheck" ]];then
			if SECFUNCpidChecks --active --check "$lnPidCheck";then
				if ! $lbQuiet;then
					echo "$lstrUniqueFile"
				fi
			else
				local lstrQuickLock="${lstrUniqueFile}.ToCreateRealFile.lock"
				if ln -s "$lstrUniqueFile" "$lstrQuickLock";then
					rm "$lstrUniqueFile"
					echo "[`SECFUNCdtTimeForLogMessages`]Removed lstrUniqueFile='$lstrUniqueFile' with dead lnPidCheck='$lnPidCheck'." >>/dev/stderr
					rm "$lstrQuickLock" #after all is done
				fi
			fi
		done
		SECFUNCdbgFuncOutA;return 0
	fi
	
	# if the pid stored in the unique file has died, it will be removed, but not at this point; to avoid unnecessarily spending cpu time. #TODO where this comment really fits?
	
	############################################################
	################## CREATE THE UNIQUE FILE! #################
	############################################################
	#local l_lockFile="${l_runUniqueFile}.lock"
	if [[ ! -f "$l_runUniqueFile" ]];then
		local lstrQuickLock="${l_runUniqueFile}.ToCreateRealFile.lock"
		if ln -s "$l_runUniqueFile" "$lstrQuickLock";then
			echo $l_pid >"$l_runUniqueFile"
			rm "$lstrQuickLock" #after all is done
		fi
	fi
	
	function SECFUNCuniqueLock_release() {
		SECFUNCfileLock --unlock "$l_runUniqueFile"
		rm "$l_runUniqueFile";
		#rm "$l_lockFile";
	}
	
	if ${l_bRelease:?};then
		SECFUNCuniqueLock_release
		SECFUNCdbgFuncOutA;return 0
	fi
	
	local lnLockPid=`SECFUNCfileLock --islocked "$l_runUniqueFile"` #lock will be validated and released here
	if [[ -n "$lnLockPid" ]];then
		SECnDaemonPid="$lnLockPid"
		if(($l_pid==$lnLockPid));then
			SECFUNCechoWarnA "redundant lock '$lstrId' request..."
			if ! ${lbQuiet:?};then
				echo "$SECnDaemonPid"
			fi
			SECFUNCdbgFuncOutA;return 0
		else
			# this unique lock is in use, output the pid and return failure
			if ! ${lbQuiet:?};then
				echo "$SECnDaemonPid"
			fi
			SECFUNCdbgFuncOutA;return 1
		fi
	else
		if SECFUNCfileLock --nowait "$l_runUniqueFile";then
			echo $l_pid >"$l_runUniqueFile"
			chmod o-rwx "$l_runUniqueFile"
			SECnDaemonPid="$l_pid"
			if ! ${lbQuiet:?};then
				echo "$SECnDaemonPid"
			fi
		else
			SECFUNCdbgFuncOutA;return 1 #TODO: check if concurrent attempts can make it fail? so pass failure to caller...
		fi
	fi

	if $lbGetDaemonPid;then
		echo "$SECnDaemonPid"
		SECFUNCdbgFuncOutA;return 0
	fi
	
	SECFUNCdbgFuncOutA;return 0
}

function pSECFUNCcfgOptSet(){ #help <"$@"> to be used at --cfg scripts option
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCcfgOptSet_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCcfgOptSet_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCcfgOptSet_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
#		else
#			SECFUNCechoErrA "invalid option '$1'"
#			$FUNCNAME --help
#			return 1
		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
			SECFUNCechoErrA "invalid option '$1'"
			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	while true;do
		if ${1+false};then break;fi
		if [[ "${1}" == "help" ]];then 
			SECFUNCcfgFileName --show;
		else 
			SECFUNCcfgWriteVar "${1}";
		fi;
		shift
	done;
	
	return 0
}

function SECFUNCcfgFileName() { #help Application config file for scripts.\n\t[SECcfgFileName], if not set will default to `basename "$0"`
	# var init here
	local lbGetFilename=false
	local lbShow=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCcfgFileName_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--get" || "$1" == "-g" ]];then #SECFUNCcfgFileName_help get the config filename.
			lbGetFilename=true
		elif [[ "$1" == "--show" || "$1" == "-s" ]];then #SECFUNCcfgFileName_help show config file contents
			lbShow=true
		elif [[ "$1" == "--" ]];then #SECFUNCcfgFileName_help params after this are ignored as being these options
			shift
			break
#		else
#			SECFUNCechoErrA "invalid option '$1'"
#			SECFUNCshowHelp $FUNCNAME
#			return 1
		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
			SECFUNCechoErrA "invalid option '$1'"
			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	local lpath="$SECstrUserHomeConfigPath/SEC.ScriptsConfigurationFiles"
	#if [[ -d "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]];then mv -v "$SECstrUserHomeConfigPath/SEC.AppVars.DB" "$lpath" >>/dev/stderr;	ln -sv "$lpath" "$SECstrUserHomeConfigPath/SEC.AppVars.DB" >>/dev/stderr; fi 
	if [[ ! -d "$lpath" ]];then
		if [[ -d "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]] && [[ ! -L "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]];then #TODO remove this check one day, it is here just to provide an easy migration...
			mv -Tv "$SECstrUserHomeConfigPath/SEC.AppVars.DB" "$lpath" >>/dev/stderr; # just rename
			ln -Tsv "$lpath" "$SECstrUserHomeConfigPath/SEC.AppVars.DB" >>/dev/stderr;
		fi
		mkdir -p "$lpath"
	fi
	
	# SECcfgFileName is a global
	if [[ -n "${1-}" ]];then
		SECcfgFileName="$lpath/${1}.cfg"
	#fi
	else
		if [[ -z "$SECcfgFileName" ]];then
		#if [[ -z "$SECcfgFileName" ]];then
			local lstrCanonicalFileName="`readlink -f "$0"`"
			#echo "lstrCanonicalFileName=$lstrCanonicalFileName" >>/dev/stderr
			#SECcfgFileName="$lpath/`basename "$0"`.cfg"
			SECcfgFileName="$lpath/`basename "$lstrCanonicalFileName"`.cfg"
		fi
	fi
	
	if $lbGetFilename;then
		echo "$SECcfgFileName"
	elif $lbShow;then
		if [[ -f "$SECcfgFileName" ]];then
			SECFUNCexecA -ce cat "$SECcfgFileName"
		else
			SECFUNCechoWarnA "file SECcfgFileName='$SECcfgFileName' does not exist yet!"
		fi
	fi
	
	#echo "$lpath/${SECcfgFileName}.cfg"
	#echo "$SECcfgFileName"
	return 0 # important to have this default return value in case some non problematic command fails before returning
}
function SECFUNCcfgReadDB() { #help read the cfg file and set all its env vars at current env
	SECFUNCdbgFuncInA;
	#echo oi;eval `cat tst.db`;return
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		SECFUNCdbgFuncOutA;return
	fi
	
	if [[ -f "$SECcfgFileName" ]];then
  	SECFUNCfileLock "$SECcfgFileName"
  	#sedFixStoredArray="s,^([^=]*)=(\(.*\));$,declare -ax \\\\\n\1='\2';," # arrays stored just like `astr=();`, should be `declare -a astr='()';`, my bad... now I have to fix it...
		#sed -i.bkp -r -e "$sedFixStoredArray" $SECcfgFileName
  	#sed -r -e "$sedFixStoredArray" $SECcfgFileName
		while true;do
			#eval "`cat "$SECcfgFileName"`"
			#eval "`sed -r -e "$sedFixStoredArray" $SECcfgFileName`"
			#source "$SECcfgFileName"
			eval "`cat "$SECcfgFileName"`" #TODO eval is safer than `source`? in case of a corrupt file?
			local lnRetFromEval=$?
			if((lnRetFromEval!=0));then
				SECFUNCechoErrA "at config file SECcfgFileName='$SECcfgFileName'"
				SECFUNCfixCorruptFile "$SECcfgFileName"
			else
				break
			fi
		done
  	SECFUNCfileLock --unlock "$SECcfgFileName"
  fi
  SECFUNCdbgFuncOutA;
  #set -x
}
function pSECFUNCprepareEnvVarsToWriteDB() { #private: store in a way that when being read will be considered global by adding -g
	#declare -p "$@" |sed -r "s'^(declare )([^ ]*) '\1\2g '"
	declare -p "$@" |sed -r "s'^(declare )([^ ]*)( .*)'\1\2g\3;'"
}
function SECFUNCcfgWriteVar() { #help <var>[=<value>] write a variable to config file
	#TODO make SECFUNCvarSet use this and migrate all from there to here?
	local lbRemoveVar=false
	local lbReport=false;
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--remove" ]];then #SECFUNCcfgWriteVar_help remove the variable from config file
			lbRemoveVar=true
		elif [[ "$1" == "--report" || "$1" == "-r" ]];then #SECFUNCcfgWriteVar_help output the variable being written
			lbReport=true
		elif [[ "${1-}" == "--help" ]];then
			SECFUNCshowHelp ${FUNCNAME}
			return 0
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	# if var is being set, eval (do) it
#	local lbIsArray=false
	if echo "$1" |grep -q "^[[:alnum:]_]*=";then # here the var will never be array
		eval "`echo "$1" |sed -r 's,^([[:alnum:]_]*)=(.*),\
			\1="\2";\
			lstrVarId="\1";\
			lstrValue="\2";\
		,'`"
	else
		local lstrVarId="$1"
	fi
	
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	#if [[ -z "`declare |grep "^${lstrVarId}="`" ]];then
	if ! declare -p "${lstrVarId}" >>/dev/null;then
		SECFUNCechoErrA "invalid var '$lstrVarId' to write at cfg file '$SECcfgFileName'"
		return 1
	fi
	
	eval "export $lstrVarId" #make it sure it is exported
	
#	# `declare` must be stripped off or the evaluation of the cfg file will fail!!!
#	if declare -p "${lstrVarId}" |grep -q "^declare -[aA]";then
#		lbIsArray=true
#	fi
	
#	local lstrPliqForArray=""
#	if $lbIsArray;then
#		lstrPliqForArray="'"
#	fi
	
#	local lstrDeclareAssociativeArray=""
#	if declare -p "$lstrVarId" |grep -q "^declare -A";then
##		lstrDeclareAssociativeArray="declare -Axg $lstrVarId;"
#		lstrDeclareAssociativeArray="declare -Axg \\"
#	fi
#	if declare -p "$lstrVarId" |grep -q "^declare -a";then # normal array too
##		lstrDeclareAssociativeArray="declare -axg $lstrVarId;"
#		lstrDeclareAssociativeArray="declare -axg \\"
#	fi
	
	#local lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	#local lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=(.*)$,\1=\2,"`
	#local lstrToWrite="`declare -p ${lstrVarId}`"
	#local lstrToWrite="`declare -p ${lstrVarId} |sed -r "s'^(declare )([^ ]*)( ${lstrVarId}=.*)'\1\2g\3'"`" # store in a way that when being read will be considered global
	local lstrToWrite="`pSECFUNCprepareEnvVarsToWriteDB ${lstrVarId}`"
	
	if [[ ! -f "$SECcfgFileName" ]];then
		echo -n >"$SECcfgFileName"
	fi
	
	SECFUNCfileLock "$SECcfgFileName"
#	local lstrMatchLineToRemove=`echo "$lstrToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
#	sed -i "/$lstrMatchLineToRemove/d" "$SECcfgFileName" #will remove the variable line
#	sed -i "/declare -A ${lstrVarId}/d" "$SECcfgFileName" #will remove the variable declaration
#	sed -i "/${lstrVarId}=/d" "$SECcfgFileName" #will remove the variable line
	sed -i "/^declare [^ ]* ${lstrVarId}=/d" "$SECcfgFileName" #will remove the variable declaration
	if ! $lbRemoveVar;then
#		if [[ -n "$lstrDeclareAssociativeArray" ]];then
#			# must come before the array values set
#			echo "$lstrDeclareAssociativeArray" >>"$SECcfgFileName"
#		fi
#		echo "${lstrToWrite};" >>"$SECcfgFileName" #append new line with var
		echo "${lstrToWrite}" >>"$SECcfgFileName" #append new line with var
	fi
	SECFUNCfileLock --unlock "$SECcfgFileName"
	
	chmod u+rw,go-rw "$SECcfgFileName" #permissions for safety
	
	if $lbReport;then
		echo "$lstrToWrite" >>/dev/stderr
	fi
	
	return 0
}
function SECFUNCcfgAutoWriteAllVars(){ #help will only match vars beggining with specified prefix, default "CFG"
	# var init here
	local lstrPrefix="CFG"
	local lbShowAll=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCcfgAutoWriteAllVars_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--noshow" || "$1" == "-n" ]];then #SECFUNCcfgAutoWriteAllVars_help will hide the default displaying of all config variables
			lbShowAll=false
		elif [[ "$1" == "--prefix" || "$1" == "-p" ]];then #SECFUNCcfgAutoWriteAllVars_help <lstrPrefix> cfg variables must begin with this prefix
			shift
			lstrPrefix="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCcfgAutoWriteAllVars_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCshowHelp $FUNCNAME
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	local lstrAllCfgVars="`declare |egrep "^[[:alnum:]_]*=" |egrep "^$lstrPrefix" |sed -r 's"^([^=]*)=.*"\1"'`"
	#declare -p lstrAllCfgVars
	local lastrAllCfgVars;IFS=$'\n' read -d'' -r -a lastrAllCfgVars < <(echo "$lstrAllCfgVars")&&:
	#declare -p lastrAllCfgVars
	
	if((`SECFUNCarraySize lastrAllCfgVars`>0));then
		for lstrCfgVar in "${lastrAllCfgVars[@]-}";do
			SECFUNCcfgWriteVar $lstrCfgVar
			if $lbShowAll;then
				echo "SECCFG: $lstrCfgVar='${!lstrCfgVar-}'" >>/dev/stderr
			fi
		done
	fi
	
#	if $lbShowAll;then
#		if [[ -n "${lastrAllCfgVars[@]-}" ]];then
#			SECFUNCexecA -ce cat "$SECcfgFileName"
#			#declare -p ${lastrAllCfgVars[@]}
#		else
#			SECFUNCechoWarnA "no cfg variables found..."
#		fi
#	fi
}

function SECFUNCdaemonCheckHold() { #help used to fastly check and hold daemon execution, this code fully depends on what is coded at secDaemonsControl.sh
	SECFUNCdbgFuncInA;
	: ${SECbDaemonRegistered:=false}
	if ! $SECbDaemonRegistered;then
		secDaemonsControl.sh --register
		SECbDaemonRegistered=true
	fi
	_SECFUNCdaemonCheckHold_SubShell() {
		SECFUNCdbgFuncInA;
		# IMPORTANT: subshell to protect parent envinronment variable SECcfgFileName
		local bHoldScripts=false
		SECFUNCcfgFileName secDaemonsControl.sh
		SECFUNCcfgReadDB
		#echo "$SECcfgFileName";cat "$SECcfgFileName";echo "bHoldScripts=$bHoldScripts"
		if $bHoldScripts;then
			secDaemonsControl.sh --checkhold #will cause recursion if this function is called on that command...
		fi
		SECFUNCdbgFuncOutA;
	};export -f _SECFUNCdaemonCheckHold_SubShell
	
	# secinit --base; is required so the non exported functions are defined and the aliases are expanded
	#SECFUNCarraysExport;bash -c 'eval `secinit --base`;_SECFUNCdaemonCheckHold_SubShell;'
	SECFUNCexecOnSubShell 'eval `secinit --ilog --fast`;_SECFUNCdaemonCheckHold_SubShell;' #--ilog to prevent creation of many temporary, and hard to track, log files.
	
	SECFUNCdbgFuncOutA;
}

function SECFUNCfileSleepDelay() { #help <file> show how long (in seconds) a file is not active (has not been updated or touch)
	
	local lbReal=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--real" ]];then #SECFUNCfileSleepDelay_help force the file checked to be the real one, not symlinks
			lbReal=true
		elif [[ "${1-}" == "--help" ]];then
			SECFUNCshowHelp ${FUNCNAME}
			return
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local lfile="$1"
	
	if $lbReal;then
		lfile="`readlink -f "$lfile"`"
	fi
	
	if [[ ! -f "$lfile" ]] && [[ ! -L "$lfile" ]];then
		#echo -n "0"
		SECFUNCechoErrA "invalid file '$lfile'"
		return 1
	fi
	
	local lnSecondsFile=`stat -c "%Y" "$lfile"`;
	local lnSecondsNow=`date +"%s"`;
	local lnSecondsDelay=$((lnSecondsNow-lnSecondsFile))
	echo -n "$lnSecondsDelay"
}

#function SECFUNCexit() { #useful to do 'before exit' tasks
#	local lnStatus=$?
#	if [[ -n "${1-}" ]];then
#		lnStatus=$1
#	fi
#	
#	SECFUNCvarWriteDB #to remove dups
#	
#	exit $nStatus
#}

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcMisc.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowHelp --onlyvars
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibMisc=$$

