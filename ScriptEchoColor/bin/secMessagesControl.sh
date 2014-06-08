#!/bin/bash

eval `secinit --base`

export SEC_WARN=true
export SEC_DEBUG=true
export SEC_BUGTRACK=true

alias SECFUNCsingleLetterOptionsA='SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" '
function SECFUNCsingleLetterOptions() { #add this to the top of your options loop: eval "set -- `SECFUNCsingleLetterOptionsA "$@"`"; #it will expand joined single letter options to separated ones like in '-abc' to '-a' '-b' '-c' 
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

bWarn=false
bDebug=false
bBugtrack=false
bOn=false
bOff=false
nPid=""
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	eval "set -- `SECFUNCsingleLetterOptionsA "$@"`"
	if [[ "$1" == "--help" ]];then #help show this help
		echo "[options] <pid>; in this case such pid will have its messages toggled or forced."
		echo "[options] <custom params to be run>; in this case, messages can be optionally turned ON only."
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--on" ]];then #help will force enable all requested messages overhidding toggle mode
		bOn=true
	elif [[ "$1" == "--off" ]];then #help will force disable all requested messages overhidding toggle mode
		bOff=true
#	elif [[ "$1" == "--pid" || "$1" == "-p" ]];then #help <pid> pid to deal with instead of running a command
#		shift
#		nPid="${1-}"
	elif [[ "$1" == "--warn" || "$1" == "-w" ]];then #help
		bWarn=true
	elif [[ "$1" == "--debug" || "$1" == "-d" ]];then #help
		bDebug=true
	elif [[ "$1" == "--bugtrack" || "$1" == "-b" ]];then #help
		bBugtrack=true
	elif [[ "$1" == "--all" || "$1" == "-a" ]];then #help all messages at once
		bWarn=true
		bDebug=true
		bBugtrack=true
	else
		echoc -p "invalid option '$1'"
		exit 1 
	fi
	shift
done

if [[ -z "${1-}" ]];then
	echoc -p "<pid> or <commandsToBeRun> expected..."
	exit 1
fi

if [[ -z "`echo "$1" |tr -d "[:digit:]"`" ]];then
	# has only digits
	nPid="$1"
fi

if((nPid>0));then
	if ! SECFUNClockFileAllowedPid --active --check "$nPid";then
		echoc -p "invalid nPid='$nPid'"
		exit 1
	fi

	strForce=""
	if $bOn;then
		strForce="on"
	elif $bOff;then
		strForce="off"
	fi
	
	if $bWarn;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.WARN.$nPid"
	fi
	if $bDebug;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.DEBUG.$nPid"
	fi
	if $bBugtrack;then
			echo "$strForce" |tee "${SECstrFileMessageToggle}.BUGTRACK.$nPid"
	fi
else
	strExec=`SECFUNCparamsToEval "$@"`
	if $bWarn;then
			export SEC_WARN=true
	fi
	if $bDebug;then
			export SEC_DEBUG=true
	fi
	if $bBugtrack;then
			export SEC_BUGTRACK=true
	fi
	eval "$strExec"
fi

