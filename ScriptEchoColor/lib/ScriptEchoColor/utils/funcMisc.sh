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
	local lfSleepDelay="`SECFUNCbcPrettyCalc --scale 3 "$SECnLockRetryDelay/1000.0"`"
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
		ls -1 "$SEC_TmpFolder/.SEC.FileLock."*".lock."* 2>/dev/null		
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
		
		if SECFUNCbcPrettyCalc --cmpquiet "$lfSleepDelay<0.001";then
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

function SECFUNCuniqueLock() { #help Creates a unique lock that help the script to prevent itself from being executed more than one time simultaneously. If lock exists, outputs the pid holding it.
	SECFUNCdbgFuncInA;
	#set -x
	local l_bRelease=false
	local l_pid=$$
	local lbQuiet=false
	local lbDaemon=false
	local lbWaitDaemon=false
	local lbOnlyCheckIfDaemonIsRunning=false
	local lbListAndCleanUniqueFiles=false
	
	#local lstrId="`basename "$0"`"
	local lstrCanonicalFileName="`readlink -f "$0"`"
	local lstrId="`basename "$lstrCanonicalFileName"`"
	
	SECnPidDaemon=0
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--quiet" ]];then #SECFUNCuniqueLock_help prevent all output to /dev/stdout
			lbQuiet=true
		elif [[ "$1" == "--notquiet" ]];then #SECFUNCuniqueLock_help allow output to /dev/stdout
			lbQuiet=false
		elif [[ "$1" == "--id" ]];then #SECFUNCuniqueLock_help <id> set the lock id, if not set, the 'id' defaults to `basename $0`
			shift
			lstrId="$1"
		elif [[ "$1" == "--pid" ]];then #SECFUNCuniqueLock_help <pid> force pid to be related to the lock
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
		elif [[ "$1" == "--setdbtodaemon" ]];then #SECFUNCuniqueLock_help Auto set the DB to the daemon DB if it is already running, or create a new DB; Also sets this variable: SECbDaemonWasAlreadyRunning.
			lbDaemon=true
		elif [[ "$1" == "--daemonwait" || "$1" == "--waitbecomedaemon" ]];then #SECFUNCuniqueLock_help will wait for the other daemon to exit, and then will become the daemon
			lbDaemon=true
			lbWaitDaemon=true
		elif [[ "$1" == "--isdaemonrunning" ]];then #SECFUNCuniqueLock_help check if daemon is running
			lbOnlyCheckIfDaemonIsRunning=true
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
	
	if ${lbDaemon:?};then #will call this self function, beware..
		SECONDS=0
		while true;do
			#set -x
			SECbDaemonWasAlreadyRunning=false #global NOT to export #TODO WHY?
			if SECFUNCuniqueLock --quiet --id "$lstrId"; then
				SECFUNCvarSetDB -f
				SECnPidDaemon=$l_pid # ONLY after the lock has been acquired!
			else
				#echo ">>>$SECvarFile,$lstrId,`SECFUNCuniqueLock --id "$lstrId"`"
				#set -x
				SECFUNCvarSetDB `SECFUNCuniqueLock --id "$lstrId"` #allows intercommunication between proccesses started from different parents
				#set +x
				#echo ">>>$SECvarFile"
				SECbDaemonWasAlreadyRunning=true
			fi
			#set +x
			
			if ${lbWaitDaemon:?};then
				if $SECbDaemonWasAlreadyRunning;then
					echo -ne "$FUNCNAME: Wait Daemon '$lstrId': ${SECONDS}s...\r" >>/dev/stderr
					sleep 1 #keep trying to become the daemon
				else
					break #has become the daemon, breaks loop..
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
	
	#local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$l_pid.$lstrId"
	local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$lstrId"
	#local l_lockFile="${l_runUniqueFile}.lock"
	if [[ ! -f "$l_runUniqueFile" ]];then
		if $lbOnlyCheckIfDaemonIsRunning;then
			# if the pid stored in the unique file has died, it will be removed, but not at this point; to avoid unnecessarily spending cpu time.
			SECFUNCdbgFuncOutA;return 1
		fi
		
		local lstrQuickLock="${l_runUniqueFile}.ToCreateRealFile.lock"
		if ln -s "$l_runUniqueFile" "$lstrQuickLock";then
			echo $l_pid >"$l_runUniqueFile"
			rm "$lstrQuickLock" #after all is done
		fi
	fi
	if $lbOnlyCheckIfDaemonIsRunning;then
		SECFUNCdbgFuncOutA;return 0
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
		if(($l_pid==$lnLockPid));then
			SECFUNCechoWarnA "redundant lock '$lstrId' request..."
			SECFUNCdbgFuncOutA;return 0
		else
			if ! ${lbQuiet:?};then
				echo "$lnLockPid"
			fi
			SECFUNCdbgFuncOutA;return 1
		fi
	else
		if SECFUNCfileLock --nowait "$l_runUniqueFile";then
			echo $l_pid >"$l_runUniqueFile"
		else
			SECFUNCdbgFuncOutA;return 1 #TODO: check if concurrent attempts can make it fail? so pass failure to caller...
		fi
	fi
	
	SECFUNCdbgFuncOutA;
}

function SECFUNCcfgFileName() { #help Application config file for scripts.\n\t[cfgIdentifier], if not set will default to `basename "$0"`
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	local lpath="$SECuserConfigPath/SEC.AppVars.DB"
	if [[ ! -d "$lpath" ]];then
		mkdir -p "$lpath"
	fi
	
	# SECcfgFileName is a global
	if [[ -n "${1-}" ]];then
		SECcfgFileName="$lpath/${1}.cfg"
	#fi
	else
	#if [[ -z "$SECcfgFileName" ]];then
		local lstrCanonicalFileName="`readlink -f "$0"`"
		#echo "lstrCanonicalFileName=$lstrCanonicalFileName" >>/dev/stderr
		#SECcfgFileName="$lpath/`basename "$0"`.cfg"
		SECcfgFileName="$lpath/`basename "$lstrCanonicalFileName"`.cfg"
	fi
	
	#echo "$lpath/${SECcfgFileName}.cfg"
	#echo "$SECcfgFileName"
}
function SECFUNCcfgRead() { #help read the cfg file and set all its env vars at current env
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
		while true;do
			eval "`cat "$SECcfgFileName"`"
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
function SECFUNCcfgWriteVar() { #help <var>[=<value>] write a variable to config file
	#TODO make SECFUNCvarSet use this and migrate all from there to here?
	local lbRemoveVar=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--remove" ]];then #SECFUNCcfgWriteVar_help remove the variable from config file
			lbRemoveVar=true
		elif [[ "${1-}" == "--help" ]];then
			SECFUNCshowHelp ${FUNCNAME}
			return
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	# if var is being set, eval (do) it
	local lbIsArray=false
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
	
	if [[ -z "`declare |grep "^${lstrVarId}="`" ]];then
		SECFUNCechoErrA "invalid var '$lstrVarId' to write at cfg file '$SECcfgFileName'"
		return 1
	fi
	
	# `declare` must be stripped off or the evaluation of the cfg file will fail!!!
	if declare -p "${lstrVarId}" |grep -q "^declare -[aA]";then
		lbIsArray=true
	fi
	
	local lstrPliqForArray=""
	if $lbIsArray;then
		lstrPliqForArray="'"
	fi
	
	local lstrDeclareAssociativeArray=""
	if declare -p "$lstrVarId" |grep -q "^declare -A";then
		lstrDeclareAssociativeArray="declare -Ag $lstrVarId;"
	fi
	
	local lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	
	if [[ ! -f "$SECcfgFileName" ]];then
		echo -n >"$SECcfgFileName"
	fi
	
	SECFUNCfileLock "$SECcfgFileName"
#	local lstrMatchLineToRemove=`echo "$lstrToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
#	sed -i "/$lstrMatchLineToRemove/d" "$SECcfgFileName" #will remove the variable line
	sed -i "/declare -A ${lstrVarId}/d" "$SECcfgFileName" #will remove the variable declaration
	sed -i "/${lstrVarId}=/d" "$SECcfgFileName" #will remove the variable line
	if ! $lbRemoveVar;then
		if [[ -n "$lstrDeclareAssociativeArray" ]];then
			# must come before the array values set
			echo "$lstrDeclareAssociativeArray" >>"$SECcfgFileName"
		fi
		echo "${lstrToWrite};" >>"$SECcfgFileName" #append new line with var
	fi
	SECFUNCfileLock --unlock "$SECcfgFileName"
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
		SECFUNCcfgRead
		#echo "$SECcfgFileName";cat "$SECcfgFileName";echo "bHoldScripts=$bHoldScripts"
		if $bHoldScripts;then
			secDaemonsControl.sh --checkhold #will cause recursion if this function is called on that command...
		fi
		SECFUNCdbgFuncOutA;
	};export -f _SECFUNCdaemonCheckHold_SubShell
	
	# secinit --base; is required so the non exported functions are defined and the aliases are expanded
	#SECFUNCarraysExport;bash -c 'eval `secinit --base`;_SECFUNCdaemonCheckHold_SubShell;'
	SECFUNCexecOnSubShell 'eval `secinit --base`;_SECFUNCdaemonCheckHold_SubShell;'
	
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

# LAST THINGS CODE
if [[ `basename "$0"` == "funcMisc.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibMisc=$$

