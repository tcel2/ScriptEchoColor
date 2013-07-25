#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

_SECselfBaseName="secSayStack.sh" #@@@!!! update me if needed!
_SECfileSayStack="/tmp/SEC.SayStack.tmp"

source "`ScriptEchoColor --getinstallpath`/lib/ScriptEchoColor/utils/funcMisc.sh"

function FUNCsayStack() {
	####################### internal cfg of variables, functions and base initializations
	local selfMainFunctionPid="$BASHPID" #$$ WONT WORK if this code has been sourced on another script, it requires $BASHPID for the instance pid of a child process with this function
	local lockFile="${_SECfileSayStack}.lock"
	local suspendFile="${_SECfileSayStack}.suspend"
	local strSuspendAtKey="SayStackSuspendedAtPid"
	local strSuspendByKey="SayStackSuspendedByPid"
	local SEC_SAYVOL=100
  local sleepDelay=0.1
  local bDaemon=false
  local bWaitSay=false
  local bResume=false
  local strDaemonSays="Say stack daemon initialized."
  
  function FUNCechoDbgSS() { 
  	SECFUNCechoDbg --caller "FUNCsayStack" "$1"; 
  }
  
  function FUNCechoErrSS() { 
  	SECFUNCechoErr --caller "FUNCsayStack" "$1"; 
  }
  
  function FUNCexecSS() {
  	###### options
  	local caller=""
		while [[ "${1:0:2}" == "--" ]]; do
			if [[ "$1" == "--help" ]];then #FUNCexecSS_help show this help
				grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
				return
			elif [[ "$1" == "--caller" ]];then #FUNCexecSS_help is the name of the function calling this one
				shift
				caller="${1}: "
			else
				FUNCechoErrSS "$FUNCNAME: $LINENO: invalid option $1"
				return 1
			fi
			shift
		done
  	
  	###### main code
		SECFUNCexec --caller "FUNCsayStack" --quiet "$@"
  }
  
  function FUNCisPidActive() { #generic check with info
  	if [[ -z "$1" ]]; then
			FUNCechoErrSS "$FUNCNAME: $LINENO: empty pid value"
			return 1
  	fi
		
		# this is necessary as pid ids wrap at `cat /proc/sys/kernel/pid_max`
  	# the pid 'command' at `ps` must have this script filename
  	# this prevents this file from being sourced, see (*1) at the end...
  	# do not use FUNCexecSS or SECFUNCexec here!
  	if ! ps -p $1 --no-headers -o command |grep -q "$_SECselfBaseName"; then
  		return 1
  	fi
  	
  	FUNCexecSS --caller "$FUNCNAME" ps -p $1 -o pid,ppid,stat,state,command;
  	return $?
  }
  
  function FUNCcheckIfLockPidIsRunning() {
  	local realLockFile="$1"
  	
		# if exist, check if its pid is running
		local otherPid=`echo "$realLockFile" |sed -r "s'.*[.]([[:digit:]]*)[.]lock$'\1'"`
		FUNCechoDbgSS "already running pid is $otherPid"
		if ! FUNCisPidActive $otherPid; then
			# if pid is not running, probably crashed so clean up locks
			FUNCexecSS rm $_SECdbgVerboseOpt "${_SECfileSayStack}."*".lock"
			return 1 # pid is not running
		fi
		
		return 0 # pid is running
	}
  
	function FUNCgetRealLockFile() {
		while true; do
			if ! sleep $sleepDelay; then return 1; fi #sleep to help not mess the CPU
			
			# lock file exist?
			local realLockFile=""
			if [[ -L "$lockFile" ]];then
				realLockFile=`readlink "$lockFile"`
				if [[ ! -f "$realLockFile" ]];then
					FUNCechoErrSS "$FUNCNAME: $LINENO: $realLockFile doesnt exist, its pid crashed?"
					FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
					continue
				fi
			elif [[ -a "$lockFile" ]];then
				#rm "${_SECfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
				FUNCechoErrSS "$FUNCNAME: $LINENO: $lockFile should be a symlink! the mess will be cleaned..."
				FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
				continue
			fi
	
			echo "$realLockFile"
			return 0
		done
	}
  
  function FUNCsuspend() {
		echo "$strSuspendByKey=$$" >"$suspendFile"
		# wait for the other secSayStack.sh pid, to acknowledge to suspending
		while true;do
			# suspend file was already removed...
			if [[ ! -f "$suspendFile" ]];then
				# in case --resume happens before the other secSayStack.sh can acknowledge
				break;
			fi
			
			# there is no say stack to be suspended...
			local nSayStackDataSize=`du -b "$_SECfileSayStack" |sed -r "s'^([[:digit:]]*).*'\1'"`
			if((nSayStackDataSize==0));then
				# no one is trying to say anything...
				break;
			fi
			
			local realLockFile=`FUNCgetRealLockFile`
			
			# there is no pid trying to say anything...
			if [[ -z "$realLockFile" ]];then
				break;
			fi
			
			# the lock pid crashed, so no one is trying to say anything...
			if ! FUNCcheckIfLockPidIsRunning "$realLockFile";then
				break
			fi
			
			# the lock pid aknowledged to the suspend command!
			if grep --quiet "$strSuspendAtKey" "$suspendFile";then
				break;
			fi
			
			if ! sleep $sleepDelay; then return 1; fi
		done
  }
  
  function FUNCresumeJustDel() {
  	FUNCexecSS rm $_SECdbgVerboseOpt "$suspendFile"
  }
  
  ####################### other initializations
  
	local selfFullCmd="`SECFUNCparamsToEval $0 "$@"`"
 	FUNCechoDbgSS "<- start at"
 	FUNCechoDbgSS "pids: script $$, instance $selfMainFunctionPid, parent $PPID"
 	
  ####################### options
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #FUNCsayStack_help show this help
			grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--sayvol" ]];then #FUNCsayStack_help set volume to be used at festival
			shift
		  SEC_SAYVOL="$1"
		elif [[ "$1" == "--daemon" ]];then #FUNCsayStack_help keeps running and takes care of all speak requests with log
			bDaemon=true
		elif [[ "$1" == "--waitsay" ]];then #FUNCsayStack_help only exit after the saying of the specified text has finished
			bWaitSay=true
		elif [[ "$1" == "--suspend" ]];then #FUNCsayStack_help suspend speaking, and return only after the speaking is surely suspended (see --resume)
			FUNCsuspend
			# must not allow to speak anything after suspend or this function wont exit...
			return #exit_FUNCsayStack: wont put empty lines
		elif [[ "$1" == "--resume" ]];then #FUNCsayStack_help resume speaking
			FUNCresumeJustDel
			bResume=true
		elif [[ "$1" == "--resume-justdel" ]];then #FUNCsayStack_help just delete the suspend file, allowing other pids to resume speaking
			FUNCresumeJustDel
			return #exit_FUNCsayStack: wont put empty lines
		elif [[ "$1" == "--reset" ]];then #FUNCsayStack_help reset and clear all that would have been spoken
			FUNCexecSS rm $_SECdbgVerboseOpt "${_SECfileSayStack}"
			return #exit_FUNCsayStack: wont put empty lines
		else
			FUNCechoErrSS "$FUNCNAME: $LINENO: invalid option $1"
		  return 1 #exit_FUNCsayStack: 
		fi
		shift
	done
	local sayText="$1" #last param
	if $bDaemon;then
		sayText="${strDaemonSays}${sayText}"
	fi
	
	####################### what will be said (configured to festival)
	if [[ -z "$sayText" ]]; then
		if $bResume;then
			sayText=" " #dummy speech to force resuming, probably in case saying pid crashed or was killed.
		else
			return #exit_FUNCsayStack: wont put empty lines
		fi
	fi
	
	#echo "$sayText" >>"$_SECfileSayStack"
	sayVol=`echo "scale=2;$SEC_SAYVOL/100" |bc -l`
	paramSortOrder="(Parameter.set 'SECsortOrder '`date +"%s.%N"`)" # I created this param with a var name SECsortOrder that I believe wont conflict with pre-existant ones on festival
	echo "${paramSortOrder}\
	      (Parameter.set 'Audio_Method 'Audio_Command)\
				(Parameter.set 'Audio_Required_Rate 16000)\
				(Parameter.set 'Audio_Required_Format 'snd)\
				(Parameter.set 'Audio_Command \"play -v $sayVol \$FILE\")\
				(SayText \"$sayText\")" >>"$_SECfileSayStack"
	sort "$_SECfileSayStack" -o "$_SECfileSayStack" #ensure FIFO
	
	####################### lock file work
	while true; do
		if ! sleep $sleepDelay; then return 1; fi #sleep to help not mess the CPU in case of a infinite loop bug.. #exit_FUNCsayStack: also exits on sleep fail
		
#		# lock file exist?
#		local realLockFile=""
#		if [[ -L "$lockFile" ]];then
#			realLockFile=`readlink "$lockFile"`
#			if [[ ! -f "$realLockFile" ]];then
#				#cleanup because probably crashed and the file wasnt normally removed?
#				#realLockFile=""
#				FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
#				continue #try again
#			fi
#		elif [[ -a "$lockFile" ]];then
#			#rm "${_SECfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
#			FUNCechoErrSS "$FUNCNAME: $LINENO: $lockFile should be a symlink!"
#			return 1 #exit_FUNCsayStack: 
#		fi
#		if ! local realLockFile=`FUNCgetRealLockFile`;then
#			continue #try again
#		fi
		local realLockFile=`FUNCgetRealLockFile`
	
		if [[ -z "$realLockFile" ]];then
			# if not exist, aquire lock
			realLockFile="${_SECfileSayStack}.$selfMainFunctionPid.lock"
			
			#create the real file
			echo "$selfFullCmd" >>"$realLockFile"
			ps -p $selfMainFunctionPid --no-headers -o command >>"$realLockFile"
			
			while ! FUNCexecSS ln $_SECdbgVerboseOpt -s "$realLockFile" "$lockFile"; do #create the symlink
				if ! sleep $sleepDelay; then return 1; fi #exit_FUNCsayStack: on sleep fail
			done
			break
		else
			if ! FUNCcheckIfLockPidIsRunning "$realLockFile";then
				continue #try again
			fi
#			# if exist, check if its pid is running
#			local otherPid=`echo "$realLockFile" |sed -r "s'.*[.]([[:digit:]]*)[.]lock$'\1'"`
#			FUNCechoDbgSS "already running pid is $otherPid"
#			if ! FUNCisPidActive $otherPid; then
#				# if pid is not running, probably crashed so clean up locks
#				FUNCexecSS rm $_SECdbgVerboseOpt "${_SECfileSayStack}."*".lock"
#				continue #try again
#			fi
		
			FUNCechoDbgSS "pid $otherPid will take care of say stack!"
			if $bWaitSay;then
				while grep -q "$paramSortOrder" "$_SECfileSayStack";do
					if ! sleep $sleepDelay; then return 1; fi #exit_FUNCsayStack: on sleep fail
				done
			fi
			return #exit_FUNCsayStack: as another pid is already saying the stack
		fi
		
		FUNCechoErrSS "$FUNCNAME: $LINENO: this line of the code should not have been reached!"
		return 1 #exit_FUNCsayStack: 
	done	
	
	####################### say the stack buffer FIFO
	while true; do
		while [[ -f "$suspendFile" ]];do
			if ! grep --quiet "$strSuspendAtKey" "$suspendFile";then
				if [[ -f "$suspendFile" ]];then #safety double check
					echo "$strSuspendAtKey=$$" >>"$suspendFile"
				fi
			fi
			if ! sleep $sleepDelay; then return 1; fi #exit_FUNCsayStack: on sleep fail
		done
		
		if [[ -f "$_SECfileSayStack" ]];then
			local strHead=`head -n 1 "$_SECfileSayStack"`
			if [[ -n "$strHead" ]]; then
				if $bDaemon; then
					echo "Said at `SECFUNCdtTimePrettyNow`: $strHead"
				fi
			
				echo "$strHead"	|FUNCexecSS festival --pipe

				FUNCexecSS sed -i 1d "$_SECfileSayStack" #delete 1st line
			else
				if ! $bDaemon;then
					break
				fi
			fi
		else
			if ! $bDaemon;then
				break
			fi
		fi
		
		if ! sleep $sleepDelay; then return 1; fi #exit_FUNCsayStack: on sleep fail
	done
	
	####################### release the lock
	FUNCexecSS rm $_SECdbgVerboseOpt "$realLockFile"
	FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
	FUNCechoDbgSS "<- exit at"
}

if [[ -n "$1" ]]; then
	FUNCsayStack "$@"
	exit 0
fi

#(*1)
if [[ `basename "$0"` != "$_SECselfBaseName" ]];then
	SECFUNCechoErr "this file '$_SECselfBaseName' cannot be used as source script! or, update var _SECselfBaseName with correct filename is required! press a key to exit."; read -n 1; exit 1
fi

