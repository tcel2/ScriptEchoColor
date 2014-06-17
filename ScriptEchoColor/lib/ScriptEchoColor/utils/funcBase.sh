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

# THIS FILE must contain everything that can be used everywhere without any problems (if possible)

shopt -s expand_aliases
set -u #so when unset variables are expanded, gives fatal error

# THIS ATOMIC FUNCTION IS SPECIAL AND CAN COME HERE, IT MUST DEPEND ON NOTHING!!!
function _SECFUNCcriticalForceExit() {
	while true;do
		#read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m CRITICAL!!! unable to continue!!! press 'ctrl+c' to fix your code or report bug!!! \E[0m"`" >&2
		read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m CRITICAL!!! unable to continue!!! hit 'ctrl+c' to fix your code or report bug!!! \E[0m"`" >>/dev/stderr
	done
}

export SECinitialized=true
export SECinstallPath="`secGetInstallPath.sh`";
SECastrFuncFilesShowHelp=("$SECinstallPath/lib/ScriptEchoColor/utils/funcBase.sh")
export _SECmsgCallerPrefix='`basename $0`,p$$,bp$BASHPID,bss$BASH_SUBSHELL,${FUNCNAME-}(),L$LINENO'

export SEC_TmpFolder="/dev/shm"
if [[ ! -d "$SEC_TmpFolder" ]];then
	SEC_TmpFolder="/run/shm"
	if [[ ! -d "$SEC_TmpFolder" ]];then
		SEC_TmpFolder="/tmp"
		# is not fast as ramdrive (shm) and may cause trouble..
	fi
fi
if [[ -L "$SEC_TmpFolder" ]];then
	SEC_TmpFolder="`readlink -f "$SEC_TmpFolder"`" #required with `find` that would fail on symlink to a folder..
fi
SEC_TmpFolder="$SEC_TmpFolder/.SEC.$USER"
if [[ ! -d "$SEC_TmpFolder" ]];then
	mkdir "$SEC_TmpFolder"
fi

export SECstrFileMessageToggle="$SEC_TmpFolder/.SEC.MessageToggle"

if ${SECastrBashDebugFunctionIds+false};then 
	SECastrBashDebugFunctionIds=(); #help if array has items, wont reach here, tho if it has NO items, it will be re-initialized to what it was: an empty array (will remain the same). If any item of the array is "+all", all functions will match.
else
	_SECastrBashDebugFunctionIds_Check="`declare -p SECastrBashDebugFunctionIds 2>/dev/null`";
	if [[ "${_SECastrBashDebugFunctionIds_Check:0:10}" != 'declare -a' ]];then
		echo "SECastrBashDebugFunctionIds='$SECastrBashDebugFunctionIds' MUST BE DECLARED AS AN ARRAY..." >>/dev/stderr
		_SECFUNCcriticalForceExit
	fi
fi
export SECastrBashDebugFunctionIds

export SECstrFileErrorLog="$SEC_TmpFolder/.SEC.Error.log"

export SECstrExportedArrayPrefix="SEC_EXPORTED_ARRAY_"

export SECastrFunctionStack=() #TODO arrays do not export, any workaround?

#export _SECbugFixDate="0" #seems to be working now...

alias SECFUNCechoErrA="SECFUNCechoErr --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoDbgA="set +x;SECFUNCechoDbg --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoWarnA="SECFUNCechoWarn --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoBugtrackA="SECFUNCechoBugtrack --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCsingleLetterOptionsA='SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" '

alias SECFUNCexecA="SECFUNCexec --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCvalidateIdA="SECFUNCvalidateId --caller \"\${FUNCNAME-}\" "
alias SECFUNCfixIdA="SECFUNCfixId --caller \"\${FUNCNAME-}\" "
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA --funcin -- "$@" '
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA --funcout '

alias SECexitA='SECFUNCdbgFuncOutA;exit '
alias SECreturnA='SECFUNCdbgFuncOutA;return '

# IMPORTANT!!!!!!! do not use echoc or ScriptEchoColor on functions here, may become recursive infinite loop...

######### EXTERNAL VARIABLES can be set by user #########
: ${SEC_DEBUG:=false}
if [[ "$SEC_DEBUG" != "true" ]]; then #compare to inverse of default value
	export SEC_DEBUG=false # of course, np if already "false"
fi

: ${SEC_WARN:=false}
if [[ "$SEC_WARN" != "true" ]]; then #compare to inverse of default value
	export SEC_WARN=false # of course, np if already "false"
fi

: ${SEC_BUGTRACK:=false}
if [[ "$SEC_BUGTRACK" != "true" ]]; then #compare to inverse of default value
	export SEC_BUGTRACK=false # of course, np if already "false"
fi

: ${SEC_MsgColored:=true}
if [[ "$SEC_MsgColored" != "false" ]];then
	export SEC_MsgColored=true
fi

: ${SEC_ShortFuncsAliases:=true}
if [[ "$SEC_ShortFuncsAliases" != "false" ]]; then
	export SEC_ShortFuncsAliases=true
fi

: ${SECfuncPrefix:=sec} #this prefix can be setup by the user
export SECfuncPrefix #help function aliases for easy coding

: ${SEC_DEBUG_FUNC:=}
export SEC_DEBUG_FUNC #help this variable can be a function name to be debugged, only debug lines on that funcion will be shown

# between each lock check, validation or attempt, this is the sleep delay
: ${SECnLockRetryDelay:=100} #in miliseconds
if((SECnLockRetryDelay<1));then
	SECnLockRetryDelay=1
elif((SECnLockRetryDelay>10000));then
	SECnLockRetryDelay=10000
fi
export SECnLockRetryDelay

###################### INTERNAL VARIABLES are set by functions ########
: ${SECcfgFileName:=} #do NOT export, each script must know its cfg file properly; a script calling another could mess that other cfg filename if it is exported...

: ${SECnPidDaemon:=0}
export SECnPidDaemon

: ${SECbDaemonWasAlreadyRunning:=false}
export SECbDaemonWasAlreadyRunning

###################### SETUP ENVIRONMENT
if $SEC_ShortFuncsAliases; then 
	#TODO validate if such aliases or executables exist before setting it here and warn about it
	#TODO for all functions, create these aliases automatically
	alias "$SECfuncPrefix"delay='SECFUNCdelay';
fi

_SECdbgVerboseOpt=""
if [[ "$SEC_DEBUG" == "true" ]];then
	_SECdbgVerboseOpt="-v"
fi

: ${SECnPidMax:=`cat /proc/sys/kernel/pid_max`}

########################## FUNCTIONS

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

function SECFUNCexecOnSubShell(){
	SECFUNCarraysExport
	bash -c "$@"
}

function SECFUNCisNumber(){ #"is float" check by default
	local bDecimalCheck=false
	local bNotNegativeCheck=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		#eval "set -- `SECFUNCsingleLetterOptionsA "$@"`";	
		if [[ "$1" == "--help" ]];then #SECFUNCisNumber_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--decimal" || "$1" == "-d" ]];then #SECFUNCisNumber_help decimal check
			bDecimalCheck=true
		elif [[ "$1" == "--notnegative" || "$1" == "-n" ]];then #SECFUNCisNumber_help if negative, return false (1)
			bNotNegativeCheck=true
		elif [[ "$1" == "-dn" || "$1" == "-nd" ]];then #just to keep this function fast...
			bDecimalCheck=true
			bNotNegativeCheck=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done

	local lnValue="${1-}"
	
	if [[ -z "${lnValue}" ]];then
		return 1
	fi
	
	if [[ -n "`echo "${lnValue}" |tr -d '[:digit:].+-'`" ]];then
		return 1
	fi
	
	local lstrTmp="${lnValue//[^.]}"
	if $bDecimalCheck;then
		if((${#lstrTmp}>0));then
			return 1
		fi
	else
		if((${#lstrTmp}>1));then
			return 1
		fi
	fi
	
	local lstrTmp="${lnValue//[^+]}"
	if((${#lstrTmp}>1));then
		return 1
	elif((${#lstrTmp}==1)) && [[ "${lnValue:0:1}" != "+" ]];then
		return 1
	fi
	
	local lstrTmp="${lnValue//[^-]}"
	if $bNotNegativeCheck;then
		if((${#lstrTmp}>0));then
			return 1
		fi
	else
		if((${#lstrTmp}>1));then
			return 1
		elif((${#lstrTmp}==1)) && [[ "${lnValue:0:1}" != "-" ]];then
			return 1
		fi
	fi

	return 0
}

function SECFUNCrealFile(){
	local lfile="${1-}"
	if [[ ! -f "$lfile" ]];then
		SECFUNCechoErrA "lfile='$lfile' not found."
		echo "$lfile"
		return 1
	fi
	
	lfile="`which "$lfile"`"
	lfile="`readlink -f "$lfile"`"
	
	echo "$lfile"
}

function SECFUNCarraysExport() { #export all arrays
	SECFUNCdbgFuncInA;
	local lsedArraysIds='s"^([[:alnum:]_]*)=\(.*"\1";tfound;d;:found' #this avoids using grep as it will show only matching lines labeled 'found' with 't'
	# this is a list of arrays that are set by the system or bash, not by SEC
	local lastrArraysToSkip=(`env -i bash -i -c declare 2>/dev/null |sed -r "$lsedArraysIds"`)
	local lastrArrays=(`declare |sed -r "$lsedArraysIds"`)
	lastrArraysToSkip+=(
		BASH_REMATCH 
		FUNCNAME 
		lastrArraysToSkip 
		lastrArrays
		SECastrFunctionStack 
	) #TODO how to automatically list all arrays to be skipped? 'BASH_REMATCH' and 'FUNCNAME', I had to put by hand, at least now only export arrays already marked to be exported what may suffice...
	export SECcmdExportedAssociativeArrays=""
	for lstrArrayName in ${lastrArrays[@]};do
		local lbSkip=false
		for lstrArrayNameToSkip in ${lastrArraysToSkip[@]};do
			if [[ "$lstrArrayName" == "$lstrArrayNameToSkip" ]];then
				lbSkip=true
				break;
			fi
		done
		if $lbSkip;then
			continue;
		fi
		
		# only export already exported arrays...
		if ! declare -p "$lstrArrayName" |grep -q "^declare -.x";then
			continue
		fi
		
		# associative arrays MUST BE DECLARED like: declare -A arrayVarName; previously to having its values attributted, or it will break the code...
		if declare -p "$lstrArrayName" |grep -q "^declare -A";then
			if [[ -z "$SECcmdExportedAssociativeArrays" ]];then
				SECcmdExportedAssociativeArrays="declare -Ag "
			fi
			#export "${SECstrExportedArrayPrefix}_ASSOCIATIVE_${lstrArrayName}=true"
			SECcmdExportedAssociativeArrays+="${lstrArrayName} "
		fi
		
		# creates the variable to be restored on a child shell
		eval "export `declare -p $lstrArrayName |sed -r 's"declare -[[:alpha:]]* (.*)"'${SECstrExportedArrayPrefix}'\1"'`"
	done
	SECFUNCdbgFuncOutA;
}
function SECFUNCarraysRestore() { #restore all exported arrays
	SECFUNCdbgFuncInA;
	
	# declare associative arrays to make it work properly
	eval "${SECcmdExportedAssociativeArrays-}"
	unset SECcmdExportedAssociativeArrays
	
	# restore the exported arrays
	eval "`declare |sed -r "s%^${SECstrExportedArrayPrefix}([[:alnum:]_]*)='(.*)'$%\1=\2;%;tfound;d;:found"`"
	
	# remove the temporary variables representing exported arrays
	eval "`declare |sed -r "s%^(${SECstrExportedArrayPrefix}[[:alnum:]_]*)='(.*)'$%unset \1;%;tfound;d;:found"`"
	SECFUNCdbgFuncOutA;
}

function SECFUNCdtFmt() { #[time in seconds since epoch] otherwise current (now) is used
	local ldtTime=""
	local lbPretty=false
	local lbFilename=false
	local lbLogMessages=false
	local lbShowDate=true
	local lstrFmtCustom=""
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCdtFmt_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--pretty" ]];then #SECFUNCdtFmt_help
			lbPretty=true
		elif [[ "$1" == "--filename" ]];then #SECFUNCdtFmt_help to be used on filename
			lbFilename=true
		elif [[ "$1" == "--logmessages" ]];then #SECFUNCdtFmt_help compact for log messages
			lbLogMessages=true
		elif [[ "$1" == "--nodate" ]];then #SECFUNCdtFmt_help show only time, not the date
			lbShowDate=false
		elif [[ "$1" == "--fmt" ]];then #SECFUNCdtFmt_help <format> specify a custom format
			shift
			lstrFmtCustom="${1-}"
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	if [[ -n "${1-}" ]];then
		ldtTime="$1"
	fi
	
	local lstrFormat="%s.%N"
	if [[ -n "$lstrFmtCustom" ]];then
		lstrFormat="$lstrFmtCustom"
	else
		local lstrFmtDate=""
		if $lbPretty;then
			if $lbShowDate;then	lstrFmtDate="%d/%m/%Y ";fi
			lstrFormat="${lstrFmtDate}%H:%M:%S.%N"
		elif $lbFilename;then
			if $lbShowDate;then	lstrFmtDate="%Y_%m_%d-";fi
			lstrFormat="${lstrFmtDate}%H_%M_%S_%N"
		elif $lbLogMessages;then
			if $lbShowDate;then	lstrFmtDate="%Y%m%d+";fi
			lstrFormat="${lstrFmtDate}%H%M%S.%N"
		fi
	fi
	
	if [[ -n "$ldtTime" ]];then
		if ! date -d "@$ldtTime" "+$lstrFormat";then
			SECFUNCechoErrA "invalid ldtTime='$ldtTime'"
			return 1
		fi
	else
		# Now
		if ! date "+$lstrFormat";then
			SECFUNCechoErrA "invalid lstrFormat='$lstrFormat'"
			return 1
		fi
	fi
}

function SECFUNCdtNow() { 
	#date +"%s.%N"; 
	SECFUNCdtFmt
}
function SECFUNCdtTimeNow() { 
	SECFUNCdtFmt
}
function SECFUNCtimePretty() {
	#date -d "@`bc <<< "${_SECbugFixDate}+${1}"`" +"%H:%M:%S.%N"
	#date -d "@${1}" +"%H:%M:%S.%N"
	SECFUNCdtFmt --nodate --pretty ${1-}
}
function SECFUNCtimePrettyNow() {
	#SECFUNCtimePretty `SECFUNCdtNow`
	SECFUNCdtFmt --nodate --pretty
}
function SECFUNCdtTimePretty() {
	#date -d "@${1}" +"%d/%m/%Y %H:%M:%S.%N"
	SECFUNCdtFmt --pretty ${1-}
}
function SECFUNCdtTimePrettyNow() {
	#SECFUNCdtTimePretty `SECFUNCdtNow`
	SECFUNCdtFmt --pretty
}
function SECFUNCdtTimeToFileName() {
	#date -d "@${1}" +"%Y_%m_%d-%H_%M_%S_%N"
	SECFUNCdtFmt --filename ${1-}
}
function SECFUNCdtTimeToFileNameNow() {
	#SECFUNCdtTimeToFileName `SECFUNCdtNow`
	SECFUNCdtFmt --filename
}

function SECFUNCarraySize() { #usefull to prevent unbound variable error message
	local lstrArrayId="$1"
	if ! ${!lstrArrayId+false};then #this becomes false if unbound
		eval 'echo "${#'$lstrArrayId'[@]}"'
	else
		echo "0"
	fi
#	local laArrayId="$1"
#	local bWasNoUnset=false
#	if set -o |grep nounset |grep -q "on$";then
#		bWasNoUnset=true
#	fi
#	set +u
#	eval echo "\${#${laArrayId}[@]}"
#	if $bWasNoUnset;then
#		set -u
#	fi
}

function SECFUNCshowHelp() {
	local lbColorizeEcho=false
	local lbSort=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]];then #SECFUNCshowHelp_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "${1-}" == "--colorize" ]];then #SECFUNCshowHelp_help helps to colorize specific text
			shift
			lstrColorizeEcho="${1-}"
		
			lbColorizeEcho=true
		elif [[ "${1-}" == "--nosort" ]];then #SECFUNCshowHelp_help skip sorting the help options
			lbSort=false
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	# Colors: light blue=94, light yellow=93, light green=92, light cyan=96, light red=91
	local le=$(printf '\033') # Escape char to provide colors on sed on terminal
	local lsedColorizeOptionals='s,[[]([^]]*)[]],'$le'[0m'$le'[96m[\1]'$le'[0m,g' #!!!ATTENTION!!! this will match the '[' of color formatting and will mess things up if it is not the 1st to be used!!!
	local lsedColorizeRequireds='s,[<]([^>]*)[>],'$le'[0m'$le'[91m<\1>'$le'[0m,g'
	local lsedColorizeTheOption='s,([[:blank:]])(-?-[^[:blank:]]*)([[:blank:]]),'$le'[0m'$le'[92m\1\2\3'$le'[0m,g'
	local lsedTranslateEscn='s,\\n,\n,g'
	local lsedTranslateEsct='s,\\t,\t,g'
	if $lbColorizeEcho;then
		echo "$lstrColorizeEcho" \
			|sed -r "$lsedColorizeOptionals" \
			|sed -r "$lsedColorizeRequireds" \
			|sed -r "$lsedColorizeTheOption" \
			|sed -r "$lsedTranslateEscn" \
			|sed -r "$lsedTranslateEsct" \
			|cat #dummy to help coding...
		return
	fi
	
	local lstrFunctionNameToken="${1-}"
	
	local lastrFile=("$0")
	if [[ ! -f "${lastrFile[0]}" ]];then
		if [[ "${lstrFunctionNameToken:0:10}" == "SECFUNCvar" ]];then
			#TODO !!! IMPORTANT !!! this MUST be the only place on funcMisc.sh that funcVars.sh or anything from it is known about!!! BEWARE!!!!!!!!!!!!!!!!!! Create a validator on a package builder?
			lastrFile=("$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh")
		elif [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
			lastrFile=("${SECastrFuncFilesShowHelp[@]}")
		else
			# as help text are comments and `type` wont show them, the real script files is required...
			SECFUNCechoErrA "unable to access script file '${lastrFile[0]}'"
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
		local lstrFuncDesc=`grep -h "function ${lstrFunctionNameToken}[[:blank:]]*().*{.*#" "${lastrFile[@]}" |sed -r "s;^function ${lstrFunctionNameToken}[[:blank:]]*\(\).*\{.*#(.*);\1;"`
		if [[ -n "$lstrFuncDesc" ]];then
			echo -e "\t$lstrFuncDesc"
		fi
		
		lstrFunctionNameToken="${lstrFunctionNameToken}_"
	else
		echo "Help options for `basename "$0"`:"
	fi
	
	# SCRIPT OPTIONS or FUNCTION OPTIONS are taken care here
	cmdSort="cat" #dummy to not break code...
	if $lbSort;then
		cmdSort="sort"
	fi
	local lgrepNoCommentedLines="^[[:blank:]]*#"
	local lgrepMatchHelpToken="#${lstrFunctionNameToken}help"
	local lsedOptionsAndHelpText='s,.*\[\[(.*)\]\].*(#'$lstrFunctionNameToken'help.*),\1\2,'
	local lsedRemoveTokenOR='s,(.*"[[:blank:]]*)[|]{2}([[:blank:]]*".*),\1\2,' #if present
#	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'$le'[0m'$le'[92m\1'$le'[0m\t,g'
	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g'
	local lsedRemoveHelpToken='s,#'${lstrFunctionNameToken}'help,,'
#	local lsedColorizeRequireds='s,#'${lstrFunctionNameToken}'help ([^<]*)[<]([^>]*)[>],\1'$le'[0m'$le'[91m<\2>'$le'[0m,g'
#	local lsedColorizeOptionals='s,#'${lstrFunctionNameToken}'help ([^[]*)[[]([^]]*)[]],\1'$le'[0m'$le'[96m[\2]'$le'[0m,g'
	#local lsedAddNewLine='s".*"&\n"'
	cat "${lastrFile[@]}" \
		|egrep -v "$lgrepNoCommentedLines" \
		|grep -w "$lgrepMatchHelpToken" \
		|sed -r "$lsedOptionsAndHelpText" \
		|sed -r "$lsedRemoveTokenOR" \
		|sed -r "$lsedRemoveComparedVariable" \
		|sed -r "$lsedRemoveHelpToken" \
		|sed -r "$lsedColorizeOptionals" \
		|sed -r "$lsedColorizeRequireds" \
		|sed -r "$lsedColorizeTheOption" \
		|sed -r "$lsedTranslateEsct" \
		|$cmdSort \
		|sed -r "$lsedTranslateEscn" \
		|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		#|sed -r "$lsedAddNewLine"
}

function SECFUNCechoErr() { #echo error messages
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoErr_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoErr_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			echo "[`SECFUNCdtFmt --logmessages`]SECERROR:invalid option '$1'" >>/dev/stderr; 
			return 1
		fi
		shift
	done
	
	###### main code
	#echo "SECERROR[`SECFUNCdtNow`]: ${caller}$@" >>/dev/stderr; 
	local l_output="[`SECFUNCdtFmt --logmessages`]SECERROR: ${caller}$@"
	if $SEC_MsgColored;then
		echo -e " \E[0m\E[91m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
	echo "${l_output}" >>"$SECstrFileErrorLog"
}
#if [[ "$SEC_DEBUG" == "true" ]];then
#	SECFUNCechoErrA "test error message"
#	SECFUNCechoErr --caller "caller=funcMisc.sh" "test error message"
#fi

function _SECFUNCmsgCtrl() {
	local lstrMsgMode="$1"
	if [[ -f "${SECstrFileMessageToggle}.$lstrMsgMode.$$" ]];then
		local lstrForceMessage="`cat "${SECstrFileMessageToggle}.$lstrMsgMode.$$"`"
		if [[ "$lstrMsgMode" == "DEBUG" ]];then
			if [[ -f "${SECstrFileMessageToggle}.BASHDEBUG.$$" ]];then
				SECastrBashDebugFunctionIds=("`cat "${SECstrFileMessageToggle}.BASHDEBUG.$$"`")
				rm "${SECstrFileMessageToggle}.BASHDEBUG.$$" 2>/dev/null
			fi
		fi
		
		rm "${SECstrFileMessageToggle}.$lstrMsgMode.$$" 2>/dev/null
		
		if [[ -n "$lstrForceMessage" ]];then
			if [[ "$lstrForceMessage" == "on" ]];then
				eval SEC_$lstrMsgMode=true
			elif [[ "$lstrForceMessage" == "off" ]];then
				eval SEC_$lstrMsgMode=false
			fi				
		else
			local lstrVarTemp="SEC_${lstrMsgMode}"
			if ${!lstrVarTemp};then 
				eval SEC_$lstrMsgMode=false;	
			else 
				eval SEC_$lstrMsgMode=true;
			fi
		fi
	fi
}

function SECFUNCechoDbg() { #will echo only if debug is enabled with SEC_DEBUG
	# Log is stopped on the alias #set +x
	_SECFUNCmsgCtrl DEBUG
	if [[ "$SEC_DEBUG" != "true" ]];then # to not loose more time
		return 0
	fi
	
	###### options
	local caller=""
	local lstrFuncCaller=""
	local lbFuncIn=false
	local lbFuncOut=false
	local lbStopParams=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoDbg_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoDbg_help is the name of the function calling this one
			shift
			caller="${1}: "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoDbg_help <FUNCNAME> will show debug only if the caller function matches SEC_DEBUG_FUNC in case it is not empty
			shift
			lstrFuncCaller="${1}"
		elif [[ "$1" == "--funcin" ]];then #SECFUNCechoDbg_help just to tell it was placed on the beginning of a function
			lbFuncIn=true
		elif [[ "$1" == "--funcout" ]];then #SECFUNCechoDbg_help just to tell it was placed on the end of a function
			lbFuncOut=true
		elif [[ "$1" == "--" ]];then #SECFUNCechoDbg_help remaining params after this are considered as not being options
			lbStopParams=true;
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
		if $lbStopParams;then
			break;
		fi
	done
	
	###### main code
	local lnLength=0
	local lstrLastFuncId=""
	function SECFUNCechoDbg_updateStackVars(){
		lnLength="${#SECastrFunctionStack[@]}"
		if((lnLength>0));then
			lstrLastFuncId="${SECastrFunctionStack[lnLength-1]}"
		fi
		#echo "SECastrBashDebugFunctionIds=(${SECastrBashDebugFunctionIds[@]})" >>/dev/stderr
	}
	SECFUNCechoDbg_updateStackVars
	strFuncInOut=""
	declare -g -A _dtSECFUNCdebugTimeDelayArray
	if $lbFuncIn;then
		_dtSECFUNCdebugTimeDelayArray[$lstrFuncCaller]="`date +"%s.%N"`"
		strFuncInOut="Func-IN: "
		SECastrFunctionStack+=($lstrFuncCaller)
		SECFUNCechoDbg_updateStackVars
	elif $lbFuncOut;then
		local ldtNow="`date +"%s.%N"`"
		local ldtFuncDelay="-1"
		if [[ "${_dtSECFUNCdebugTimeDelayArray[$lstrFuncCaller]-0}" != "0" ]];then
			ldtFuncDelay=$(bc <<< "scale=9;$ldtNow-${_dtSECFUNCdebugTimeDelayArray[$lstrFuncCaller]}")
		fi
		strFuncInOut="Func-OUT: "
		if [[ "$ldtFuncDelay" != "-1" ]];then
			strFuncInOut+="(${ldtFuncDelay}s) "
		fi
		if((lnLength>0));then
			if [[ "$lstrFuncCaller" == "$lstrLastFuncId" ]];then
				unset SECastrFunctionStack[lnLength-1]
				SECFUNCechoDbg_updateStackVars
			else
				SECFUNCechoErrA "lstrFuncCaller='$lstrFuncCaller' expected lstrLastFuncId='$lstrLastFuncId'"
			fi
		else
			SECFUNCechoErrA "lstrFuncCaller='$lstrFuncCaller', SECastrFunctionStack lnLength='$lnLength'"
		fi
	fi
	if((lnLength>0));then
		local lnCount="$lnLength"
		if $lbFuncIn;then
			((lnCount--))
		fi
		if((lnCount>0));then
			strFuncStack="`echo "${SECastrFunctionStack[@]:0:lnCount}" |tr ' ' '.'`: "
		else
			strFuncStack=""
		fi
	else
		strFuncStack=""
	fi
	
	function SECFUNCechoDbg_isOnTheList(){
		local lstrFuncToCheck="${1-}"
		if((${#SECastrBashDebugFunctionIds[@]}>0));then
			local lnIndex
			for lnIndex in ${!SECastrBashDebugFunctionIds[@]};do
				local strBashDebugFunctionId="${SECastrBashDebugFunctionIds[lnIndex]}"
				if [[ "$strBashDebugFunctionId" == "+all" ]];then
					return 0
				fi
				if [[ "$lstrFuncToCheck" == "$strBashDebugFunctionId" ]];then
					return 0
				fi
			done
		fi
		return 1
	}
	
	local lbBashDebug=false
	if SECFUNCechoDbg_isOnTheList	$lstrFuncCaller || 
	   SECFUNCechoDbg_isOnTheList	$lstrLastFuncId;
	then
		lbBashDebug=true
	fi
	
#	local lbBashDebug=false
#	if((${#SECastrBashDebugFunctionIds[@]}>0));then
#		local lnIndex
#		for lnIndex in ${!SECastrBashDebugFunctionIds[@]};do
#			local strBashDebugFunctionId="${SECastrBashDebugFunctionIds[lnIndex]}"
#			if [[ "$lstrFuncCaller" == "$strBashDebugFunctionId" ]] ||
#			   [[ "$lstrLastFuncId" == "$strBashDebugFunctionId" ]];then
#				lbBashDebug=true
#				break
#			fi
#		done
#	fi

#	if $lbBashDebug;then
#		if $lbFuncOut;then
#			set +x #stop log
#		fi
#	fi

	local lbDebug=true
	
	if [[ "$SEC_DEBUG" != "true" ]];then
		lbDebug=false
	fi
	
	if [[ -n "$SEC_DEBUG_FUNC" ]];then
		if [[ "$lstrFuncCaller" != "$SEC_DEBUG_FUNC" ]];then
			lbDebug=false
		fi
	fi
	
	if $lbDebug;then
		local l_output="[`SECFUNCdtFmt --logmessages`]SECDEBUG: ${strFuncStack}${caller}${strFuncInOut}$@"
		if $SEC_MsgColored;then
			echo -e " \E[0m\E[97m\E[47m${l_output}\E[0m" >>/dev/stderr
		else
			echo "${l_output}" >>/dev/stderr
		fi
	fi
	
	# LAST CHECK ON THIS FUNCTION!!!
	if $lbBashDebug;then
		if $lbFuncOut;then
			if [[ -z "$lstrLastFuncId" ]];then
				set +x #end log
			else
				#if _SECFUNCechoDbg_isOnTheList	$lstrLastFuncId;then
					set -x
				#fi
			fi
		else
			set -x #start log
		fi
	fi
}

function SECFUNCechoWarn() { 
#	if [[ -f "${SECstrFileMessageToggle}.WARN.$$" ]];then
#		rm "${SECstrFileMessageToggle}.WARN.$$" 2>/dev/null
#		if $SEC_WARN;then SEC_WARN=false;	else SEC_WARN=true; fi
#	fi
	_SECFUNCmsgCtrl WARN
	if [[ "$SEC_WARN" != "true" ]];then # to not loose time
		return 0
	fi
	
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoWarn_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoWarn_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	###### main code
	#echo "SECWARN[`SECFUNCdtNow`]: ${caller}$@" >>/dev/stderr
	local l_output="[`SECFUNCdtFmt --logmessages`]SECWARN: ${caller}$@"
	if $SEC_MsgColored;then
		echo -e " \E[0m\E[93m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
}

function SECFUNCechoBugtrack() { 
#	if [[ -f "${SECstrFileMessageToggle}.BUGTRACK.$$" ]];then
#		rm "${SECstrFileMessageToggle}.BUGTRACK.$$" 2>/dev/null
#		if $SEC_BUGTRACK;then SEC_BUGTRACK=false;	else SEC_BUGTRACK=true; fi
#	fi
	_SECFUNCmsgCtrl BUGTRACK
	if [[ "$SEC_BUGTRACK" != "true" ]];then # to not loose time
		return 0
	fi
	
	###### options
	local caller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoBugtrack_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoBugtrack_help is the name of the function calling this one
			shift
			caller="${1}: "
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	###### main code
	local l_output="[`SECFUNCdtFmt --logmessages`]SECBUGTRACK: ${caller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[36m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
}

function SECFUNClockFileAllowedPid() { # defaults to return the allowed pid stored at SECstrLockFileAllowedPid
	local lbCheckOnly=false
	local lbCmpPid=false
	local lbWritePid=false
	local lbHasOtherPidsPidSkip=false
	local lbMustBeActive=false
	local lbCheckPid=false
	#!!! local lnPid= #do not set it!!! unbound will work
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNClockFileAllowedPid_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--hasotherpids" ]];then #SECFUNClockFileAllowedPid_help <skipPid> return true if there are other requests other than the skipPid (usually $$ of caller script)
			shift
			lnPid="${1-0}"
			
			lbHasOtherPidsPidSkip=true
			lbCheckPid=true
		elif [[ "$1" == "--cmp" ]];then #SECFUNClockFileAllowedPid_help <pid>
			shift
			lnPid="${1-0}"
			
			lbCmpPid=true
			lbCheckPid=true
		elif [[ "$1" == "--write" || "$1" == "--allow" ]];then #SECFUNClockFileAllowedPid_help <pid>
			shift
			lnPid="${1-0}"
			
			lbWritePid=true
			lbCheckPid=true
		elif [[ "$1" == "--active" ]];then #SECFUNClockFileAllowedPid_help the pid of other options must be active or it will return false
			lbMustBeActive=true
		elif [[ "$1" == "--check" ]];then #SECFUNClockFileAllowedPid_help <pid>
			shift
			lnPid="${1-0}"
			
			lbCheckOnly=true
			lbCheckPid=true
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	if $lbHasOtherPidsPidSkip && $lbMustBeActive;then
		SECFUNCechoWarnA "the option '--hasotherpids' ignores '--active'"
		lbMustBeActive=false
	fi
	
	function SECFUNClockFileAllowedPid_check(){
		local lnPid="${1-}"
		
		if [[ -z "$lnPid" ]];then
			SECFUNCechoErrA "lnPid='$lnPid' empty"
			return 1
		fi
		if [[ -n "`echo "$lnPid" |tr -d "[:digit:]"`" ]];then
			SECFUNCechoErrA "lnPid='$lnPid' is not a pid"
			return 1
		fi
		if(($1<1));then
			SECFUNCechoErrA "lnPid='$lnPid' < 1"
			return 1
		fi
		if(($1>SECnPidMax));then
			SECFUNCechoErrA "lnPid='$lnPid' > $SECnPidMax"
			return 1
		fi
		return 0
	}
	
	# pid check only
	if $lbCheckPid;then
		if ! SECFUNClockFileAllowedPid_check "$lnPid";then
			if $lbHasOtherPidsPidSkip;then
				# if pid is invalid all other pids available are valid to return 0
				lnPid=-1
			else
				return 1
			fi
		fi
		if [[ ! -d "/proc/$lnPid" ]];then
			if $lbMustBeActive;then
				return 1
			fi
			SECFUNCechoWarnA "pid '$lnPid' not found"
		fi
		if $lbCheckOnly;then
			return 0
		fi
	fi
			
	# other functionalities
	
	if $lbHasOtherPidsPidSkip;then
		# empty arrays create one empty line prevented with "^$"
		local lnCount="`cat "$SECstrLockFileRequests" "$SECstrLockFileAceptedRequests" 2>/dev/null |grep -wv "$lnPid" |grep -v "^$" |wc -l`"
		#echo "lnCount=$lnCount, `cat "$SECstrLockFileRequests" "$SECstrLockFileAceptedRequests"`" >>/dev/stderr
		if((lnCount>0));then
			return 0
		else
			return 1
		fi
	fi
	
	if $lbWritePid;then
		if [[ -f "$SECstrLockFileAllowedPid" ]];then
			SECFUNCechoWarnA "file SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid' exists, overwritting"
		fi
		if [[ ! -d "/proc/$lnPid" ]];then
			SECFUNCechoErrA "there is no such lnPid='$lnPid' running..."
			return 1
		fi
		echo -n "$lnPid" >"$SECstrLockFileAllowedPid"
		return 0
	fi

	local lnAllowedPid="-1"
	local lbAllowedIsValid=false
	if [[ -f "$SECstrLockFileAllowedPid" ]];then
		lnAllowedPid="`cat "$SECstrLockFileAllowedPid" 2>/dev/null`"
		if SECFUNClockFileAllowedPid_check $lnAllowedPid;then
			lbAllowedIsValid=true
		fi
	else
		SECFUNCechoWarnA "file not available SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid'"
	fi
		
	if $lbCmpPid;then
		if ! $lbAllowedIsValid;then
			return 1
		fi
		
		if((lnAllowedPid==lnPid));then
			return 0
		else
			return 1
		fi
	fi
	
	if $lbAllowedIsValid;then
		echo -n "$lnAllowedPid"
		return 0
	else
		echo -n "-1"
		return 1
	fi
	
	return 1
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

function SECFUNCparamsToEval() {
	local lstrToExec=""
	for lstrParam in "$@";do
		lstrToExec+="'$lstrParam' "
	done
  echo "$lstrToExec"
}
#function SECFUNCparamsToEval() {
#	###### options
##	bEscapeQuotes=false
##	bEscapeQuotesTwice=false
#	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
#		if [[ "$1" == "--help" ]];then #SECFUNCparamsToEval_help show this help
#			SECFUNCshowHelp ${FUNCNAME}
#			return
##		elif [[ "$1" == "--escapequotes" ]];then #SECFUNCparamsToEval_help quotes will be escaped like '\"'
##			bEscapeQuotes=true
##		elif [[ "$1" == "--escapequotestwice" ]];then #SECFUNCparamsToEval_help quotes will be escaped TWICE like '\\\"'
##			bEscapeQuotesTwice=true
#		else
#			SECFUNCechoErrA "invalid option $1"
#			return 1
#		fi
#		shift
#	done
#	
##	strEscapeQuotes=""
##	if $bEscapeQuotes;then
##		strEscapeQuotes='\'
##	fi
##	if $bEscapeQuotesTwice;then
##		strEscapeQuotes='\\\'
##	fi
#	
##	local strExec=""
##	while [[ -n "${1-}" ]];do
##  	if [[ -n "$strExec" ]];then
##	  	strExec="${strExec} ";
##  	fi
##  	strExec="${strExec}${strEscapeQuotes}\"$1${strEscapeQuotes}\"";
##  	shift;
##  done;
#	local lstrToExec=""
#	for lstrParam in "$@";do
#		lstrToExec+="'$lstrParam' "
#	done
#  echo "$lstrToExec"
#}

function SECFUNCsingleLetterOptions() { #Add this to the top of your options loop: eval "set -- `SECFUNCsingleLetterOptionsA "$@"`";\n\tIt will expand joined single letter options to separated ones like in '-abc' to '-a' '-b' '-c';\n\tOf course will only work with options that does not require parameters, unless the parameter is for the last option...\n\tThis way code maintenance is made easier by not having to update more than one place with the single letter option.
	local lstrCaller=""
	if [[ "${1-}" == "--caller" ]];then #SECFUNCsingleLetterOptions_help is the name of the function calling this one
		shift
		lstrCaller="${1-}: "
		shift
	fi
	
	# $1 will be bound
	local lstrOptions=""
	if [[ "${1:0:1}" == "-" && "${1:1:1}" != "-" ]];then
		for((nOptSingleLetterIndex=1; nOptSingleLetterIndex < ${#1}; nOptSingleLetterIndex++));do
			lstrOptions+="'-${1:nOptSingleLetterIndex:1}' "
		done
	else
		lstrOptions="'$1' "
	fi
	
	lstrOptions+="`SECFUNCparamsToEval "${@:2}"`"
	echo "$lstrOptions"
}

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
		echo "[`SECFUNCdtFmt --logmessages`]SECFUNCexec: caller=${caller}: $strExec" >>/dev/stderr
	fi
	
	if $bWaitKey;then
		echo -n "[`SECFUNCdtFmt --logmessages`]SECFUNCexec: caller=${caller}: press a key to exec..." >>/dev/stderr;read -n 1;
	fi
	
	local ini=`SECFUNCdtNow`;
  eval "$strExec" $omitOutput;nRet=$?
	local end=`SECFUNCdtNow`;
	
  SECFUNCechoDbgA "caller=${caller}: RETURN=${nRet}: $strExec"
  
	if $bShowElapsed;then
		echo "[`SECFUNCdtFmt --logmessages`]SECFUNCexec: caller=${caller}: ELAPSED=`SECFUNCbcPrettyCalc "$end-$ini"`s"
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
	local lnScale=2
	local lbRound=true
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCbcPrettyCalc_help --help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--cmp" ]];then #SECFUNCbcPrettyCalc_help output comparison result as "true" or "false"
			bCmpMode=true
		elif [[ "$1" == "--cmpquiet" ]];then #SECFUNCbcPrettyCalc_help return comparison as execution value for $? where 0=true 1=false
			bCmpMode=true
			bCmpQuiet=true
		elif [[ "$1" == "--scale" ]];then #SECFUNCbcPrettyCalc_help scale is the decimal places shown to the right of the dot
			shift
			lnScale=$1
		elif [[ "$1" == "--trunc" ]];then #SECFUNCbcPrettyCalc_help default is to round the decimal value
			lbRound=false
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	local lstrOutput="$1"
	
	if $lbRound;then
		lstrOutput="`bc <<< "scale=$((lnScale+1));$lstrOutput"`"
		
		local lstrSignal="+"
		if [[ "${lstrOutput:0:1}" == "-" ]];then
			lstrSignal="-"
		fi
		lstrOutput=`bc <<< "scale=${lnScale};\
			((${lstrOutput}*(10^${lnScale})) ${lstrSignal}0.5) / (10^${lnScale})"`
			
#		local lstrLcNumericBkp="$LC_NUMERIC"
#		export LC_NUMERIC="en_US.UTF-8" #force "." as decimal separator to make printf work...
#		lstrOutput="`printf "%0.${lnScale}f" "${lstrOutput}"`"
#		export LC_NUMERIC="$lstrLcNumericBkp"
#	else
#		lstrOutput="`bc <<< "scale=$lnScale;($lstrOutput)/1.0;"`"
	fi
	
	local lstrZeroDotZeroes="0"
	if((lnScale>0));then
		lstrZeroDotZeroes="0.`eval "printf '0%.0s' {1..$lnScale}"`"
	fi
	
	#TODO: what is this comment??? -> if delay is less than 1s prints leading "0" like "0.123" instead of ".123"
	local lstrOutput=`bc <<< "scale=$lnScale;x=($lstrOutput)/1; if(x==0) print \"$lstrZeroDotZeroes\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x";`
	
	
	if $bCmpMode;then
		if [[ "${lstrOutput:0:1}" == "1" ]];then
			if $bCmpQuiet;then
				return 0
			else
				echo -n "true"
			fi
		elif [[ "${lstrOutput:0:1}" == "0" ]];then
			if $bCmpQuiet;then
				return 1
			else
				echo -n "false"
			fi
		else
		  SECFUNCechoErrA "invalid result for comparison lstrOutput: '$lstrOutput'"
		  return 2
		fi
	else
		echo -n "$lstrOutput"
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
	
	# replaces all non-alphanumeric and non underscore with underscore
	#echo "$1" |tr '.-' '__' | sed 's/[^a-zA-Z0-9_]/_/g'
	echo "$1" |sed 's/[^a-zA-Z0-9_]/_/g'
}

function SECFUNCfixCorruptFile() { #usually after a blackout?
	echo "CORRUPT_DATA_FILE: backuping..." >>/dev/stderr
	cp -v "$1" "${1}.`SECFUNCdtFmt --filename`" >>/dev/stderr
	
	if [[ "`read -n 1 -p "CORRUPT_DATA_FILE: remove it (y/...) or manually fix it?" strResp;echo "$strResp"`" == "y" ]];then
		echo >>/dev/stderr
		rm -v "$1" >>/dev/stderr
	else
		echo >>/dev/stderr
		while [[ "`read -n 1 -p "CORRUPT_DATA_FILE: (waiting manual fix) ready to continue (y/...)?" strResp;echo "$strResp"`" != "y" ]];do
			echo >>/dev/stderr
		done
	fi
}

function SECFUNCdelay() { #The first parameter can optionally be a string identifying a custom delay like:\n\tSECFUNCdelay main --init;\n\tSECFUNCdelay test --init;
	declare -g -A _dtSECFUNCdelayArray
	
	local bIndexSetByUser=false
	local indexId="$FUNCNAME"
	# if is not an "--" option, it is the indexId
	if [[ -n "${1-}" ]] && [[ "${1:0:2}" != "--" ]];then
		bIndexSetByUser=true
		indexId="`SECFUNCfixIdA "$1"`"
		shift
	fi
	
	function _SECFUNCdelayValidateIndexIdForOption() { # validates if indexId has been set in the environment to use all other options other than --init
		local lbSimpleCheck=false
		if [[ "${1-}" == "--simplecheck" ]];then
			lbSimpleCheck=true
			shift
		fi
		if [[ -z "${_dtSECFUNCdelayArray[$indexId]-}" ]];then
			# programmer must have coded it somewhere to make that code clear
			#echo "--init [indexId=$indexId] needed before calling $1" >&2
			if ! $lbSimpleCheck;then
				SECFUNCechoErrA "the --init option is required before using option '$1' with [indexId=$indexId]"
				_SECFUNCcriticalForceExit
			fi
			return 1
		fi
	}
	
	local lbInit=false
	local lbGet=false
	local lbGetSec=false
	local	lbGetPretty=false
	local lbNow=false
	local lbCheckOrInit=false
	local l_b1stIsTrueOnCheckOrInit=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdelay_help --help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--1stistrue" ]];then #SECFUNCdelay_help to use with --checkorinit that makes 1st run return true
			l_b1stIsTrueOnCheckOrInit=true
		elif [[ "$1" == "--checkorinit" ]];then #SECFUNCdelay_help <delayLimit> will check if delay is above or equal specified at delayLimit;\n\t\twill then return true and re-init the delay variable;\n\t\totherwise return false
			shift
			local nCheckDelayAt=${1-}
			
			lbCheckOrInit=true
		elif [[ "$1" == "--checkorinit1" ]];then #SECFUNCdelay_help <delayLimit> like --1stistrue  --checkorinit 
			shift
			local nCheckDelayAt=${1-}
			
			lbCheckOrInit=true
			l_b1stIsTrueOnCheckOrInit=true
		elif [[ "$1" == "--init" ]];then #SECFUNCdelay_help set temp date storage to now
			lbInit=true
		elif [[ "$1" == "--get" ]];then #SECFUNCdelay_help get delay from init (is the default if no option parameters are set)
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
		elif [[ "$1" == "--getsec" ]];then #SECFUNCdelay_help get (only seconds without nanoseconds) from init
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
			lbGetSec=true
		elif [[ "$1" == "--getpretty" ]];then #SECFUNCdelay_help get full delay pretty time
			if ! _SECFUNCdelayValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
			lbGetPretty=true
		elif [[ "$1" == "--now" ]];then #SECFUNCdelay_help get time now since epoch in seconds
			lbNow=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	#if $lbCheckOrInit && ( $lbInit || $lbGet || $lbGetSec || $lbGetPretty || $lbNow );then
	if $lbCheckOrInit;then
		if $lbInit || $lbGet || $lbGetSec || $lbGetPretty || $lbNow;then
			SECFUNCechoErrA "--checkorinit must be used without other options"
			SECFUNCdelay --help |grep "\-\-checkorinit"
			_SECFUNCcriticalForceExit
		fi
	else
		if ! $lbInit;then
			if ! _SECFUNCdelayValidateIndexIdForOption "";then return 1;fi
		fi
	fi
	
	function SECFUNCdelay_init(){
		_dtSECFUNCdelayArray[$indexId]=`SECFUNCdtNow`
	}
	
	function SECFUNCdelay_get(){
		local now=`SECFUNCdtNow`
		local lstrOutput="`SECFUNCbcPrettyCalc "${now} - ${_dtSECFUNCdelayArray[$indexId]}"`"
		if $lbGetSec;then
			echo "$lstrOutput" |sed -r 's"^([[:digit:]]*)[.][[:digit:]]*$"\1"'
		elif $lbGetPretty;then
			local delay=`SECFUNCdelay $indexId --get`
			#SECFUNCtimePretty "$delay"
			local lnFixDate="(3600*3)" #to fix from: "31/12/1969 21:00:00.000000000" ...
			SECFUNCtimePretty "`SECFUNCbcPrettyCalc "$delay+$lnFixDate"`"
		else
			echo "$lstrOutput"
		fi
	}
	
	if $lbInit;then
		SECFUNCdelay_init
	elif $lbGet;then
		SECFUNCdelay_get
	elif $lbNow;then
		SECFUNCdtNow
  elif $lbCheckOrInit;then
		if [[ -z "$nCheckDelayAt" ]] || [[ -n `echo "$nCheckDelayAt" |tr -d '[:digit:].'` ]];then
			SECFUNCechoErrA "required valid <delayLimit>, can be float"
			SECFUNCdelay --help |grep "\-\-checkorinit"
			_SECFUNCcriticalForceExit
		fi
		
		if ! _SECFUNCdelayValidateIndexIdForOption --simplecheck "--checkorinit";then
			SECFUNCdelay_init
			if $l_b1stIsTrueOnCheckOrInit;then
				return 0
			fi
		fi
		
		local delay=`SECFUNCdelay_get`
		if SECFUNCbcPrettyCalc --cmpquiet "$delay>=$nCheckDelayAt";then
			SECFUNCdelay_init
			return 0
		else
			return 1
		fi
	else
		SECFUNCdelay_get #default
	fi
}

if [[ `basename "$0"` == "funcBase.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

SECFUNCarraysRestore #this is useful when SECFUNCarraysExport is used on parent shell

