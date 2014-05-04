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

shopt -s expand_aliases
set -u #so when unset variables are expanded, gives fatal error

export SECinitialized=true
export SECinstallPath="`secGetInstallPath.sh`";
export _SECselfFile_funcMisc="$SECinstallPath/lib/ScriptEchoColor/utils/funcMisc.sh"
export _SECmsgCallerPrefix='`basename $0`,p$$,bp$BASHPID,bss$BASH_SUBSHELL,${FUNCNAME-}(),L$LINENO'
export _SECbugFixDate="(3600*3)" #to fix from: "31/12/1969 21:00:00.000000000" ...
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA "func In"'
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA "func Out"'
alias SECexitA='SECFUNCdbgFuncOutA;exit '
alias SECreturnA='SECFUNCdbgFuncOutA;return '

# IMPORTANT!!!!!!! do not use echoc or ScriptEchoColor on functions here, may become recursive infinite loop...

######### EXTERNAL VARIABLES can be set by user #########
: ${SEC_DEBUG:=false}
if [[ "$SEC_DEBUG" != "true" ]]; then #compare to inverse of default value
	export SEC_DEBUG=false # of course, np if already "false"
fi

: ${SEC_MsgColored:=true}
if [[ "$SEC_MsgColored" != "false" ]];then
	export SEC_MsgColored=true
fi

: ${SEC_ShortFuncsAliases:=true}
if [[ "$SEC_ShortFuncsAliases" != "false" ]]; then
	export SEC_ShortFuncsAliases=true
fi

# function aliases for easy coding
: ${SECfuncPrefix:=sec} #this prefix can be setup by the user
export SECfuncPrefix

###################### INTERNAL VARIABLES are set by functions ########
: ${SECcfgFileName:=} #do NOT export, each script must know its cfg file properly; a script calling another could mess that other cfg filename if it is exported...

: ${SECnPidDaemon:=0}
export SECnPidDaemon

: ${SECbDaemonWasAlreadyRunning:=false}
export SECbDaemonWasAlreadyRunning

###################### SETUP ENVIRONMENT
if $SEC_ShortFuncsAliases; then 
	#TODO validate if such aliases or executables exist before setting it here and warn about it
	alias "$SECfuncPrefix"delay='SECFUNCdelay';
fi

export SEC_TmpFolder="/dev/shm"
if [[ ! -d "$SEC_TmpFolder" ]];then
	SEC_TmpFolder="/run/shm"
	if [[ ! -d "$SEC_TmpFolder" ]];then
		SEC_TmpFolder="/tmp"
		# is not fast as ramdrive (shm) and may cause trouble..
	fi
fi
if [[ -L "$SEC_TmpFolder" ]];then
	SEC_TmpFolder="`readlink "$SEC_TmpFolder"`" #required for find that would fail on symlink to a folder..
fi

_SECdbgVerboseOpt=""
if [[ "$SEC_DEBUG" == "true" ]];then
	_SECdbgVerboseOpt="-v"
fi

################ FUNCTIONS

function SECFUNCexportFunctions() {
	declare -F \
		|grep "SECFUNC" \
		|sed 's"declare .* SECFUNC"export -f SECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f SECFUNC"
	
	declare -F \
		|grep "pSECFUNC" \
		|sed 's"declare .* pSECFUNC"export -f pSECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f pSECFUNC"
}

function SECFUNCdtNow() { 
	date +"%s.%N"; 
}
function SECFUNCtimePretty() {
	date -d "@`bc <<< "${_SECbugFixDate}+${1}"`" +"%H:%M:%S.%N"
}
function SECFUNCtimePrettyNow() {
	SECFUNCtimePretty `SECFUNCdtNow`
}
function SECFUNCdtTimePretty() {
	date -d "@`bc <<< "${_SECbugFixDate}+${1}"`" +"%d/%m/%Y %H:%M:%S.%N"
}
function SECFUNCdtTimePrettyNow() {
	SECFUNCdtTimePretty `SECFUNCdtNow`
}
function SECFUNCdtTimeToFileName() {
	date -d "@`bc <<< "${_SECbugFixDate}+${1}"`" +"%Y_%m_%d-%H_%M_%S_%N"
}
function SECFUNCdtTimeToFileNameNow() {
	SECFUNCdtTimeToFileName `SECFUNCdtNow`
}

alias SECFUNCechoErrA="SECFUNCechoErr --caller \"$_SECmsgCallerPrefix\" "
function SECFUNCechoErr() { #echo error messages
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoErr_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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
	#echo "SECERROR[`SECFUNCdtNow`]: ${caller}$@" >/dev/stderr; 
	local l_output="SECERROR[`SECFUNCdtNow`]: ${caller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[91m${l_output}\E[0m" >/dev/stderr
	else
		echo "${l_output}" >/dev/stderr
	fi
}
#if [[ "$SEC_DEBUG" == "true" ]];then
#	SECFUNCechoErrA "test error message"
#	SECFUNCechoErr --caller "caller=funcMisc.sh" "test error message"
#fi

alias SECFUNCechoDbgA="SECFUNCechoDbg --caller \"$_SECmsgCallerPrefix\" "
function SECFUNCechoDbg() { #will echo only if debug is enabled with SEC_DEBUG
	if [[ "$SEC_DEBUG" != "true" ]];then # to not loose time
		return 0
	fi
	
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoDbg_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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
		local l_output="SECDEBUG[`SECFUNCdtNow`]: ${caller}$@"
		if $SEC_MsgColored;then
			echo -e "\E[0m\E[97m\E[47m${l_output}\E[0m" >/dev/stderr
		else
			echo "${l_output}" >/dev/stderr
		fi
	fi
}

alias SECFUNCechoWarnA="SECFUNCechoWarn --caller \"$_SECmsgCallerPrefix\" "
function SECFUNCechoWarn() { 
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoWarn_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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
	#echo "SECWARN[`SECFUNCdtNow`]: ${caller}$@" >/dev/stderr
	local l_output="SECWARN[`SECFUNCdtNow`]: ${caller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[93m${l_output}\E[0m" >/dev/stderr
	else
		echo "${l_output}" >/dev/stderr
	fi
}

function SECFUNCparamsToEval() {
	###### options
	bEscapeQuotes=false
	bEscapeQuotesTwice=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCparamsToEval_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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
	while [[ -n "${1-}" ]];do
  	if [[ -n "$strExec" ]];then
	  	strExec="${strExec} ";
  	fi
  	strExec="${strExec}${strEscapeQuotes}\"$1${strEscapeQuotes}\"";
  	shift;
  done;
  echo "$strExec"
}

alias SECFUNCexecA="SECFUNCexec --caller \"$_SECmsgCallerPrefix\" "
function SECFUNCexec() {
	omitOutput="2>/dev/null 1>/dev/null" #">/dev/null 2>&1" is the same..
	bOmitOutput=false
	bShowElapsed=false
	bWaitKey=false
	bExecEcho=false
	
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCexec_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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
  local separator="${1-}"
  shift
  
  local pidList=()
  local ppid=$$;
  while((ppid>=1));do 
    ppid=`ps -o ppid -p $ppid --no-heading |tail -n 1`; 
    #pidList=(${pidList[*]} $ppid)
    pidList+=($ppid)
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
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCbcPrettyCalc_help --help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
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

function SECFUNCdrawLine() { #[wordsAlignedDefaultMiddle] [lineFillChars]
	local lstrAlign="middle"
	local lbStay=false
	local lbTrunc=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdrawLine_help show help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--left" || "$1" == "-0" ]];then #SECFUNCdrawLine_help align words at left
			lstrAlign="left"
		elif [[ "$1" == "--middle" || "$1" == "-1" ]];then #SECFUNCdrawLine_help align words at middle
			lstrAlign="middle"
		elif [[ "$1" == "--right" || "$1" == "-2" ]];then #SECFUNCdrawLine_help align words at right
			lstrAlign="right"
		elif [[ "$1" == "--stay" ]];then #SECFUNCdrawLine_help no newline at end, and appends \r
			lbStay=true
		elif [[ "$1" == "--notrunc" ]];then #SECFUNCdrawLine_help do not trunc line to fit columns
			lbTrunc=false
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	local lstrWords="${1-}";
	shift
	local lstrFill="${1-}"
	
	if [[ -z "$lstrFill" ]];then
		lstrFill="="
	fi
	
	local lnTerminalWidth=`tput cols`
	local lnTotalFillChars=$((lnTerminalWidth-${#lstrWords}))
	local lnFillCharsLeft=$((lnTotalFillChars/2))
	local lnFillCharsRight=$((lnTotalFillChars/2))
	
	# if odd width, add one char
	if(( (lnTotalFillChars%2) == 1 ));then 
		((lnFillCharsRight++))
	fi
	
	# at least one complete fill must happen at beggining and ending, what may cause more than one line to be printed
	if((lnFillCharsLeft<${#lstrFill}));then
		lnFillCharsLeft=${#lstrFill}
	fi
	if((lnFillCharsRight<${#lstrFill}));then
		lnFillCharsRight=${#lstrFill}
	fi
	
	local lstrFill=`eval "printf \"%.0s${lstrFill}\" {1..${lnTerminalWidth}}"`
	
	case $lstrAlign in
		left)   local lstrWordsLeft=$lstrWords;;
		middle) local lstrWordsMiddle=$lstrWords;;
		right)  local lstrWordsRight=$lstrWords;;
	esac
	
	local lstrOutput="${lstrWordsLeft-}${lstrFill:0:lnFillCharsLeft}${lstrWordsMiddle-}${lstrFill:${#lstrFill}-lnFillCharsRight}${lstrWordsRight-}"
	
	local loptNewLine=""
	local loptCarryageReturn=""
	if $lbStay;then
		loptNewLine="-n"
		loptCarryageReturn="\r"
	fi
	
	#trunc
	if $lbTrunc;then
		if((${#lstrOutput}>lnTerminalWidth));then
			lstrOutput="${lstrOutput:0:lnTerminalWidth}"
		fi
	fi
	
	echo -e $loptNewLine "$lstrOutput$loptCarryageReturn"
}

alias SECFUNCvalidateIdA="SECFUNCvalidateId --caller \"\${FUNCNAME-}\" "
function SECFUNCvalidateId() { #Id can only be alphanumeric or underscore ex.: for functions and variables name.
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--caller" ]];then #SECFUNCvalidateId_help is the name of the function calling this one
			shift
			caller="${1}(): "
		fi
		shift
	done
	
	if [[ -n `echo "$1" |tr -d '[:alnum:]_'` ]];then
		SECFUNCechoErrA "${caller}invalid id '$1', only allowed alphanumeric and underscores."
		return 1
	fi
	return 0
}
alias SECFUNCfixIdA="SECFUNCfixId --caller \"\${FUNCNAME-}\" "
function SECFUNCfixId() { #fix the id, use like: strId="`SECFUNCfixId "TheId"`"
	local caller=""
	local lbJustFix=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--caller" ]];then #SECFUNCfixId_help is the name of the function calling this one
			shift
			caller="${1}(): "
		elif [[ "$1" == "--justfix" ]];then #SECFUNCfixId_help otherwise it will also validate and inform invalid id to user
			lbJustFix=true
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	if ! $lbJustFix;then
		# just to inform invalid id to user be able to set it properly if wanted
		SECFUNCvalidateId --caller "$caller" "$1"
	fi
	
	# removes all non-alphanumeric and non underscore
	#echo "$1" |tr '.-' '__' | sed 's/[^a-zA-Z0-9_]/_/g'
	echo "$1" |sed 's/[^a-zA-Z0-9_]/_/g'
}


function SECFUNCdelay() { #The first parameter can optionally be a string identifying a custom delay like:\n\tSECFUNCdelay main --init;\n\tSECFUNCdelay test --init;
	declare -g -A _dtSECFUNCdelayArray
	
	local indexId="$FUNCNAME"
	if [[ -n "${1-}" ]] && [[ "${1:0:2}" != "--" ]];then
#		if ! SECFUNCvalidateIdA "$1";then
#			return 1
#		fi
#		if [[ -n `echo "$1" |tr -d '[:alnum:]_'` ]];then
#			SECFUNCechoErrA "invalid indexId '$1', only allowed alphanumeric id and underscores."
#			return 1
#		fi
		indexId="`SECFUNCfixIdA $1`"
		shift
	fi
	
	function _SECFUNCdelayValidateIndexIdForOption() {
		local l_bQuiet=false
		if [[ "${1-}" == "--quiet" ]];then
			l_bQuiet=true
			shift
		fi
		SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$indexId]-}=${_dtSECFUNCdelayArray[$indexId]-}"
		if [[ -z "${_dtSECFUNCdelayArray[$indexId]-}" ]];then
			# programmer must have coded it somewhere to make that code clear
			#echo "--init [indexId=$indexId] needed before calling $1" >&2
			if ! $l_bQuiet;then
				SECFUNCechoErrA "--init [indexId=$indexId] needed before calling $1"
			fi
			return 1
		fi
	}
	
	local l_b1stIsTrueOnCheckOrInit=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdelay_help --help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--1stistrue" ]];then #SECFUNCdelay_help to use with --checkorinit that makes 1st run return true
			l_b1stIsTrueOnCheckOrInit=true
		elif [[ "$1" == "--checkorinit1" ]];then #SECFUNCdelay_help <delayLimit> like --1stistrue --checkorinit
			shift
			local nCheckDelayAt=$1
			
			#l_b1stIsTrueOnCheckOrInit=true
			
			SECFUNCdelay $indexId --1stistrue --checkorinit "$nCheckDelayAt"
			return $?
		elif [[ "$1" == "--checkorinit" ]];then #SECFUNCdelay_help <delayLimit> will check if delay is above or equal specified at delayLimit; will then return true and re-init the delay variable; otherwise return false
			shift
			local nCheckDelayAt=$1
			if [[ -z "$nCheckDelayAt" ]] || [[ -n `echo "$nCheckDelayAt" |tr -d '[:digit:].'` ]];then
				SECFUNCechoErrA "required valid <delayLimit>, can be float"
				SECFUNCdelay --help |grep "\-\-checkorinit"
				read -n 1 -p "press ctrl+c to fix your code" >&2
				return 1
			fi
			
			if ! _SECFUNCdelayValidateIndexIdForOption --quiet "--checkorinit";then
				SECFUNCdelay $indexId --init
				if $l_b1stIsTrueOnCheckOrInit;then
					return 0
				fi
			fi
			
			local delay=`SECFUNCdelay $indexId --get`
			if SECFUNCbcPrettyCalc --cmpquiet "$delay>=$nCheckDelayAt";then
				SECFUNCdelay $indexId --init
				return 0
			else
				return 1
			fi
		elif [[ "$1" == "--init" ]];then #SECFUNCdelay_help set temp date storage to now
			#@@@r SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$indexId]}=${_dtSECFUNCdelayArray[$indexId]}"
			_dtSECFUNCdelayArray[$indexId]=`SECFUNCdtNow`
			#@@@r SECFUNCechoDbgA "\${_dtSECFUNCdelayArray[$indexId]}=${_dtSECFUNCdelayArray[$indexId]}"
			return
		elif [[ "$1" == "--get" ]];then #SECFUNCdelay_help get delay from init (is the default if no option parameters are set)
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			local now=`SECFUNCdtNow`
			SECFUNCbcPrettyCalc "${now} - ${_dtSECFUNCdelayArray[$indexId]}"
			return
		elif [[ "$1" == "--getsec" ]];then #SECFUNCdelay_help get (only seconds without nanoseconds) from init
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			SECFUNCdelay $indexId --get |sed -r 's"^([[:digit:]]*)[.][[:digit:]]*$"\1"'
			return
		elif [[ "$1" == "--getpretty" ]];then #SECFUNCdelay_help get full delay pretty time
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			local delay=`SECFUNCdelay $indexId --get`
			SECFUNCtimePretty "$delay"
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
	
	SECFUNCdelay $indexId --get #default
}

function SECFUNCfileLock() { #Waits until the specified file is unlocked/lockable.\n\tCreates a lock file for the specified file.\n\t<realFile> cannot be a symlink or a directory
			
	local l_bUnlock=false
	local l_bCheckIfIsLocked=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfileLock_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--unlock" ]];then #SECFUNCfileLock_help releases the lock for the specified file.
			l_bUnlock=true
		elif [[ "$1" == "--islocked" ]];then #SECFUNCfileLock_help check if is locked and, if so, outputs the locking pid.
			l_bCheckIfIsLocked=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local l_file="${1-}" #can be with full path
	if [[ ! -f "$l_file" ]];then
		SECFUNCechoErrA "file '$l_file' does not exist (if symlink must point to a file)"
		return 1
	fi
	
	# l_file must be the real file where all symlinks point to; therefore this will break in case the file has hard links being locked too...
	while [[ -L "$l_file" ]];do
		l_file=`readlink "$l_file"`
	done
	
	if [[ "${l_file:0:1}" != "/" ]];then
		l_file="`pwd`/$l_file"
	fi
	
	local l_sedMd5sumOnly='s"([[:alnum:]]*) .*"\1"'
	local l_md5sum=`echo "$l_file" |md5sum |sed -r "$l_sedMd5sumOnly"`
	local l_fileLock="$SEC_TmpFolder/.SEC.FileLock.$l_md5sum.lock"
	local l_fileLockPid="$SEC_TmpFolder/.SEC.FileLock.$l_md5sum.lock.pid"
	local l_lockingPid=-1 #no pid can be -1 right?
	
	function SECFUNCfileLock_removeLock() {
		local l_bRemoved=false
		
		if [[ -f "$l_fileLock" ]];then
			rm "$l_fileLock"
			l_bRemoved=true
		fi
		
		if [[ -f "$l_fileLockPid" ]];then
			rm "$l_fileLockPid"
			l_bRemoved=true
		fi
		
		if ! $l_bRemoved;then
			return 1
		fi
		
		return 0
	}
	
	function SECFUNCfileLock_validateLock() {
		#TODO? use find to validate all lock files for all pid as maintenance each 10minutes (in some way... see `at` command at shell!). but.. tmp and ramdrive variables are erased on boot..
		# if locking pid is missing (for any reason), remove lock
		if [[ ! -f "$l_fileLockPid" ]];then
			if SECFUNCfileLock_removeLock;then
				SECFUNCechoDbgA "Locking pid file '$l_fileLockPid' was missing, for file '$l_file', removed lock..."
			fi
		else
			l_lockingPid=`cat "$l_fileLockPid" 2>/dev/null` # the locking pid file can be removed just before this command happens!
	
			# if pid died, remove locking files
			if ! ps -p $l_lockingPid >/dev/null 2>&1;then
				SECFUNCechoDbgA "Pid '$l_lockingPid' died, removing lock '$l_fileLock', for file '$l_file'..."
				SECFUNCfileLock_removeLock
				l_lockingPid=-1
			fi
		fi
	}
	
	# important to initialize l_lockingPid from the 2nd time on this func is called...
	if [[ -f "$l_fileLockPid" ]];then
		SECFUNCfileLock_validateLock
	fi
	
	if $l_bCheckIfIsLocked;then
		if(($l_lockingPid>-1));then
			echo "$l_lockingPid" #outputs the locking pid
			return 0
		else
			return 1
		fi
	elif $l_bUnlock;then
		if [[ -L "$l_fileLock" ]];then
			if(($l_lockingPid==$$));then
				SECFUNCfileLock_removeLock
				return 0
			elif(($l_lockingPid==-1));then
				SECFUNCechoWarnA "File '$l_file' was not locked..."
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
	else # asking to lock
		if(($l_lockingPid==$$));then
			SECFUNCechoDbgA "file '$l_file' is already locked with '$l_fileLock' (this pid $$)..." # if it was a warning would not be that useful right? just annoying...
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

function SECFUNCuniqueLock() { #Creates a unique lock that help the script to prevent itself from being executed more than one time simultaneously. If lock exists, outputs the pid holding it.
	#set -x
	local l_bRelease=false
	local l_pid=$$
	local l_bQuiet=false
	local lbDaemon=false
	local lbWaitDaemon=false
	local lstrId="`basename "$0"`"
	SECnPidDaemon=0
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			#grep "#${FUNCNAME}_help" "$_SECselfFile_funcMisc" |sed -r "s'.*(--.*)\" ]];then #${FUNCNAME}_help (.*)'\t\1\t\2'"
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--quiet" ]];then #SECFUNCuniqueLock_help prevent all output to /dev/stdout
			l_bQuiet=true
		elif [[ "$1" == "--notquiet" ]];then #SECFUNCuniqueLock_help allow output to /dev/stdout
			l_bQuiet=false
		elif [[ "$1" == "--id" ]];then #SECFUNCuniqueLock_help <id> set the lock id, if not set, the 'id' defaults to `basename $0`
			shift
			lstrId="$1"
		elif [[ "$1" == "--pid" ]];then #SECFUNCuniqueLock_help <pid> force pid to be related to the lock
			shift
			l_pid=$1
			if ! ps -p $l_pid >/dev/null 2>&1;then
				SECFUNCechoErrA "invalid pid: '$l_pid'"
				return 1
			fi
		elif [[ "$1" == "--release" ]];then #SECFUNCuniqueLock_help release the lock
			l_bRelease=true
		elif [[ "$1" == "--daemon" ]];then #SECFUNCuniqueLock_help Auto set the DB to the daemon DB if it is already running, or create a new DB; Also sets this variable: SECbDaemonWasAlreadyRunning.
			lbDaemon=true
		elif [[ "$1" == "--daemonwait" ]];then #SECFUNCuniqueLock_help will wait for the other daemon to exit, and then will become the daemon
			lbDaemon=true
			lbWaitDaemon=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	lstrId="`SECFUNCfixIdA --justfix "$lstrId"`"
#	if ! SECFUNCvalidateIdA "$lstrId";then
#		return 1
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
					echo -ne "Wait Daemon '$lstrId': ${SECONDS}s...\r" >>/dev/stderr
					sleep 1 #keep trying to become the daemon
				else
					break #has become the daemon, breaks loop..
				fi
			else
				break; #always break, because DB is always set (child or master)
			fi
		done
		return 0 # to prevent bugs..
	fi
	
	#local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$l_pid.$lstrId"
	local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$lstrId"
	local l_lockFile="${l_runUniqueFile}.lock"
	
	function SECFUNCuniqueLock_release() {
		rm "$l_runUniqueFile";
		rm "$l_lockFile";
	}
	
	if ${l_bRelease:?};then
		SECFUNCuniqueLock_release
		return 0
	fi
	
	if [[ -f "$l_runUniqueFile" ]];then
		local l_lockPid=`cat "$l_runUniqueFile"`
		if ps -p $l_lockPid >/dev/null 2>&1; then
			if(($l_pid==$l_lockPid));then
				SECFUNCechoWarnA "redundant lock '$lstrId' request..."
				return 0
			else
				if ! ${l_bQuiet:?};then
					echo "$l_lockPid"
				fi
				return 1
			fi
		else
			SECFUNCechoWarnA "releasing lock '$lstrId' of dead process..."
			SECFUNCuniqueLock_release
		fi
	fi
	
	if [[ ! -f "$l_runUniqueFile" ]];then
		# try to create a symlink lock file to the unique file
		if ! ln -s "$l_runUniqueFile" "${l_runUniqueFile}.lock";then
			# other pid created the symlink first!
			return 1
		fi
	
		echo $l_pid >"$l_runUniqueFile"
		return 0
	fi
}

#function SECFUNCdaemonUniqueLock() { #Auto set the DB to the daemon DB if it is already running, or set a new DB\n\tAlso sets this variable: SECbDaemonWasAlreadyRunning\n\tAnd finally passes all parameters to function: SECFUNCuniqueLock
#	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
#		if [[ "$1" == "--help" ]];then #SECFUNCdaemonUniqueLock
#			SECFUNCshowHelp ${FUNCNAME}
#			return
#		else
#			break #SECFUNCuniqueLock will take care of parameters now
#		fi
#		shift
#	done
#	
#	SECbDaemonWasAlreadyRunning=false #global NOT to export
#	if SECFUNCuniqueLock --quiet "$@"; then
#		SECFUNCvarSetDB -f
#	else
#		SECFUNCvarSetDB `SECFUNCuniqueLock` #allows intercommunication between proccesses started from different parents
#		SECbDaemonWasAlreadyRunning=true
#	fi
#}

function SECFUNCshowHelp() {
	local lstrFunctionNameToken="${1-}"
	
	local lstrFile="$0"
	if [[ ! -f "$lstrFile" ]];then
		if [[ "${lstrFunctionNameToken:0:10}" == "SECFUNCvar" ]];then
			#TODO !!! IMPORTANT !!! this MUST be the only place on funcMisc.sh that funcVars.sh or anything from it is known about!!! BEWARE!!!!!!!!!!!!!!!!!! Create a validator on a package builder?
			lstrFile="$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh"
		elif [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
			lstrFile="$_SECselfFile_funcMisc"
		else
			# as help text are comments and `type` wont show them, the real script files is required...
			SECFUNCechoErrA "unable to access script file '$lstrFile'"
			return 1
		fi
	fi
	
	if [[ -n "$lstrFunctionNameToken" ]];then
		if [[ -n `echo "$lstrFunctionNameToken" |tr -d '[:alnum:]_'` ]];then
			SECFUNCechoErrA "invalid prefix '$lstrFunctionNameToken'"
			return 1
		fi
		
		echo -e "  \E[0m\E[0m\E[94m$lstrFunctionNameToken\E[0m\E[93m()\E[0m"
		
		# for function description
		local lstrFuncDesc=`grep "function ${lstrFunctionNameToken}[[:blank:]]*().*{.*#" "$lstrFile" |sed -r "s;^function ${lstrFunctionNameToken}[[:blank:]]*\(\).*\{.*#(.*);\1;"`
		if [[ -n "$lstrFuncDesc" ]];then
			echo -e "\t$lstrFuncDesc"
		fi
		
		lstrFunctionNameToken="${lstrFunctionNameToken}_"
	else
		echo "Help options for `basename "$0"`:"
	fi
	
	# for script options or function options
	local lgrepNoCommentedLines="^[[:blank:]]*#"
	local lgrepMatchHelpToken="#${lstrFunctionNameToken}help"
	local lsedOptionsAndHelpText='s,.*\[\[(.*)\]\].*(#'$lstrFunctionNameToken'help.*),\1\2,'
	local lsedRemoveTokenOR='s,(.*"[[:blank:]]*)[|]{2}([[:blank:]]*".*),\1\2,' #if present
	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g'
	local lsedRemoveHelpToken='s,#'${lstrFunctionNameToken}'help,,'
	#local lsedAddNewLine='s".*"&\n"'
	cat "$lstrFile" \
		|egrep -v "$lgrepNoCommentedLines" \
		|grep -w "$lgrepMatchHelpToken" \
		|sed -r "$lsedOptionsAndHelpText" \
		|sed -r "$lsedRemoveTokenOR" \
		|sed -r "$lsedRemoveComparedVariable" \
		|sed -r "$lsedRemoveHelpToken"
		#|sed -r "$lsedAddNewLine"
}

function SECFUNCcfgFileName() { #Application config file for scripts.\n\t[cfgIdentifier], if not set will default to `basename "$0"`
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	local lpath="$HOME/.ScriptEchoColor/SEC.AppVars.DB"
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
		#echo "lstrCanonicalFileName=$lstrCanonicalFileName" >/dev/stderr
		#SECcfgFileName="$lpath/`basename "$0"`.cfg"
		SECcfgFileName="$lpath/`basename "$lstrCanonicalFileName"`.cfg"
	fi
	
	#echo "$lpath/${SECcfgFileName}.cfg"
	#echo "$SECcfgFileName"
}
function SECFUNCcfgRead() { #read the cfg file and set all its env vars at current env
	#echo oi;eval `cat tst.db`;return
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	if [[ -f "$SECcfgFileName" ]];then
  	SECFUNCfileLock "$SECcfgFileName"
  	
  	#declare -p aDaemonsPid
  	#echo "$SECcfgFileName"
  	#cat "$SECcfgFileName"
  	#source "$SECcfgFileName"
  	#local lstrCfgData=`cat "$SECcfgFileName"`
  	#echo $lstrCfgData
  	#eval $lstrCfgData
  	#eval `cat "$SECcfgFileName"`
  	#echo ">>>tst=${tst-}"
  	eval "`cat "$SECcfgFileName"`"
  	#declare -p aDaemonsPid
  	
  	SECFUNCfileLock --unlock "$SECcfgFileName"
  fi
}
function SECFUNCcfgWriteVar() { #<var>[=<value>] write a variable to config file
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
#		local lsedVarId='s"^([[:alnum:]_]*)=.*"\1"'
#		local lsedValue='s"^[[:alnum:]_]*=(.*)"\1"'
#		lstrVarId=`echo "$1" |sed -r "$lsedVarId"`
#		local lstrValue=`echo "$1" |sed -r "$lsedValue"`
#		eval "$lstrVarId=\"$lstrValue\""
		eval "`echo "$1" |sed -r 's,^([[:alnum:]_]*)=(.*),\
			\1="\2";\
			lstrVarId="\1";\
			lstrValue="\2";\
		,'`"
	else
		local lstrVarId="$1"
#		local lstrArrayToWrite=`declare -p ${lstrVarId}`
#		if $lstrArrayToWrite |grep -q "^declare -[aA]";then
#			lbIsArray=true
#			#local lstrValue=`declare -p ${lstrVarId} |sed -r "s,^declare -[aA] ([[:alnum:]_]*)='(.*)',\2,"`
#		else
#			local lstrValue="${!lstrVarId-}"
#		fi
	fi
	
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	if [[ -z "`declare |grep "^${lstrVarId}="`" ]];then
		SECFUNCechoErrA "invalid var '$lstrVarId' to write at cfg file '$SECcfgFileName'"
		return 1
	fi
	
	# `declare` must be stripped off or the evaluation of the cfg file will fail!!!
	if declare -p ${lstrVarId} |grep -q "^declare -[aA]";then
		lbIsArray=true
	fi
	
	local lstrPliqForArray=""
	if $lbIsArray;then
		lstrPliqForArray="'"
		#lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^(declare -[[:alpha:]-]* [[:alnum:]_]*)='(.*)'$,${lstrVarId}=\"\";unset ${lstrVarId};\1=\2,"`
#		lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)='(.*)'$,\1=\2,"`
#	else
#		lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=(.*)$,\1=\2,"`
	fi
	
	local lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	
#	local lstrPliqForArray=""
#	local lstrPrepareArray=""
#	if $lbIsArray;then
#		lstrPliqForArray="'"
#		
#		local lstrDeclareArray=`declare -p $lstrVarId |sed -r 's"^([^=]*)=.*"\1"'`
#		lstrPrepareArray="$lstrVarId='';unset $lstrVarId;$lstrDeclareArray;"
#	fi
#	lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	#echo "lstrToWrite=$lstrToWrite"
	#eval export ${lstrVarId}
	
	if [[ ! -f "$SECcfgFileName" ]];then
		echo -n >"$SECcfgFileName"
	fi
	
	SECFUNCfileLock "$SECcfgFileName"
	#set -x	
	local lstrMatchLineToRemove=`echo "$lstrToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
	sed -i "/$lstrMatchLineToRemove/d" "$SECcfgFileName" #will remove the variable line
	if ! $lbRemoveVar;then
		echo "${lstrToWrite};" >>"$SECcfgFileName" #append new line with var
	fi
	#set +x
#	if $lbIsArray;then
#		local lstrMatchLineToRemove=`echo "$lstrArrayToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
#		sed "/$lstrMatchLineToRemove/d" "$SECcfgFileName"
#		echo "$lstrArrayToWrite;" >>"$SECcfgFileName"
#	else
#		if grep -q "^${lstrVarId}=" "$SECcfgFileName";then
#			# sed substitute variable and value
#			sed -i "s'^${lstrVarId}=.*'${lstrVarId}=\"${lstrValue}\";'" "$SECcfgFileName"
#		else
#			echo "${lstrVarId}=\"${lstrValue}\";" >>"$SECcfgFileName"
#		fi
#	fi
	SECFUNCfileLock --unlock "$SECcfgFileName"
}

function SECFUNCshowFunctionsHelp() { #show functions specific help
	#set -x
	if [[ "${1-}" == "--help" ]];then #SECFUNCshowFunctionsHelp show this help
		#this option also prevents infinite loop for this script help
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	echo "`basename "$0"` Functions:"
	local lsedFunctionNameOnly='s".*(SECFUNC.*)\(\).*"\1"'
	local lastrFunctions=(`grep "function SECFUNC.*" "$0" |grep -v grep |sed -r "$lsedFunctionNameOnly"`)
	lastrFunctions=(`echo "${lastrFunctions[@]}" |tr " " "\n" |sort`)
	for lstrFuncId in ${lastrFunctions[@]};do
		echo
		if type $lstrFuncId 2>/dev/null |grep -q "\-\-help";then
			local lstrHelp=`$lstrFuncId --help`
			if [[ -n "$lstrHelp" ]];then
				echo "$lstrHelp"
			else
				#echo "  $lstrFuncId()"
				SECFUNCshowHelp $lstrFuncId #this only happens for SECFUNCechoDbg ...
			fi
		else
			#echo "  $lstrFuncId()"
			SECFUNCshowHelp $lstrFuncId
		fi
	done
}

function SECFUNCarraySize() { #usefull to prevent unbound variable error message
	local laArrayId="$1"
	local bWasNoUnset=false
	if set -o |grep nounset |grep -q "on$";then
		bWasNoUnset=true
	fi
	set +u
	eval echo "\${#${laArrayId}[@]}"
	if $bWasNoUnset;then
		set -u
	fi
}

#function SECFUNCdaemonsControl() {
#	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
#		if [[ "$1" == "--help" ]];then #SECFUNCdaemonsControl_help show this help
#			SECFUNCshowHelp "$FUNCNAME"
#			return
#		elif [[ "$1" == "--set" ]];then #SECFUNCdaemonsControl_help set vars on daemons control main file
#			shift
#			local lstrVar="$1"
#			shift
#			local lstrValue="$1"
#		else
#			SECFUNCechoErrA "invalid option: $1"
#			return 1
#		fi
#	done
#	local lstrFile="$SEC_TmpFolder/SEC.DaemonsControl.tmp"
#}
function SECFUNCdaemonCheckHold() { #used to fastly check and hold daemon execution, this code fully depends on what is coded at secDaemonsControl.sh
	: ${SECbDaemonRegistered:=false}
	if ! $SECbDaemonRegistered;then
		secDaemonsControl.sh --register
		SECbDaemonRegistered=true
	fi
	_SECFUNCdaemonCheckHold_SubShell() {
		# IMPORTANT: subshell to protect parent envinronment variable SECcfgFileName
		local bHoldScripts=false
		SECFUNCcfgFileName secDaemonsControl.sh
		SECFUNCcfgRead
		#echo "$SECcfgFileName";cat "$SECcfgFileName";echo "bHoldScripts=$bHoldScripts"
		if $bHoldScripts;then
			secDaemonsControl.sh --checkhold #will cause recursion if this function is called on that command...
		fi
	};export -f _SECFUNCdaemonCheckHold_SubShell
	bash -c "_SECFUNCdaemonCheckHold_SubShell"
}

function SECFUNCfileSleepDelay() { #<file> show how long (in seconds) a real file (not the symlink) is not active (has not been updated or touch)
	local lfile="`readlink -f "$1"`"
	if [[ ! -a "$lfile" ]];then
		SECFUNCechoErrA "invalid file '$lfile'"
		return 1
	fi
	
	local lnSecondsFile=`stat -c "%Y" "$lfile"`;
	local lnSecondsNow=`date +"%s"`;
	local lnSecondsDelay=$((lnSecondsNow-lnSecondsFile))
	echo "$lnSecondsDelay"
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

if [[ `basename "$0"` == "funcMisc.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

