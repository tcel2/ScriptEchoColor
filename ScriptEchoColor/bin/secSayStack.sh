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

export _SECSAYselfBaseName="secSayStack.sh" #@@@!!! update me if needed!
export _SECSAYfileSayStack="/tmp/SEC.SayStack.tmp"
export _SECSAYcacheFolder="$HOME/.ScriptEchoColor/SEC.SayStack.cache" #cant be at /tmp that is erased (everytime?) on boot..

if [[ "$SEC_SAYMP3" != "false" ]]; then #compare to inverse of default value
	export SEC_SAYMP3=true # of course, np if already "false"
fi
if [[ -z "$SEC_SAYVOL" ]]; then
	export SEC_SAYVOL=100
fi
if [[ -z "$SEC_SAYID" ]]; then
	export SEC_SAYID="SecSayStackDefaultId"
fi

#source "`ScriptEchoColor --getinstallpath`/lib/ScriptEchoColor/utils/funcMisc.sh"
source "`secGetInstallPath`/lib/ScriptEchoColor/utils/funcMisc.sh"

function FUNCsayStack() {
	####################### internal cfg of variables, functions and base initializations
	local selfMainFunctionPid="$BASHPID" #$$ WONT WORK if this code has been sourced on another script, it requires $BASHPID for the instance pid of a child process with this function
	local lockFile="${_SECSAYfileSayStack}.lock"
	local suspendFile="${_SECSAYfileSayStack}.suspend"
	local strSuspendAtKey="SayStackSuspendedAtPid"
	local strSuspendByKey="SayStackSuspendedByPid"
	#export SEC_SAYVOL=100
	#export SEC_SAYMP3=true
	local sleepDelay=0.1
	local bDaemon=false
	local bWaitSay=false
	local strSayId="$SEC_SAYID"
	local bResume=false
	local strDaemonSays="Say stack daemon initialized."
	local bClearCache=false
  
  function FUNCechoDbgSS() { 
  	SECFUNCechoDbgA --caller "FUNCsayStack" "$1"; 
  };export -f FUNCechoDbgSS
  
  function FUNCechoErrSS() { 
  	SECFUNCechoErrA --caller "FUNCsayStack" "$1"; 
  };export -f FUNCechoErrSS
  
  function FUNCexecSS() {
  	###### options
  	local caller=""
		while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
			if [[ "$1" == "--help" ]];then #FUNCexecSS_help show this help
				#grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
				SECFUNCshowHelp ${FUNCNAME}
				return 0
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
		SECFUNCexecA --caller "FUNCsayStack" --quiet "$@"
  };export -f FUNCexecSS
  
  function FUNCisPidActive() { #generic check with info
  	if [[ -z "${1-}" ]]; then
			FUNCechoErrSS "$FUNCNAME: $LINENO: empty pid value"
			return 1
  	fi
		
		# this is necessary as pid ids wrap at `cat /proc/sys/kernel/pid_max`
  	# the pid 'command' at `ps` must have this script filename
  	# this prevents this file from being sourced, see (*1) at the end...
  	# do not use FUNCexecSS or SECFUNCexec or SECFUNCexecA here! #TODO why?
  	if ! ps -p $1 --no-headers -o command |grep -q "$_SECSAYselfBaseName"; then
  		return 1
  	fi
  	
  	FUNCexecSS --caller "$FUNCNAME" ps -p $1 -o pid,ppid,stat,state,command;
  	return $?
  };export -f FUNCisPidActive
  
  function FUNCcheckIfLockPidIsRunning() {
  	local realLockFile="$1"
  	
		# if exist, check if its pid is running
		local otherPid=`echo "$realLockFile" |sed -r "s'.*[.]([[:digit:]]*)[.]lock$'\1'"`
		FUNCechoDbgSS "already running pid is $otherPid"
		if ! FUNCisPidActive $otherPid; then
			# if pid is not running, probably crashed so clean up locks
			FUNCexecSS rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}."*".lock"
			return 1 # pid is not running
		fi
		
		return 0 # pid is running
	};export -f FUNCcheckIfLockPidIsRunning
  
	function FUNCgetRealLockFile() {
		while true; do
			if ! sleep $sleepDelay; then return 1; fi #sleep to help not mess the CPU
			
			# lock file exist?
			local realLockFile=""
			if [[ -L "$lockFile" ]];then
				realLockFile="`readlink "$lockFile"`"
				if [[ ! -f "$realLockFile" ]];then
					FUNCechoErrSS "$FUNCNAME: $LINENO: $realLockFile doesnt exist, its pid crashed?"
					FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
					continue
				fi
			elif [[ -a "$lockFile" ]];then
				#rm "${_SECSAYfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
				FUNCechoErrSS "$FUNCNAME: $LINENO: $lockFile should be a symlink! the mess will be cleaned..."
				FUNCexecSS rm $_SECdbgVerboseOpt "$lockFile"
				continue
			fi
	
			echo "$realLockFile"
			return 0
		done
	};export -f FUNCgetRealLockFile
  
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
			local nSayStackDataSize=`du -b "$_SECSAYfileSayStack" |sed -r "s'^([[:digit:]]*).*'\1'"`
			if((nSayStackDataSize==0));then
				# no one is trying to say anything...
				break;
			fi
			
			local realLockFile="`FUNCgetRealLockFile`"
			
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
  };export -f FUNCsuspend
  
  function FUNCresumeJustDel() {
  	FUNCexecSS rm $_SECdbgVerboseOpt "$suspendFile"
  };export -f FUNCresumeJustDel
  
	function FUNChasCache() {
		local md5sumText="${1-}"
		local fileAudio="${2-}" #optional
		
		local cacheFile="$_SECSAYcacheFolder/$md5sumText"
		local cacheFileReal="`readlink -f "$cacheFile"`"
		if [[ -f "$cacheFileReal" ]] && ((`stat -c "%s" "$cacheFileReal"`>0));then
			SECFUNCechoDbgA "cache exists: $cacheFile"
			return 0
		else
			SECFUNCechoDbgA "cache missing: $cacheFile"
			# mainly to remove invalid (size=0) files
			FUNCexecSS rm "$cacheFile"
			FUNCexecSS rm "$cacheFileReal"
		fi
		
		if [[ -f "$fileAudio" ]];then
			FUNCexecSS cp "$fileAudio" "$_SECSAYcacheFolder/${md5sumText}"
			SECFUNCechoDbgA "SEC_SAYMP3=$SEC_SAYMP3"
			if $SEC_SAYMP3;then
				local lbConversionWorked=false
				local lnBitRate=32
				
				if ! $lbConversionWorked;then
					if ! FUNCexecSS avconv -i "$_SECSAYcacheFolder/${md5sumText}" -b ${lnBitRate}k "$_SECSAYcacheFolder/${md5sumText}.mp3";then
						SECFUNCechoErrA "avconv failed."
						rm "$_SECSAYcacheFolder/${md5sumText}.mp3"
					else
						lbConversionWorked=true
					fi
				fi
				
				if ! $lbConversionWorked;then
					if ! FUNCexecSS ffmpeg -i "$_SECSAYcacheFolder/${md5sumText}" -b ${lnBitRate}k "$_SECSAYcacheFolder/${md5sumText}.mp3";then
						SECFUNCechoErrA "ffmpeg failed."
						rm "$_SECSAYcacheFolder/${md5sumText}.mp3"
					else
						lbConversionWorked=true
					fi
				fi
				
				if $lbConversionWorked;then
					rm "$_SECSAYcacheFolder/${md5sumText}"
					ln -s "$_SECSAYcacheFolder/${md5sumText}.mp3" "$_SECSAYcacheFolder/${md5sumText}"
				fi
			fi
		fi
		return 1
	};export -f FUNChasCache
	function FUNCplay() { 
		local md5sumText="${1-}"
		local sayVol="${2-}"
		local fileAudio="${3-}" #optional
		SECFUNCechoDbgA "md5sumText=$md5sumText sayVol=$sayVol fileAudio=$fileAudio"
		
		local cacheFile="$_SECSAYcacheFolder/$md5sumText"
		if FUNChasCache "$md5sumText" "$fileAudio";then
			FUNCexecSS touch "$cacheFile" #to indicate that it was recently used
			fileAudio="$cacheFile"
			if $SEC_SAYMP3;then
				local fileAudioMp3="${fileAudio}.mp3"
				if [[ -f "$fileAudioMp3" ]];then
					fileAudio="$fileAudioMp3"
				fi
			fi
		fi
		
		FUNCexecSS play -v $sayVol "$fileAudio";
	};export -f FUNCplay;
  
  ####################### other initializations
  
	local selfFullCmd="`SECFUNCparamsToEval "$0" "$@"`"
 	FUNCechoDbgSS "<- start at"
 	FUNCechoDbgSS "pids: script $$, instance $selfMainFunctionPid, parent $PPID"
 	
  ####################### options
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		bNextIsParam=false #otherwise is option
		if [[ -n "${2-}" ]] && [[ "${2:0:1}" != "-" ]];then
			bNextIsParam=true
		fi
		
		if [[ "$1" == "--help" ]];then #FUNCsayStack_help show this help
			#grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			#FUNCexecSS --help
			SECFUNCshowHelp ${FUNCNAME}
			return 0
		elif [[ "$1" == "--sayvol" ]];then #FUNCsayStack_help set volume to be used at festival
			shift
		  SEC_SAYVOL="$1"
		elif [[ "$1" == "--nomp3" ]];then #FUNCsayStack_help do not use mp3 format, but cache files will be about 10x bigger...
			SEC_SAYMP3=false
		elif [[ "$1" == "--clearcache" ]];then #FUNCsayStack_help all audio files on cache will be removed
			bClearCache=true
		elif [[ "$1" == "--daemon" ]];then #FUNCsayStack_help keeps running and takes care of all speak requests with log
			bDaemon=true
		elif [[ "$1" == "--waitsay" ]];then #FUNCsayStack_help only exit after the saying of the specified text has finished
			bWaitSay=true
		elif [[ "$1" == "--suspend" ]];then #FUNCsayStack_help suspend speaking, and return only after the speaking is surely suspended (see --resume)
			FUNCsuspend
			# must not allow to speak anything after suspend or this function wont exit...
			return 0 #exit_FUNCsayStack: wont put empty lines
		elif [[ "$1" == "--resume" ]];then #FUNCsayStack_help resume speaking
			FUNCresumeJustDel
			bResume=true
		elif [[ "$1" == "--resume-justdel" ]];then #FUNCsayStack_help just delete the suspend file, allowing other pids to resume speaking
			FUNCresumeJustDel
			return 0 #exit_FUNCsayStack: wont put empty lines
#		elif [[ "$1" == "--clearbuffer" ]];then #FUNCsayStack_help [id filter], clear SayStack buffer for all speeches requested by all applications til now; if filter is set, will only clear matching lines, see --id option
#			if $bNextIsParam;then
#				shift
#				strSayId="$1"
#				grep -v "SECsayId '$strSayId)"
#			else
#				FUNCexecSS rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}"
#			fi
#			return 0 #exit_FUNCsayStack: wont put empty lines
		elif [[ "$1" == "--clearbuffer" ]];then #FUNCsayStack_help clear SayStack buffer for all speeches requested by all applications til now; Though if SEC_SAYID, or --id, is set, will only clear matching lines..
			if [[ -n "$strSayId" ]];then
				FUNCexecSS sed -i "/SECsayId '$strSayId/d" "${_SECSAYfileSayStack}"
			else
				FUNCexecSS rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}"
			fi
			return 0 #exit_FUNCsayStack: wont put empty lines
		elif [[ "$1" == "--id" ]];then #FUNCsayStack_help identifier to store at buffer
			shift
			strSayId="$1"
		elif [[ "$1" == "--i-play" ]];then #(internal use)
			shift
			FUNCplay "$@"
			return 0 #exit_FUNCsayStack: wont put empty lines
		else
			FUNCechoErrSS "$FUNCNAME: $LINENO: invalid option $1"
		  return 1 #exit_FUNCsayStack: 
		fi
		shift
	done
	local sayText="${1-}" #last param
	sedOnlyMd5sum='s"([[:alnum:]]*)[[:blank:]]*.*"\1"'
	local md5sumText=`echo "$sayText" |tr "[A-Z]" "[a-z]" |md5sum |sed -r "$sedOnlyMd5sum"`
	if $bClearCache;then
		FUNCexecSS trash "$_SECSAYcacheFolder"
		return 0 #exit_FUNCsayStack: clear cache must be called alone (why?)
	fi
	FUNCexecSS mkdir -p "$_SECSAYcacheFolder"
	if $bDaemon;then
		sayText="${strDaemonSays}${sayText}"
	fi
	
	####################### what will be said (configured to festival)
	if [[ -z "$sayText" ]]; then
		if $bResume;then
			sayText=" " #dummy speech to force resuming, probably in case saying pid crashed or was killed.
		else
			return 0 #exit_FUNCsayStack: wont put empty lines
		fi
	fi
	
	#echo "$sayText" >>"$_SECSAYfileSayStack"
	sayVol=`echo "scale=2;$SEC_SAYVOL/100" |bc -l`
	paramSortOrder="(Parameter.set 'SECsortOrder '`date +"%s.%N"`)" # I created this param with a var name SECsortOrder that I believe wont conflict with pre-existant ones on festival
	paramMd5sum="(Parameter.set 'SECmd5sum '$md5sumText)" #useful to access cached voiced files instead of always generating them with festival
	paramSayVol="(Parameter.set 'SECsayVol '$sayVol)"
	paramSayId="(Parameter.set 'SECsayId '$strSayId)"
	echo "${paramSortOrder}\
				${paramMd5sum}\
				${paramSayVol}\
				${paramSayId}\
				(Parameter.set 'Audio_Method 'Audio_Command)\
				(Parameter.set 'Audio_Required_Rate 16000)\
				(Parameter.set 'Audio_Required_Format 'snd)\
				(Parameter.set 'Audio_Command \"bash -c '$_SECSAYselfBaseName --i-play $md5sumText $sayVol '\$FILE\")\
				(SayText \"$sayText\")" >>"$_SECSAYfileSayStack"
	sort "$_SECSAYfileSayStack" -o "$_SECSAYfileSayStack" #ensure FIFO
	
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
#			#rm "${_SECSAYfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
#			FUNCechoErrSS "$FUNCNAME: $LINENO: $lockFile should be a symlink!"
#			return 1 #exit_FUNCsayStack: 
#		fi
#		if ! local realLockFile=`FUNCgetRealLockFile`;then
#			continue #try again
#		fi
		local realLockFile=`FUNCgetRealLockFile`
	
		if [[ -z "$realLockFile" ]];then
			# if not exist, aquire lock
			realLockFile="${_SECSAYfileSayStack}.$selfMainFunctionPid.lock"
			
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
#				FUNCexecSS rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}."*".lock"
#				continue #try again
#			fi
		
			FUNCechoDbgSS "pid $otherPid will take care of say stack!"
			if $bWaitSay;then
				while grep -q "$paramSortOrder" "$_SECSAYfileSayStack";do
					if ! sleep $sleepDelay; then return 1; fi #exit_FUNCsayStack: on sleep fail
				done
			fi
			return 0 #exit_FUNCsayStack: as another pid is already saying the stack
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
		
		if [[ -f "$_SECSAYfileSayStack" ]];then
			local strHead=`head -n 1 "$_SECSAYfileSayStack"`
			if [[ -n "$strHead" ]]; then
				if $bDaemon; then
					SECFUNCdrawLine " `SECFUNCdtFmt --pretty` "
					echo "$strHead"
				fi
				
				sedGetMd5sum="s;.* 'SECmd5sum '([[:alnum:]]*)\).*;\1;"
				md5sumText=`echo "$strHead" |sed -r "$sedGetMd5sum"`
				sedGetSayVol="s;.* 'SECsayVol '([[:digit:]]*[.][[:digit:]]*)\).*;\1;"
				sayVol=`echo "$strHead" |sed -r "$sedGetSayVol"`
				#echo "strHead=$strHead" >>/dev/stderr
				if FUNChasCache $md5sumText;then
					FUNCplay "$md5sumText" $sayVol
				else
					echo "$strHead"	|FUNCexecSS festival --pipe
				fi
				
				#FUNCexecSS sed -i 1d "$_SECSAYfileSayStack" #delete 1st line
				FUNCexecSS sed -i "/$md5sumText/d" "$_SECSAYfileSayStack" #delete correct line
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

if [[ -n "${1-}" ]]; then
	FUNCsayStack "$@"
	exit 0
fi

#(*1)
if [[ "`basename "$0"`" != "$_SECSAYselfBaseName" ]];then
	SECFUNCechoErrA "This file _SECSAYselfBaseName='$_SECSAYselfBaseName' cannot be loaded as source at script '`basename "$0"`'! Or this is a bug requiring _SECSAYselfBaseName be updated with correct filename..."
	_SECFUNCcriticalForceExit
fi

