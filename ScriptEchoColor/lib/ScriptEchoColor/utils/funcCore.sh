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

strSECFUNCtrapErrCustomMsg="" # see SECFUNCexec for usage
function SECFUNCtrapErr() { #help <"${FUNCNAME-}"> <"${LINENO-}"> <"${BASH_COMMAND-}"> <"${BASH_SOURCE[@]-}">
	local lnRetTrap="$1";shift
	local lstrFuncName="$1";shift
	local lstrLineNo="$1";shift
	local lstrBashCommand="$1";shift
	local lastrBashSource=("$@"); #MUST BE THE LAST PARAM!!!
	
	#local lstrBashSourceListTrap="${BASH_SOURCE[@]-}";
	local lstrBashSourceListTrap="${lastrBashSource[@]}";
	
	local lstrErrorTrap="[`date +"%Y%m%d+%H%M%S.%N"`]"
	lstrErrorTrap+="SECERROR(trap);"
	lstrErrorTrap+="strSECFUNCtrapErrCustomMsg='$strSECFUNCtrapErrCustomMsg';"
	lstrErrorTrap+="SECstrRunLogFile='${SECstrRunLogFile-}';"
	lstrErrorTrap+="SECastrFunctionStack='${SECastrFunctionStack[@]-}.${lstrFuncName}',LINENO='${lstrLineNo}';"
	lstrErrorTrap+="BASH_COMMAND='${lstrBashCommand}';"
	lstrErrorTrap+="BASH_SOURCE[@]=(${lstrBashSourceListTrap});"
	lstrErrorTrap+="lnRetTrap='$lnRetTrap';"
	lstrErrorTrap+="SECstrDbgLastCaller='`   echo "${SECstrDbgLastCaller-}'"    |tr ';' ' '`;"
	lstrErrorTrap+="SECstrDbgLastCallerIn='` echo "${SECstrDbgLastCallerIn-}'"  |tr ';' ' '`;"
	lstrErrorTrap+="SECstrDbgLastCallerOut='`echo "${SECstrDbgLastCallerOut-}'" |tr ';' ' '`;"

#	lstrErrorTrap+="pid='$$';PPID='$PPID';"
#	lstrErrorTrap+="pidCommand='`ps --no-header -p $$ -o cmd&&:`';"
#	lstrErrorTrap+="ppidCommand='`ps --no-header -p $PPID -o cmd&&:`';"
	local lnPid=$$
	local lnPidIndex=0
	while((lnPid>0));do
		#lstrErrorTrap+="pid[$lnPidIndex]='$lnPid';"
		#lstrErrorTrap+="CMD[$lnPidIndex]='`ps --no-header -p $lnPid -o cmd&&:`';"
		lstrErrorTrap+="pidCMD[$lnPidIndex]='`ps --no-header -o pid,cmd -p $lnPid&&:`';"
		lnPid="`grep PPid /proc/$lnPid/status |cut -f2&&:`"
		((lnPidIndex++))&&:
	done
	
	if [[ -n "$lstrBashSourceListTrap" ]] && [[ "${lstrBashSourceListTrap}" != *bash_completion ]];then
	 	# if "${BASH_SOURCE[@]-}" has something, it is running from a script, otherwise it is a command on the shell beying typed by user, and wont mess development...
	 	if [[ -f "${SECstrFileErrorLog-}" ]];then #SECstrFileErrorLog not set may happen once..
			echo "$lstrErrorTrap" >>"$SECstrFileErrorLog";
		fi
		echo "$lstrErrorTrap" |sed -r 's";"\n\t"g' >>/dev/stderr;
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
	local lstrCriticalMsg=" CRITICAL!!! unable to continue!!! hit 'ctrl+c' to fix your code or report bug!!! "
#	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$lstrCriticalMsg" >>"/tmp/.SEC.CriticalMsgs.`id -u`.log"
	_SECFUNClogMsg "$SECstrFileCriticalErrorLog" "$lstrCriticalMsg"
	if test -t 0;then
		while true;do
			#read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m CRITICAL!!! unable to continue!!! press 'ctrl+c' to fix your code or report bug!!! \E[0m"`" >&2
			read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m${lstrCriticalMsg}\E[0m"`" >>/dev/stderr
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

#function _SECFUNCcheckIfIsArrayAndInit() { #help only simple array, not associative -A arrays...
#	#echo ">>>>>>>>>>>>>>>>${1}" >>/dev/stderr
#	if ${!1+false};then 
#		declare -a -x -g ${1}='()';
#	else
#		local lstrCheck="`declare -p "$1" 2>/dev/null`";
#		if [[ "${lstrCheck:0:10}" != 'declare -a' ]];then
#			echo "$1='${!1-}' MUST BE DECLARED AS AN ARRAY..." >>/dev/stderr
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

# IMPORTANT!!!!!!! do not use echoc or ScriptEchoColor on functions here, may become recursive infinite loop...

######### EXTERNAL VARIABLES can be set by user #########
: ${SEC_DEBUG:=false}
if [[ "$SEC_DEBUG" != "true" ]]; then #compare to inverse of default value
	export SEC_DEBUG=false # of course, np if already "false"
fi

# this lets -x fully works
: ${SEC_DEBUGX:=false}
if [[ "$SEC_DEBUGX" != "true" ]]; then #compare to inverse of default value
	export SEC_DEBUGX=false # of course, np if already "false"
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

: ${SECnPidMax:=`cat /proc/sys/kernel/pid_max`}

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
	if ! declare -p "$lstrArrayId" >>/dev/null;then
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
	eval 'echo "${#'$lstrArrayId'[@]}"'
	
	return 0
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
	
	# valid env var
	if ! declare -p "$lstrArrayId" >>/dev/null;then
		SECFUNCechoErrA "invalid lstrArrayId='$lstrArrayId'"
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
#	#export |grep "${lstrArrayId}=" >>/dev/stderr #@@@R
#	#export >>/dev/stderr #@@@R
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
	
	if ! declare -p "$lstrArrayId" >>/dev/null;then
		SECFUNCechoErrA "invalid lstrArrayId='$lstrArrayId'"
		echo "0"
		return 1
	fi
	
	local lstrArrayAllElements="${lstrArrayId}[@]"
	#local lstrArraySize="#${lstrArrayId}[@]"
	#local lnSize="${!lstrArraySize}"
	local lnIndex=0
	for strTmp in "${!lstrArrayAllElements}";do
#			echo "strTmp='$strTmp' $lnIndex" >>/dev/stderr
#			declare -p "$lstrArrayId" >>/dev/stderr
			
		local lbUnset=false
		if [[ -z "$lstrMatch" ]];then
			if [[ -z "$strTmp" ]];then
				lbUnset=true
			fi
		elif [[ "$strTmp" =~ $lstrMatch ]];then
			lbUnset=true
		fi
		
		if $lbUnset;then
			eval "unset $lstrArrayId[$lnIndex]"
#			declare -p "$lstrArrayId" >>/dev/stderr
		fi
		((lnIndex++))&&:
	done
	
	return 0 # important to have this default return value in case some non problematic command fails before returning
}

: ${SECstrBashSourceFiles:=}
export SECstrBashSourceFiles
#_SECFUNCcheckIfIsArrayAndInit SECastrBashSourceFilesPrevious

: ${SECbBashSourceFilesShow:=false}
export SECbBashSourceFilesShow

: ${SECbBashSourceFilesForceShowOnce:=false}
export SECbBashSourceFilesForceShowOnce

function SECFUNCbashSourceFiles() {
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
	#for lstrSourceFile in "${BASH_SOURCE[@]-}";do
	if((`SECFUNCarraySize BASH_SOURCE`>0));then
		for lnSourceFileIndex in "${!BASH_SOURCE[@]}";do
#			echo ">>>lnSourceFileIndex=$lnSourceFileIndex,${#BASH_SOURCE[@]}-1,${BASH_SOURCE[lnSourceFileIndex]}" >>/dev/stderr
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
#		echo "$lstrFuncList" >>/dev/stderr
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
	
	declare -F \
		|grep "pSECFUNC" \
		|sed 's"declare .* pSECFUNC"export -f pSECFUNC"' \
		|sed 's".*"&;"' \
		|grep "export -f pSECFUNC"
}

export SECstrUserHomeConfigPath="$HOME/.ScriptEchoColor"
if [[ ! -d "$SECstrUserHomeConfigPath" ]]; then
  mkdir "$SECstrUserHomeConfigPath"
fi

function SECFUNCshowHelp() { #help [$FUNCNAME] if function name is supplied, a help will be shown specific to such function.
#SECFUNCshowHelp_help \tOtherwise a help will be shown to the script file as a whole.
#SECFUNCshowHelp_help \tMultiline help is supported.
#SECFUNCshowHelp_help \tbasically help lines must begin with #help or #FunctionName_help, see examples on scripts.
	SECFUNCdbgFuncInA;
	local lbSort=false
	local lstrScriptFile="$0"
	local lstrColorizeEcho=""
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
		elif [[ "$1" == "--checkMissPlacedFunctionHelps" ]];then #SECFUNCshowHelp_help list all functions help tokens on *.sh scripts recursively
			grep "#[[:alnum:]]*_help " * --include="*.sh" -rIoh
			SECFUNCdbgFuncOutA;return
		elif [[ "${1-}" == "--dummy-selftest" ]];then #SECFUNCshowHelp_help ([lstrScriptFile] <lbSort> this is not an actual option, it is just to show self tests only...)
			#SECFUNCshowHelp_help (This is the multiline test at an option.)
			:
		else
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	# Colors: light blue=94, light yellow=93, light green=92, light cyan=96, light red=91
	#local le=$(printf '\033') # Escape char to provide colors on sed on terminal
	local lsedMatchRequireds='([<])([^>]*)([>])'
	local lsedMatchOptionals='([[])([^]]*)([]])'
	local lsedColorizeOptionals="s,$lsedMatchOptionals,${SECcolorCancel}${SECcharEsc}[96m[\2]${SECcolorCancel},g" #!!!ATTENTION!!! this will match the '[' of color formatting and will mess things up if it is not the 1st to be used!!!
	local lsedColorizeRequireds="s,$lsedMatchRequireds,${SECcolorCancel}${SECcolorLightRed}<\2>${SECcolorCancel},g"
	local lsedColorizeTheOption="s,([[:blank:]])(-?-[^[:blank:]]*)([[:blank:]]),${SECcolorCancel}${SECcharEsc}[92m\1\2\3${SECcolorCancel},g"
	local lsedTranslateEscn='s,\\n,\n,g'
	local lsedTranslateEsct='s,\\t,\t,g'

	function _SECFUNCshowHelp_SECFUNCmatch(){
		#read lstrLine
		IFS= read -r lstrLine #IFS= required to prevent skipping \t, and -r required to not interpret "\"
		#IFS=$'\n' read lstrLine
		
		local lstrMatch="$1"
		local lstrVarId="`echo "$lstrLine" |sed -r "s,.*$lstrMatch.*,\2,"`"
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
			echo "$lstrLine" |sed -r "s,$lstrMatch,\1\2='${SECcolorLightYellow}${!lstrVarId}${SECcolorLightRed}'\3,"
		else
			echo "$lstrLine"
		fi
	}
	function _SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues(){
		local lstrLineMain;
		#while	read lstrLineMain;do
		while	IFS= read -r lstrLineMain;do #IFS= required to prevent skipping /t
		#while	IFS=$'\n' read lstrLineMain;do
			#echo "lstrLine='$lstrLine'" >>/dev/stderr
			echo "$lstrLineMain" \
				|_SECFUNCshowHelp_SECFUNCmatch "$lsedMatchOptionals" \
				|_SECFUNCshowHelp_SECFUNCmatch "$lsedMatchRequireds" 
		done
	}
	
	######################### a text line passed to --colorize
	if [[ -n "${lstrColorizeEcho}" ]];then
		echo "$lstrColorizeEcho" \
			|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
			|sed -r "$lsedColorizeOptionals" \
			|sed -r "$lsedColorizeRequireds" \
			|sed -r "$lsedColorizeTheOption" \
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
			SECFUNCechoErrA "unable to access script file '${lastrFile[0]}'"
			SECFUNCdbgFuncOutA;return 1
		fi
		#fix duplicity on array
		#SECstrIFSbkp="$IFS";IFS=$'\n';lastrFile=(`printf "%s\n" "${lastrFile[@]}" |sort -u`);IFS="$SECstrIFSbkp"
		IFS=$'\n' declare -a lastrFile=(`printf "%s\n" "${lastrFile[@]}" |sort -u`) #the declare is to force IFS be set only for this line of code
	fi
	
	local lgrepNoFunctions="^[[:blank:]]*function .*"
	if [[ -n "$lstrFunctionNameToken" ]];then
		if [[ -n `echo "$lstrFunctionNameToken" |tr -d '[:alnum:]_'` ]];then
			SECFUNCechoErrA "invalid prefix '$lstrFunctionNameToken'"
			SECFUNCdbgFuncOutA;return 1
		fi
		
		local lstrRegexFuncMatch="^[[:blank:]]*function ${lstrFunctionNameToken}[[:blank:]]*().*{.*#help"
		local lstrFileNameWithMatch=""
		for lstrFile in "${lastrFile[@]}";do
			if grep -q "$lstrRegexFuncMatch" "$lstrFile";then
				lstrFileNameWithMatch=" at `basename "$lstrFile"`"
				break;
			fi
		done
		
		echo -e "\t\E[0m\E[0m\E[94m$lstrFunctionNameToken\E[0m\E[93m()\E[0m${lstrFileNameWithMatch}"
		
		######################### function description
		local lstrFuncDesc=`grep -h "$lstrRegexFuncMatch" "${lastrFile[@]}" |sed -r "s;^function ${lstrFunctionNameToken}[[:blank:]]*\(\).*\{.*#help (.*);\1;"`
		if [[ -n "$lstrFuncDesc" ]];then
			echo -e "\t$lstrFuncDesc" \
				|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
				|sed -r "$lsedColorizeOptionals" \
				|sed -r "$lsedColorizeRequireds" \
				|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		fi
		
		lstrFunctionNameToken="${lstrFunctionNameToken}_"
		lgrepNoFunctions="^$" #will actually "help?" by removing empty lines
	else
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
	local lsedOptionsText='.*\[\[(.*)\]\].*'
#	if $lbAll;then lsedOptionsText=".*";fi
	local lsedOptionsAndHelpText="s,${lsedOptionsText}(#${lstrFunctionNameToken}help.*),\1\2,"
	local lsedRemoveTokenOR='s,(.*"[[:blank:]]*)[|]{2}([[:blank:]]*".*),\1\2,' #if present
#	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'${SECcharEsc}'[0m'${SECcharEsc}'[92m\1'${SECcharEsc}'[0m\t,g'
	#local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g'
	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'${SECcharEsc}'[0m'${SECcharEsc}'[92m\1'${SECcharEsc}'[0m\t,g' #some options may not have -- or -, so this redundantly colorizes all options for sure
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
		|sed -r "$lsedOptionsAndHelpText" \
		|sed -r "$lsedRemoveTokenOR" \
		|sed -r "$lsedRemoveHelpToken" \
		|_SECFUNCshowHelp_SECFUNCsedWithDefaultVarValues \
		|sed -r "$lsedColorizeOptionals" \
		|sed -r "$lsedColorizeRequireds" \
		|sed -r "$lsedRemoveComparedVariable" \
		|sed -r "$lsedColorizeTheOption" \
		|sed -r "$lsedTranslateEsct" \
		|$cmdSort \
		|sed -r "$lsedTranslateEscn" \
		|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		#|sed -r "$lsedAddNewLine"
		
	SECFUNCdbgFuncOutA;
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
	for lstrFuncId in ${lastrFunctions[@]-};do
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
}

#function SECFUNCisNumberChkExit(){
#	if ! SECFUNCisNumber "$@";then
#		
#	fi
#}

function SECFUNCisNumber(){ #help "is float" check by default
	local bDecimalCheck=false
	local bNotNegativeCheck=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
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
		elif [[ -z "`echo "$1" |tr -d "[:digit:].-"`" ]];then #this is the actual number that is negative!
			break
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
			echo " [`SECFUNCdtTimeForLogMessages`]SECERROR:invalid option '$1'" >>/dev/stderr; 
			return 1
		fi
		shift
	done
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECERROR: ${lstrCaller}$@"
	if ! $lbLogOnly;then
		if $SEC_MsgColored;then
			echo -e "\E[0m\E[91m${l_output}\E[0m" >>/dev/stderr
		else
			echo "${l_output}" >>/dev/stderr
		fi
	fi
	echo "${l_output}" >>"$SECstrFileErrorLog"
}

function SECFUNCmsgCtrl() {
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
	if [[ "$SEC_DEBUG" != "true" ]];then # to not loose more time
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
#		SECFUNCppidList --comm "\n" >>/dev/stderr 2>&1
#		echo "$$,$PPID" >>/dev/stderr
#		(set |grep "^SECastr";) >>/dev/stderr 2>&1
#		set |grep SECinstallPath >>/dev/stderr 2>&1
#		declare -p SECastrFunctionStack >>/dev/stderr 2>&1
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
		#declare -p SECastrBashDebugFunctionIds >>/dev/stderr
		#set |grep "^SEC" >>/dev/stderr
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
			echo -e "\E[0m\E[97m\E[47m${l_output}\E[0m" >>/dev/stderr
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

function SECFUNCechoWarn() { #help
#	if [[ -f "${SECstrFileMessageToggle}.WARN.$$" ]];then
#		rm "${SECstrFileMessageToggle}.WARN.$$" 2>/dev/null
#		if $SEC_WARN;then SEC_WARN=false;	else SEC_WARN=true; fi
#	fi
	SECFUNCmsgCtrl WARN
	if [[ "$SEC_WARN" != "true" ]];then # to not loose time
		return 0
	fi
	
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
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECWARN: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[93m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
}

function SECFUNCechoBugtrack() { #help
#	if [[ -f "${SECstrFileMessageToggle}.BUGTRACK.$$" ]];then
#		rm "${SECstrFileMessageToggle}.BUGTRACK.$$" 2>/dev/null
#		if $SEC_BUGTRACK;then SEC_BUGTRACK=false;	else SEC_BUGTRACK=true; fi
#	fi
	SECFUNCmsgCtrl BUGTRACK
	if [[ "$SEC_BUGTRACK" != "true" ]];then # to not loose time
		return 0
	fi
	
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
	
	###### main code
	local l_output=" [`SECFUNCdtTimeForLogMessages`]SECBUGTRACK: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[36m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
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
  shift
  
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

function SECFUNCcheckActivateRunLog() {
	local lbRestoreDefaults=false
	local lbInheritParentLog=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCcheckActivateRunLog_help
			SECFUNCshowHelp $FUNCNAME
			return
		elif [[ "$1" == "--restoredefaultoutputs" ]];then #SECFUNCcheckActivateRunLog_help restore default outputs to stdout and stderr
			lbRestoreDefaults=true
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
	
	if $SECbRunLogDisable || $lbRestoreDefaults;then
#		exec 1>/dev/stdout
#		exec 2>/dev/stderr
		if $SECbRunLogEnabled;then
			exec 1>&3 2>&4 #restore (if not yet enabled it would redirect to nothing and bug out)
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
		#		SEC_WARN=true SECFUNCechoWarnA "stderr and stdout copied to '$SECstrRunLogFile'" >>/dev/stderr
				echo " SECINFO: stderr and stdout copied to '$SECstrRunLogFile'." >>/dev/stderr
			#	exec 1>"$SECstrRunLogFile"
			#	exec 2>"$SECstrRunLogFile"
				exec 3>&1 4>&2 #backup
				exec > >(tee "$SECstrRunLogFile")
				exec 2>&1
				
				SECnRunLogTeePid="`pgrep -fx "tee $SECstrRunLogFile"`"
				SECstrRunLogPipe="`readlink /proc/$$/fd/1`" #Must be updated because it was redirected.
			
				if $SECbRunLogPidTree;then
					local lstrLogTreeFolder="$SECstrTmpFolderLog/PidTree/`SECFUNCppidList --reverse --comm "/"`"
					mkdir -p "$lstrLogTreeFolder"
					ln -sf "$SECstrRunLogFile" "$lstrLogTreeFolder/`basename "$SECstrRunLogFile"`"
				fi
			
				SECbRunLogEnabled=true
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

function SECFUNCrestoreAliases() {
	source "$SECstrFileLibFast";
}

export SECbScriptSelfNameChanged=false
if SECFUNCscriptSelfNameCheckAndSet;then
	SECbScriptSelfNameChanged=true
fi

export SECstrUserScriptCfgPath="${SECstrUserHomeConfigPath}/${SECstrScriptSelfName}"

export SECstrTmpFolderLog="$SEC_TmpFolder/log"
mkdir -p "$SECstrTmpFolderLog"

: ${SECbRunLogForce:=false} # the override default, only actually used at secLibsInit.sh
export SECbRunLogForce

: ${SECbRunLog:=false} # user can set this true at .bashrc, but applications inside scripts like `less` will not work properly
export SECbRunLog

: ${SECbRunLogParentInherited:=false}
export SECbRunLogParentInherited

export SECstrRunLogFileDefault="$SECstrTmpFolderLog/$SECstrScriptSelfName.$$.log" #this is named based on current script name; but the log may be happening already from its parent...
: ${SECstrRunLogFile:="$SECstrRunLogFileDefault"}
export SECstrRunLogFile

: ${SECbRunLogDisable:=false} #DO NOT EXPORT THIS ONE as subshells may have trouble to start logging... #TODO review this...

: ${SECbRunLogEnabled:=false}
export SECbRunLogEnabled

: ${SECstrRunLogPipe:=}
export SECstrRunLogPipe

: ${SECnRunLogTeePid:=0}
export SECnRunLogTeePid

: ${SECbRunLogPidTree:=true}
export SECbRunLogPidTree

#TODO !!!! complete this escaped colors list!!!! to, one day, improve main echoc
export SECcharTab=$'\t' #$(printf '\011') # this speeds up instead of using `echo -e "\t"`
export SECcharNewLine=$'\n' # this speeds up instead of using `echo -e "\n"`
export SECcharNL=$'\n' # this speeds up instead of using `echo -e "\n"`
export SECcharCr=$'\r' # carriage return
#export SECcolorEscapeChar=$'\e' #$(printf '\033') # Escape char to provide colors on sed on terminal
export SECcharEsc=$'\e' #$(printf '\033') # Escape char to provide colors on sed on terminal
# so now, these are the terminal escaped codes (not the string to be interpreted)
export SECcolorLightRed="$SECcharEsc[91m"
export SECcolorLightYellow="$SECcharEsc[93m"
export SECcolorCancel="$SECcharEsc[0m"

SECFUNCcheckActivateRunLog #important to be here as shell may not be interactive so log will be automatically activated...

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcCore.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibCore=$$

