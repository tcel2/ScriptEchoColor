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

# THIS FILE must contain everything that can be used everywhere without any problems; put here all core functions.

# TOP CODE
if ${SECinstallPath+false};then export SECinstallPath="`secGetInstallPath.sh`";fi; #to be faster
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcCore.sh") #no need for the array to be previously set empty
export SECstrFileLibFast="$SECinstallPath/lib/ScriptEchoColor/utils/funcFast.sh"
source "$SECstrFileLibFast";
###############################################################################

# FUNCTIONS

function SECFUNCerrCodeExplained() { #help <lnErrCode> describe error codes
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	local lbShowAll=false;
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCerrCodeExplained_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--showall" || "$1" == "-a" ]];then #SECFUNCerrCodeExplained_help dump all known error codes
			lbShowAll=true
		elif [[ "$1" == "--" ]];then #SECFUNCerrCodeExplained_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	
	local lnErrCode="${1-}"
	
	local lanErrCodes
	if $lbShowAll;then
		lanErrCodes=({1..255})
	else
		lanErrCodes=($lnErrCode)
	fi
	for lnErrCode in "${lanErrCodes[@]}";do
		local lstrMsg=""
		case "$lnErrCode" in
			1) lstrMsg="generic error";;
			2) lstrMsg="shell builtins usage error, ex.: permission, or some keyword is missing etc.";;
			126) lstrMsg="command is not executable, or permission problem";;
			127) lstrMsg="command not found";;
			129) lstrMsg="SIGHUP - hangup or death";; #128+n where n>=1
		  130) lstrMsg="SIGINT - interrupt";;
		  131) lstrMsg="SIGQUIT - quit";;
		  132) lstrMsg="SIGILL - illegal Instruction";; #        4       Core    Illegal Instruction
		  134) lstrMsg="SIGABRT - abort";; #       6       Core    Abort signal from abort(3)
		  136) lstrMsg="SIGFPE - floating point exception";; #        8       Core    Floating point exception
		  137) lstrMsg="SIGKILL - kill ";; #       9       Term    Kill signal
		  139) lstrMsg="SIGSEGV - segmentation fault";; #      11       Core    Invalid memory reference
		  141) lstrMsg="SIGPIPE - broken pipe";; #      13       Term    Broken pipe: write to pipe with no readers
		  142) lstrMsg="SIGALRM - timer signals alarm";; #      14       Term    Timer signal from alarm(2)
		  143) lstrMsg="SIGTERM - termination";; #      15       Term    Termination signal
			255) lstrMsg="invalid exit value, should have been in the range of 0 to 254";; # to 254 as 255 already means problem
			*) if ! $lbShowAll;then lstrMsg="User error code?";fi;;
		esac
		if [[ -n "$lstrMsg" ]];then echo "($lnErrCode) $lstrMsg";fi #stdout to be easily capturable
	done
}

strSECFUNCtrapErrCustomMsg="" # see SECFUNCexec for usage
function SECFUNCtrapErr() { #help <"${FUNCNAME-}"> <"${LINENO-}"> <"${BASH_COMMAND-}"> <"${BASH_SOURCE[@]-}">
	local lnRetTrap="$1";shift
	local lstrFuncName="$1";shift
	local lstrLineNo="$1";shift
	local lstrBashCommand="$1";shift
	local lastrBashSource=("$@"); #MUST BE THE LAST PARAM!!!
	
	#local lstrBashSourceListTrap="${BASH_SOURCE[@]-}";
	local lstrBashSourceListTrap="${lastrBashSource[@]}";
	
	function _SECFUNCtrapErr_addLine(){
		lstrErrorTrap+="${SECcharTab}${1}${SECcharNL}"
	}
	
#	strLnTab="`echo -e "\n\t"`";
	local lstrErrorTrap="[`date +"%Y%m%d+%H%M%S.%N"`] SECERROR='trap';${SECcharNL}"
#	local lstrSECFUNCtrapErrCustomMsgSimple="`echo "$strSECFUNCtrapErrCustomMsg" |tr ";" ":"`" # this is useful to avoid the ; translation to \n
	_SECFUNCtrapErr_addLine "strSECFUNCtrapErrCustomMsg='${strSECFUNCtrapErrCustomMsg-}';"
	_SECFUNCtrapErr_addLine "SECstrRunLogFile='${SECstrRunLogFile-}';"
	_SECFUNCtrapErr_addLine "SECastrFunctionStack='${SECastrFunctionStack[@]-}.${lstrFuncName-},LINENO=${lstrLineNo-}';"
#	_SECFUNCtrapErr_addLine "BASH_COMMAND='`tr '\n' ';' <<< "${lstrBashCommand-}"`';"
	_SECFUNCtrapErr_addLine "BASH_COMMAND='${lstrBashCommand-}';"
	_SECFUNCtrapErr_addLine "BASH_SOURCE[@]='(${lstrBashSourceListTrap-})';"
	_SECFUNCtrapErr_addLine "lnRetTrap='$lnRetTrap';"
	_SECFUNCtrapErr_addLine "ErrorDesc='`SECFUNCerrCodeExplained "$lnRetTrap"`';"
#	_SECFUNCtrapErr_addLine "SECstrDbgLastCaller='`   echo "${SECstrDbgLastCaller-}'"    |tr ';' ' '`;"
#	_SECFUNCtrapErr_addLine "SECstrDbgLastCallerIn='` echo "${SECstrDbgLastCallerIn-}'"  |tr ';' ' '`;"
#	_SECFUNCtrapErr_addLine "SECstrDbgLastCallerOut='`echo "${SECstrDbgLastCallerOut-}'" |tr ';' ' '`;"
	_SECFUNCtrapErr_addLine "SECstrDbgLastCaller='${SECstrDbgLastCaller-}';"
	_SECFUNCtrapErr_addLine "SECstrDbgLastCallerIn='${SECstrDbgLastCallerIn-}';"
	_SECFUNCtrapErr_addLine "SECstrDbgLastCallerOut='${SECstrDbgLastCallerOut-}';"
	
#	lstrErrorTrap+="pid='$$';PPID='$PPID';"
#	lstrErrorTrap+="pidCommand='`ps --no-header -p $$ -o cmd&&:`';"
#	lstrErrorTrap+="ppidCommand='`ps --no-header -p $PPID -o cmd&&:`';"
	local lnPid=$$
	local lnPidIndex=0
	while((lnPid>0));do
		#lstrErrorTrap+="pid[$lnPidIndex]='$lnPid';"
		#lstrErrorTrap+="CMD[$lnPidIndex]='`ps --no-header -p $lnPid -o cmd&&:`';"
		_SECFUNCtrapErr_addLine "pidCMD[`printf "%02d" $lnPidIndex`]='`ps --no-header -o pid,cmd -p $lnPid&&:`';"
		
		lnPid="`grep PPid /proc/$lnPid/status |cut -f2&&:`"
		((lnPidIndex++))&&:
	done
#	lstrErrorTrap+="`echo`"
	
	if [[ -n "$lstrBashSourceListTrap" ]] && [[ "${lstrBashSourceListTrap}" != *bash_completion ]];then
	 	# if "${BASH_SOURCE[@]-}" has something, it is running from a script, otherwise it is a command on the shell beying typed by user, and wont mess development...
	 	if [[ -f "${SECstrFileErrorLog-}" ]];then #SECstrFileErrorLog not set may happen once..
#			echo "$lstrErrorTrap" |tr -d '\n\t' >>"$SECstrFileErrorLog";
			local lstrCleanedLine="`echo "$lstrErrorTrap" |tr -d "${SECcharTab}${SECcharNL}"`"
			echo "$lstrCleanedLine" >>"$SECstrFileErrorLog"; # removed \n \t therefore one for the whole line must be re-added
		fi
#		echo "$lstrErrorTrap" |tr -d "${SECcharTab}${SECcharNL}" >&2;echo
#		echo "$lstrErrorTrap" |tr -d "\n\t" >&2;echo
#		echo "$lstrErrorTrap" |sed -r 's";"\n\t"g' >&2;
#		echo "$lstrErrorTrap" |tr -d '\n\t'
		echo "$lstrErrorTrap" >&2;
		return 1;
	fi;
}

# fix duplicity on array, the declare is required to make IFS work only on this line of code
IFS=$'\n' declare -a SECastrFuncFilesShowHelp=(`printf "%s\n" "${SECastrFuncFilesShowHelp[@]-}" |sort -u`) #TODO discover in what circunstances this array may not be filled when this line is reached?

# INITIALIZATIONS

function _SECFUNClogMsg() { #<logfile> <params become message>
	local lstrLogFile="$1"
	shift
	#echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$@;" >>"$lstrLogFile"
	echo " `date "+%Y%m%d+%H%M%S.%N"`;p$$;bp$BASHPID;bss$BASH_SUBSHELL;pp$PPID;$0;`ps --no-headers -o cmd -p $$`;$@;" >>"$lstrLogFile"
}
function _SECFUNCbugTrackExec() {
	#(echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;$@;" && "$@" 2>&1) >>"$SECstrBugTrackLogFile"
#	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$@;" >>"$SECstrBugTrackLogFile"
	local lstrBugTrackLogFile="/tmp/.SEC.BugTrack.`id -un`.log"
	_SECFUNClogMsg "$lstrBugTrackLogFile" "$@"
	"$@" 2>>"$lstrBugTrackLogFile" #do not protect with &&:, it would not help on fixing commands...
}
: ${SECstrFileCriticalErrorLog:="/tmp/.SEC.CriticalMsgs.`id -un`.log"}
export SECstrFileCriticalErrorLog
function _SECFUNCcriticalForceExit() {
	local lstrCriticalMsg1=" CRITICAL!!! "
	local lstrCriticalMsg2=" unable to continue!!! hit 'ctrl+c' to fix your code or report bug!!! "
#	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$lstrCriticalMsg" >>"/tmp/.SEC.CriticalMsgs.`id -u`.log"
	_SECFUNClogMsg "$SECstrFileCriticalErrorLog" "$lstrCriticalMsg1$lstrCriticalMsg2"
	if test -t 0;then
		while true;do
			#read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m CRITICAL!!! unable to continue!!! press 'ctrl+c' to fix your code or report bug!!! \E[0m"`" >&2
			read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m${lstrCriticalMsg1}\E[0m\E[31m\E[103m${lstrCriticalMsg2}\E[0m"`" >&2
			sleep 1
		done
	fi
	
	exit 1
}

function SECFUNCgetUserNameOrId(){ #help outputs username (prefered) or userid
	if [[ -n "${USER-}" ]];then
		echo "$USER"
		return
	fi
	
	local lstrUser="`_SECFUNCbugTrackExec strace id -un`"
	if [[ -n "$lstrUser" ]];then
		echo "$lstrUser"
		return
	fi
	
#	(echo -n " `date "+%Y%m%d+%H%M%S.%N"`,p$$;strace id -un;" && strace id -un 2>&1) >>"$SECstrBugTrackLogFile"
#	_SECFUNCbugTrackExec strace id -un
	
	# teoretically, this line should never be reached...
	_SECFUNCbugTrackExec strace id -u
}
function SECFUNCgetUserName(){ #help this is not an atomic function.
	local lstrUserName=`SECFUNCgetUserNameOrId`
	if [[ -z "`echo "$lstrUserName" |tr -d "[:digit:]"`" ]];then
		SECFUNCechoErrA "lstrUserName='$lstrUserName' must NOT be numeric"
		_SECFUNCcriticalForceExit
	fi
	echo "$lstrUserName"
}
function SECFUNCdefaultBoolValue(){ #help
	local lstrId="$1";
	local lstrValue="$2"
	
	if [[ "$lstrValue" != "true" && "$lstrValue" != "false" ]];then
		SECFUNCechoErrA "lstrValue='$lstrValue' must be \"boolean like\""
		_SECFUNCcriticalForceExit
	fi
	
	if ! ${!lstrId+false};then # if it is set, just fix if needed
		if [[ "${!lstrId}" != "true" && "${!lstrId}" != "false" ]];then
			SECFUNCechoWarnA "fixing lstrId='$lstrId' of value '${!lstrId}' should be \"boolean like\""
			declare -xg $lstrId="$lstrValue"
		fi
	else
		declare -xg $lstrId="$lstrValue"
	fi
	
#	: ${!${lstrId}:=$lstrValue}
#	if [[ "$SEC_DEBUG" != "true" ]]; then #compare to inverse of default value
#		export SEC_DEBUG=false # of course, np if already "false"
#	fi
}

#function _SECFUNCcheckIfIsArrayAndInit() { #help only simple array, not associative -A arrays...
#	#echo ">>>>>>>>>>>>>>>>${1}" >&2
#	if ${!1+false};then 
#		declare -a -x -g ${1}='()';
#	else
#		local lstrCheck="`declare -p "$1" 2>/dev/null`";
#		if [[ "${lstrCheck:0:10}" != 'declare -a' ]];then
#			echo "$1='${!1-}' MUST BE DECLARED AS AN ARRAY..." >&2
#			_SECFUNCcriticalForceExit
#		fi
#	fi
#}

if [[ -z "${SECstrTmpFolderBase-}" ]];then
	export SECstrTmpFolderBase="/dev/shm"
	if [[ ! -d "$SECstrTmpFolderBase" ]];then
		SECstrTmpFolderBase="/run/shm"
		if [[ ! -d "$SECstrTmpFolderBase" ]];then
			SECstrTmpFolderBase="/tmp"
			# is not fast as ramdrive (shm) and may be troublesome..
		fi
	fi
	if [[ -L "$SECstrTmpFolderBase" ]];then
		SECstrTmpFolderBase="`readlink -f "$SECstrTmpFolderBase"`" #required with `find` that would fail on symlink to a folder..
	fi
fi
if [[ -z "${SEC_TmpFolder-}" ]];then
	export SEC_TmpFolder="$SECstrTmpFolderBase/.SEC.`SECFUNCgetUserNameOrId`"
	#export SEC_TmpFolder="$SECstrTmpFolderBase/.SEC.`id -un`"
	if [[ ! -d "$SEC_TmpFolder" ]];then
		#mkdir "$SEC_TmpFolder" 2>>"$SECstrBugTrackLogFile"
		_SECFUNCbugTrackExec mkdir -p "$SEC_TmpFolder"
	fi
fi
#TODO ln -sT; -T prevents creation of symlink inside a folder by requiring folder to not exist; check other "ln.*-.*s" that could be improved with `-T`

#export SECstrTmpFolderUserName="$SECstrTmpFolderBase/.SEC.`SECFUNCgetUserNameOrId`"
#if [[ "$SEC_TmpFolder" != "$SECstrTmpFolderUserName" ]];then
#	# using user name
##	if ln -sT "$SEC_TmpFolder" "$SECstrTmpFolderUserName" 2>>"$SECstrBugTrackLogFile";then
#	if _SECFUNCbugTrackExec ln -sT "$SEC_TmpFolder" "$SECstrTmpFolderUserName";then
#		SEC_TmpFolder="$SECstrTmpFolderUserName"
#	fi
#fi

export SECstrFileMessageToggle="$SEC_TmpFolder/.SEC.MessageToggle"

#_SECFUNCcheckIfIsArrayAndInit SECastrBashDebugFunctionIds # If any item of the array is "+all", all functions will match.

export SECnFixDate="$((3600*3))" #to fix from: "31/12/1969 21:00:00.000000000" when used with `date -d` command

export SECstrFileErrorLog="$SEC_TmpFolder/.SEC.Error.log"

export SECstrExportedArrayPrefix="SEC_EXPORTED_ARRAY_"

#_SECFUNCcheckIfIsArrayAndInit SECastrFunctionStack

#export _SECbugFixDate="0" #seems to be working now...

: ${SECvarCheckScriptSelfNameParentChange:=true}
if [[ "$SECvarCheckScriptSelfNameParentChange" != "false" ]]; then
	export SECvarCheckScriptSelfNameParentChange=true
fi

: ${SECstrScriptSelfName=}
: ${SECstrScriptSelfNameParent=}

############################################
# IMPORTANT!!!!!!! do not use echoc or ScriptEchoColor on functions here, may become recursive infinite loop...
#############################################

######### EXTERNAL VARIABLES can be set by user #########
#: ${SEC_DEBUG:=false}
#if [[ "$SEC_DEBUG" != "true" ]]; then #compare to inverse of default value
#	export SEC_DEBUG=false # of course, np if already "false"
#fi
SECFUNCdefaultBoolValue SEC_DEBUG false

## this lets -x fully works
#: ${SEC_DEBUGX:=false}
#if [[ "$SEC_DEBUGX" != "true" ]]; then #compare to inverse of default value
#	export SEC_DEBUGX=false # of course, np if already "false"
#fi
SECFUNCdefaultBoolValue SEC_DEBUGX false # this lets -x fully works

#: ${SEC_WARN:=true}
#if [[ "$SEC_WARN" != "false" ]]; then #compare to inverse of default value
#	export SEC_WARN=true # of course, np if already "false"
#fi
SECFUNCdefaultBoolValue SEC_WARN false

#: ${SEC_BUGTRACK:=false}
#if [[ "$SEC_BUGTRACK" != "true" ]]; then #compare to inverse of default value
#	export SEC_BUGTRACK=false # of course, np if already "false"
#fi
SECFUNCdefaultBoolValue SEC_BUGTRACK false

#: ${SEC_MsgColored:=true}
#if [[ "$SEC_MsgColored" != "false" ]];then
#	export SEC_MsgColored=true
#fi
SECFUNCdefaultBoolValue SEC_MsgColored true

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

: ${SECnDaemonPid:=0} #set at SECFUNCuniqueLock
export SECnDaemonPid

: ${SECbDaemonWasAlreadyRunning:=false}
export SECbDaemonWasAlreadyRunning

###################### SETUP ENVIRONMENT

_SECdbgVerboseOpt=""
if [[ "$SEC_DEBUG" == "true" ]];then
	_SECdbgVerboseOpt="-v"
fi

#: ${SECnPidMax:=`cat /proc/sys/kernel/pid_max`}

# MAIN CODE
#export SECstrBugTrackLogFile="/tmp/.SEC.BugTrack.`id -u`.log"

function SECFUNCarraySize() { #help <lstrArrayId> usefull to prevent unbound variable error message; returns 1 if var is not an array and output 0; output to stdout the array size value
	# var init here
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarraySize_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--" ]];then #SECFUNCarraySize_help params after this are ignored as being these options
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
	local lstrArrayId="${1-}"
	
#	if [[ -z "$lstrArrayId" ]];then
#		SECFUNCechoWarnA "invalid lstrArrayId='$lstrArrayId'"
#		echo "0"
#		return 1
#	fi

#	if ! declare -p "$lstrArrayId" >>/dev/null;then
	if ! SECFUNCarrayCheck "$lstrArrayId";then
		SECFUNCechoErrA "invalid lstrArrayId='$lstrArrayId'"
		echo "0"
		return 1
	fi
	
	local sedGetVarModifiers="s@declare -([^[:blank:]]*) ${lstrArrayId}=.*@\1@"
	if ! declare -p "${lstrArrayId}" |sed -r "$sedGetVarModifiers" |egrep -qo "[Aa]";then
		SECFUNCechoWarnA "is not an array lstrArrayId='$lstrArrayId'"
		echo "0"
		return 1
	fi
	
#	if ! ${!lstrArrayId+false};then #this becomes false if unbound
#		eval 'echo "${#'$lstrArrayId'[@]}"'
#	else
#		SECFUNCechoWarnA "is not an array lstrArrayId='$lstrArrayId'"
#		echo "0" #if not array or invalid
#	fi
	declare -n laRef="$lstrArrayId"
	echo "${#laRef[@]}"
#	eval 'echo "${#'$lstrArrayId'[@]}"'
	
	return 0
}

function SECFUNCarrayContains() { #help <lstrArrayIdA> <lstrElementToMatch> return 0 if it contains element
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarrayContains_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCarrayContains_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCarrayContains_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	
	local lstrArrayIdA="${1-}"
	shift
	local lstrElementToMatch="${1-}"
	shift 
	
	if ! SECFUNCarrayCheck "$lstrArrayIdA";then
		SECFUNCechoErrA "invalid array lstrArrayIdA='$lstrArrayIdA'"
		return 1 #generic error indicating a problem that MUST be fixed by the user
	fi
	
	if((`SECFUNCarraySize "$lstrArrayIdA"`==0));then
#		SECFUNCechoWarnA "empty array lstrArrayIdA='$lstrArrayIdA'"
		###
		# SAY NOTHING!!! the contains check can return false (non 0) in case array is empty, is not even a warning...
		###
		return 4 #empty array
	fi
	
	local lstrArrayIdValA="${lstrArrayIdA}[@]"
	for lstrCheck in "${!lstrArrayIdValA}";do
#		echo "($lstrCheck) == ($lstrElementToMatch)" >&2
		if [[ "$lstrCheck" == "$lstrElementToMatch" ]];then
			return 0
		fi
	done
	
	#SECFUNCechoWarnA "element lstrElementToMatch='$lstrElementToMatch' not found."
	###
	# SAY NOTHING!!! the contains check can return false (non 0) in case element was not found, is not even a warning...
	###
	return 3 #a non conflicting return value indicating array does not contain element
}

function SECFUNCarrayCmp() { #help <lstrArrayIdA> <lstrArrayIdB> return 0 if both arrays are identical
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarrayCmp_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCarrayCmp_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCarrayCmp_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	
	local lstrArrayIdA="${1-}"
	shift
	local lstrArrayIdB="${1-}"
	shift 
	
	if ! SECFUNCarrayCheck "$lstrArrayIdA";then
		SECFUNCechoErrA "invalid array lstrArrayIdA='$lstrArrayIdA'"
		return 1
	fi
	
	if ! SECFUNCarrayCheck "$lstrArrayIdB";then
		SECFUNCechoErrA "invalid array lstrArrayIdB='$lstrArrayIdB'"
		return 1
	fi
	
	local lstrArrayIdValA="`declare -p ${lstrArrayIdA} |sed -r "s'$lstrArrayIdA''"`"
	local lstrArrayIdValB="`declare -p ${lstrArrayIdB} |sed -r "s'$lstrArrayIdB''"`"
	
	if [[ "$lstrArrayIdValA" != "$lstrArrayIdValB" ]];then
		return 1
	fi
	
	return 0
	
#	local lstrArrayIdValA="${lstrArrayIdA}[@]"
#	local lstrArrayIdValB="${lstrArrayIdB}[@]"
#	
#	local lbIsEqual=true
#	for strA in "${!lstrArrayIdValA}";do
#		for strB in "${!lstrArrayIdValB}";do
#			if [[ "$strA" != "$strB" ]];then
#				lbIsEqual=false;
#				break;
#			fi
#		done 
#	done
#	
#	if $lbIsEqual;then 
#		return 0; 
#	else 
#		return 1;
#	fi
}

function SECFUNCarrayCheck() { #help <lstrArrayId> check if this environment variable is an array, return 0 (true)
	# var init here
	local lstrExample="DefaultValue"
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarrayCheck_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCarrayCheck_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCarrayCheck_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
	
	# code here
	local lstrArrayId="${1-}"
	
	# valid env var check
	if ! declare -p "$lstrArrayId" >>/dev/null 2>&1;then
		# I opted to ommit this message, as when a var is just being set like `varset str=abc`, it is not a problem at all..
		SECFUNCechoDbgA "env var lstrArrayId='$lstrArrayId' not declared yet."
		return 1;
	fi
	
	# export it to easy tests below
	# THIS DOES NOT WORK...: eval "declare -x $lstrArrayId"&&:
	# THIS DOES NOT WORK...: declare -x $lstrArrayId&&:
	export "$lstrArrayId"&&: #eval "export $lstrArrayId"&&:
	if (($? != 0));then
		SECFUNCechoErrA "problem exporting env var related to lstrArrayId='$lstrArrayId'"
		return 1
	fi
	
	# declare is a much slower than export #local l_strTmp=`declare |grep "^$1=("`; 
	local lstrTmp="`export |grep "^declare -[Aa]x ${lstrArrayId}='("`";
 	if [[ -z "$lstrTmp" ]]; then
 		return 1;
 	fi;
 	
 	return 0;
}
#function SECFUNCarrayCheck() { #help <lstrArrayId> check if this environment variable is an array
#	# var init here
#	local lstrExample="DefaultValue"
#	local lastrRemainingParams=()
#	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
#		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
#		if [[ "$1" == "--help" ]];then #SECFUNCarrayCheck_help show this help
#			SECFUNCshowHelp $FUNCNAME
#			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCarrayCheck_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
#		elif [[ "$1" == "--" ]];then #SECFUNCarrayCheck_help params after this are ignored as being these options, and stored at lastrRemainingParams
#			shift #lastrRemainingParams=("$@")
#			while ! ${1+false};do	# checks if param is set
#				lastrRemainingParams+=("$1")
#				shift #will consume all remaining params
#			done
#		else
#			SECFUNCechoErrA "invalid option '$1'"
#			$FUNCNAME --help
#			return 1
##		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
##			SECFUNCechoErrA "invalid option '$1'"
##			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
#		fi
#		shift&&:
#	done
#	
#	# code here
#	local lstrArrayId="$1"
#	
#	# valid env var
#	if ! declare -p "$lstrArrayId" >>/dev/null;then
#		return 1;
#	fi

#	#local l_strTmp=`declare |grep "^$1=("`; #declare is a bit slower than export
#	#eval "export $lstrArrayId"
#	# export it to easy tests below
#	if ! declare -x $lstrArrayId;then
#		return 1
#	fi
#	
#	#export |grep "${lstrArrayId}=" >&2 #@@@R
#	#export >&2 #@@@R
#	
#	local l_strTmp="`export |grep "^declare -[Aa]x ${lstrArrayId}='("`";
# 	#if(($?==0));then
# 	if [[ -z "$l_strTmp" ]]; then
# 		return 1;
# 	fi;
# 	
# 	return 0;
##  local l_arrayCount=`eval 'echo ${#'$1'[*]}'`
##  if((l_arrayCount>1));then
##  	return 0;
## 	fi
## 	return 1
#}

function SECFUNCarrayClean() { #help <lstrArrayId> [lstrMatch] helps on regex cleaning array elements. If lstrMatch is empty, will clean empty elements (default behavior)
	# var init here
	local lstrArrayId=""
	local lstrMatch=""
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarrayClean_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCarrayClean_help <lstrExample> MISSING DESCRIPTION
#			shift
#			lstrExample="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCarrayClean_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
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
	
	# code here
	lstrArrayId="${1-}"
	shift
	lstrMatch="${1-}"
	
#	if ! declare -p "$lstrArrayId" >>/dev/null;then
#		SECFUNCechoErrA "invalid lstrArrayId='$lstrArrayId'"
#		echo "0"
#		return 1
#	fi
	if ! SECFUNCarrayCheck "$lstrArrayId";then
		SECFUNCechoErrA "invalid lstrArrayId='$lstrArrayId'"
		echo "0"
		return 1
	fi
	
#	echo "TST:$lstrArrayId" >&2
#	declare -p $lstrArrayId >&2
	
	#set -x
	local lstrArrayAllElements="${lstrArrayId}[@]"
	local lstrArrayCopyTmp=("${!lstrArrayAllElements}")
	#local lstrArraySize="#${lstrArrayId}[@]"
#	echo "TST: ${lstrArrayCopyTmp[@]}" >&2
	#local lnSize="${!lstrArraySize}"
	local lnIndex=0
	for strTmp in "${lstrArrayCopyTmp[@]}";do #for strTmp in "${!lstrArrayAllElements}";do
#			echo "strTmp='$strTmp' $lnIndex" >&2
#			declare -p "$lstrArrayId" >&2
			
		local lbUnset=false
		if [[ -z "$lstrMatch" ]];then
			if [[ -z "$strTmp" ]];then
				lbUnset=true
			fi
		elif [[ "$strTmp" =~ $lstrMatch ]];then
			lbUnset=true
		fi
		
		if $lbUnset;then
			#eval "unset $lstrArrayId[$lnIndex]"
			unset lstrArrayCopyTmp[$lnIndex]
#			declare -p "$lstrArrayId" >&2
		fi
		((lnIndex++))&&:
	done
	#set +x
	
	#declare -p lstrArrayCopyTmp >&2 #@@@R
	if((${#lstrArrayCopyTmp[@]}==0));then
		eval "$lstrArrayId"'=()'
	else
		# the remaining elements index values will be kept (ex.: 1 8 12 13 15), this fixed it
		#eval "$lstrArrayId=(\"\${$lstrArrayId[@]-}\")"
		eval "$lstrArrayId"'=("${lstrArrayCopyTmp[@]}")'
	#	eval "$lstrArrayId=(\"\${${!lstrArrayAllElements}}\")"
	fi
	
	return 0 # important to have this default return value in case some non problematic command fails before returning
}

: ${SECstrBashSourceFiles:=}
export SECstrBashSourceFiles
#_SECFUNCcheckIfIsArrayAndInit SECastrBashSourceFilesPrevious

: ${SECbBashSourceFilesShow:=false}
export SECbBashSourceFilesShow

: ${SECbBashSourceFilesForceShowOnce:=false}
export SECbBashSourceFilesForceShowOnce

function SECFUNCbashSourceFiles() { #help
	if ! $SECbBashSourceFilesForceShowOnce;then
		if ! $SECbBashSourceFilesShow;then
			return
		fi
		if ! ($SEC_DEBUG || $SEC_WARN || $SEC_BUGTRACK);then
			return
		fi
	fi
	SECbBashSourceFilesForceShowOnce=false
	
	if [[ "${SECastrBashSourceFilesPrevious[@]-}" == "${BASH_SOURCE[@]-}" ]];then
		#TODO this doesnt seem to help to speed up?
		echo "$SECstrBashSourceFiles"
		return
	fi
	SECastrBashSourceFilesPrevious=("${BASH_SOURCE[@]-}")
	
	local lstrSourceFileList=""
	if((`SECFUNCarraySize BASH_SOURCE`>0));then
		for lnSourceFileIndex in "${!BASH_SOURCE[@]}";do
#			echo ">>>lnSourceFileIndex=$lnSourceFileIndex,${#BASH_SOURCE[@]}-1,${BASH_SOURCE[lnSourceFileIndex]}" >&2
			#if(( lnSourceFileIndex == (${#BASH_SOURCE[@]}-1) ));then #last is always this script...
			if(( lnSourceFileIndex == 0 ));then #last shown, and 1st on loop, is always this script...
				continue; #so skip it
			fi
			local lstrSourceFile="${BASH_SOURCE[lnSourceFileIndex]}"
			if [[ -n "$lstrSourceFileList" ]];then
				lstrSourceFileList=">$lstrSourceFileList"
			fi
			lstrSourceFileList="`basename "$lstrSourceFile"`$lstrSourceFileList"
		done
	fi
	SECstrBashSourceFiles="$lstrSourceFileList"
	echo "$lstrSourceFileList"
}

function _SECFUNCfillDebugFunctionPerFileArray() {
	local lsedOnlyFunctions="s'^function (SECFUNC[[:alnum:]_]*).*'\1'"
	local lastrLibs=(Core Base Misc Vars)
	local lstrLib 
	local lstrFunctionId
	for lstrLib in "${lastrLibs[@]}";do
		local lastrFuncList=(`grep "^function SECFUNC" "$SECinstallPath/lib/ScriptEchoColor/utils/func$lstrLib.sh" |sed -r "$lsedOnlyFunctions" |sort`)
#		echo "$lstrFuncList" >&2
#			|while read lstrFunctionId;do
		for lstrFunctionId in ${lastrFuncList[@]};do
			if [[ -n "${SECastrDebugFunctionPerFile[$lstrFunctionId]-}" ]];then
				if [[ "${SECastrDebugFunctionPerFile[$lstrFunctionId]-}" != "$lstrLib" ]];then
					SECFUNCechoErrA "$lstrFunctionId (defined at $lstrLib) was already defined at ${SECastrDebugFunctionPerFile[$lstrFunctionId]}"
					_SECFUNCcriticalForceExit
				fi
			fi
			SECastrDebugFunctionPerFile[$lstrFunctionId]="$lstrLib"
		done
	done
}
#SECastrDebugFunctionPerFile[SECstrBashSourceIdDefault]="${BASH_SOURCE[@]}" #easy trick
#SECastrDebugFunctionPerFile[SECstrBashSourceIdDefault]="${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}" #easy trick
#SECastrDebugFunctionPerFile[SECstrBashSourceIdDefault]="`basename "$0"`" #easy trick
_SECFUNCfillDebugFunctionPerFileArray

function SECFUNCexportFunctions() { #help 
	declare -F \
		|grep "SECFUNC" \
		|sed 's"declare .* SECFUNC"export -f SECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f SECFUNC"
	
	# private ones may not be present yet
	declare -F \
		|grep "pSECFUNC" \
		|sed 's"declare .* pSECFUNC"export -f pSECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f pSECFUNC" &&:
	
	return 0
}

export SECstrUserHomeConfigPath="$HOME/.ScriptEchoColor"
if [[ ! -d "$SECstrUserHomeConfigPath" ]]; then
  mkdir "$SECstrUserHomeConfigPath"
fi

export SECbShowHelpSummaryOnly;: ${SECbShowHelpSummaryOnly:=false}; #help shows only summary when calling SECFUNCshowHelp
function SECFUNCshowHelp() { #help [$FUNCNAME] if function name is supplied, a help will be shown specific to such function.
#SECFUNCshowHelp_help \tOtherwise a help will be shown to the script file as a whole.
#SECFUNCshowHelp_help \tMultiline help is supported.
#SECFUNCshowHelp_help \tbasically help lines must begin with #help or #FunctionName_help, see examples on scripts.
	SECFUNCdbgFuncInA;
	local lbSort=false
	local lstrScriptFile="$0"
	local lstrColorizeEcho=""
	local lbOnlyVars=false
#	local lbAll=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]];then #SECFUNCshowHelp_help show this help
			SECFUNCshowHelp --nosort ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "${1-}" == "--colorize" || "${1-}" == "-c" ]];then #SECFUNCshowHelp_help <lstrColorizeEcho> helps to colorize specific text
			shift
			lstrColorizeEcho="${1-}"
		elif [[ "${1-}" == "--sort" ]];then #SECFUNCshowHelp_help sort the help options
			lbSort=true
		elif [[ "${1-}" == "--nosort" ]];then #SECFUNCshowHelp_help skip sorting the help options (is default now)
			lbSort=false
#		elif [[ "${1-}" == "--all" || "${1-}" == "-a" ]];then #SECFUNCshowHelp_help will show every help commented line, not only for options or functions
#			lbAll=true
		elif [[ "${1-}" == "--file" ]];then #SECFUNCshowHelp_help <lstrScriptFile> set the script file to gather help data from
			shift
			lstrScriptFile="${1-}"
		elif [[ "${1-}" == "--onlyvars" ]];then #SECFUNCshowHelp_help show help only about the exported variables safely modifyiable by users
			lbOnlyVars=true
		elif [[ "$1" == "--checkMissPlacedFunctionHelps" ]];then #SECFUNCshowHelp_help list all functions help tokens on *.sh scripts recursively
			grep "#[[:alnum:]]*_help " * --include="*.sh" -rIoh
			SECFUNCdbgFuncOutA;return
		elif [[ "${1-}" == "--dummy-selftest" ]];then #SECFUNCshowHelp_help ([lstrScriptFile] [lstrColorizeEcho] <lbSort> <lbOnlyVars> this is not an actual option, it is just to show self tests only...)
			#SECFUNCshowHelp_help (This is the multiline test at an option.)
			:
		else
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	##########################
	### The number of sed selections must be equal on the optionals and requireds.
	##########################
	# Colors: light blue=94, light yellow=93, light green=92, light cyan=96, light red=91
	#local le=$(printf '\033') # Escape char to provide colors on sed on terminal
	local lsedMatchRequireds='(.)([<])([^>]*)([>])'
#	local lsedMatchOptionals='([[])([^]]*)([]])'
#	local lsedMatchOptionals='([[])([^0-9]{0,1}+[^]]*)([]])' #color codes are `SECcharEsc + '[' + digit... + m`. Variables always begin with alpha char. So deny 0-9 matches that mean colors.
#	local lsedMatchOptionals="([^${SECcharEsc}][[])([a-zA-Z][^]]*)([]])" #color codes are `SECcharEsc + '[' + digit... + m`, so deny SECcharEsc before '['. Variables always begin with alpha char, so require alpha after '['.
	local lsedMatchOptionals="([^${SECcharEsc}])([[])([a-zA-Z][^]]*)([]])" #color codes are `SECcharEsc + '[' + digit... + m`, so deny SECcharEsc before '['. Variables always begin with alpha char, so require alpha after '['.
#	local lsedMatchOptionals="[^${SECcharEsc}].([[])([^]]*)([]])"
#	local lsedColorizeOptionals="s,$lsedMatchOptionals,${SECcolorCancel}${SECcharEsc}[96m[\2]${SECcolorCancel},g" #!!!ATTENTION!!! this will match the '[' of color formatting and will mess things up if it is not the 1st to be used!!!
	local lsedColorizeOptionals="s,$lsedMatchOptionals,${SECcolorCancel}${SECcolorLightCyan}\1[\3${SECcolorLightCyan}]${SECcolorCancel},g" #!!!ATTENTION!!! this will match the '[' of color formatting and will mess things up if it is not the 1st to be used!!!
	local lsedColorizeRequireds="s,$lsedMatchRequireds,${SECcolorCancel}${SECcolorLightRed}\1<\3${SECcolorLightRed}>${SECcolorCancel},g"
	local lsedMatchOptiId="([[:blank:]])(-?-[^[:blank:]]*)([[:blank:]])"
	local lsedColorizeTheOptiId="s,${lsedMatchOptiId},${SECcolorCancel}${SECcolorLightGreen}\1\2\3${SECcolorCancel},g"
	local lsedTranslateEscn='s,\\n,\n,g'
	local lsedTranslateEsct='s,\\t,\t,g'

	function _SECFUNCshowHelp_SECFUNCmatch(){
		#read lstrLine
		IFS= read -r lstrLine #IFS= required to prevent skipping \t, and -r required to not interpret "\"
		#IFS=$'\n' read lstrLine
		
		local lstrMode="$1";shift
		local lstrMatch="$1";shift
		
		local lstrColorClosing="${SECcolorLightRed}" #"req"
		if [[ "$lstrMode" == "opt" ]];then
			lstrColorClosing="${SECcolorLightCyan}"
		fi
		
		local lstrVarId="`echo "$lstrLine" |sed -r "s,.*$lstrMatch.*,\3,"`"
		local lbShowValue=true
		if [[ "$lstrVarId" == "FUNCNAME" ]];then
			lbShowValue=false
		fi
		if ${!lstrVarId+false};then #if variable, stored into lstrVarId, is NOT set (if it is set the result is empty that evaluates to true)
			lbShowValue=false
		fi
		#if ! ${!lstrVarId+false};then
		if $lbShowValue;then
			#echo "$lstrLine" |sed -r "s,$lstrMatch,\1\2='${SECcharEsc}[5m${!lstrVarId}${SECcharEsc}[25m'\3,"
#			echo "$lstrLine">&2
#			echo "s,$lstrMatch,\1\2='${SECcolorLightYellow}${!lstrVarId-}${SECcolorLightRed}'\3," >&2
#			echo "$lstrLine" |sed -r "s${SECsedTk}$lstrMatch${SECsedTk}\1\2='${SECcolorLightYellow}${!lstrVarId-}${SECcolorLightRed}'\3${SECsedTk}"
			local lsedExtractValue='s@[^=]*="(.*)"@\1@'
			local lstrVarIdValue="$(declare -p $lstrVarId |sed -r "$lsedExtractValue")"
			echo "$lstrLine" |sed -r "s${SECsedTk}${lstrMatch}${SECsedTk}\1\2\3='${SECcolorLightYellow}${lstrVarIdValue}${lstrColorClosing}'\4${SECcolorCancel}${SECsedTk}"
#			echo "$lstrLine" |sed -r "s${SECsedTk}${lstrMatch}${SECsedTk}\1\2='${SECcolorCancel}${lstrVarIdValue}${SECcolorLightRed}'\3${SECsedTk}"
		else
			echo "$lstrLine"
		fi
	}
	function _SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues(){
		local lstrLineMain;
		#while	read lstrLineMain;do
		while	IFS= read -r lstrLineMain;do #IFS= required to prevent skipping /t
		#while	IFS=$'\n' read lstrLineMain;do
			#echo "lstrLine='$lstrLine'" >&2
			echo "$lstrLineMain" \
				|_SECFUNCshowHelp_SECFUNCmatch opt "$lsedMatchOptionals" \
				|_SECFUNCshowHelp_SECFUNCmatch req "$lsedMatchRequireds" 
		done
	}
	
	######################### a text line passed to --colorize
	if [[ -n "${lstrColorizeEcho}" ]];then
		echo "$lstrColorizeEcho" \
			|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
			|sed -r "$lsedColorizeOptionals" \
			|sed -r "$lsedColorizeRequireds" \
			|sed -r "$lsedColorizeTheOptiId" \
			|sed -r "$lsedTranslateEscn" \
			|sed -r "$lsedTranslateEsct" \
			|cat #dummy to help coding...
		SECFUNCdbgFuncOutA;return
	fi
	
	local lstrFunctionNameToken="${1-}"
	
#	if [[ ! -f "$lstrScriptFile" ]];then
#		SECFUNCechoErrA "invalid lstrScriptFile='$lstrScriptFile'"
#		SECFUNCdbgFuncOutA;return 1
#	fi
	
	local lastrFile=("$lstrScriptFile")
	if [[ ! -f "${lastrFile[0]}" ]] || [[ "`basename "${lastrFile[0]}"`" == "bash" ]];then
#		if [[ "${lstrFunctionNameToken:0:10}" == "SECFUNCvar" ]];then
#			#TODO !!! IMPORTANT !!! this MUST be the only place on funcMisc.sh that funcVars.sh or anything from it is known about!!! BEWARE!!!!!!!!!!!!!!!!!! Create a validator on a package builder?
#			lastrFile=("$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh")
#		elif [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
		if [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
			lastrFile=("${SECastrFuncFilesShowHelp[@]}")
		else
			# as help text are comments and `type` wont show them, the real script files is required...
			SECFUNCechoErrA "unable to access script file '${lastrFile[0]}' (obs.: lstrFunctionNameToken='$lstrFunctionNameToken')"
			SECFUNCdbgFuncOutA;return 1
		fi
		#fix duplicity on array
		#SECstrIFSbkp="$IFS";IFS=$'\n';lastrFile=(`printf "%s\n" "${lastrFile[@]}" |sort -u`);IFS="$SECstrIFSbkp"
		IFS=$'\n' declare -a lastrFile=(`printf "%s\n" "${lastrFile[@]}" |sort -u`) #the declare is to force IFS be set only for this line of code
	fi
	
#	local lgrepNoFunctions="^[[:blank:]]*function .*"
	local lbFunctionMode=false
	if [[ -n "$lstrFunctionNameToken" ]];then
		if [[ -n `echo "$lstrFunctionNameToken" |tr -d '[:alnum:]_'` ]];then
			SECFUNCechoErrA "invalid prefix '$lstrFunctionNameToken'"
			SECFUNCdbgFuncOutA;return 1
		fi
		
		local lstrRegexFuncMatch="^[[:blank:]]*function ${lstrFunctionNameToken}[[:blank:]]*().*{.*#help"
		local lstrFileNameWithMatch=""
		for lstrFile in "${lastrFile[@]}";do
			if grep -q "$lstrRegexFuncMatch" "$lstrFile";then
#				lstrFileNameWithMatch=" at `basename "$lstrFile"`"
				lstrFileNameWithMatch=" at '$lstrFile'"
				break;
			fi
		done
		
		echo -e "\t\E[0m\E[0m\E[94m$lstrFunctionNameToken\E[0m\E[93m()\E[0m${lstrFileNameWithMatch}"
		
		######################### function description
		local lstrFuncDesc="`grep -h "$lstrRegexFuncMatch" "${lastrFile[@]}" |sed -r "s;^function ${lstrFunctionNameToken}[[:blank:]]*\(\).*\{.*#help (.*);\1;"`"
		if [[ -n "$lstrFuncDesc" ]];then
			echo -e "\t$lstrFuncDesc" \
				|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
				|sed -r "$lsedColorizeOptionals" \
				|sed -r "$lsedColorizeRequireds" \
				|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		fi
		
		lstrFunctionNameToken="${lstrFunctionNameToken}_"
#		lgrepNoFunctions="^$" #will actually "help?" by removing empty lines
		
		lbFunctionMode=true;
	fi
	
	if ! $SECbShowHelpSummaryOnly;then
		#################### environment variables that user can modify safely
		# only if the help is being shown to the entire script file
		local lstrRegexMatchEnvVars="^(export)[[:blank:]]*([[:alnum:]_]*).*#help (.*)"
		if ! $lbFunctionMode;then
			IFS=$'\n' read -d '' -r -a lastrUserEnvVarList < <(
				sed -n -r "s${SECsedTk}${lstrRegexMatchEnvVars}${SECsedTk}\2${SECsedTk} p" "$lstrScriptFile")&&:
	#		declare -p lastrUserEnvVarList
		
			if((`SECFUNCarraySize lastrUserEnvVarList`>0));then
				local lstrUserEnvVarsOutput="`
					egrep "$lstrRegexMatchEnvVars" "$lstrScriptFile" \
						|sed -r "s${SECsedTk}${lstrRegexMatchEnvVars}${SECsedTk}\1 \2 \3${SECsedTk}"`"
	#					|sed -r "s${SECsedTk}${lstrRegexMatchEnvVars}${SECsedTk}\t${SECcolorYellow}\1 ${SECcolorCyan}\2 ${SECcolorGreen}\3${SECcolorCancel}${SECsedTk}"`"
	#						-e "s${SECsedTk}.*${SECsedTk}\t&${SECsedTk}" \
	#						-e "s${SECsedTk}.*${SECsedTk}&${SECcolorCancel}${SECsedTk}"
	#						-e "s${SECsedTk}(.*)[[:blank:]]*(#help)[[:blank:]]*(.*)${SECsedTk}\1 ${SECcolorGreen}\3${SECsedTk}" \
	#						-e "s${SECsedTk}${lstrRegexMatchEnvVars}${SECsedTk}${SECcolorYellow}\1${SECcolorCyan} \2 \3${SECsedTk}" \

	#						-e "s${SECsedTk}(export)[ ]*([[:alnum:]_]*)${SECsedTk}${SECcolorYellow}\1${SECcolorCyan} \2${SECsedTk}" \
			
				echo "Help about external variables accepted by this script:"
				for lstrUserEnvVar in "${lastrUserEnvVarList[@]}";do
					local lstrOutEnvVarHelp="`echo "$lstrUserEnvVarsOutput" \
						|sed -n -r "s${SECsedTk}^export $lstrUserEnvVar (.*)${SECsedTk}\1${SECsedTk} p"`"
					
					local lstrCfgVarHelp=""
					if [[ "$lstrUserEnvVar" =~ ^CFG.* ]];then
						lstrCfgVarHelp=" (must be set using --cfg option)"
					fi
					
					echo "${SECcharTab}${SECcolorCyan}$lstrUserEnvVar${SECcolorYellow}=${SECcolorLightYellow}'${!lstrUserEnvVar-}' ${SECcolorGreen}${lstrOutEnvVarHelp}${lstrCfgVarHelp}${SECcolorCancel}"
				done
				echo
			fi
		
			if $lbOnlyVars;then
				SECFUNCdbgFuncOutA;return 0
			fi
		
			echo "Help options for `basename "$lstrScriptFile"`:"
		fi
	
		######################### SCRIPT OPTIONS or FUNCTION OPTIONS are taken care here
		cmdSort="cat" #dummy to not break code...
		if $lbSort;then
			cmdSort="sort"
		fi
		#local lgrepNoCommentedLines="^[[:blank:]]*#"
		local lstrHelpToken="${lstrFunctionNameToken}help"
		#local lgrepNoCommentedLines="^[[:blank:]]*#[^h][^e][^l][^p]"
		#local lgrepNoCommentedLines="^[[:blank:]]*#`echo "$lstrHelpToken" |sed 's"."[^&]"g'`" #negates each letter
		#if $lbAll;then lgrepNoCommentedLines="";fi
		#local lgrepMatchHelpToken="#${lstrHelpToken}|^[[:blank:]]*#help" #will also include simplified special help lines
		#local lgrepMatchHelpToken="#${lstrHelpToken}|^[[:blank:]]*#help"
		local lgrepMatchHelpToken="#${lstrHelpToken}"
		local lgrepNoInvalidHelps="[[:blank:]]*#.*#${lstrHelpToken}" #preceding a help comment, must be working (non commented) code
		local lgrepNoUserEnvVars="$lstrRegexMatchEnvVars"
		local lgrepNoFunctions="^[[:blank:]]*function .*"
		local lsedOptionsText='.*\[\[(.*)\]\].*'
	#	if $lbAll;then lsedOptionsText=".*";fi
		local lsedOptionsAndHelpText="s,${lsedOptionsText}(#${lstrFunctionNameToken}help.*),\1\2,"
		local lsedRemoveTokenOR='s,(.*"[[:blank:]]*)[|]{2}([[:blank:]]*".*),\1\2,' #if present
	#	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'${SECcharEsc}'[0m'${SECcharEsc}'[92m\1'${SECcharEsc}'[0m\t,g'
		#local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g'
		local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'${SECcolorCancel}${SECcolorLightGreen}'\1'${SECcolorCancel}'\t,g' #some options may not have -- or -, so this redundantly colorizes all options for sure
		#local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[-_[:alnum:]{}]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g' #some options may not have -- or -, so this redundantly colorizes all options for sure
		local lsedRemoveHelpToken='s,#'${lstrFunctionNameToken}'help,,'
	#	local lsedColorizeRequireds='s,#'${lstrFunctionNameToken}'help ([^<]*)[<]([^>]*)[>],\1'${SECcharEsc}'[0m'${SECcharEsc}'[91m<\2>'${SECcharEsc}'[0m,g'
	#	local lsedColorizeOptionals='s,#'${lstrFunctionNameToken}'help ([^[]*)[[]([^]]*)[]],\1'${SECcharEsc}'[0m'${SECcharEsc}'[96m[\2]'${SECcharEsc}'[0m,g'
		#local lsedAddNewLine='s".*"&\n"'
	#		|egrep -v "$lgrepNoCommentedLines" \
	#		|egrep -v "$lgrepNoFunctions" \
		cat "${lastrFile[@]}" \
			|egrep -w "$lgrepMatchHelpToken" \
			|egrep -v "$lgrepNoInvalidHelps" \
			|egrep -v "$lgrepNoUserEnvVars" \
			|egrep -v "$lgrepNoFunctions" \
			|sed -r "$lsedOptionsAndHelpText" \
			|sed -r "$lsedRemoveTokenOR" \
			|sed -r "$lsedRemoveHelpToken" \
			|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
			|sed -r "$lsedColorizeOptionals" \
			|sed -r "$lsedColorizeRequireds" \
			|sed -r "$lsedRemoveComparedVariable" \
			|sed -r "$lsedColorizeTheOptiId" \
			|sed -r "$lsedTranslateEsct" \
			|$cmdSort \
			|sed -r "$lsedTranslateEscn" \
			|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
			#|sed -r "$lsedAddNewLine"
	fi
	
	SECFUNCdbgFuncOutA;return 0
}
function SECFUNCshowFunctionsHelp() { #help [script filename] show functions specific help for self script or supplied filename
	#set -x
	local lstrScriptFile="$0"
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCshowFunctionsHelp_help
			SECFUNCshowHelp --nosort $FUNCNAME
			return
		elif [[ "$1" == "--file" ]];then #SECFUNCshowFunctionsHelp_help <file> use to gather help data from
			shift
			lstrScriptFile="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCshowFunctionsHelp_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
#		else #USE THIS ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift
	done

	if [[ ! -f "$lstrScriptFile" ]];then
		SECFUNCechoErrA "invalid lstrScriptFile='$lstrScriptFile'"
		return 1
	fi
	
	if [[ ! -f "$lstrScriptFile" ]];then
		SECFUNCechoErrA "invalid script file '$lstrScriptFile'"
		return 1
	fi
	
	echo "`basename "$lstrScriptFile"` Functions:"
	local lsedFunctionNameOnly='s".*function[[:blank:]]*([[:alnum:]_]*)[[:blank:]]*\(\).*"\1"'
	local lastrFunctions=(`grep "^[[:blank:]]*function[[:blank:]]*[[:alnum:]_]*[[:blank:]]*()" "$lstrScriptFile" |grep "#help" |sed -r "$lsedFunctionNameOnly"`)
	lastrFunctions=(`echo "${lastrFunctions[@]-}" |tr " " "\n" |sort`)
	if((`SECFUNCarraySize lastrFunctions`>0));then
		for lstrFuncId in ${lastrFunctions[@]};do
			echo
			if type $lstrFuncId 2>/dev/null |grep -q "\-\-help";then
				local lstrHelp=`$lstrFuncId --help`
				if [[ -n "$lstrHelp" ]];then
					echo "$lstrHelp"
				else
					#echo "  $lstrFuncId()"
					SECFUNCshowHelp --file "$lstrScriptFile" $lstrFuncId #this only happens for SECFUNCechoDbg ...
				fi
			else
				#echo "  $lstrFuncId()"
				SECFUNCshowHelp --file "$lstrScriptFile" $lstrFuncId
			fi
		done
	fi
}

#function SECFUNCisNumberChkExit(){
#	if ! SECFUNCisNumber "$@";then
#		
#	fi
#}

function SECFUNCisNumber(){ #help "is float" check by default
	local bDecimalCheck=false
	local bNotNegativeCheck=false
	local lbAssert=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCisNumber_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--decimal" || "$1" == "-d" ]];then #SECFUNCisNumber_help decimal check
			bDecimalCheck=true
		elif [[ "$1" == "--notnegative" || "$1" == "-n" ]];then #SECFUNCisNumber_help if negative, return false (1)
			bNotNegativeCheck=true
		elif [[ "$1" == "--assert" ]];then #SECFUNCisNumber_help if check fail will use critical message exit
			lbAssert=true
		elif [[ "$1" == "-dn" || "$1" == "-nd" ]];then #just to keep this function fast...
			bDecimalCheck=true
			bNotNegativeCheck=true
		elif [[ -z "`echo "$1" |tr -d "[:digit:].-"`" ]];then #this is the actual number that is negative!
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done

	local lnValue="${1-}"
	
	function SECFUNCisNumber_assertMsg(){
		if ! $lbAssert;then return ;fi	
		
		SECFUNCechoErrA "invalid lnValue='$lnValue'"
		_SECFUNCcriticalForceExit
	}
	
	if [[ -z "${lnValue}" ]];then
		SECFUNCisNumber_assertMsg
		return 1
	fi
	
	if [[ -n "`echo "${lnValue}" |tr -d '[:digit:].+-'`" ]];then
		SECFUNCisNumber_assertMsg
		return 1
	fi
	
	local lstrTmp="${lnValue//[^.]}"
	if $bDecimalCheck;then
		if((${#lstrTmp}>0));then
			SECFUNCisNumber_assertMsg
			return 1
		fi
	else
		if((${#lstrTmp}>1));then
			SECFUNCisNumber_assertMsg
			return 1
		fi
	fi
	
	local lstrTmp="${lnValue//[^+]}"
	if((${#lstrTmp}>1));then
		SECFUNCisNumber_assertMsg
		return 1
	elif((${#lstrTmp}==1)) && [[ "${lnValue:0:1}" != "+" ]];then
		SECFUNCisNumber_assertMsg
		return 1
	fi
	
	local lstrTmp="${lnValue//[^-]}"
	if $bNotNegativeCheck;then
		if((${#lstrTmp}>0));then
			SECFUNCisNumber_assertMsg
			return 1
		fi
	else
		if((${#lstrTmp}>1));then
			SECFUNCisNumber_assertMsg
			return 1
		elif((${#lstrTmp}==1)) && [[ "${lnValue:0:1}" != "-" ]];then
			SECFUNCisNumber_assertMsg
			return 1
		fi
	fi

	return 0
}

function SECFUNCscriptSelfNameCheckAndSet() { #help check if equal, return 0, if changed return 1
	SECFUNCdbgFuncInA;
	local lbScriptNameChanged=false
	local lSECstrScriptSelfName="`basename $0`"
	SECFUNCechoDbgA "lSECstrScriptSelfName=$lSECstrScriptSelfName"
#	if [[ "$SECstrScriptSelfName" != "$lSECstrScriptSelfName" ]];then
#		export SECstrScriptSelfNameParent="$SECstrScriptSelfName"
#	fi
#	export SECstrScriptSelfName="$lSECstrScriptSelfName"
	if [[ -n "$SECstrScriptSelfName" ]];then
		if [[ "$lSECstrScriptSelfName" != "$SECstrScriptSelfName" ]];then
			lbScriptNameChanged=true
		fi
	fi
	SECFUNCechoDbgA "lbScriptNameChanged=$lbScriptNameChanged"
	
	SECFUNCechoDbgA "SECstrScriptSelfNameParent=$SECstrScriptSelfNameParent"
	SECFUNCechoDbgA "SECstrScriptSelfName=$SECstrScriptSelfName"
	export SECstrScriptSelfNameParent="$SECstrScriptSelfName"
	export SECstrScriptSelfName="$lSECstrScriptSelfName"
	SECFUNCechoDbgA "SECstrScriptSelfNameParent=$SECstrScriptSelfNameParent"
	SECFUNCechoDbgA "SECstrScriptSelfName=$SECstrScriptSelfName"
	
	if [[ -n "$SECstrScriptSelfNameParent" ]];then
		if [[ "$SECstrScriptSelfNameParent" != "$SECstrScriptSelfName" ]];then
			lbScriptNameChanged=true
		fi
	fi
	
	SECFUNCdbgFuncOutA;if $lbScriptNameChanged;then return 1;fi
}

function SECFUNCdtTimeForLogMessages() { #help useful to core functions only
	date +"%Y%m%d+%H%M%S.%N"
}

function SECFUNCechoErr() { #help echo error messages
#	function _SECFUNCechoErr_SECFUNCdtFmt() {
#		if [[ "$SEClstrFuncCaller" != "SECFUNCdtFmt" ]];then
#			SECFUNCdtFmt "$@"
#		fi
#	}
	###### options
	local lstrCaller=""
#	local lbShowTime=true
	local SEClstrFuncCaller=""
	local lbLogOnly=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoErr_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoErr_help is the name of the function calling this one
			shift
#			lstrCaller="${1};pidcmd=$(ps --no-headers -o comm -p $$);ppidcmd=$(ps --no-headers -o comm -p $$): "
			lstrCaller="${1};"
			lstrCaller+="cmd='`ps --no-headers -o cmd -p $$`';"
			lstrCaller+="PPIDcmd='`ps --no-headers -o cmd -p $PPID`';"
			lstrCaller+=": "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoErr_help <FUNCNAME>
			shift
			SEClstrFuncCaller="${1}"
#		elif [[ "$1" == "--skiptime" ]];then #SECFUNCechoErr_help to be used at SECFUNCdtFmt preventing infinite loop
#			lbShowTime=false
		elif [[ "$1" == "--logonly" ]];then #SECFUNCechoErr_help to not output to stderr and only log it
			shift
			lbLogOnly=true
		else
			echo " [`SECFUNCdtTimeForLogMessages`]SECERROR:invalid option '$1'" >&2; 
			return 1
		fi
		shift
	done
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECERROR: ${lstrCaller}$@"
	if ! $lbLogOnly;then
		if $SEC_MsgColored;then
			echo -e "\E[0m\E[91m${l_output}\E[0m" >&2
		else
			echo "${l_output}" >&2
		fi
	fi
	echo "${l_output}" >>"$SECstrFileErrorLog"
}

function SECFUNCmsgCtrl() { #help
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

function SECFUNCechoDbg() { #help will echo only if debug is enabled with SEC_DEBUG
	# Log is stopped on the alias #set +x
	SECFUNCmsgCtrl DEBUG
	if [[ "$SEC_DEBUG" != "true" ]];then # to not lose more time, THIS MUST BE BEFORE HELP CODE only for debug!!!
		return 0
	fi
	
	###### options
	local lstrCaller=""
	local SEClstrFuncCaller=""
	local lbFuncIn=false
	local lbFuncOut=false
	#local lbStopParams=false
	#declare -A lastrVarId=() #will be local
	#local lastrVarId=()
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do # checks if param is set
		if [[ "$1" == "--help" ]];then #SECFUNCechoDbg_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoDbg_help is the name of the function calling this one
			shift
			lstrCaller="${1}: "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoDbg_help <FUNCNAME> will show debug only if the caller function matches SEC_DEBUG_FUNC in case it is not empty
			shift
			SEClstrFuncCaller="${1}"
		elif [[ "$1" == "--funcin" ]];then #SECFUNCechoDbg_help just to tell it was placed on the beginning of a function
			lbFuncIn=true
		elif [[ "$1" == "--funcout" ]];then #SECFUNCechoDbg_help just to tell it was placed on the end of a function
			lbFuncOut=true
#		elif [[ "$1" == "--vars" ]];then #SECFUNCechoDbg_help show variables values, must be last option, all remaining params will be used...
#			shift
#			while [[ -n "${1-}" ]];do
#				lastrVarId+=("$1")
#				shift #will consume all remaining params
#			done
		elif [[ "$1" == "--" ]];then #SECFUNCechoDbg_help remaining params after this are considered as not being options
			shift
			while ! ${1+false};do	#lastrRemainingParams=("$@")
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
			break # to skip main loop's shift
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
#		if $lbStopParams;then
#			break;
#		fi
	done
	
	###### main code
	if [[ -n "$lstrCaller" ]];then #this is a generic spot to be a bit more helpful
		SECstrDbgLastCaller="${lstrCaller} ${lastrRemainingParams[@]-}"
	fi
	
	local lnLength=0
	local lstrLastFuncId=""
	function SECFUNCechoDbg_updateStackVars(){
#		SECFUNCppidList --comm "\n" >&2 2>&1
#		echo "$$,$PPID" >&2
#		(set |grep "^SECastr";) >&2 2>&1
#		set |grep SECinstallPath >&2 2>&1
#		declare -p SECastrFunctionStack >&2 2>&1
#		if ${SECastrFunctionStack+false};then
#			SECastrFunctionStack=()
#		fi
		lnLength="${#SECastrFunctionStack[@]}"
		if((lnLength>0));then
			lstrLastFuncId="${SECastrFunctionStack[lnLength-1]}"
		fi
	}
	SECFUNCechoDbg_updateStackVars
	strFuncInOut=""
	declare -g -A _dtSECFUNCdebugTimeDelayArray
	if $lbFuncIn;then
		if [[ -n "$lstrCaller" ]];then
			SECstrDbgLastCallerIn="${lstrCaller} ${lastrRemainingParams[@]-}"
		fi
		_dtSECFUNCdebugTimeDelayArray[$SEClstrFuncCaller]="`date +"%s.%N"`"
		strFuncInOut="Func-IN: "
		SECastrFunctionStack+=($SEClstrFuncCaller)
		SECFUNCechoDbg_updateStackVars
	elif $lbFuncOut;then
		if [[ -n "$lstrCaller" ]];then
			SECstrDbgLastCallerOut="${lstrCaller} ${lastrRemainingParams[@]-}"
		fi
		local ldtNow="`date +"%s.%N"`"
		local ldtFuncDelay="-1"
		if [[ "${_dtSECFUNCdebugTimeDelayArray[$SEClstrFuncCaller]-0}" != "0" ]];then
			ldtFuncDelay=$(bc <<< "scale=9;$ldtNow-${_dtSECFUNCdebugTimeDelayArray[$SEClstrFuncCaller]}")
		fi
		strFuncInOut="Func-OUT: "
		if [[ "$ldtFuncDelay" != "-1" ]];then
			strFuncInOut+="(${ldtFuncDelay}s) "
		fi
		if((lnLength>0));then
			if [[ "$SEClstrFuncCaller" == "$lstrLastFuncId" ]];then
				unset SECastrFunctionStack[lnLength-1]
				SECFUNCechoDbg_updateStackVars
			else
				SECFUNCechoErrA "SEClstrFuncCaller='$SEClstrFuncCaller' expected lstrLastFuncId='$lstrLastFuncId'"
			fi
		else
			SECFUNCechoErrA "SEClstrFuncCaller='$SEClstrFuncCaller', SECastrFunctionStack lnLength='$lnLength'"
		fi
	fi
	local strFuncStack=""
	if((lnLength>0));then
		local lnCount="$lnLength"
		if $lbFuncIn;then
			((lnCount--))
		fi
		if((lnCount>0));then
#			strFuncStack="`echo "${SECastrFunctionStack[@]:0:lnCount}" |tr ' ' '.'`: "
			local lstrFunction
			for lstrFunction in ${SECastrFunctionStack[@]:0:lnCount};do
				if [[ -n "$strFuncStack" ]];then strFuncStack+=".";fi
				strFuncStack+="$lstrFunction@${SECastrDebugFunctionPerFile[$lstrFunction]-}"
			done
#			strFuncStack+=": "
		else
			strFuncStack=""
		fi
	else
		strFuncStack=""
	fi
	
	function SECFUNCechoDbg_isOnTheList(){
		local lstrFuncToCheck="${1-}"
		#declare -p SECastrBashDebugFunctionIds >&2
		#set |grep "^SEC" >&2
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
	if SECFUNCechoDbg_isOnTheList	$SEClstrFuncCaller || 
	   SECFUNCechoDbg_isOnTheList	$lstrLastFuncId;
	then
		lbBashDebug=true
	fi
	
	local lbDebug=true
	
	if [[ "$SEC_DEBUG" != "true" ]];then
		lbDebug=false
	fi
	
	if [[ -n "$SEC_DEBUG_FUNC" ]];then
		if [[ "$SEClstrFuncCaller" != "$SEC_DEBUG_FUNC" ]];then
			lbDebug=false
		fi
	fi
	
	if $lbDebug;then
		local lstrText=""
		if((`SECFUNCarraySize lastrRemainingParams`>0));then
			for lstrParam in ${lastrRemainingParams[@]};do
				lstrText+="$lstrParam='${!lstrParam-}' "
			done
		else
			lstrText="$@"
		fi
		local l_output=" [`SECFUNCdtTimeForLogMessages`]SECDEBUG: ${strFuncStack}${lstrCaller}${strFuncInOut}$lstrText"
		if $SEC_MsgColored;then
			echo -e "\E[0m\E[97m\E[47m${l_output}\E[0m" >&2
		else
			echo "${l_output}" >&2
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

function SECFUNCechoWarn() { #help warn messages will only show if SEC_WARN is true
	###### options
	local lstrCaller=""
	local SEClstrFuncCaller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoWarn_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoWarn_help is the name of the function calling this one
			shift
			lstrCaller="${1}: "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoWarn_help <FUNCNAME>
			shift
			SEClstrFuncCaller="${1}"
			#local SEClstrFuncCaller=""
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
#	if [[ -f "${SECstrFileMessageToggle}.WARN.$$" ]];then
#		rm "${SECstrFileMessageToggle}.WARN.$$" 2>/dev/null
#		if $SEC_WARN;then SEC_WARN=false;	else SEC_WARN=true; fi
#	fi
	SECFUNCmsgCtrl WARN
	if [[ "$SEC_WARN" != "true" ]];then # to not lose time
		return 0
	fi
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECWARN: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[93m${l_output}\E[0m" >&2
	else
		echo "${l_output}" >&2
	fi
}

function SECFUNCechoBugtrack() { #help bugtrack messages will only show if SEC_BUGTRACK is true
	###### options
	local lstrCaller=""
	local SEClstrFuncCaller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoBugtrack_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoBugtrack_help is the name of the function calling this one
			shift
			lstrCaller="${1}: "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoBugtrack_help <FUNCNAME>
			shift
			SEClstrFuncCaller="${1}"
			#local SEClstrFuncCaller=""
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
#	if [[ -f "${SECstrFileMessageToggle}.BUGTRACK.$$" ]];then
#		rm "${SECstrFileMessageToggle}.BUGTRACK.$$" 2>/dev/null
#		if $SEC_BUGTRACK;then SEC_BUGTRACK=false;	else SEC_BUGTRACK=true; fi
#	fi
	SECFUNCmsgCtrl BUGTRACK
	if [[ "$SEC_BUGTRACK" != "true" ]];then # to not lose time
		return 0
	fi
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECBUGTRACK: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[36m${l_output}\E[0m" >&2
	else
		echo "${l_output}" >&2
	fi
}

function SECFUNCaddToString() { #help <lstrVariableId> <lstrSeparator> <lstrWhatToAdd>\n\tappend "+string" or prefix "-string" to lstrVariableId, only if such string is missing at lstrVariableId value\n\tlstrSeparator is expected to already exist on the lstrVariableId data to work properly
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCaddToString_help
			SECFUNCshowHelp --nosort $FUNCNAME
			return
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCaddToString_help MISSING DESCRIPTION
#			echo "#TODO"
		elif [[ "$1" == "--" ]];then #SECFUNCaddToString_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
#		else #USE THIS ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift
	done
	
	local lstrVariableId="${1-}"
	local lstrSeparator="${2-}"
	local lstrWhatToAdd="${3-}"
	
	if ${!lstrVariableId+false};then
		SECFUNCechoErrA "lstrVariableId='$lstrVariableId' was not declared yet"
		return 1
	fi
	if [[ -z "${lstrWhatToAdd}" ]];then
		SECFUNCechoErrA "missing lstrWhatToAdd"
		return 1
	fi
	
	local lstrCtrlChar="${lstrWhatToAdd:0:1}"
	lstrWhatToAdd="${lstrWhatToAdd:1}" #remove control char
	local lstrToGrep="$lstrWhatToAdd"
	case "$lstrCtrlChar" in
		"-") lstrToGrep="${lstrToGrep}${lstrSeparator}";; #separator goes after
		"+") lstrToGrep="${lstrSeparator}${lstrToGrep}";; #separator goes before
		*) SECFUNCechoErrA "invalid control char '$lstrCtrlChar'";return 1;;
	esac
	if ! echo "${!lstrVariableId}" |fgrep -q "${lstrToGrep}";then
		case "$lstrCtrlChar" in
			#`declare -g` instead of `export` keeps unexported ones that way
			"-") declare -g ${lstrVariableId}="${lstrWhatToAdd}${lstrSeparator}${!lstrVariableId}";; #before
			"+") declare -g ${lstrVariableId}="${!lstrVariableId}${lstrSeparator}${lstrWhatToAdd}";; #after
			*) SECFUNCechoErrA "invalid control char '$lstrCtrlChar'";return 1;;
		esac
	fi
}

function SECFUNCisShellInteractive() { #--force shell to be interactive or exit
	local lbForce=false
	if [[ "${1-}" == "--force" ]];then
		lbForce=true
		shift
	fi
#	if [[ "`tty`" == "not a tty" ]];then
#		return 1
#	fi
#	if ! [ -t 0 ];then 
#		return 1
#	fi
#	if ! test -t 0;then
#		return 1
#	fi
	if test -t 0;then #0 = STDIN is a tty? 1 = STDOUT, 2 = STDERR
		SECFUNCechoDbgA "shell is interactive"
		return 0
	else
		SECFUNCechoDbgA "shell is NOT interactive"
		if $lbForce;then
			_SECFUNCcriticalForceExit
		fi
		return 1
	fi
}

function SECFUNCvalidateId() { #help Id can only be alphanumeric or underscore ex.: for functions and variables name.
	local lstrCaller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--caller" ]];then #SECFUNCvalidateId_help is the name of the function calling this one
			shift
			lstrCaller="${1}(): "
		fi
		shift
	done
	
	if [[ -n `echo "$1" |tr -d '[:alnum:]_'` ]];then
		SECFUNCechoErrA "${lstrCaller}invalid id '$1', only allowed alphanumeric and underscores."
		return 1
	fi
	return 0
}
function SECFUNCfixId() { #help fix the id, use like: strId="`SECFUNCfixId "TheId"`"
	local lstrCaller=""
	local lbJustFix=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfixId_help
			SECFUNCshowHelp --nosort $FUNCNAME
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCfixId_help is the name of the function calling this one
			shift
			lstrCaller="${1}(): "
		elif [[ "$1" == "--justfix" || "$1" == "-f" ]];then #SECFUNCfixId_help otherwise it will also validate and inform invalid id to user
			lbJustFix=true
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	if ! $lbJustFix;then
		# just to inform invalid id to user be able to set it properly if wanted
		SECFUNCvalidateId --caller "$lstrCaller" "$1"
	fi
	
	# replaces all non-alphanumeric and non underscore with underscore
	#echo "$1" |tr '.-' '__' | sed 's/[^a-zA-Z0-9_]/_/g'
	echo "$1" |sed 's/[^a-zA-Z0-9_]/_/g'
}

function SECFUNCppidList() { #help [separator] between pids
	local lbReverse=false
	local lbComm=false
	local lnPid=$$
  local lstrSeparator=" "
  local lnPidCheck=0
  local lbAddSelf=false
  local lbChildList=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCppidList_help
			SECFUNCshowHelp $FUNCNAME
			return
		elif [[ "$1" == "--reverse" || "$1" == "-r" ]];then #SECFUNCppidList_help show in reverse order
			lbReverse=true
		elif [[ "$1" == "--comm" || "$1" == "-c" ]];then #SECFUNCppidList_help add the short comm to pid
			lbComm=true
		elif [[ "$1" == "--child" ]];then #SECFUNCppidList_help instead of parent list, shows a list of child of child of... pids.
			lbChildList=true
		elif [[ "$1" == "--pid" || "$1" == "-p" ]];then #SECFUNCppidList_help <lnPid> use it as reference for the list
			shift
			lnPid=${1-}
		elif [[ "$1" == "--addself" || "$1" == "-a" ]];then #SECFUNCppidList_help include self pid on the list, not only parents
			lbAddSelf=true
		elif [[ "$1" == "--checkpid" ]];then #SECFUNCppidList_help <lnPidCheck> check if it is on the ppid list
			shift
			lnPidCheck=${1-}
		elif [[ "$1" == "--separator" || "$1" == "-s" ]];then #SECFUNCppidList_help <lstrSeparator> use it as reference for the list
			shift
		  lstrSeparator="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCppidList_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done

	if [[ -n "${1-}" ]];then
	  lstrSeparator="$1"
	fi
  shift&&:
  
  if [[ "$lnPidCheck" != "0" ]];then
  	if ! SECFUNCisNumber -dn "$lnPidCheck";then
			SECFUNCechoErrA "invalid lnPidCheck='$lnPidCheck'"
			return 1
  	fi
  fi
  
  if ! SECFUNCisNumber -dn "$lnPid";then
		SECFUNCechoErrA "invalid lnPid='$lnPid'"
		return 1
  fi
  
  if [[ ! -d "/proc/$lnPid" ]];then
		SECFUNCechoErrA "no lnPid='$lnPid'"
		return 1
  fi
  
	local anPidList=()
  if $lbChildList;then
  	anPidList=(`pstree -l -p $lnPid |grep "([[:digit:]]*)" -o |tr -d '()'`)
		if ! $lbAddSelf;then
			unset anPidList[0] #loop on anPidList[@] will skip the unset item
		fi
  else #parent pid list
		if $lbAddSelf;then
			anPidList+=($lnPid)
		fi
		local lnPPid=$lnPid;
		while((lnPPid>1));do 
			# get parent pid
			lnPPid="`grep PPid /proc/$lnPPid/status |cut -f2&&:`"
			anPidList+=($lnPPid)
		done
	fi
	
	local lnPidCurrent=-1
	local lstrPidList=""
	for lnPidCurrent in "${anPidList[@]}";do
	  if((lnPidCheck>0));then
	  	if((lnPidCurrent==lnPidCheck));then
	  		return 0
	  	fi
	  fi
	  
		strComm=""    
		if $lbComm;then
			strComm="_`cat "/proc/$lnPidCurrent/comm"`"
			strComm="`SECFUNCfixId -f "$strComm"`"
		fi
	  if [[ -n "$lstrPidList" ]];then # after 1st
			if $lbReverse;then
				lstrPidList="${lnPidCurrent}${strComm}${lstrSeparator}${lstrPidList}"
			else
				lstrPidList="${lstrPidList}${lstrSeparator}${lnPidCurrent}${strComm}"
			fi
	  else
	  	lstrPidList="${lnPidCurrent}${strComm}"
		fi
	done
		
#	local lstrPidList=""
#	local anPidList=()
#	local ppid=$lnPid;
#	local lbFirstLoopCheck=true
#	while((ppid>=1));do 
#	  #ppid=`ps -o ppid -p $ppid --no-heading |tail -n 1`; 
#	  local lbGetParentPid=true
#	  if $lbFirstLoopCheck;then
#	  	if $lbAddSelf;then
#	  		lbGetParentPid=false
#	  	fi
#	  	lbFirstLoopCheck=false
#	  fi
#	  if $lbGetParentPid;then
#	  	# get parent pid
#		  ppid="`grep PPid /proc/$ppid/status |cut -f2&&:`"
#	 	fi
#	  
#	  if((lnPidCheck>0));then
#	  	if((ppid==lnPidCheck));then
#	  		return 0
#	  	fi
#	  fi
#	  
#	  #anPidList=(${anPidList[*]} $ppid)
#	  anPidList+=($ppid)
#	  
##    if [[ -n "$lstrPidList" ]];then # after 1st
##		  if [[ -n "$lstrSeparator" ]];then
##		  	lstrPidList+="$lstrSeparator"
##		  fi
##		fi
#		strComm=""    
#		if $lbComm;then
#			strComm="_`cat "/proc/$ppid/comm"`"
#			strComm="`SECFUNCfixId -f "$strComm"`"
#		fi
#	  if [[ -n "$lstrPidList" ]];then # after 1st
#			if $lbReverse;then
#				lstrPidList="${ppid}${strComm}${lstrSeparator}${lstrPidList}"
#			else
#				lstrPidList="${lstrPidList}${lstrSeparator}${ppid}${strComm}"
#			fi
#	  else
#	  	lstrPidList="${ppid}${strComm}"
#		fi
#	
#	  #echo $ppid; 
#	  if((ppid==1));then break; fi; 
#	done
  
#  local output="${anPidList[*]}"
#  if [[ -n "$lstrSeparator" ]];then
#    local sedChangeSeparator='s" "'"$lstrSeparator"'"g'
#    output=`echo "$output" |sed "$sedChangeSeparator"`
#  fi
  
  #echo "$output"
  if((lnPidCheck>0));then
  	return 1; # reached here because did not match any ppid
  else
	  echo -e "$lstrPidList"
	fi
  
  return 0
}

function SECFUNCrestoreDefaultOutputs() { #help same as `SECFUNCcheckActivateRunLog --restoredefaultoutputs "${@-}"`
	if [[ "${1-}" == "--help" ]];then #SECFUNCrestoreDefaultOutputs_help
		SECFUNCshowHelp $FUNCNAME
		return 0
	fi
	
	#SECFUNCcheckActivateRunLog --restoredefaultoutputs "${@-}" #keep its return status
  SECFUNCfdRestore
}

if [[ -z "${SECanFdList-}" ]];then SECanFdList=();fi # any better way to initialize arrays? this fails: `: ${SECanFdList:=()}`
function SECFUNCfdUpdateList() { #help SECanFdList
  declare -gax SECanFdList
  IFS=$'\n' read -d '' -r -a SECanFdList < <(ls "/proc/$$/fd/")&&:
  return 0
}

function SECFUNCfdGetTermOutput() { #help this outputs to stdout (fall back returned fd is current err output)
  local loutput="`readlink /proc/$$/fd/2`" # defaults to current err output 
	local lastrAllParams=("${@-}") # this may be useful
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCfdGetTermOutput_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCfdGetTermOutput_help <lstrExample> MISSING DESCRIPTION
			shift
			lstrExample="${1-}"
    elif [[ "$1" == "-o" || "$1" == "--out" ]];then #SECFUNCfdGetTermOutput_help sets fall back to current default "out" output
      loutput="`readlink /proc/$$/fd/1`"
		elif [[ "$1" == "--" ]];then #SECFUNCfdGetTermOutput_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
  
  SECFUNCfdUpdateList
  for lnFd in "${SECanFdList[@]}";do 
    if [[ -t "$lnFd" ]];then
      loutput="`readlink /proc/$$/fd/$lnFd`" # let it crash if fails here...
    fi
  done
  
  echo "$loutput"
}

function SECFUNCfdReport(){ #help list detailed fd
  #~ for((i=0;i<=2;i++));do
    #~ ls -l --color=always "/proc/$$/fd/$i" >&2
    #~ declare -p SECbkpFd$i&&:
  #~ done
  #~ local lnFdList;
  local loutput="`SECFUNCfdGetTermOutput`"; # fd  list went subshell lost
  #~ SECFUNCfdUpdateList
  #~ IFS=$'\n' read -d '' -r -a lnFdList < <(ls "/proc/$$/fd/")&&:
  #~ for lnFd in "${SECanFdList[@]}";do 
    #~ if [[ -t "$lnFd" ]];then
      #~ # if &2 is redirected try to find a valid terminal fd for it TODO should this be optional?
      #~ loutput="`readlink /proc/$$/fd/$lnFd`"
      #~ break;
    #~ fi
  #~ done
  
  declare -p SECbkpTermFd >$loutput &&:
  
  local lnFd; 
  SECFUNCfdUpdateList
  for lnFd in "${SECanFdList[@]}";do
    ls -l --color=always "/proc/$$/fd/$lnFd" >$loutput &&:
    if((lnFd<=2));then
      declare -p "SECbkpFd${lnFd}" >$loutput &&:
    fi
  done
}

function SECFUNCfdBkp() { #help
  #TODO is the fd backup useless? may be when redirecting to files, terminal or pipes may remain on the backuped fd(s), try to test it...
  SECFUNCfd --bkp "$@" #so --help will work here too
}

function SECFUNCfdRestore() { #help 
  #TODO help msg?: restore (default) or backup file descriptors (fd) only if it is a terminal OR a pipe
  SECFUNCfd --restore "$@" #so --help will work here too
}

function SECFUNCfdPanic() { #help PANIC!! will try to retore fd to terminal
  SECFUNCfd --forceterm "$@"
}

: ${SECbkpTermFd:=""}
function SECFUNCfd() { #help fd 
	SECFUNCdbgFuncInA;
	# var init here
	local lstrExample="DefaultValue"
  local lbExample=false
	local lastrRemainingParams=()
  local lbBkp=false
  local lbForceTerm=false
  #~ local lbUseFd0=false
	local lastrAllParams=("${@-}") # this may be useful
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCfd_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #SECFUNCfd_help <lstrExample> MISSING DESCRIPTION
			shift
			lstrExample="${1-}"
    elif [[ "$1" == "-b" || "$1" == "--bkp" ]];then #SECFUNCfd_help MISSING DESCRIPTION
      lbBkp=true
    elif [[ "$1" == "-r" || "$1" == "--restore" ]];then #SECFUNCfd_help default
      lbBkp=false # TODO this may be useless...
    #~ elif [[ "$1" == "-0" || "$1" == "--usefd0" ]];then #SECFUNCfd_help MISSING DESCRIPTION
      #~ lbUseFd0=true
    elif [[ "$1" == "-t" || "$1" == "--forceterm" ]];then #SECFUNCfd_help force restore to a terminal fd if available (warning: this will break all redirections)
      lbBkp=false # TODO this may be useless...
      lbForceTerm=true
		elif [[ "$1" == "--" ]];then #SECFUNCfd_help params after this are ignored as being these options, and stored at lastrRemainingParams
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
  #~ local lbBkp=false;if [[ "${1-}" == "--bkp" ]];then lbBkp=true;fi
  #~ local lbUseFd0=false;if [[ "${1-}" == "--usefd0" ]];then lbUseFd0=true;fi
  
  function _SECFUNCfd_fdOk() { # <lnFdIndex> <lstrFd>
    #~ local lnFdIndex="$1";shift
    #~ local lstrFd="$1";shift
    
    if [[ -t $lnFdIndex ]] || [[ -c "$lstrFd" ]] || [[ "$lstrFd" =~ ^pipe:.* ]];then return 0;fi #TODO what about "socket:.*" ?
    return 1
  }
  
  function _SECFUNCfd_fdBkp() { # <lnFdIndex> <lstrFd> <lstrBkpId>
    #~ local lnFdIndex="$1";shift
    #~ local lstrFd="$1";shift
    #~ local lstrBkpId="$1";shift

    if [[ -z "${!lstrBkpId-}" ]];then
      if _SECFUNCfd_fdOk;then #"$lnFdIndex" "$lstrFd";then
        declare -gx $lstrBkpId="$lstrFd"
      fi 
    fi
    
    return 0;
  }
  
  if $lbBkp;then # special Terminal FD backup
    SECFUNCfdUpdateList
    local lnFdIndex; 
    for lnFdIndex in "${SECanFdList[@]}";do
      if [[ -t "$lnFdIndex" ]];then 
        declare -gx SECbkpTermFd="`readlink /proc/$$/fd/${lnFdIndex}`";
      fi 
    done
  fi
  
  for((i=0;i<=2;i++));do
    local lnFdIndex="$i"
    local lstrFd="`readlink /proc/$$/fd/${lnFdIndex}`"
    local lstrBkpId="SECbkpFd${lnFdIndex}"
    #~ declare -p lstrBkpId >>/dev/stderr
    if $lbBkp;then
      #~ if [[ -t "$lnFdIndex ]];then declare -gx SECbkpTermFd="$lstrFd";fi # special Terminal FD backup
      _SECFUNCfd_fdBkp #"${lnFdIndex}" "${lstrFd}" "${lstrBkpId}"
    else
      SECFUNCfdReport #TODO this is just a workaround to actually let the restore work (WHY IT WORKS? AND ONLY ON THIS CODE LINE!!? I dont like magic...), test case: SECFUNCexecA -ce --resdefop bash; #and inside of new bash instance: SECFUNCexec --help #comment this code line and the last test case command will freeze...
        
      local lstrFdRestore="${!lstrBkpId-}"
      if $lbForceTerm && [[ -n "$SECbkpTermFd" ]];then
        lstrFdRestore="$SECbkpTermFd"
      fi
      
      if [[ -n "$lstrFdRestore" ]] && [[ "$lstrFd" != "$lstrFdRestore" ]];then
        eval "exec ${lnFdIndex}>${lstrFdRestore}"
      fi
    fi
  done
  
  #~ if ! $lbBkp && $lbUseFd0;then # restore
    #~ if [[ -t 0 ]];then # if stdin is terminal
      #~ exec 1>&0;
      #~ exec 2>&0;
      
      #~ if [[ -t 1 ]] && [[ -t 2 ]];then
        #~ return 0;
      #~ else
        #~ SECFUNCechoWarnA "restore based on fd 0 failed for fd 1 and/or 2, trying with backups"
      #~ fi
    #~ fi
  #~ fi
  
  #~ local lnFdBase=100;
  #~ local lbResFd1Ok=false
  #~ local lbResFd2Ok=false
  #~ local lnBkpTot=3 
  #~ local lnBkpCount1=0
  #~ local lnBkpCount2=0
  #~ local i
  #~ for((i=0;i<lnBkpTot;i++));do
    #~ if $lbBkp;then
      #~ #declare -gx SECFUNCfdRestore_bkpFd0
      
      #~ if ! [[ -a /proc/$$/fd/$((lnFdBase+1)) ]];then
        #~ eval "exec $((lnFdBase+1))>&1"
      #~ fi
      #~ #if [[ -t $((lnFdBase+1)) ]];then ((lnBkpCount1++))&&:;fi
      #~ if _SECFUNCfdRestore_fdOk $((lnFdBase+1));then ((lnBkpCount1++))&&:;fi
      
      #~ if ! [[ -a /proc/$$/fd/$((lnFdBase+2)) ]];then
        #~ eval "exec $((lnFdBase+2))>&2"
      #~ fi
      #~ #if [[ -t $((lnFdBase+2)) ]];then ((lnBkpCount2++))&&:;fi
      #~ if _SECFUNCfdRestore_fdOk $((lnFdBase+2));then ((lnBkpCount2++))&&:;fi
    #~ else
      #~ #if [[ -t 1 ]];then lbResFd1Ok=true;fi
      #~ if _SECFUNCfdRestore_fdOk 1;then lbResFd1Ok=true;fi 
      #~ if ! $lbResFd1Ok;then
        #~ if [[ -t $((lnFdBase+1)) ]];then
          #~ eval "exec 1>&$((lnFdBase+1))"
          #~ lbResFd1Ok=true
        #~ fi
      #~ fi
      
      #~ #if [[ -t 2 ]];then lbResFd2Ok=true;fi
      #~ if _SECFUNCfdRestore_fdOk 2;then lbResFd1Ok=true;fi 
      #~ if ! $lbResFd2Ok;then
        #~ if [[ -t $((lnFdBase+2)) ]];then
          #~ eval "exec 2>&$((lnFdBase+2))"
          #~ lbResFd2Ok=true
        #~ fi
      #~ fi
      
      #~ if $lbResFd1Ok && $lbResFd2Ok;then break;fi
    #~ fi
    
    #~ ((lnFdBase+=10))&&: #so it ends always in 0, 1 or 2
  #~ done
  
  #~ if $lbBkp;then
    #~ if((lnBkpCount1==0));then SECFUNCechoWarnA "fd 1 bkp lnBkpCount1='$lnBkpCount1'";fi;
    #~ if((lnBkpCount2==0));then SECFUNCechoWarnA "fd 2 bkp lnBkpCount2='$lnBkpCount2'";fi;
  #~ else
    #~ if ! $lbResFd1Ok;then SECFUNCechoWarnA "fd 1 restore failed";fi
    #~ if ! $lbResFd2Ok;then SECFUNCechoWarnA "fd 2 restore failed";fi
  #~ fi
  
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

function SECFUNCcheckActivateRunLog() { #help
	local lbRestoreDefaults=false
	local lbInheritParentLog=false
	local lbVerbose=false
	local lastrAllParams=("${@-}")
	local lbForceStdin=false
	local lbSimpleReport=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCcheckActivateRunLog_help
			SECFUNCshowHelp $FUNCNAME
			return
		elif [[ "$1" == "--verbose" || "$1" == "-v" ]];then #SECFUNCcheckActivateRunLog_help restore default outputs to stdout and stderr
			lbVerbose=true
		elif [[ "$1" == "--restoredefaultoutputs" ]];then #SECFUNCcheckActivateRunLog_help restore default outputs to stdout and stderr
			lbRestoreDefaults=true
		elif [[ "$1" == "--forcestdin" ]];then #SECFUNCcheckActivateRunLog_help will force all to point to stdin
			lbForceStdin=true
		elif [[ "$1" == "--report" || "$1" == "-r" ]];then #SECFUNCcheckActivateRunLog_help simple report
			lbSimpleReport=true
		elif [[ "$1" == "--inheritparent" || "$1" == "-i" ]];then #SECFUNCcheckActivateRunLog_help force inherit parent log
			lbInheritParentLog=true
		elif [[ "$1" == "--" ]];then #SECFUNCcheckActivateRunLog_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	function _SECFUNCcheckActivateRunLog_report(){
		if $lbVerbose || $lbSimpleReport;then
			echo "SECINFO: $FUNCNAME: ${lastrAllParams[@]}: $@" >&2
			#ls /proc/$$/fd -l >&2
      #ls -l --color=always "/proc/$$/fd" >&2
      SECFUNCfdReport
			declare -p SECbRunLogEnabled SECnRunLogTeePid SECstrRunLogFile SECstrRunLogFileDefault&&: >&2
		fi
	}
	
	if $lbSimpleReport;then
		_SECFUNCcheckActivateRunLog_report
		return 0
	fi
	
	if $lbForceStdin;then
		_SECFUNCcheckActivateRunLog_report before
		exec 1>&0 2>&0
		_SECFUNCcheckActivateRunLog_report after
		return 0
	fi
	
	if $SECbRunLogDisable || $lbRestoreDefaults;then
#		exec 1>/dev/stdout
#		exec 2>&2
		if $SECbRunLogEnabled;then
			_SECFUNCcheckActivateRunLog_report before
      SECFUNCfdRestore
			#~ # 101 and 102 to try to avoid any conflicts
			#~ if [[ -t 101 ]];then
				#~ exec 1>&101
			#~ else
				#~ exec 1>&0 # if broken, fallback to stdin
				#~ SECFUNCechoWarnA "fd 101 was broken..." #after the redirection of course...
			#~ fi
			
			#~ if [[ -t 102 ]];then
				#~ exec 2>&102
			#~ else
				#~ exec 2>&0 # if broken, fallback to stdin
				#~ SECFUNCechoWarnA "fd 102 was broken..." #after the redirection of course...
			#~ fi
			
#			exec 1>&101 2>&102 #restore (if not yet enabled it would redirect to nothing and bug out)
			_SECFUNCcheckActivateRunLog_report after
			SECbRunLogEnabled=false
		fi
		return 0
	fi
	
#	local lbReinitialize=false
	
#	if ! ${SECstrRunLogFile+false};then # it will always be initialized...
#		#if already initialized
		if $SECbRunLogParentInherited || $lbInheritParentLog;then # will be inherited
			# parent issued `tee` will keep handling the log
			return 0
#		else # if NOT inherited, will be reinitialized!
#			lbReinitialize=true
		fi
#	else # it will always be initialized...
#		# if NOT initialized, will be initialized
#		lbReinitialize=true
#	fi
	
#	if $lbReinitialize;then

		#echo "SECbRunLog=$SECbRunLog"
		local lstrRunLogPipe="`readlink /proc/$$/fd/1`"
		
		local lbSetToDisabled=false
		if ! $lbSetToDisabled && [[ "$lstrRunLogPipe" != "$SECstrRunLogPipe" ]];then
			lbSetToDisabled=true
		fi
		if ! $lbSetToDisabled && [[ ! -d "/proc/$SECnRunLogTeePid" ]];then
			lbSetToDisabled=true
		fi
		if $lbSetToDisabled;then
			SECbRunLogEnabled=false
			SECnRunLogTeePid=0
			SECstrRunLogPipe=""
		fi
		
		if $SECbRunLogEnabled;then
			if [[ -d "/proc/$SECnRunLogTeePid" ]];then
				if [[ "$SECstrRunLogFile" != "$SECstrRunLogFileDefault" ]];then
					if [[ -f "$SECstrRunLogFileDefault" ]];then
						local lstrAlreadyPointsTo="`readlink -f "$SECstrRunLogFileDefault"`"
						if [[ "$lstrAlreadyPointsTo" != "$SECstrRunLogFile" ]];then
							SECFUNCechoErrA "SECstrRunLogFileDefault='$SECstrRunLogFileDefault' already exists and readlink to lstrAlreadyPointsTo='$lstrAlreadyPointsTo', unable to create it as symlink pointing to SECstrRunLogFile='$SECstrRunLogFile'"
						fi
					else
						if [[ ! -a "$SECstrRunLogFileDefault" ]] || [[ -L "$SECstrRunLogFileDefault" ]];then #if it is a symlink, such is broken
							if [[ -L "$SECstrRunLogFileDefault" ]];then
								SECFUNCechoWarnA "overwriting broken symlink SECstrRunLogFileDefault='$SECstrRunLogFileDefault'"
							fi
							ln -sf "$SECstrRunLogFile" "$SECstrRunLogFileDefault"
						fi
					fi
				fi
			fi
		else
			SECstrRunLogFile="$SECstrRunLogFileDefault" #ensure it is properly set to current script
			
			if ( ! SECFUNCisShellInteractive ) || $SECbRunLog;then
		#		SEC_WARN=true SECFUNCechoWarnA "stderr and stdout copied to '$SECstrRunLogFile'" >&2
				echo " SECINFO: stderr and stdout copied to '$SECstrRunLogFile'." >&2
			#	exec 1>"$SECstrRunLogFile"
			#	exec 2>"$SECstrRunLogFile"
        
        # make some backups 
        SECFUNCfdBkp
        #~ nFdBase=100;
        #~ for((i=0;i<10;i++));do
          #~ eval "exec $((nFdBase+1))>&1 $((nFdBase+2))>&2" #backup
          #~ ((nFdBase+=10))
        #~ done
        
				exec > >(tee "$SECstrRunLogFile") #TODO this caused error once, WHY??? and... can it be protected in some way? while sleep?
				exec 2>&1
				
				# waits tee to properly start...
				while ! SECnRunLogTeePid="`pgrep -fx "tee $SECstrRunLogFile"`";do 
					SECFUNCechoWarnA "waiting 'tee $SECstrRunLogFile'..."
					sleep 0.1;
				done #synchronization
#				SECFUNCechoWarnA "SECnRunLogTeePid='$SECnRunLogTeePid'"
				
				SECstrRunLogPipe="`readlink /proc/$$/fd/1`" #Must be updated because it was redirected.
			
				if $SECbRunLogPidTree;then
					local lstrLogTreeFolder="$SECstrTmpFolderLog/PidTree/`SECFUNCppidList --reverse --comm "/"`"
					mkdir -p "$lstrLogTreeFolder"
					ln -sf "$SECstrRunLogFile" "$lstrLogTreeFolder/`basename "$SECstrRunLogFile"`"
				fi
			
				SECbRunLogEnabled=true
				_SECFUNCcheckActivateRunLog_report enabled
			fi
		fi
#	fi

	if [[ -f "$SECstrRunLogFile" ]];then
		chmod o-rw "$SECstrRunLogFile"
	fi
}

function SECFUNCconsumeKeyBuffer() { #help keys that were pressed before this function, and so before any prompt that happens after this function, will be consumed here.
	while true;do
		read -n 1 -t 0.1&&:
		if(($?==142));then #142 is: no key was pressed
			break;
		fi;
	done
}

function SECFUNCrestoreAliases() { #help
	source "$SECstrFileLibFast";
}

export SECbScriptSelfNameChanged=false
if SECFUNCscriptSelfNameCheckAndSet;then
	SECbScriptSelfNameChanged=true
fi

export SECstrUserScriptCfgPath="${SECstrUserHomeConfigPath}/${SECstrScriptSelfName}"

export SECstrTmpFolderLog="$SEC_TmpFolder/log"
mkdir -p "$SECstrTmpFolderLog"

: ${SECbRunLogForce:=false} 
export SECbRunLogForce # the override default, only actually used at secLibsInit.sh

: ${SECbRunLog:=false} 
export SECbRunLog #help user can set this true at .bashrc, but applications inside scripts like `less` will not work properly, and anything redirected to stderr will end on stdout, mainly for debugging, use with caution

: ${SECbRunLogParentInherited:=false}
export SECbRunLogParentInherited

export SECstrRunLogFileDefault="$SECstrTmpFolderLog/$SECstrScriptSelfName.$$.log" # this is named based on current script name; but the log may be happening already from its parent...
: ${SECstrRunLogFile:="$SECstrRunLogFileDefault"}
export SECstrRunLogFile #help if not set, will be the default

: ${SECbRunLogDisable:=false} #DO NOT EXPORT THIS ONE as subshells may have trouble to start logging... #TODO review this...

: ${SECbRunLogEnabled:=false}
export SECbRunLogEnabled 

: ${SECstrRunLogPipe:=}
export SECstrRunLogPipe 

: ${SECnRunLogTeePid:=0}
export SECnRunLogTeePid 

: ${SECbRunLogPidTree:=true}
export SECbRunLogPidTree 

export SECsedTk=$'\x01'; # this is important to use with sed commands that will help on avoiding cohincidence of the delimiter token

#TODO !!!! complete this escaped colors list!!!! to, one day, improve main echoc
export SECcharTab=$'\t' #$(printf '\011') # this speeds up instead of using `echo -e "\t"`
export SECcharNewLine=$'\n' # this speeds up instead of using `echo -e "\n"`
export SECcharNL=$'\n' # this speeds up instead of using `echo -e "\n"`
export SECcharCr=$'\r' # carriage return
#export SECcolorEscapeChar=$'\e' #$(printf '\033') # Escape char to provide colors on sed on terminal
export SECcharEsc=$'\e' #$(printf '\033') # Escape char to provide colors on sed on terminal
# so now, these are the terminal escaped codes (not the string to be interpreted)

# foregrounds
export SECcolorRed="$SECcharEsc[31m";export SECcR="$SECcolorRed"
export SECcolorGreen="$SECcharEsc[32m"
export SECcolorBlue="$SECcharEsc[34m"
export SECcolorCyan="$SECcharEsc[36m"
export SECcolorMagenta="$SECcharEsc[35m"
export SECcolorYellow="$SECcharEsc[33m"
export SECcolorBlack="$SECcharEsc[39m"
export SECcolorWhite="$SECcharEsc[37m"
# light foregrounds
export SECcolorLightRed="$SECcharEsc[91m";export SECcLR="$SECcolorLightRed"
export SECcolorLightGreen="$SECcharEsc[92m"
export SECcolorLightBlue="$SECcharEsc[94m"
export SECcolorLightCyan="$SECcharEsc[96m"
export SECcolorLightMagenta="$SECcharEsc[95m"
export SECcolorLightYellow="$SECcharEsc[93m"
export SECcolorLightBlack="$SECcharEsc[90m"
export SECcolorLightWhite="$SECcharEsc[97m"

# backgrounds
export SECcolorBackgroundRed="$SECcharEsc[41m";export SECcBR="$SECcolorBackgroundRed"
export SECcolorBackgroundGreen="$SECcharEsc[42m"
export SECcolorBackgroundBlue="$SECcharEsc[44m"
export SECcolorBackgroundCyan="$SECcharEsc[46m"
export SECcolorBackgroundMagenta="$SECcharEsc[45m"
export SECcolorBackgroundYellow="$SECcharEsc[43m"
export SECcolorBackgroundBlack="$SECcharEsc[40m" #yes it is 40...
export SECcolorBackgroundWhite="$SECcharEsc[47m"
# light backgrounds
export SECcolorLightBackgroundRed="$SECcharEsc[101m";export SECcLBR="$SECcolorLightBackgroundRed"
export SECcolorLightBackgroundGreen="$SECcharEsc[102m"
export SECcolorLightBackgroundBlue="$SECcharEsc[104m"
export SECcolorLightBackgroundCyan="$SECcharEsc[106m"
export SECcolorLightBackgroundMagenta="$SECcharEsc[105m"
export SECcolorLightBackgroundYellow="$SECcharEsc[103m"
export SECcolorLightBackgroundBlack="$SECcharEsc[100m" #yes it is 40...
export SECcolorLightBackgroundWhite="$SECcharEsc[107m"

export SECcolorCancel="$SECcharEsc[0m"

SECFUNCcheckActivateRunLog #important to be here as shell may not be interactive so log will be automatically activated...

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcCore.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowHelp --onlyvars
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibCore=$$

