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

# BEFORE EVERYTHING: UNIQUE CHECK, SPECIAL CODE
if((`id -u`==0));then echo -e "\E[0m\E[33m\E[41m\E[1m\E[5m ScriptEchoColor is still beta, do not use as root... \E[0m" >>/dev/stderr;exit 1;fi

shopt -s expand_aliases
set -u #so when unset variables are expanded, gives fatal error

# TOP CODE
if ${SECinstallPath+false};then export SECinstallPath="`secGetInstallPath.sh`";fi; #to be faster
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcCore.sh") #no need for the array to be previously set empty

SECstrIFSbkp="$IFS";IFS=$'\n';SECastrFuncFilesShowHelp=(`printf "%s\n" "${SECastrFuncFilesShowHelp[@]}" |sort -u`);IFS="$SECstrIFSbkp" #fix duplicity on array

# MAIN CODE
#export SECstrBugTrackLogFile="/tmp/.SEC.BugTrack.`id -u`.log"

export _SECmsgCallerPrefix='`basename $0`,p$$,bp$BASHPID,bss$BASH_SUBSHELL,${FUNCNAME-}(),L$LINENO'
alias SECFUNCechoErrA="SECFUNCechoErr --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoDbgA="if ! \$SEC_DEBUGX;then set +x;fi;SECFUNCechoDbg --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoWarnA="SECFUNCechoWarn --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoBugtrackA="SECFUNCechoBugtrack --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "


# THESE ATOMIC FUNCTIONS are SPECIAL AND CAN COME HERE, they MUST DEPEND only on each other!!!
function _SECFUNClogMsg() { #<logfile> <params become message>
	local lstrLogFile="$1"
	shift
	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$@;" >>"$lstrLogFile"
}
function _SECFUNCbugTrackExec() {
	#(echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;$@;" && "$@" 2>&1) >>"$SECstrBugTrackLogFile"
#	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$@;" >>"$SECstrBugTrackLogFile"
	local lstrBugTrackLogFile="/tmp/.SEC.BugTrack.`id -un`.log"
	_SECFUNClogMsg "$lstrBugTrackLogFile" "$@"
	"$@" 2>>"$lstrBugTrackLogFile"
}
function _SECFUNCcriticalForceExit() {
	local lstrCriticalMsg=" CRITICAL!!! unable to continue!!! hit 'ctrl+c' to fix your code or report bug!!! "
#	echo " `date "+%Y%m%d+%H%M%S.%N"`,p$$;`basename "$0"`;$lstrCriticalMsg" >>"/tmp/.SEC.CriticalMsgs.`id -u`.log"
	_SECFUNClogMsg "/tmp/.SEC.CriticalMsgs.`id -un`.log" "$lstrCriticalMsg"
	while true;do
		#read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m CRITICAL!!! unable to continue!!! press 'ctrl+c' to fix your code or report bug!!! \E[0m"`" >&2
		read -n 1 -p "`echo -e "\E[0m\E[31m\E[103m\E[5m${lstrCriticalMsg}\E[0m"`" >>/dev/stderr
		sleep 1
	done
}

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

alias SECFUNCreturnOnFailA='if(($?!=0));then return 1;fi'
alias SECFUNCreturnOnFailDbgA='if(($?!=0));then SECFUNCdbgFuncOutA;return 1;fi'

export SECstrUserHomeConfigPath="$HOME/.ScriptEchoColor"
if [[ ! -d "$SECstrUserHomeConfigPath" ]]; then
  mkdir "$SECstrUserHomeConfigPath"
fi

function SECFUNCshowHelp() { #help [$FUNCNAME] if function name is supplied, a help will be shown specific to such function but only in case the help is implemented as expected (see examples on scripts).\n\tOtherwise a help will be shown to the script itself in the same manner.
	local lbColorizeEcho=false
	local lbSort=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]];then #SECFUNCshowHelp_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "${1-}" == "--colorize" || "${1-}" == "-c" ]];then #SECFUNCshowHelp_help helps to colorize specific text
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
#		if [[ "${lstrFunctionNameToken:0:10}" == "SECFUNCvar" ]];then
#			#TODO !!! IMPORTANT !!! this MUST be the only place on funcMisc.sh that funcVars.sh or anything from it is known about!!! BEWARE!!!!!!!!!!!!!!!!!! Create a validator on a package builder?
#			lastrFile=("$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh")
#		elif [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
		if [[ "${lstrFunctionNameToken:0:7}" == "SECFUNC" ]];then
			lastrFile=("${SECastrFuncFilesShowHelp[@]}")
		else
			# as help text are comments and `type` wont show them, the real script files is required...
			SECFUNCechoErrA "unable to access script file '${lastrFile[0]}'"
			return 1
		fi
		#fix duplicity on array
		SECstrIFSbkp="$IFS";IFS=$'\n';lastrFile=(`printf "%s\n" "${lastrFile[@]}" |sort -u`);IFS="$SECstrIFSbkp"
	fi
	
	local lgrepNoFunctions="^[[:blank:]]*function .*"
	if [[ -n "$lstrFunctionNameToken" ]];then
		if [[ -n `echo "$lstrFunctionNameToken" |tr -d '[:alnum:]_'` ]];then
			SECFUNCechoErrA "invalid prefix '$lstrFunctionNameToken'"
			return 1
		fi
		
		echo -e "  \E[0m\E[0m\E[94m$lstrFunctionNameToken\E[0m\E[93m()\E[0m"
		
		# for function description
		local lstrFuncDesc=`grep -h "function ${lstrFunctionNameToken}[[:blank:]]*().*{.*#help" "${lastrFile[@]}" |sed -r "s;^function ${lstrFunctionNameToken}[[:blank:]]*\(\).*\{.*#help (.*);\1;"`
		if [[ -n "$lstrFuncDesc" ]];then
			echo -e "\t$lstrFuncDesc" \
				|sed -r "$lsedColorizeOptionals" \
				|sed -r "$lsedColorizeRequireds" \
				|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		fi
		
		lstrFunctionNameToken="${lstrFunctionNameToken}_"
		lgrepNoFunctions="^$" #will actually "help?" by removing empty lines
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
	#local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g'
	local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[_[:alnum:]{}-]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t'$le'[0m'$le'[92m\1'$le'[0m\t,g' #some options may not have -- or -, so this redundantly colorizes all options for sure
	#local lsedRemoveComparedVariable='s,[[:blank:]]*"\$[-_[:alnum:]{}]*"[[:blank:]]*==[[:blank:]]*"([-_[:alnum:]]*)"[[:blank:]]*,\t\1\t,g' #some options may not have -- or -, so this redundantly colorizes all options for sure
	local lsedRemoveHelpToken='s,#'${lstrFunctionNameToken}'help,,'
#	local lsedColorizeRequireds='s,#'${lstrFunctionNameToken}'help ([^<]*)[<]([^>]*)[>],\1'$le'[0m'$le'[91m<\2>'$le'[0m,g'
#	local lsedColorizeOptionals='s,#'${lstrFunctionNameToken}'help ([^[]*)[[]([^]]*)[]],\1'$le'[0m'$le'[96m[\2]'$le'[0m,g'
	#local lsedAddNewLine='s".*"&\n"'
	cat "${lastrFile[@]}" \
		|egrep -v "$lgrepNoCommentedLines" \
		|egrep -v "$lgrepNoFunctions" \
		|grep  -w "$lgrepMatchHelpToken" \
		|sed -r "$lsedOptionsAndHelpText" \
		|sed -r "$lsedRemoveTokenOR" \
		|sed -r "$lsedRemoveHelpToken" \
		|sed -r "$lsedColorizeOptionals" \
		|sed -r "$lsedColorizeRequireds" \
		|sed -r "$lsedRemoveComparedVariable" \
		|sed -r "$lsedColorizeTheOption" \
		|sed -r "$lsedTranslateEsct" \
		|$cmdSort \
		|sed -r "$lsedTranslateEscn" \
		|cat #this last cat is useless, just to help coding without typing '\' at the end all the time..
		#|sed -r "$lsedAddNewLine"
}
function SECFUNCshowFunctionsHelp() { #help show functions specific help
	#set -x
	if [[ "${1-}" == "--help" ]];then #SECFUNCshowFunctionsHelp show this help
		#this option also prevents infinite loop for this script help
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	echo "`basename "$0"` Functions:"
	local lsedFunctionNameOnly='s".*(SECFUNC.*)\(\).*"\1"'
	local lastrFunctions=(`grep "^[[:blank:]]*function SECFUNC" "$0" |grep "#help" |sed -r "$lsedFunctionNameOnly"`)
	lastrFunctions=(`echo "${lastrFunctions[@]-}" |tr " " "\n" |sort`)
	for lstrFuncId in ${lastrFunctions[@]-};do
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
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCechoErr_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCechoErr_help is the name of the function calling this one
			shift
			lstrCaller="${1}: "
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoErr_help <FUNCNAME>
			shift
			SEClstrFuncCaller="${1}"
#		elif [[ "$1" == "--skiptime" ]];then #SECFUNCechoErr_help to be used at SECFUNCdtFmt preventing infinite loop
#			lbShowTime=false
		else
			echo "[`SECFUNCdtTimeForLogMessages`]SECERROR:invalid option '$1'" >>/dev/stderr; 
			return 1
		fi
		shift
	done
	
	###### main code
	local l_output="[`SECFUNCdtTimeForLogMessages`]SECERROR: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e " \E[0m\E[91m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
	echo "${l_output}" >>"$SECstrFileErrorLog"
}

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

function SECFUNCechoDbg() { #help will echo only if debug is enabled with SEC_DEBUG
	# Log is stopped on the alias #set +x
	_SECFUNCmsgCtrl DEBUG
	if [[ "$SEC_DEBUG" != "true" ]];then # to not loose more time
		return 0
	fi
	
	###### options
	local lstrCaller=""
	local SEClstrFuncCaller=""
	local lbFuncIn=false
	local lbFuncOut=false
	local lbStopParams=false
	#declare -A lastrVarId=() #will be local
	local lastrVarId=()
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
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
		elif [[ "$1" == "--vars" ]];then #SECFUNCechoDbg_help show variables values, must be last option, all remaining params will be used...
			shift
			while [[ -n "${1-}" ]];do
				lastrVarId+=("$1")
				shift #will consume all remaining params
			done
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
		_dtSECFUNCdebugTimeDelayArray[$SEClstrFuncCaller]="`date +"%s.%N"`"
		strFuncInOut="Func-IN: "
		SECastrFunctionStack+=($SEClstrFuncCaller)
		SECFUNCechoDbg_updateStackVars
	elif $lbFuncOut;then
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
	if SECFUNCechoDbg_isOnTheList	$SEClstrFuncCaller || 
	   SECFUNCechoDbg_isOnTheList	$lstrLastFuncId;
	then
		lbBashDebug=true
	fi
	
#	local lbBashDebug=false
#	if((${#SECastrBashDebugFunctionIds[@]}>0));then
#		local lnIndex
#		for lnIndex in ${!SECastrBashDebugFunctionIds[@]};do
#			local strBashDebugFunctionId="${SECastrBashDebugFunctionIds[lnIndex]}"
#			if [[ "$SEClstrFuncCaller" == "$strBashDebugFunctionId" ]] ||
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
		if [[ "$SEClstrFuncCaller" != "$SEC_DEBUG_FUNC" ]];then
			lbDebug=false
		fi
	fi
	
	if $lbDebug;then
		local lstrText=""
		if((`SECFUNCarraySize lastrVarId`>0));then
			for lstrVarId in ${lastrVarId[@]};do
				lstrText+="$lstrVarId='${!lstrVarId-}' "
			done
		else
			lstrText="$@"
		fi
		local l_output="[`SECFUNCdtTimeForLogMessages`]SECDEBUG: ${strFuncStack}${lstrCaller}${strFuncInOut}$lstrText"
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

function SECFUNCechoWarn() { #help
#	if [[ -f "${SECstrFileMessageToggle}.WARN.$$" ]];then
#		rm "${SECstrFileMessageToggle}.WARN.$$" 2>/dev/null
#		if $SEC_WARN;then SEC_WARN=false;	else SEC_WARN=true; fi
#	fi
	_SECFUNCmsgCtrl WARN
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
	local l_output="[`SECFUNCdtTimeForLogMessages`]SECWARN: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e " \E[0m\E[93m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
}

function SECFUNCechoBugtrack() { #help
#	if [[ -f "${SECstrFileMessageToggle}.BUGTRACK.$$" ]];then
#		rm "${SECstrFileMessageToggle}.BUGTRACK.$$" 2>/dev/null
#		if $SEC_BUGTRACK;then SEC_BUGTRACK=false;	else SEC_BUGTRACK=true; fi
#	fi
	_SECFUNCmsgCtrl BUGTRACK
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
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCechoWarn_help <FUNCNAME>
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
	local l_output="[`SECFUNCdtTimeForLogMessages`]SECBUGTRACK: ${lstrCaller}$@"
	if $SEC_MsgColored;then
		echo -e "\E[0m\E[36m${l_output}\E[0m" >>/dev/stderr
	else
		echo "${l_output}" >>/dev/stderr
	fi
}

# LAST THINGS CODE
if [[ `basename "$0"` == "funcCore.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibCore=$$

