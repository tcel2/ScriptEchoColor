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
	local lbGetLock=false
	local lstrLockFile=""
	local lstrRevalidateLock=""
	local lfSleepDelay="`SECFUNCbcPrettyCalcA --scale 3 "$SECnLockRetryDelay/1000.0"`"
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfileLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--unlock" ]];then #SECFUNCfileLock_help releases the lock for the specified file.
			lbUnlock=true
		elif [[ "$1" == "--delay" ]];then #SECFUNCfileLock_help <lfSleepDelay> sleep delay between lock attempts to easy on cpu usage
			shift
			lfSleepDelay="${1-}"
		elif [[ "$1" == "--islocked" ]];then #SECFUNCfileLock_help check if is locked and, if so, outputs the locking pid.
			lbCheckIfIsLocked=true
		elif [[ "$1" == "--nowait" ]];then #SECFUNCfileLock_help will not wait for lock to be freed and will return 1 if cannot get the lock
			lbNoWait=true
		elif [[ "$1" == "--revalidate" ]];then #SECFUNCfileLock_help <lstrRevalidateLock> ~single will revalidate the specified lockfile and return
			shift
			lstrRevalidateLock="${1-}"
		elif [[ "$1" == "--pidOverride" ]];then #SECFUNCfileLock_help <lnPid> ~DoNotUse Only used at maintenance daemon.
			shift
			lnPid=${1-}
		elif [[ "$1" == "--list" ]];then #SECFUNCfileLock_help list of lock files with pid
			lbListLocksWithPids=true
		elif [[ "$1" == "--getlock" ]];then #SECFUNCfileLock_help will return the lock file for the specified real file if it was locked
			lbGetLock=true
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
	
	if [[ -n "$lstrRevalidateLock" ]];then
		#~ if [[ -L "${lstrRevalidateLock}" ]];then
			if [[ ! -a "${lstrRevalidateLock}" ]];then # broken link
				local lstrMissingTarget="`readlink "${lstrRevalidateLock}"`"
				#~ if [[ ! -f "$lstrMissingTarget" ]];then
					SECFUNCechoWarnA "removing broken lock link lstrRevalidateLock='${lstrRevalidateLock}', lstrMissingTarget='$lstrMissingTarget'"
					rm -vf "${lstrRevalidateLock}" >&2
					SECFUNCdbgFuncOutA;return 1
				#~ else
					#~ SECFUNCechoWarnA "TODO:IMPOSSIBLE? lstrMissingTarget='$lstrMissingTarget' exists?"
				#~ fi
			fi
		#~ else
			#~ SECFUNCechoWarnA "TODO-IMPOSSIBLE? should be a symlink lstrRevalidateLock='${lstrRevalidateLock}'"
			#~ SECFUNCdbgFuncOutA;return 1
		#~ fi
		return 0
	fi
	
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
		ls -1 \
			"$SEC_TmpFolder/.SEC.FileLock."*".lock" \
			"$SEC_TmpFolder/.SEC.FileLock."*".lock."* &&: 2>/dev/null		
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
	
	if $lbCheckIfIsLocked || $lbGetLock;then
		if [[ ! -L "$lfileLock" ]] || ! $lbFileExist;then
			SECFUNCdbgFuncOutA;return 1;
		else
			if $lbGetLock;then
				echo "$lfileLock"
			else
				local lfileLockPidOther="`readlink "$lfileLock"`"
				local lnLockingPid="`echo "$lfileLockPidOther" |sed -r 's".*[.]([[:digit:]]*)$"\1"'`"
				echo "$lnLockingPid"
			fi
		fi
	elif $lbUnlock;then
		if ! rm "$lfileLockPid";then #will promptly remove the lockpid one
			SECFUNCechoWarnA "failed to remove lfileLockPid='$lfileLockPid'"
		fi
		
		local lfileLockPointsTo="`readlink "$lfileLock"`"
		if [[ "$lfileLockPointsTo" == "$lfileLockPid" ]];then
			if ! rm "$lfileLock";then
				if [[ ! -L "$lfileLock" ]];then
					SECFUNCechoWarnA "lfileLock='$lfileLock' does not exist anymore, look at maintenance daemon log files..."
				else
					SECFUNCechoErrA "unable to remove file lfileLock='$lfileLock'"
					ls -l "$lfileLock" >&2
					SECFUNCdbgFuncOutA;return 1
				fi
			fi
		else
			SECFUNCechoWarnA "unable to unlock as actual lock lfileLock='$lfileLock' is owned by other pid lfileLockPointsTo='$lfileLockPointsTo'"
			SECFUNCdbgFuncOutA;return 0 #return 1 
		fi
	else # try to acquire the lock
		ln -s "$lfile" "$lfileLockPid" 2>/dev/null &&: # just create the pid link referencing the real file
		
		local lfileCurrentLockIs="`readlink "$lfileLock"`"&&:
		if [[ "$lfileCurrentLockIs" == "$lfileLockPid" ]];then
			# the script calling this, has already acquired the lock, so just return true
			SECFUNCechoWarnA "already locked lfile='$lfile' with lfileLockPid='$lfileLockPid'"
			SECFUNCdbgFuncOutA;return 0;
		fi
		
		# retry loop to acquire the lock
		if SECFUNCbcPrettyCalcA --cmpquiet "$lfSleepDelay<0.001";then # fix delay
			SECFUNCechoBugtrackA "SECnLockRetryDelay='$SECnLockRetryDelay' but lfSleepDelay='$lfSleepDelay'"
			#lfSleepDelay="0.001"
			lfSleepDelay="0.1" #seems something went wrong so use default
		fi
		while true;do
			if ln -s "$lfileLockPid" "$lfileLock" 2>/dev/null;then
				SECFUNCdbgFuncOutA; return 0;
				#break;
			fi
			
			if $lbNoWait;then
				SECFUNCdbgFuncOutA; return 1;
			fi
		
			if SECFUNCdelay "${FUNCNAME}_lock" --checkorinit 3;then
				if ! lstrCurrentLockIs="`readlink "$lfileLock"`";then
					lstrCurrentLockIs="(ERROR_READLINK)"
				fi
				
				SECFUNCechoWarnA "waiting to get lock for lfile='$lfile', lstrCurrentLockIs='$lstrCurrentLockIs'"
			fi
				
			sleep $lfSleepDelay
		done
	fi
	
	SECFUNCdbgFuncOutA; return 0;
}

function SECFUNCrequest() {
	SECFUNCsimpleSyncRequest "$@"
}
function SECFUNCsimpleSyncRequest() { #help <lstrId> simple synchronized execution requests
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	local lbWait=false
	local lbListen=false;
#	local lstrBaseId="`SECFUNCfixIdA -f -- "$SECstrScriptSelfName"`"
	local lstrId=""
	local lbStack=false
	local lbRequest=false
	local	lbSpeak=false;
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCsimpleSyncRequest_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--listen" || "$1" == "-l" ]];then #SECFUNCsimpleSyncRequest_help
			lbListen=true;
		elif [[ "$1" == "--request" || "$1" == "-r" ]];then #SECFUNCsimpleSyncRequest_help
			lbRequest=true;
		elif [[ "$1" == "--stack" || "$1" == "-s" ]];then #SECFUNCsimpleSyncRequest_help while listening, all concurrent requests happenng while the listener work is being processed will stack (each will be processed independently), otherwise all concurrent requests will be dropped when the 1st is processed
			lbStack=true;
		elif [[ "$1" == "--wait" || "$1" == "-w" ]];then #SECFUNCsimpleSyncRequest_help only returns after successful (request accepted or listening for a request)
			lbWait=true;
		elif [[ "$1" == "--speak" || "$1" == "-p" ]];then #SECFUNCsimpleSyncRequest_help about requests
			lbSpeak=true;
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCsimpleSyncRequest_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCsimpleSyncRequest_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	# one script can have many Ids
	lstrId="`SECFUNCfixIdA -f -- "$lstrId"`"
	
	local lstrPrefixMsg="$SECstrScriptSelfName:$FUNCNAME:"
	
	# code here
	local lstrIdCfgPRL="CFGanPidRequesterListFor${lstrId}"
	# this line is useless, but keep as reference:	declare -ax "$lstrIdCfgPRL"
	declare -nx lanRefPRL="$lstrIdCfgPRL" # creates a reference to be assigned as an array
	lanRefPRL=() # initializes/creates the referenced array as empty
	export "$lstrIdCfgPRL"
#	echo "A${#lanRefPRL[@]}"
#	lanRefPRL+=(a)
#	echo "B${#lanRefPRL[@]}"
#	echo "C${#lanRefPRL[0]}"
#	local lstrIdCfgPRL1stElem="$lstrIdCfgPRL[0]"
#	local lstrIdCfgPRLallElems="$lstrIdCfgPRL[@]"
#	local lstrIdCfgPRLSize="#${lstrIdCfgPRLallElems}"
#	local lstrIdCfgPRLrm1stElem="${lstrIdCfgPRLallElems}:1"
#	declare -a "$lstrIdCfgPRL"
#	"$lstrIdCfgPRL"=()
	SECFUNCcfgReadDB
	
#	local lbCfgReq="CFGb${lstrBaseId}${lstrId}"
#	if ${!lbCfgReq+false};then SECFUNCcfgWriteVar "$lbCfgReq"=false;fi #set default
	
	if $lbListen;then
		# if not stacking requests, that list must be cleaned before begin listening
		if ! $lbStack;then 
#			declare -a "$lstrIdCfgPRL"=();
			lanRefPRL=()
			SECFUNCcfgWriteVar "${!lanRefPRL}";
		fi
		
		local lbAccepted=false
		local lnSECONDS=$SECONDS
		while true;do
#			SECFUNCexecA -ce declare -p lanRefPRL ${!lanRefPRL} >&2
			SECFUNCcfgReadDB #"${!lanRefPRL}"
#			cat `SECFUNCcfgFileName --get`
#			SECFUNCcfgFileName --show
#			SECFUNCexecA -ce declare -p lanRefPRL ${!lanRefPRL} >&2
#			SECFUNCcfgFileName --show
#			SECFUNCexecA -ce declare -p lanRefPRL ${!lanRefPRL} >&2
#			echo "lanRefPRL[@]=${lanRefPRL[@]-}" >&2
			if((${#lanRefPRL[@]}>0));then
				local lnPid="${lanRefPRL[0]}"
				local lstrReport="$lstrId request from lnpid='$lnPid' accepted"
				if ! $lbStack;then lstrReport="${lstrReport}, other requests dropped";fi
				echo "${lstrPrefixMsg} $lstrReport" >&2
				if $lbSpeak;then secSayStack.sh --showtext "request accepted";fi #to not speak so much as the report...
#				SECFUNCcfgWriteVar "$lbCfgReq"=false # accepted, reset
				
				if $lbStack;then 
#					declare -a "$lstrIdCfgPRL"=("${!lstrIdCfgPRLrm1stElem}");
					lanRefPRL=("${lanRefPRL[@]:1}")
#					declare -p "${!lanRefPRL}"
#					SECFUNCarrayClean "${!lanRefPRL}" "$lnPid"
#					declare -p "${!lanRefPRL}"
#					SECFUNCcfgWriteVar "${!lanRefPRL}";
				else
					lanRefPRL=()
				fi
				SECFUNCcfgWriteVar "${!lanRefPRL}";
				
				lbAccepted=true
				break
			else
				echo -en "${lstrPrefixMsg} Waiting '$lstrId' request for $((SECONDS-lnSECONDS))s\r" >&2
			fi # to break this loop
			
			if ! $lbWait;then break;fi
			sleep 1
		done
		
		if $lbAccepted;then	return 0;else return 1;fi
	elif $lbRequest;then
		SECFUNCcfgReadDB --keeplock
#		declare -a "$lstrIdCfgPRL"=("${!lstrIdCfgPRLallElems}" "$$");
		lanRefPRL+=("$$")
		SECFUNCcfgWriteVar "${!lanRefPRL}";
		
		local lstrReport="$lstrId requested"
		echo "${lstrPrefixMsg} $lstrReport" >&2

		if $lbWait;then 
			local lnSECONDS=$SECONDS
			while true;do
				SECFUNCcfgReadDB
#				declare -p "${!lanRefPRL}"
#				SECFUNCcfgFileName --show
				if ! SECFUNCarrayContains "${!lanRefPRL}" $$;then
					break;
				fi
				
				echo -en "${lstrPrefixMsg} Waiting request '$lstrId' be accepted for $((SECONDS-lnSECONDS))s\r" >&2
				sleep 1
			done
		else
			# will not speak if the listener will already "expectedly" speak
			if $lbSpeak;then secSayStack.sh --showtext "request made";fi
		fi
		
#		SECFUNCcfgWriteVar "$lbCfgReq"=true
#		local lstrReport="$lstrId requested"
#		echo "${lstrPrefixMsg} $lstrReport" >&2
#		if $lbSpeak;then secSayStack.sh --showtext "$lstrReport";fi
#		local lnSECONDS=$SECONDS
#		while true;do
#			SECFUNCcfgReadDB
#			if ${!lbCfgReq};then #true
#				echo -en "${lstrPrefixMsg} Waiting request '$lstrId' be accepted for $((SECONDS-lnSECONDS))s\r" >&2
#			else
#				break;
#			fi # after accepted it will be set to false
#			
#			if ! $lbWait;then break;fi
#			sleep 1
#		done
	fi
		
	return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCsyncStopContinue() { #help [lstrBaseId] help on synchronizing scripts (or self calling script)
	# var init here
	local lstrExample="DefaultValue"
	local lbStop=false
	local lbContinue=false
	local lbCheckHold=false
	local lstrBaseId="`SECFUNCfixIdA -f -- "$SECstrScriptSelfName"`"
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
	lstrBaseId="`SECFUNCfixIdA -f -- "$lstrBaseId"`"
	
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
				echo -en "${lstrPrefixMsg} Waiting stop request '$lstrBaseId' be accepted for $((SECONDS-lnSECONDS))s\r" >&2
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
				echo -en "${lstrPrefixMsg} Waiting continue request '$lstrBaseId' be accepted for $((SECONDS-lnSECONDS))s\r" >&2
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
				echo -en "${lstrPrefixMsg} Holding execution '$lstrBaseId' for $((SECONDS-lnSECONDS))s\r" >&2
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

  declare -g SECnULDaemonPid=0
#	declare -g SECnDaemonPid=0
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--quiet" ]];then #SECFUNCuniqueLock_help prevent all output to /dev/stdout
			lbQuiet=true
		elif [[ "$1" == "--notquiet" ]];then #SECFUNCuniqueLock_help allow output to /dev/stdout
			lbQuiet=false
		elif [[ "$1" == "--id" ]];then #SECFUNCuniqueLock_help <lstrId> set the lock id (will be fixed if necessary), if not set, the 'id' defaults to `basename $0`
			shift
			lstrId="${1-}"
		elif [[ "$1" == "--pid" ]];then #SECFUNCuniqueLock_help <l_pid> force pid to be related to the lock, mainly to acquire (default) and --release the lock
			shift
			l_pid="${1-}"
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
		elif [[ "$1" == "--getdaemonpid" ]];then #SECFUNCuniqueLock_help output the value of SECnULDaemonPid, 0 if daemon is not running, implies --quiet
			lbGetDaemonPid=true
 			lbQuiet=true #this prevents other outputs
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
	
	lstrId="`SECFUNCfixIdA --justfix -- "$lstrId"`"
#	if ! SECFUNCvalidateIdA -- "$lstrId";then
#		SECFUNCdbgFuncOutA;return 1
#	fi
	
  local lstrFlUniq=".SEC.UniqueRun.$lstrId"
  if((${#lstrFlUniq}>=255));then
    lstrFlUniq=".SEC.UniqueRun.sum`echo "$lstrId" |cksum |tr -d " "`"
  fi
	local l_runUniqueFile="$SEC_TmpFolder/${lstrFlUniq}"
	if $lbGetUniqueFile;then
		echo "$l_runUniqueFile"
		SECFUNCdbgFuncOutA;return 0
	fi
	
  # IMPORTANT!!! the lock will be validated and if necessary released here
	local lnLockPid=`SECFUNCfileLock --islocked "$l_runUniqueFile"&&:`
  
	if $lbOnlyCheckIfDaemonIsRunning;then
		if [[ -f "$l_runUniqueFile" ]] && ((lnLockPid>0));then
			SECFUNCdbgFuncOutA;return 0
		else
			SECFUNCdbgFuncOutA;return 1
		fi
	fi
	
#	function SECFUNCuniqueLock_setDbToOtherThatIsDaemon(){
#		#SECnULDaemonPid="`SECFUNCuniqueLock --id "$lstrId"`"
#		if [[ -f "$l_runUniqueFile" ]];then
#			local lnDaemonPidCheck="`cat "$l_runUniqueFile" 2>/dev/null &&:`"
#			if SECFUNCisNumber -dn "$lnDaemonPidCheck";then
#				if [[ -d "/proc/$lnDaemonPidCheck" ]];then
#					SECnULDaemonPid=$lnDaemonPidCheck
#					SECFUNCvarSetDB $SECnULDaemonPid #allows intercommunication between proccesses started from different parents
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
					SECnULDaemonPid=$lnDaemonPidCheck
					SECFUNCvarSetDB $SECnULDaemonPid
					SECFUNCdbgFuncOutA;return 0
				fi
			fi
		fi
		
    SECFUNCechoErrA "daemon is not running l_runUniqueFile='$l_runUniqueFile'"
		SECFUNCdbgFuncOutA;return 1
	fi
	
	if ${lbDaemon:?};then #will call this self function, beware..
		SECFUNCdelay "$FUNCNAME" --init # do not mess with: SECONDS=0 !!!
		local lbBecameDaemon=false
		while true;do
			SECbDaemonWasAlreadyRunning=false #global NOT to export #TODO EXPLAIN WHY?!
			if SECFUNCuniqueLock --quiet --id "$lstrId"; then
				SECFUNCvarSetDB -f
				SECnULDaemonPid=$$ # ONLY after the lock has been acquired!
			else
				#SECFUNCuniqueLock_setDbToOtherThatIsDaemon
				if ! SECnULDaemonPid="`SECFUNCuniqueLock --id "$lstrId"`";then
					SECFUNCvarSetDB $SECnULDaemonPid # set DB to other that is daemon
					SECbDaemonWasAlreadyRunning=true
				fi
			fi
			
			if((SECnULDaemonPid==$$));then
				lbBecameDaemon=true
			fi
			
#			if SECFUNCuniqueLock_setDbToOtherThatIsDaemon;then
#				SECbDaemonWasAlreadyRunning=true
#			else
#				if SECFUNCuniqueLock --quiet --id "$lstrId"; then
#					SECFUNCvarSetDB -f # make DB file be real (prevent it being a symlink)
#					SECnULDaemonPid=$l_pid # ONLY after the lock has been acquired!
#				else
#					SECbDaemonWasAlreadyRunning=true
#				fi				
#			fi
		
			if ${lbWaitDaemon:?};then
				if $lbBecameDaemon;then
					break;
				else
#				if $SECbDaemonWasAlreadyRunning;then
					echo -ne "$FUNCNAME: Wait other ($SECnULDaemonPid) Daemon '$lstrId': `SECFUNCdelay "$FUNCNAME" --getsec`s...\r" >&2
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
		IFS=$'\n' read -d '' -r -a astrUniqueFileList < <(ls -1 "$SEC_TmpFolder/.SEC.UniqueRun."*&&:)&&: #TODO why this `&&:)&&:` was necessary instead of simply `)&&:` ? the inner error should have been ignored...
		local lstrUniqueFile
		if((`SECFUNCarraySize astrUniqueFileList`>0));then
			for lstrUniqueFile in "${astrUniqueFileList[@]}";do
			#ls -1 "$SEC_TmpFolder/.SEC.UniqueRun."*&&: |while read lstrUniqueFile;do
				local lnPidCheck="$(cat "$lstrUniqueFile")"
				#if [[ ! -d "/proc/$lnPidCheck" ]];then
				local lbAlive=false
				if SECFUNCpidChecks --active --check "$lnPidCheck";then
					lbAlive=true
				fi
			
				if $lbAlive;then
					if ! $lbQuiet;then
	#					local lstrDeadInfo="(DEAD)"
	#					local lstrLockFile=""
	#					local lstrDeadInfo=""
						local lstrLockFile="`basename "$(SECFUNCfileLock --getlock "$lstrUniqueFile")"`"&&:
						echo "U='`basename "${lstrUniqueFile}"`', pid='${lnPidCheck}', lock='${lstrLockFile}'"
	#					echo "`basename "${lstrUniqueFile}"`,${lnPidCheck}${lstrDeadInfo},${lstrLockFile}"
					fi
				else
					# TODO confirm if this quick lock is to prevent another process from creating a lock, while trying to remove the unique file here AND DOCUMENT IT PROPERLY!!! :P
					local lstrQuickLock="${lstrUniqueFile}.ToCreateRealFile.lock"
					if ln -s "$lstrUniqueFile" "$lstrQuickLock";then
						rm "$lstrUniqueFile"
						echo "[`SECFUNCdtTimeForLogMessages`]Removed lstrUniqueFile='$lstrUniqueFile' with dead lnPidCheck='$lnPidCheck'." >&2
						rm "$lstrQuickLock" #after all is done
					fi
				fi
			done
		fi
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
	
  if $lbGetDaemonPid;then
    if [[ -n "$lnLockPid" ]];then
      echo "$lnLockPid"
    else
      echo 0
    fi
		SECFUNCdbgFuncOutA;return 0
	fi
  
	if [[ -n "$lnLockPid" ]];then
		SECnULDaemonPid="$lnLockPid"
		if(($l_pid==$lnLockPid));then
			SECFUNCechoWarnA "redundant lock '$lstrId' request..."
			if ! ${lbQuiet:?};then
				echo "$SECnULDaemonPid"
			fi
			SECFUNCdbgFuncOutA;return 0
		else
			if ! ${lbQuiet:?};then
				echo "$SECnULDaemonPid"
			fi
      SECFUNCechoErrA "this unique lock is in use l_runUniqueFile='$l_runUniqueFile'"
			SECFUNCdbgFuncOutA;return 1
		fi
	else
		if SECFUNCfileLock --nowait "$l_runUniqueFile";then
			echo $l_pid >"$l_runUniqueFile"
			chmod o-rwx "$l_runUniqueFile"
			SECnULDaemonPid="$l_pid"
			if ! ${lbQuiet:?};then
				echo "$SECnULDaemonPid"
			fi
		else
      SECFUNCechoErrA "unable to create lock l_runUniqueFile='$l_runUniqueFile'"
			SECFUNCdbgFuncOutA;return 1 #TODO: check if concurrent attempts can make it fail? so pass failure to caller...
		fi
	fi

	SECFUNCdbgFuncOutA;return 0
}

function pSECFUNCcfgOptSet(){ #help <"$@"> to be used at --cfg scripts option
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #pSECFUNCcfgOptSet_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #pSECFUNCcfgOptSet_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #pSECFUNCcfgOptSet_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	#if [[ -d "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]];then mv -v "$SECstrUserHomeConfigPath/SEC.AppVars.DB" "$lpath" >&2;	ln -sv "$lpath" "$SECstrUserHomeConfigPath/SEC.AppVars.DB" >&2; fi 
	if [[ ! -d "$lpath" ]];then
		if [[ -d "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]] && [[ ! -L "$SECstrUserHomeConfigPath/SEC.AppVars.DB" ]];then #TODO remove this check one day, it is here just to provide an easy migration...
			mv -Tv "$SECstrUserHomeConfigPath/SEC.AppVars.DB" "$lpath" >&2; # just rename
			ln -Tsv "$lpath" "$SECstrUserHomeConfigPath/SEC.AppVars.DB" >&2;
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
			#echo "lstrCanonicalFileName=$lstrCanonicalFileName" >&2
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
#function SECFUNCcfgReadDB() { #help read the cfg file and set all its env vars at current env
#	SECFUNCdbgFuncInA;
#	#echo oi;eval `cat tst.db`;return
#	if [[ -z "$SECcfgFileName" ]];then
#		SECFUNCcfgFileName
#	fi
#	
#	if [[ "${1-}" == "--help" ]];then
#		SECFUNCshowHelp ${FUNCNAME}
#		SECFUNCdbgFuncOutA;return
#	fi
#	
#	if [[ -f "$SECcfgFileName" ]];then
#  	SECFUNCfileLock "$SECcfgFileName"
#  	#sedFixStoredArray="s,^([^=]*)=(\(.*\));$,declare -ax \\\\\n\1='\2';," # arrays stored just like `astr=();`, should be `declare -a astr='()';`, my bad... now I have to fix it...
#		#sed -i.bkp -r -e "$sedFixStoredArray" $SECcfgFileName
#  	#sed -r -e "$sedFixStoredArray" $SECcfgFileName
#		while true;do
#			#eval "`cat "$SECcfgFileName"`"
#			#eval "`sed -r -e "$sedFixStoredArray" $SECcfgFileName`"
#			#source "$SECcfgFileName"
#			eval "`cat "$SECcfgFileName"`" #TODO eval is safer than `source`? in case of a corrupt file? ugh????
#			local lnRetFromEval=$?
#			if((lnRetFromEval!=0));then
#				SECFUNCechoErrA "at config file SECcfgFileName='$SECcfgFileName'"
#				SECFUNCfixCorruptFile "$SECcfgFileName"
#			else
#				break
#			fi
#		done
#  	SECFUNCfileLock --unlock "$SECcfgFileName"
#  fi
#  SECFUNCdbgFuncOutA;
#  #set -x
#}
function SECFUNCcfgReadDB() { #help read the cfg file and apply all its env vars at current env. \n\t!!!IMPORTANT!!! it seems to not work inside of some functions (test always)! TODO fix this?
	SECFUNCdbgFuncInA;
	#echo oi;eval `cat tst.db`;return
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	if [[ "$SECcfgFileName" == "bash.cfg" ]];then # bash is not a script itself, and this specific case will prevent a lot of trouble.
    SECFUNCechoWarnA "SECcfgFileName='$SECcfgFileName'" #TODO should check if the script file exists, ends with .sh and is a text file.
    SECFUNCdbgFuncOutA;return 0
  fi
	
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	local lbKeepLocked=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCcfgReadDB_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--keeplock" || "$1" == "-k" ]];then #SECFUNCcfgReadDB_help will not unlock the db after returning
			lbKeepLocked=true
		elif [[ "$1" == "--" ]];then #SECFUNCcfgReadDB_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			SECFUNCdbgFuncOutA;return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	#validate params here
	
	# code here
	if [[ -f "$SECcfgFileName" ]];then
  	SECFUNCfileLock "$SECcfgFileName"
  	#sedFixStoredArray="s,^([^=]*)=(\(.*\));$,declare -ax \\\\\n\1='\2';," # arrays stored just like `astr=();`, should be `declare -a astr='()';`, my bad... now I have to fix it...
		#sed -i.bkp -r -e "$sedFixStoredArray" $SECcfgFileName
  	#sed -r -e "$sedFixStoredArray" $SECcfgFileName
		while true;do
			#eval "`cat "$SECcfgFileName"`"
			#eval "`sed -r -e "$sedFixStoredArray" $SECcfgFileName`"
			#source "$SECcfgFileName"
			
#			declare -p CFGanPidRequesterListForFancyWork >&2
#			cat "$SECcfgFileName" >&2
			eval "`cat "$SECcfgFileName"`" #TODO eval is safer than `source`? in case of a corrupt file? ugh????
#			declare -p CFGanPidRequesterListForFancyWork >&2
			local lnRetFromEval=$?
			if((lnRetFromEval!=0));then
				SECFUNCechoErrA "at config file SECcfgFileName='$SECcfgFileName'"
				SECFUNCfixCorruptFile "$SECcfgFileName"
			else
				break
			fi
		done
		if ! $lbKeepLocked;then SECFUNCfileLock --unlock "$SECcfgFileName";fi
  fi
  
  SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}
function pSECFUNCprepareEnvVarsToWriteDB() { #private: store in a way that when being read will be considered global by adding -g
	#declare -p "$@" |sed -r "s'^(declare )([^ ]*) '\1\2g '"
	declare -p "$@" |sed -r "s'^(declare )([^ ]*)( .*)'\1\2g\3;'"
}
function SECFUNCcfgWriteVar() { #help <var>[=<value>] write a variable to config file
	#TODO make SECFUNCvarSet use this and migrate all from there to here?
	local lbRemoveVar=false
	local lbReport=false;
	local lbKeepLocked=false
  local lbChkLock=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--remove" ]];then #SECFUNCcfgWriteVar_help remove the variable from config file
			lbRemoveVar=true
		elif [[ "$1" == "--report" || "$1" == "-r" ]];then #SECFUNCcfgWriteVar_help output the variable being written
			lbReport=true
		elif [[ "$1" == "--keeplock" || "$1" == "-k" ]];then #SECFUNCcfgWriteVar_help will not unlock the db after returning
			lbKeepLocked=true
		elif [[ "$1" == "--dontchecklock" ]];then #SECFUNCcfgWriteVar_help UNSAFE but will speed up
      lbChkLock=false
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
	
	local lstrToWrite="`pSECFUNCprepareEnvVarsToWriteDB ${lstrVarId}`"
	
	if [[ ! -f "$SECcfgFileName" ]];then
		echo -n >"$SECcfgFileName"
	fi
	
  if $lbChkLock;then 
    if ! SECFUNCfileLock --islocked >/dev/null;then
      SECFUNCfileLock "$SECcfgFileName";
    fi
  fi
	######
	# this will remove the variable declaration
	######
	sed -i "/^declare [^ ]* ${lstrVarId}=/d" "$SECcfgFileName" 
	if ! $lbRemoveVar;then
		echo "${lstrToWrite}" >>"$SECcfgFileName" #append new line with var
	fi
	if ! $lbKeepLocked;then SECFUNCfileLock --unlock "$SECcfgFileName";fi
	
	chmod u+rw,go-rw "$SECcfgFileName" #permissions for safety
	
	if $lbReport;then
		echo "$lstrToWrite" >&2
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
	
	local lstrAllCfgVars="`declare |egrep "^${lstrPrefix}[[:alnum:]_]*=" |sed -r 's"^([^=]*)=.*"\1"'`"
	#declare -p lstrAllCfgVars
	local lastrAllCfgVars;IFS=$'\n' read -d'' -r -a lastrAllCfgVars < <(echo "$lstrAllCfgVars")&&:
	#declare -p lastrAllCfgVars
	
	if((`SECFUNCarraySize lastrAllCfgVars`>0));then
    if [[ ! -f "$SECcfgFileName" ]];then echo -n >>"$SECcfgFileName";fi
    SECFUNCfileLock "$SECcfgFileName"
		for lstrCfgVar in "${lastrAllCfgVars[@]}";do
			SECFUNCcfgWriteVar --dontchecklock --keeplock $lstrCfgVar
			if $lbShowAll;then
				echo "$lstrCfgVar='${!lstrCfgVar-}' #SECCFG" >&2
			fi
		done
    SECFUNCfileLock --unlock "$SECcfgFileName"
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
	#SECFUNCarraysExport;bash -c 'source <(secinit --base);_SECFUNCdaemonCheckHold_SubShell;'
	SECFUNCexecOnSubShell 'source <(secinit --ilog --fast);_SECFUNCdaemonCheckHold_SubShell;' #--ilog to prevent creation of many temporary, and hard to track, log files.
	
	SECFUNCdbgFuncOutA;
}

function SECFUNCCcpulimit() { #help [lstrMatchRegex] run cpulimit as a child process waiting for other UNIQUE process match regex
	SECFUNCdbgFuncInA;

  local lstrMatchRegex="$1";shift

	# var init here
	local lstrExample="DefaultValue"
  local lbExample=false
	local lastrRemainingParams=()
  local lnTimeout=10
  local lnPercRelat=0
	local lastrAllParams=("${@-}") # this may be useful
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCCcpulimit_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--timeout" || "$1" == "-t" ]];then #SECFUNCCcpulimit_help <lnTimeout>
			shift;lnTimeout="$1"
    elif [[ "$1" == "-l" || "$1" == "--limit" ]];then #SECFUNCCcpulimit_help use a percentage RELATIVE to the max processing power
			shift;lnPercRelat="$1"
		elif [[ "$1" == "--" ]];then #SECFUNCCcpulimit_help params after this are ignored as being these options, and stored at lastrRemainingParams. Will be used as cpulimit params.
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift&&: #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			SECFUNCdbgFuncOutA;return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done

  if((lnPercRelat>0));then
    local lnCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"
    lastrRemainingParams+=(-l $((lnPercRelat*lnCPUs)))
  fi
	
	#validate params here
	if pgrep -f "$lstrMatchRegex" >/dev/null;then
    SECFUNCechoErrA "this must be run before '$lstrMatchRegex' for uniqueness consistency."
    exit 1 #TODO capture it how?
  fi
  
	# code here
  (
    local lnStart=$SECONDS
    local lnPid
    while true;do 
      if lnPid=`pgrep -f "$lstrMatchRegex"`;then
        if((`echo "$lnPid" |wc -l`!=1));then
          SECFUNCechoErrA "match '$lstrMatchRegex' must be unique!"
          exit 1 #TODO capture it how?
        fi
        break
      fi
      echo "$FUNCNAME: `date` waiting '$lstrMatchRegex' to start..." >&2
      sleep 0.25;
      if(( (SECONDS-lnStart) > lnTimeout));then
        exit 0 # timedout
      fi
    done;
    if ! SECFUNCexecA -ce cpulimit "${lastrRemainingParams[@]}" -p $lnPid;then
      SECFUNCechoWarnA "failed to start cpulimit"
    fi
  )&
	
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCtrash() { #help verbose but let only error/warn messages that are not too repetitive
  #TODO how to fix the "unsecure...sticky" condition? it should explain why it is unsecure so we would know what to fix...
  SECFUNCexecA -ce trash -v "$@" 2>&1 \
    |egrep -v "trash: found unsecure [.]Trash dir \(should be sticky\):" \
    |egrep -v "found unusable [.]Trash dir" \
    |egrep -v "Failed to trash .*Trash.*, because :\[Errno 13\] Permission denied:" \
    |egrep -v "Failed to trash .*Trash.*, because :\[Errno 2\] No such file or directory:" \
    >&2
}

function SECFUNCfileSuffix() { #help <file> extracts the file suffix w/o '.'
  local lstrFile="$1"
  if [[ "$lstrFile" =~ .*[.].* ]];then
    echo -n "$lstrFile" |sed -r "s'.*[.]([^.]*)$'\1'"
  fi
  return 0
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

function SECFUNCscriptNameAsId(){
  SECFUNCfixId --justfix -- "$(basename "$0")"
}

function SECFUNCcreateFIFO(){ #help [lstrCustomName] create a temporary FIFO PIPE file
	SECFUNCdbgFuncInA;
	# var init here
	local lstrExample="DefaultValue"
  local lbExample=false
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #FUNCexample_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #FUNCexample_help <lstrExample> MISSING DESCRIPTION
			shift
			lstrExample="${1-}"
    elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #FUNCexample_help MISSING DESCRIPTION
      lbExample=true
		elif [[ "$1" == "--" ]];then #FUNCexample_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift&&: #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			SECFUNCdbgFuncOutA;return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	#validate params here
	
	# code here
  local lstrCustomName="${1-}";if [[ -n "$lstrCustomName" ]];then lstrCustomName=".${lstrCustomName}";fi
  
  local lstrScId="$(SECFUNCscriptNameAsId)"
  local lstrFifoFl="$SEC_TmpFolder/.${lstrScId}${lstrCustomName}.FIFO" &&: #TODO why this returns 1 but works???
  if [[ -a "$lstrFifoFl" ]];then
    if [[ ! -p "$lstrFifoFl" ]];then
      SECFUNCechoErrA "lstrFifoFl='$lstrFifoFl' not a pipe"
      return 1
    fi
    SECFUNCechoWarnA "pipe already created lstrFifoFl='$lstrFifoFl'"
  else
    mkfifo "$lstrFifoFl"
  fi
  #ls -l "$lstrFifoFl" >&2
  echo "$lstrFifoFl"
  
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCternary() { #help <boolValue> ? <acmdTrue> : <acmdFalse> # the commands can be many params
  #TODO allow many params to be cmdTrue ending it with ';' or \; like `find -exec` works :)
  local lboolValue=$1
  if [[ "$lboolValue" != "true" && "$lboolValue" != "false" ]];then #TODO 0 or 1 too? but 0=true or false? hehe.. :/
    SECFUNCechoErrA "lboolValue must be 'true' or 'false'"
    return 1
  fi
  shift
  
  if [[ "$1" != "?" ]];then
    SECFUNCechoErrA "missing '?'"
    return 1
  fi
  shift
  
  local lacmdTrue=()
  while [[ "$1" != ":" ]];do lacmdTrue+=("$1");shift;done
  shift
  
  local lacmdFalse=()
  while [[ -n "${1-}" ]];do lacmdFalse+=("$1");shift;done
  
  if((`SECFUNCarraySize lacmdTrue`==0));then SECFUNCechoErrA "empty lacmdTrue";fi
  if((`SECFUNCarraySize lacmdFalse`==0));then SECFUNCechoErrA "empty lacmdFalse";fi
  
  if $lboolValue;then
    "${lacmdTrue[@]}"
  else
    "${lacmdFalse[@]}"
  fi
  
  #~ declare -p lboolValue lacmdTrue lacmdFalse
  
  return 0
}

function SECFUNCtoggleBoolean(){ #help toggles a variable "boolean" value (true or false) only if it was already set as "boolean"
	# var init here
#	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	local lbShow=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCtoggleBoolean_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "${1-}" == "--show" ]]; then #SECFUNCtoggleBoolean_help
			lbShow=true
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCtoggleBoolean_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCtoggleBoolean_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	local lstrVarId="${1-}"
	if ! declare -p "$lstrVarId" >>/dev/null;then
		SECFUNCechoErrA "invalid var '$lstrVarId'"
		return 1
	fi
	
	# code here
	local lstrValue="${!lstrVarId}"
	local lstrNewValue=""
	if [[ "$lstrValue" == "true" ]];then
		lstrNewValue="false"
	elif [[ "$lstrValue" == "false" ]];then
		lstrNewValue="true"
	else
		SECFUNCechoErrA "var '$lstrVarId' has not boolean value '$lstrValue'"
		return 1
	fi
	
	declare -xg ${lstrVarId}="$lstrNewValue"
	if $lbShow;then declare -p ${lstrVarId};fi
	
	return 0 # important to have this default return value in case some non problematic command fails before returning
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

