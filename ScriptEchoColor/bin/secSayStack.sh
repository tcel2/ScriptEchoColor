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

#source "`ScriptEchoColor --getinstallpath`/lib/ScriptEchoColor/utils/funcMisc.sh"
#source "`secGetInstallPath`/lib/ScriptEchoColor/utils/funcMisc.sh"
source <(secinit --ilog --misc)

export _SECSAYselfBaseName="secSayStack.sh" #@@@!!! update me if needed!
export _SECSAYfileSayStack="/tmp/SEC.SayStack.tmp"
export _SECSAYcacheFolder="$HOME/.ScriptEchoColor/SEC.SayStack.cache" #cant be at /tmp that is erased (everytime?) on boot..

#: ${SECbSayMp3Mode:=true}
export SECbSayMp3Mode #help use mp3 to store created speech files
SECFUNCdefaultBoolValue SECbSayMp3Mode true
#: ${SEC_SAYMP3:=$SECbSayMp3Mode} # backwards compatibility, keep this!
export SEC_SAYMP3 # backwards compatibility, keep this!
SECFUNCdefaultBoolValue SEC_SAYMP3 true # backwards compatibility, keep this!
#if [[ "$SEC_SAYMP3" != "false" ]]; then #compare to inverse of default value
#	export SEC_SAYMP3=true # of course, np if already "false"
#fi

: ${SEC_SAYVOL:=100} # backwards compatibility, keep this!
export SEC_SAYVOL # backwards compatibility, keep this!
SECFUNCisNumber --assert -dn "$SEC_SAYVOL"
: ${SECnSayVolume:=$SEC_SAYVOL}
export SECnSayVolume #help modify this to change speech volume. Integer 100 means 100%
SECFUNCisNumber --assert -dn "$SECnSayVolume"

: ${SECstrSayId:="SecSayStackDefaultId"}
export SECstrSayId #help default say id
: ${SEC_SAYID:=$SECstrSayId} # backwards compatibility, keep this!
export SEC_SAYID # backwards compatibility, keep this!
if [[ -z "${1-}" ]]; then
	#(*1)
	if [[ "`basename "$0"`" != "$_SECSAYselfBaseName" ]];then
		SECFUNCechoErrA "This file _SECSAYselfBaseName='$_SECSAYselfBaseName' cannot be loaded as source at script '`basename "$0"`'! Or this is a bug requiring _SECSAYselfBaseName be updated with correct filename..."
		_SECFUNCcriticalForceExit
	fi
fi

####################### internal cfg of variables, functions and base initializations
selfMainFunctionPid="$BASHPID" #$$ WONT WORK if this code has been sourced on another script, it requires $BASHPID for the instance pid of a child process with this function
lockFile="${_SECSAYfileSayStack}.lock"
suspendFile="${_SECSAYfileSayStack}.suspend"
strSuspendAtKey="SayStackSuspendedAtPid"
strSuspendByKey="SayStackSuspendedByPid"
sleepDelay=0.1
bDaemon=false
bOutputSayText=false
bShowPlayOutput=false
bWaitSay=false
strSayId="$SECstrSayId"
bResume=false
strDaemonSays="Say stack daemon initialized."
bClearCache=false
strSndEffects=""
bStdoutFilename=false

function FUNCechoDbgSS() { 
	SECFUNCechoDbgA --caller "$_SECSAYselfBaseName" "$1"; 
};export -f FUNCechoDbgSS

#function FUNCechoErrSS() { 
#	SECFUNCechoErrA --caller "$_SECSAYselfBaseName" "$1"; 
#};export -f FUNCechoErrSS

#function FUNCexecSS() {
#	###### options
#	local caller=""
#	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
#		if [[ "$1" == "--help" ]];then #FUNCexecSS_help show this help
#			#grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
#			SECFUNCshowHelp ${FUNCNAME}
#			return 0
#		elif [[ "$1" == "--caller" ]];then #FUNCexecSS_help is the name of the function calling this one
#			shift
#			caller="${1}: "
#		else
#			FUNCechoErrSS "invalid option $1"
#			return 1
#		fi
#		shift
#	done
#	
#	###### main code
#	SECFUNCexecA --caller "$_SECSAYselfBaseName" --quiet "$@"
#};export -f FUNCexecSS

function FUNCisPidActive() { #generic check with info
	if [[ -z "${1-}" ]]; then
		SECFUNCechoErrA "empty pid value"
		return 1
	fi
	
	# this is necessary as pid ids wrap at `cat /proc/sys/kernel/pid_max`
	# the pid 'command' at `ps` must have this script filename
	# this prevents this file from being sourced, see (*1) at the end...
	#@@@r # do not use FUNCexecSS or SECFUNCexec or SECFUNCexecA here! #TODO explain why...
	if ! ps -p $1 --no-headers -o command |grep -q "$_SECSAYselfBaseName"; then
		return 1
	fi
	
	#FUNCexecSS --caller "$FUNCNAME" ps -p $1 -o pid,ppid,stat,state,command;
#	SECFUNCexecA ps -p $1 -o pid,ppid,stat,state,command >>/dev/null 2>&1; #TODO so useless? only to check if pid is active?
#	return $?
	
	if [[ -d "/proc/$1/" ]];then
		return 0;
	fi
	
	return 1;
};export -f FUNCisPidActive

function FUNCcheckIfLockPidIsRunning() {
	local realLockFile="$1"
	
	# if exist, check if its pid is running
	local otherPid=`echo "$realLockFile" |sed -r "s'.*[.]([[:digit:]]*)[.]lock$'\1'"`
	FUNCechoDbgSS "already running pid is $otherPid"
	if ! FUNCisPidActive $otherPid; then
		# if pid is not running, probably crashed so clean up locks
		SECFUNCexecA rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}."*".lock"
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
				SECFUNCechoErrA "$realLockFile doesnt exist, its pid crashed?"
				SECFUNCexecA rm $_SECdbgVerboseOpt "$lockFile"
				continue
			fi
		elif [[ -a "$lockFile" ]];then
			#rm "${_SECSAYfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
			SECFUNCechoErrA "$lockFile should be a symlink! the mess will be cleaned..."
			SECFUNCexecA rm $_SECdbgVerboseOpt "$lockFile"
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
	SECFUNCexecA rm $_SECdbgVerboseOpt "$suspendFile"
};export -f FUNCresumeJustDel

function FUNCcreateCache(){ #TODO create the cached files much easier with like: echo asdf |text2wave -o sampleoutput.wav
	local lmd5sumText="${1}"
	local fileAudio="${2}"
	
	SECFUNCexecA cp "$fileAudio" "$_SECSAYcacheFolder/${lmd5sumText}"
	SECFUNCechoDbgA "SEC_SAYMP3=$SEC_SAYMP3"
	if $SEC_SAYMP3;then
		local lbConversionWorked=false
		local lnBitRate=32
		_SECFUNCcheckCmdDep ffmpeg
    
		if ! $lbConversionWorked;then
			if ! SECFUNCexecA ffmpeg -i "$_SECSAYcacheFolder/${lmd5sumText}" -b ${lnBitRate}k "$_SECSAYcacheFolder/${lmd5sumText}.mp3";then
				SECFUNCechoErrA "ffmpeg failed." #is ffmpeg broken?
				rm "$_SECSAYcacheFolder/${lmd5sumText}.mp3"
			else
				lbConversionWorked=true
			fi
		fi
		
		if ! $lbConversionWorked;then
			if ! SECFUNCexecA ffmpeg -i "$_SECSAYcacheFolder/${lmd5sumText}" -b ${lnBitRate}k "$_SECSAYcacheFolder/${lmd5sumText}.mp3";then
				SECFUNCechoErrA "ffmpeg failed."
				rm "$_SECSAYcacheFolder/${lmd5sumText}.mp3"
			else
				lbConversionWorked=true
			fi
		fi
		
		if $lbConversionWorked;then
			rm "$_SECSAYcacheFolder/${lmd5sumText}"
			ln -s "$_SECSAYcacheFolder/${lmd5sumText}.mp3" "$_SECSAYcacheFolder/${lmd5sumText}"
		fi
	fi
}
function FUNChasCache() {
	local lmd5sumText="${1}"
	#local fileAudio="${2-}" #optional
	
	if [[ -z "$lmd5sumText" ]];then
		SECFUNCechoErrA "invalid lmd5sumText=''"
		return 1
	fi
	
	local lstrCacheFile="$_SECSAYcacheFolder/$lmd5sumText"
	local lstrCacheFileReal="`readlink -f "$lstrCacheFile"`"
	if [[ -f "$lstrCacheFileReal" ]] && ((`stat -c "%s" "$lstrCacheFileReal"`>0));then
		SECFUNCechoDbgA "cache exists: $lstrCacheFile"
		return 0
	fi
	
	SECFUNCechoDbgA "cache missing: $lstrCacheFile"
	# mainly to remove invalid (size=0) files
	SECFUNCexecA -ce rm -vf "$lstrCacheFile"&&:
	SECFUNCexecA -ce rm -vf "$lstrCacheFileReal"&&:
	
	return 1
};export -f FUNChasCache

function FUNCcacheFileToPlay(){
	local lmd5sumText="$1";shift
	local lstrCacheFile="$_SECSAYcacheFolder/$lmd5sumText"
	echo "$lstrCacheFile"
};export -f FUNCcacheFileToPlay

#function FUNCfileToPlay(){
#	local lmd5sumText="$1";shift
#	local fileAudio="`FUNCcacheFileToPlay`"
#	echo "$fileAudio"
#};export -f FUNCplayFileInfo

function FUNCplay() { 
#	local lbCacheOnly=false
#	if [[ "$1" == "--cacheonly" ]];then
#		lbCacheOnly=true
#		shift
#	fi
	
	local lmd5sumText="$1";shift
	local lsayVol="$1";shift
	local lstrSndEffects="$1";shift

	if ! FUNChasCache "$lmd5sumText";then
		SECFUNCechoErrA "no cache for lmd5sumText='$lmd5sumText'"
		return 1
	fi
	
	local lstrCacheFile="`FUNCcacheFileToPlay "$lmd5sumText"`" #"$_SECSAYcacheFolder/$lmd5sumText"
	
	SECFUNCexecA touch "$lstrCacheFile" #to indicate that it was recently used
	local fileAudio="$lstrCacheFile"
	SECFUNCechoDbgA "lmd5sumText=$lmd5sumText lsayVol=$lsayVol fileAudio=$fileAudio"
	if $SEC_SAYMP3;then
		local fileAudioMp3="${fileAudio}.mp3"
		if [[ -f "$fileAudioMp3" ]];then
			fileAudio="$fileAudioMp3"
		fi
	fi
	
#	if $bStdoutFilename;then
##		FUNCcacheFileToPlay "$lmd5sumText"
##		ls --color /proc/$$/fd -l >&2 
##		echo "$fileAudio" >&2 
##		echo "$fileAudio" >>/dev/stdout
#		echo "$fileAudio"
#	fi

#	local lstrPlayOutput="2>>/dev/null"
#	local lstrPlayOutput="--quiet"
#	if $bShowPlayOutput;then
#		lstrPlayOutput=""
#	fi
  _SECFUNCcheckCmdDep play
	local astrCmd=(play -v "$lsayVol" "$fileAudio" $lstrSndEffects)
	# lstrSndEffects no quotes to become params (work?)
	if $bShowPlayOutput;then
		SECFUNCexecA "${astrCmd[@]}"
	else
		SECFUNCexecA "${astrCmd[@]}" >>/dev/null 2>&1 #TODO why `SECFUNCexec --quiet` did not work?
	fi
};export -f FUNCplay;

####################### other initializations

selfFullCmd="`SECFUNCparamsToEval "$0" "$@"`"
FUNCechoDbgSS "<- start at"
FUNCechoDbgSS "pids: script $$, instance $selfMainFunctionPid, parent $PPID"

####################### options
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	bNextIsParam=false #otherwise is option
	if [[ -n "${2-}" ]] && [[ "${2:0:1}" != "-" ]];then
		bNextIsParam=true
	fi
	
	if [[ "$1" == "--help" ]];then #help show this help
		#grep "#${FUNCNAME}_help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
		#SECFUNCexecA --help
		echo "_SECSAYfileSayStack='$_SECSAYfileSayStack'"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--sayvol" ]];then #help set volume to be used at festival
		shift
	  SECnSayVolume="$1"
	elif [[ "$1" == "--effects" ]];then #help <strSndEffects>
		shift
	  strSndEffects="$1"
	elif [[ "$1" == "--nomp3" ]];then #help do not use mp3 format, but cache files will be about 10x bigger...
		SEC_SAYMP3=false
#	elif [[ "$1" == "--stdout" ]];then #help output the full sound filename to stdout, this implies --waitsay because a say buffer may be on going...
	elif [[ "$1" == "--stdout" ]];then #help output the full sound filename to stdout
		bStdoutFilename=true
	#	bWaitSay=true
	elif [[ "$1" == "--clearcache" ]];then #help all audio files on cache will be removed
		bClearCache=true
	elif [[ "$1" == "--daemon" ]];then #help keeps running and takes care of all speak requests with log
		bDaemon=true
	elif [[ "$1" == "--showtext" ]];then #help promptly outputs the text to be said, good for logs
		bOutputSayText=true;
	elif [[ "$1" == "--showplayinfo" ]];then #help show play command output
		bShowPlayOutput=true
	elif [[ "$1" == "--waitsay" ]];then #help only exit after the saying of the specified text has finished
		bWaitSay=true
	elif [[ "$1" == "--suspend" ]];then #help suspend speaking, and exit only after the speaking is surely suspended (see --resume)
		FUNCsuspend
		# must not allow to speak anything after suspend or this function wont exit...
		exit 0 #exit_FUNCsayStack: wont put empty lines
	elif [[ "$1" == "--resume" ]];then #help resume speaking
		FUNCresumeJustDel
		bResume=true
	elif [[ "$1" == "--resume-justdel" ]];then #help just delete the suspend file, allowing other pids to resume speaking
		FUNCresumeJustDel
		exit 0 #exit_FUNCsayStack: wont put empty lines
#		elif [[ "$1" == "--clearbuffer" ]];then #help [id filter], clear SayStack buffer for all speeches requested by all applications til now; if filter is set, will only clear matching lines, see --id option
#			if $bNextIsParam;then
#				shift
#				strSayId="$1"
#				grep -v "SECsayId '$strSayId)"
#			else
#				SECFUNCexecA rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}"
#			fi
#			exit 0 #exit_FUNCsayStack: wont put empty lines
	elif [[ "$1" == "--clearbuffer" ]];then #help clear SayStack buffer for all speeches requested by all applications til now; Though if SECstrSayId, or --id, is set, will only clear matching lines..
		if [[ -f "${_SECSAYfileSayStack}" ]];then
			if [[ -n "$strSayId" ]];then
				SECFUNCexecA sed -i "/SECsayId '$strSayId/d" "${_SECSAYfileSayStack}"
			else
				SECFUNCexecA rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}"
			fi
		fi
		exit 0 #exit_FUNCsayStack: wont put empty lines
	elif [[ "$1" == "--id" ]];then #help identifier to store at buffer
		shift
		strSayId="$1"
	elif [[ "$1" == "--cacheonly" ]];then #(internal use)
		shift
		FUNCcreateCache "$1" "$2"
		exit 0 #exit_FUNCsayStack: wont put empty lines
	else
		SECFUNCechoErrA "invalid option $1"
	  exit 1 #exit_FUNCsayStack: 
	fi
	shift
done
sayText="${1-}" #last param
sedOnlyMd5sum='s"([[:alnum:]]*)[[:blank:]]*.*"\1"'
md5sumText=`echo "$sayText" |tr "[A-Z]" "[a-z]" |md5sum |sed -r "$sedOnlyMd5sum"`
if $bClearCache;then
	SECFUNCexecA trash -v "$_SECSAYcacheFolder"
	exit 0 #exit_FUNCsayStack: clear cache must be called alone (why?)
fi
SECFUNCexecA mkdir -p "$_SECSAYcacheFolder"
if $bDaemon;then
	sayText="${strDaemonSays}${sayText}"
	echo "_SECSAYfileSayStack='$_SECSAYfileSayStack'"
fi

####################### what will be said (configured to festival)
if [[ -z "$sayText" ]]; then
	if $bResume;then
		sayText=" " #dummy speech to force resuming, probably in case saying pid crashed or was killed.
	else
		exit 0 #exit_FUNCsayStack: wont put empty lines
	fi
else
	if $bOutputSayText;then
		echo "SECSay: $sayText" >&2
	fi
fi

if ! $bDaemon;then
	if $bStdoutFilename;then 
#		md5sumTextGet="`FUNCgetParamValue "$strHead" SECmd5sum`"
#		FUNCcacheFileToPlay "$md5sumTextGet";
		FUNCcacheFileToPlay "$md5sumText"
	fi
fi


#echo "$sayText" >>"$_SECSAYfileSayStack"
sayVol="`echo "scale=2;$SECnSayVolume/100" |bc -l`"
#echo "sayVol='$sayVol'"
paramSortOrder="(Parameter.set 'SECsortOrder '`date +"%s.%N"`)" # I created this param with a var name SECsortOrder that I believe wont conflict with pre-existant ones on festival
paramMd5sum="(Parameter.set 'SECmd5sum '$md5sumText)" #useful to access cached voiced files instead of always generating them with festival
paramSayVol="(Parameter.set 'SECsayVol '$sayVol)"
paramSayId="(Parameter.set 'SECsayId '$strSayId)"
paramSndEffects="(Parameter.set 'SECstrSndEffects '$strSndEffects)"
sayTextFixed="`echo "$sayText" |sed 's/[^a-zA-Z0-9=_-]/ /g'`" # remove any invalid characters to prevent breaking speech application
echo "${paramSortOrder}\
			${paramMd5sum}\
			${paramSayVol}\
			${paramSayId}\
			${paramSndEffects}\
			(Parameter.set 'Audio_Method 'Audio_Command)\
			(Parameter.set 'Audio_Required_Rate 16000)\
			(Parameter.set 'Audio_Required_Format 'snd)\
			(Parameter.set 'Audio_Command \"bash -c '$_SECSAYselfBaseName --cacheonly $md5sumText '\$FILE\")\
			(SayText \"${sayTextFixed}\")" >>"$_SECSAYfileSayStack"
#			(Parameter.set 'Audio_Command \"bash -c '$_SECSAYselfBaseName --cacheonly $md5sumText $sayVol '\$FILE\")\
sort "$_SECSAYfileSayStack" -o "$_SECSAYfileSayStack" #ensure FIFO

####################### lock file work
while true; do
	if ! sleep $sleepDelay; then exit 1; fi #sleep to help not mess the CPU in case of a infinite loop bug.. #exit_FUNCsayStack: also exits on sleep fail
	
#		# lock file exist?
#		local realLockFile=""
#		if [[ -L "$lockFile" ]];then
#			realLockFile=`readlink "$lockFile"`
#			if [[ ! -f "$realLockFile" ]];then
#				#cleanup because probably crashed and the file wasnt normally removed?
#				#realLockFile=""
#				SECFUNCexecA rm $_SECdbgVerboseOpt "$lockFile"
#				continue #try again
#			fi
#		elif [[ -a "$lockFile" ]];then
#			#rm "${_SECSAYfileSayStack}"* # clean inconsistency ? but doing this wont help fix bug
#			SECFUNCechoErrA "$lockFile should be a symlink!"
#			exit 1 #exit_FUNCsayStack: 
#		fi
#		if ! local realLockFile=`FUNCgetRealLockFile`;then
#			continue #try again
#		fi
	realLockFile=`FUNCgetRealLockFile`

	if [[ -z "$realLockFile" ]];then
		# if not exist, aquire lock
		realLockFile="${_SECSAYfileSayStack}.$selfMainFunctionPid.lock"
		
		#create the real file
		echo "$selfFullCmd" >>"$realLockFile"
		ps -p $selfMainFunctionPid --no-headers -o command >>"$realLockFile"
		
		while ! SECFUNCexecA ln $_SECdbgVerboseOpt -s "$realLockFile" "$lockFile"; do #create the symlink
			if ! sleep $sleepDelay; then exit 1; fi #exit_FUNCsayStack: on sleep fail
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
#				SECFUNCexecA rm $_SECdbgVerboseOpt "${_SECSAYfileSayStack}."*".lock"
#				continue #try again
#			fi
		
		otherPid=`echo "$realLockFile" |sed -r "s'.*[.]([[:digit:]]*)[.]lock$'\1'"`
		FUNCechoDbgSS "pid $otherPid will take care of say stack!"
		if $bWaitSay;then
			while grep -q "$paramSortOrder" "$_SECSAYfileSayStack";do
				if ! sleep $sleepDelay; then exit 1; fi #exit_FUNCsayStack: on sleep fail
			done
		fi
		exit 0 #exit_FUNCsayStack: as another pid is already saying the stack
	fi
	
	SECFUNCechoErrA "this line of the code should not have been reached!"
	exit 1 #exit_FUNCsayStack: 
done	

####################### say the stack buffer FIFO
function FUNCgetParamValue() {
	local lstrFullFestivalCommand="$1"
	local lstrParamId="$2"
	echo "$lstrFullFestivalCommand" |tr ")" "\n" |grep "$lstrParamId" |sed -r "s,.*'$lstrParamId '(.*)$,\1,"
};export -f FUNCgetParamValue
while true; do
	while [[ -f "$suspendFile" ]];do
		if ! grep --quiet "$strSuspendAtKey" "$suspendFile";then
			if [[ -f "$suspendFile" ]];then #safety double check
				echo "$strSuspendAtKey=$$" >>"$suspendFile"
			fi
		fi
		if ! sleep $sleepDelay; then exit 1; fi #exit_FUNCsayStack: on sleep fail
	done
	
#	if ! $bDaemon;then
#		if $bStdoutFilename;then 
#	#		md5sumTextGet="`FUNCgetParamValue "$strHead" SECmd5sum`"
#	#		FUNCcacheFileToPlay "$md5sumTextGet";
#			FUNCcacheFileToPlay "$md5sumText"
#		fi
#	fi
	
	if [[ -f "$_SECSAYfileSayStack" ]];then
		strHead=`head -n 1 "$_SECSAYfileSayStack"`
		if [[ -n "$strHead" ]]; then
			if $bDaemon; then
				SECFUNCdrawLine " `SECFUNCdtFmt --pretty` "
				echo "$strHead"
			fi
			
			#sedGetMd5sum="s;.* 'SECmd5sum '([[:alnum:]]*)\).*;\1;"
			#md5sumText=`echo "$strHead" |sed -r "$sedGetMd5sum"`
			md5sumTextGet="`FUNCgetParamValue "$strHead" SECmd5sum`"
			#sedGetSayVol="s;.* 'SECsayVol '([[:digit:]]*[.][[:digit:]]*)\).*;\1;"
			#sayVol=`echo "$strHead" |sed -r "$sedGetSayVol"`
			nSayVolGet="`FUNCgetParamValue "$strHead" SECsayVol`"
			strSndEffectsGet="`FUNCgetParamValue "$strHead" SECstrSndEffects`"
			
#			echo "md5sumTextGet='$md5sumTextGet'" >&2
#			echo "nSayVolGet='$nSayVolGet'" >&2
#			echo "strSndEffectsGet='$strSndEffectsGet'" >&2
			
			#echo "strHead=$strHead" >&2
      #declare -p strHead >&2
			bCanPlay=true
			if [[ -z "$md5sumTextGet" ]];then
				bCanPlay=false
			elif ! FUNChasCache "$md5sumTextGet";then
        _SECFUNCcheckCmdDep festival
				if ! echo "$strHead"	|SECFUNCexecA festival --pipe;then # this line will CREATE the CACHE!
					SECFUNCechoErrA "festival failed to speak strHead='$strHead', bug? skipping..."
					# this error will not exit, it is a error but the daemon can continue running...
					bCanPlay=false
				fi
			fi
			
			if $bCanPlay;then
				if ! FUNCplay "$md5sumTextGet" "$nSayVolGet" "$strSndEffectsGet";then
					SECFUNCechoErrA "festival failed to speak strHead='$strHead', bug? skipping..."
				fi
				SECFUNCexecA sed -i "/$md5sumTextGet/d" "$_SECSAYfileSayStack" #delete precise line
			else
				SECFUNCexecA -ce sed -i 1d "$_SECSAYfileSayStack" #delete 1st line with invalid strHead data
			fi
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
	
	if ! sleep $sleepDelay; then exit 1; fi #exit_FUNCsayStack: on sleep fail
done

####################### release the lock
SECFUNCexecA rm $_SECdbgVerboseOpt "$realLockFile"
SECFUNCexecA rm $_SECdbgVerboseOpt "$lockFile"
FUNCechoDbgSS "<- exit at"

