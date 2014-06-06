#!/bin/bash

eval `secinit --base`

export SEC_WARN=true

bWarn=false
bDebug=false
bBugtrack=false
nPid=""
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help show this help
		echo "Toggle the related messages for the specified pid"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--warn" ]];then #help <pid>
		shift
		nPid="${1-}"
		
		bWarn=true
	elif [[ "$1" == "--debug" ]];then #help <pid>
		shift
		nPid="${1-}"
		
		bDebug=true
	elif [[ "$1" == "--bugtrack" ]];then #help <pid>
		shift
		nPid="${1-}"
		
		bBugtrack=true
	elif [[ "$1" == "--all" ]];then #help <pid> all messages at once will be toggled (inverted)
		shift
		nPid="${1-}"
		
		bWarn=true
		bDebug=true
		bBugtrack=true
	else
		echoc -p "invalid option '$1'"
		exit 1 
	fi
	shift
done

if ! SECFUNClockFileAllowedPid --active --check "$nPid";then
	echoc -p "invalid nPid='$nPid'"
	exit 1
fi

if $bWarn;then
		echo "WARN.$nPid" |tee "${SECstrFileMessageToggle}.WARN.$nPid"
fi
if $bDebug;then
		echo "DEBUG.$nPid" |tee "${SECstrFileMessageToggle}.DEBUG.$nPid"
fi
if $bBugtrack;then
		echo "BUGTRACK.$nPid" |tee "${SECstrFileMessageToggle}.BUGTRACK.$nPid"
fi

