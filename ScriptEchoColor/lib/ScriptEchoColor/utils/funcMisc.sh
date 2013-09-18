#!/bin/bash
# Copyright (C) 2004-2012 by Henrique Abdalla
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

shopt -s expand_aliases

#export _SECselfFile_funcMisc="`ScriptEchoColor --getinstallpath`/lib/ScriptEchoColor/utils/funcMisc.sh"
export _SECselfFile_funcMisc="`secGetInstallPath.sh`/lib/ScriptEchoColor/utils/funcMisc.sh"
export _SECaliasPrefix='`basename $0`,p$$,bp$BASHPID,bss$BASH_SUBSHELL,$FUNCNAME(),L$LINENO'
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA "func In"'
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA "func Out"'
alias SECexitA='SECFUNCdbgFuncOutA;exit '
alias SECreturnA='SECFUNCdbgFuncOutA;return '

# IMPORTANT!!!!!!! do not use echoc or ScriptEchoColor on functions here, may become recursive infinite loop...

_SECdbgVerboseOpt=""
if [[ "$SEC_DEBUG" == "true" ]];then
	_SECdbgVerboseOpt="-v"
fi

function SECFUNCexportFunctions() {
	declare -F \
		|grep "SECFUNC" \
		|sed 's"declare .* SECFUNC"export -f SECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f SECFUNC"
}

function SECFUNCdtNow() { 
	date +"%s.%N"; 
}
function SECFUNCtimePretty() {
	date -d "@`bc <<< "(3600*3)+${1}"`" +"%H:%M:%S.%N"
}
function SECFUNCtimePrettyNow() {
	SECFUNCtimePretty `SECFUNCdtNow`
}
function SECFUNCdtTimePretty() {
	date -d "@`bc <<< "(3600*3)+${1}"`" +"%d/%m/%Y %H:%M:%S.%N"
}
function SECFUNCdtTimePrettyNow() {
	SECFUNCdtTimePretty `SECFUNCdtNow`
}
function SECFUNCdtTimeToFileName() {
	date -d "@`bc <<< "(3600*3)+${1}"`" +"%Y_%m_%d-%H_%M_%S_%N"
}
function SECFUNCdtTimeToFileNameNow() {
	SECFUNCdtTimeToFileName `SECFUNCdtNow`
}

alias SECFUNCechoErrA="SECFUNCechoErr --caller \"$_SECaliasPrefix\" "
function SECFUNCechoErr() { 
	###### options
	local caller=""
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoErr_help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoErr_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			echo "SECERROR[`SECFUNCdtNow`]invalid option $1" >/dev/stderr; 
			return 1
		fi
		shift
	done
	
	###### main code
	echo "SECERROR[`SECFUNCdtNow`]: ${caller}$@" >/dev/stderr; 
}
#if [[ "$SEC_DEBUG" == "true" ]];then
#	SECFUNCechoErrA "test error message"
#	SECFUNCechoErr --caller "caller=funcMisc.sh" "test error message"
#fi

alias SECFUNCechoDbgA="SECFUNCechoDbg --caller \"$_SECaliasPrefix\" "
function SECFUNCechoDbg() { 
	if [[ "$SEC_DEBUG" != "true" ]];then # to not loose time
		return 0
	fi
	
	###### options
	local caller=""
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoDbg_help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoDbg_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	###### main code
	if [[ "$SEC_DEBUG" == "true" ]];then
		echo "SECDEBUG[`SECFUNCdtNow`]: ${caller}$@" >/dev/stderr
	fi
}

alias SECFUNCechoWarnA="SECFUNCechoWarn --caller \"$_SECaliasPrefix\" "
function SECFUNCechoWarn() { 
	###### options
	local caller=""
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoWarn_help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoWarn_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	###### main code
	echo "SECWARN[`SECFUNCdtNow`]: ${caller}$@" >/dev/stderr
}

function SECFUNCparamsToEval() {
	###### options
	bEscapeQuotes=false
	bEscapeQuotesTwice=false
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCparamsToEval_help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--escapequotes" ]];then #SECFUNCparamsToEval_help quotes will be escaped like '\"'
			bEscapeQuotes=true
#		elif [[ "$1" == "--escapequotestwice" ]];then #SECFUNCparamsToEval_help quotes will be escaped TWICE like '\\\"'
#			bEscapeQuotesTwice=true
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	strEscapeQuotes=""
	if $bEscapeQuotes;then
		strEscapeQuotes='\'
	fi
#	if $bEscapeQuotesTwice;then
#		strEscapeQuotes='\\\'
#	fi
	
	local strExec=""
	while [[ -n "$1" ]];do
  	if [[ -n "$strExec" ]];then
	  	strExec="${strExec} ";
  	fi
  	strExec="${strExec}${strEscapeQuotes}\"$1${strEscapeQuotes}\"";
  	shift;
  done;
  echo "$strExec"
}

alias SECFUNCexecA="SECFUNCexec --caller \"$_SECaliasPrefix\" "
function SECFUNCexec() {
	omitOutput="2>/dev/null 1>/dev/null" #">/dev/null 2>&1" is the same..
	bOmitOutput=false
	bShowElapsed=false
	bWaitKey=false
	bExecEcho=false
	
	###### options
	local caller=""
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCexec_help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCexec_help is the name of the function calling this one
			shift
			caller="${1}: "
		elif [[ "$1" == "--quiet" ]];then #SECFUNCexec_help ommit command output to stdout and stderr
			bOmitOutput=true
		elif [[ "$1" == "--quietoutput" ]];then #SECFUNCexec_help --quiet idem
			bOmitOutput=true
		elif [[ "$1" == "--waitkey" ]];then #SECFUNCexec_help wait a key before executing the command
			bWaitKey=true
		elif [[ "$1" == "--elapsed" ]];then #SECFUNCexec_help quiet, ommit command output to stdout and
			bShowElapsed=true;
		elif [[ "$1" == "--echo" ]];then #SECFUNCexec_help echo the command that will be executed
			bExecEcho=true;
		else
			SECFUNCechoErrA "caller=${caller}: invalid option $1"
			return 1
		fi
		shift
	done
	
	if ! $bOmitOutput || [[ "$SEC_DEBUG" == "true" ]];then
		omitOutput=""
	fi
	
	###### main code
  local strExec=`SECFUNCparamsToEval "$@"`
	SECFUNCechoDbgA "caller=${caller}: $strExec"
	
	if $bExecEcho; then
		echo "SECFUNCexec[`SECFUNCdtNow`]: caller=${caller}: $strExec" >/dev/stderr
	fi
	
	if $bWaitKey;then
		echo -n "SECFUNCexec[`SECFUNCdtNow`]: caller=${caller}: press a key to exec..." >/dev/stderr;read -n 1;
	fi
	
	local ini=`SECFUNCdtNow`;
  eval "$strExec" $omitOutput;nRet=$?
	local end=`SECFUNCdtNow`;
	
  SECFUNCechoDbgA "caller=${caller}: RETURN=${nRet}: $strExec"
  
	if $bShowElapsed;then
		echo "SECFUNCexec[`SECFUNCdtNow`]: caller=${caller}: ELAPSED=`SECFUNCbcPrettyCalc "$end-$ini"`s"
	fi
  return $nRet
}

function SECFUNCexecShowElapsed() {
	SECFUNCexec --elapsed "$@"
}

function SECFUNChelpExit() {
    #echo "usage: options runCommand"
    
    # this sed only cleans lines that have extended options with "--" prefixed
    sedCleanHelpLine='s".*\"\(.*\)\".*#opt"\t\1\t"' #helpskip
    grep "#opt" $0 |grep -v "#helpskip" |sed "$sedCleanHelpLine" #helpskip is to skip this very line too!
    
    exit 0 #whatchout this will exit the script not only this function!!!
}

function SECFUNCppidList() {
  local separator=$1
  
  local pidList=()
  local ppid=$$;
  while((ppid>=1));do 
    ppid=`ps -o ppid -p $ppid --no-heading |tail -n 1`; 
    pidList=(${pidList[*]} $ppid)
    #echo $ppid; 
    if((ppid==1));then break; fi; 
  done
  
  local output="${pidList[*]}"
  if [[ -n "$separator" ]];then
    local sedChangeSeparator='s" "'"$separator"'"g'
    output=`echo "$output" |sed "$sedChangeSeparator"`
  fi
  
  echo "$output"
}
function SECFUNCppidListToGrep() {
  # output ex.: "^[ |]*30973\|^[ |]*3861\|^[ |]*1 "

  #echo `SECFUNCppidList "|"` |sed 's"|"\\|"g'
  local ppidList=`SECFUNCppidList ","`
  local separator='\\|'
  local grepMatch="^[ |]*" # to match none or more blank spaces at begin of line
  ppidList=`echo "$ppidList" |sed "s','$separator$grepMatch'g"`
  echo "$grepMatch$ppidList "
}

function SECFUNCbcPrettyCalc() {
	local bCmpMode=false
	local bCmpQuiet=false
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCbcPrettyCalc_help --help show this help
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--cmp" ]];then #SECFUNCbcPrettyCalc_help output comparison result as "true" or "false"
			bCmpMode=true
		elif [[ "$1" == "--cmpquiet" ]];then #SECFUNCbcPrettyCalc_help return comparison as execution value for $? where 0=true 1=false
			bCmpMode=true
			bCmpQuiet=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	
	#if delay is less than 1s prints leading "0" like "0.123" instead of ".123"
	local output=`bc <<< "x=($1); if(x==0) print \"0.0\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x";`
	
	if $bCmpMode;then
		if [[ "$output" == "1" ]];then
			if $bCmpQuiet;then
				return 0
			else
				echo -n "true"
			fi
		elif [[ "$output" == "0.0" ]];then
			if $bCmpQuiet;then
				return 1
			else
				echo -n "false"
			fi
		else
		  SECFUNCechoErrA "invalid result for comparison output: '$output'"
		  return 2
		fi
	else
		echo -n "$output"
	fi
	
}

function SECFUNCdrawLine() {
	if [[ "$1" == "--help" ]];then
		echo "params: 'phrase at middle of line' 'line character to be repeated'"
		return
	fi
	
	local phrase="$1";
	local char=${2:0:1}
	
	if [[ -z "$char" ]];then
		char="="
	fi
	
	local width=`tput cols`
	#echo $width
	local nFillChars=$(((width-${#phrase})/2))
	#echo $nFillChars
	local fill=`eval printf "%.0s${char}" {1..${nFillChars}}`
	#echo $fill
	local output="$fill$phrase$fill"
	local diffWidth=$((width-${#output}))
	if((diffWidth==1));then
		output="$output$char"
	elif((diffWidth>1||diffWidth<0));then
		SECFUNCechoErrA "diffWidth=$diffWidth (should be 1 or 0)"
		return 1
	fi
	echo "$output"
#	local width=`tput cols`;
#	local half=$((width/2))
#	local sizeDtHalf=$((${#dt}/2))
#	#echo #this prevents weirdness when the previous command didnt output newline at the end...
#	local output=`printf "%*s%*s" $((half+sizeDtHalf)) "$phrase" $((half-sizeDtHalf)) "" |sed -r "s|^(.*)${phrase}(.*)$|$char|g";`
#	echo -e "${output}"
}

function SECFUNCdelay() {
	declare -g -A _dtSECFUNCdelayArray
	
	local index="$FUNCNAME"
	if [[ -n "$1" ]] && [[ "${1:0:2}" != "--" ]];then
		if [[ -n `echo "$1" |tr -d '[:alnum:]_'` ]];then
			SECFUNCechoErrA "invalid index id '$1', only allowed alphanumeric id and underscores."
			return 1
		fi
		index="$1"
		shift
	fi
	
	function _SECFUNCdelayValidate() {
		SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$index]}=${_dtSECFUNCdelayArray[$index]}"
		if [[ -z "${_dtSECFUNCdelayArray[$index]}" ]];then
			# programmer must have coded it somewhere to make that code clear
			echo "--init [index=$index] needed before calling $1" >&2
			return 1
		fi
	}
	
	while [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdelay_help --help show this help
			echo -e "Help:
	The first parameter can optionally be a string identifying a custom delay like:
		SECFUNCdelay main --init;
		SECFUNCdelay test --init;"
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--init" ]];then #SECFUNCdelay_help set temp date storage to now
			#@@@r SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$index]}=${_dtSECFUNCdelayArray[$index]}"
			_dtSECFUNCdelayArray[$index]=`SECFUNCdtNow`
			#@@@r SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$index]}=${_dtSECFUNCdelayArray[$index]}"
			return
		elif [[ "$1" == "--get" ]];then #SECFUNCdelay_help get delay from init (is the default if no option parameters are set)
			if ! _SECFUNCdelayValidate "$1";then return 1;fi
			local now=`SECFUNCdtNow`
			SECFUNCbcPrettyCalc "${now} - ${_dtSECFUNCdelayArray[$index]}"
			return
		elif [[ "$1" == "--getsec" ]];then #SECFUNCdelay_help get (only seconds without nanoseconds) from init
			if ! _SECFUNCdelayValidate "$1";then return 1;fi
			SECFUNCdelay $index --get |sed -r 's"^([[:digit:]]*)[.][[:digit:]]*$"\1"'
			return
		elif [[ "$1" == "--getpretty" ]];then #SECFUNCdelay_help get full delay pretty time
			if ! _SECFUNCdelayValidate "$1";then return 1;fi
			local delay=`SECFUNCdelay $index --get`
			SECFUNCtimePretty "$delay"
			#date -d "@`bc <<< "(3600*3)+${delay}"`" +"%H:%M:%S.%N"
			return
		elif [[ "$1" == "--now" ]];then #SECFUNCdelay_help get time now since epoch in seconds
			SECFUNCdtNow
			return
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	SECFUNCdelay $index --get #default
}

function SECFUNCfileLock() {
	local l_bUnlock=false
	while [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfileLock_help show this help
			echo "Creates a lock file for the specified file."
			echo "Params: <realFile> cannot be a symlink or a directory"
			
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--unlock" ]];then #SECFUNCfileLock_help releases the lock for the specified file.
			l_bUnlock=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local l_file="$1" #can be with full path
	if [[ ! -f "$l_file" ]];then
		SECFUNCechoErrA "file '$l_file' does not exist (if symlink must point to a file)"
		return 1
	fi
	
	if [[ "${l_file:0:1}" != "/" ]];then
		l_file="`pwd`/$l_file"
	fi
	
	local l_sedMd5sumOnly='s"([[:alnum:]]*) .*"\1"'
	local l_md5sum=`echo "$l_file" |md5sum |sed -r "$l_sedMd5sumOnly"`
	local l_fileLock="/tmp/.SEC.FileLock.$l_md5sum.lock"
	local l_fileLockPid="/tmp/.SEC.FileLock.$l_md5sum.lock.pid"
	local l_lockingPid=-1 #no pid can be -1 right?
	
	function SECFUNCfileLock_removeLock() {
		if [[ -f "$l_fileLock" ]];then
			rm "$l_fileLock"
		fi
		if [[ -f "$l_fileLockPid" ]];then
			rm "$l_fileLockPid"
		fi
	}
	
	function SECFUNCfileLock_validateLock() {
		#TODO use find to validate all lock files for all pid as maintenance each 10minutes (in some way...).
		# validate lock files
		if [[ -f "$l_fileLockPid" ]];then
			# if locking pid is missing (for any reason), remove lock
			if [[ ! -f "$l_fileLockPid" ]];then
				SECFUNCechoWarnA "Locking pid file '$l_fileLockPid' is missing, for file '$l_file', removing lock..."
				SECFUNCfileLock_removeLock
			else
				l_lockingPid=`cat "$l_fileLockPid"`
		
				# if pid died, remove locking files
				if ! ps -p $l_lockingPid >/dev/null 2>&1;then
					SECFUNCechoDbgA "Pid '$l_lockingPid' died, removing lock '$l_fileLock', for file '$l_file'..."
					SECFUNCfileLock_removeLock
				fi
			fi
		fi
	}
	SECFUNCfileLock_validateLock
	
	if $l_bUnlock;then
		if [[ -L "$l_fileLock" ]];then
			if(($l_lockingPid==$$));then
				SECFUNCfileLock_removeLock
				return 0
			else
				SECFUNCechoWarnA "Cant unlock. File '$l_file' was locked by pid $l_lockingPid..."
				return 1
			fi
		else
			if [[ -f "$l_fileLock" ]];then
				SECFUNCechoErrA "lock file '$l_fileLock' should be a symlink..."
				return 1
			else
				SECFUNCechoWarnA "lock file '$l_fileLock' is missing, already unlocked..."
				return 0
			fi
		fi
	else
		if(($l_lockingPid==$$));then
			SECFUNCechoWarnA "file '$l_file' is already locked with '$l_fileLock' by this pid $$..."
			return 0
		fi
		
		#wait for lock to be released and lock it up!
		local l_count=0
		while ! ln -s "$l_file" "$l_fileLock" >/dev/null 2>&1;do
			sleep 0.1
			((l_count++))
			if(( (l_count%30)==0 ));then
				SECFUNCechoWarnA "for file '$l_file', cant get lock '$l_fileLock', for `SECFUNCbcPrettyCalc "$l_count*0.1"` seconds..."
				#SECFUNCfileLock_validateLock
			fi
			SECFUNCfileLock_validateLock
		done
		echo "$$" >"$l_fileLockPid"
	fi
	
	return 0
}

function SECFUNCuniqueLock() { 
	local l_bRelease=false
	while [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			echo "Creates a unique lock that help the script to prevent itself from being executed more than one time simultaneously."
			echo "If lock exists, outputs the pid holding it."
			echo 'Parameters: [id] defaults to `basename $0`'
			
			grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			return
		elif [[ "$1" == "--release" ]];then #SECFUNCuniqueLock_help release the lock
			l_bRelease=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local l_id="$1"
	if [[ -z "$l_id" ]];then
		l_id=`basename $0`
	fi
	
	local l_runUniqueFile="/tmp/.SEC.UniqueRun.$l_id"
	local l_lockFile="${l_runUniqueFile}.lock"
	
	function SECFUNCuniqueLock_release() {
		rm "$l_runUniqueFile";
		rm "$l_lockFile";
	}
	
	if $l_bRelease;then
		SECFUNCuniqueLock_release
		return 0
	fi
	
	if [[ -f "$l_runUniqueFile" ]];then
		local l_lockPid=`cat "$l_runUniqueFile"`
		if ps -p $l_lockPid >/dev/null 2>&1; then
			if(($$==$l_lockPid));then
				SECFUNCechoWarnA "redundant lock '$l_id' request..."
				return 0
			else
				echo "$l_lockPid"
				return 1
			fi
		else
			SECFUNCechoWarnA "releasing lock '$l_id' of dead process..."
			SECFUNCuniqueLock_release
		fi
	fi
	
	if [[ ! -f "$l_runUniqueFile" ]];then
		# try to create a symlink lock file to the unique file
		if ! ln -s "$l_runUniqueFile" "${l_runUniqueFile}.lock";then
			# other pid created the symlink first!
			return 1
		fi
	
		echo $$ >"$l_runUniqueFile"
		return 0
	fi
}

