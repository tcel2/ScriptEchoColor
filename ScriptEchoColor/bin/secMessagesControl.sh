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

eval `secinit --base`

#export SEC_WARN=true
#export SEC_DEBUG=true
#export SEC_BUGTRACK=true

bWarn=false
bDebug=false
bBugtrack=false
bOn=false
bOff=false
nPid=""
bBashDebug=false
strFunctionNames=""
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
	elif [[ "$1" == "--all" || "$1" == "-a" ]];then #help all messages at once (least --bashdebug)
		bWarn=true
		bDebug=true
		bBugtrack=true
	elif [[ "$1" == "--bashdebug" || "$1" == "-g" ]];then #help <functionNames> will use the bash debug 'set -x' on beggining of a function and 'set +x' at its end;\n\trequires -d option;\n\tmultiple function names can be provided like "FUNC1 FUNC2";\n\tif functionNames is empty "", this debug will be turned off to all functions
		shift
		strFunctionNames="${1-}"
		
		bBashDebug=true
	else
		echoc -p "invalid option '$1'"
		exit 1 
	fi
	shift
done

if $bBashDebug;then
	if [[ -n "$strFunctionNames" ]];then
		if [[ -n "`echo "$strFunctionNames" |tr -d '[:alnum:]_ '`" ]];then
			echoc -p "invalid strFunctionNames='$strFunctionNames'"
			exit 1
		else
			SECastrBashDebugFunctionIds=($strFunctionNames)
			declare -p SECastrBashDebugFunctionIds
		fi
	else
		echoc -p "strFunctionNames required..."
		exit 1
	fi
fi

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
	else
		ps -o pid,ppid,tty,cmd -p "$nPid"
	fi

	strForce=""
	if $bOn;then
		strForce="on"
	elif $bOff;then
		strForce="off"
	fi
	
	astrCmdFiles=()
	if $bWarn;then
			strFile="${SECstrFileMessageToggle}.WARN.$nPid"
			astrCmdFiles+=("$strFile")
			echo "$strForce" |tee "$strFile"
	fi
	if $bDebug;then
			strFile="${SECstrFileMessageToggle}.DEBUG.$nPid"
			astrCmdFiles+=("$strFile")
			echo "$strForce" |tee "$strFile"
	fi
	if $bBugtrack;then
			strFile="${SECstrFileMessageToggle}.BUGTRACK.$nPid"
			astrCmdFiles+=("$strFile")
			echo "$strForce" |tee "$strFile"
	fi
	
	if $bBashDebug;then
			strFile="${SECstrFileMessageToggle}.BASHDEBUG.$nPid"
			astrCmdFiles+=("$strFile")
			
			# has an space ' ' because that file will be read as an array
			echo "${strFunctionNames} " |tee "$strFile"
	fi
	
	for strFile in "${astrCmdFiles[@]}";do
		echo
		echo "checking: strFile='$strFile'"
		SECFUNCdelay CheckCmdAccepted --init
		while [[ -f "$strFile" ]];do
			if [[ ! -d "/proc/$nPid" ]];then
				echoc -p "nPid='$nPid' died"
				exit 1
			fi
			echo -en "waiting command be accepted for strFile='$strFile' `SECFUNCdelay CheckCmdAccepted`s\r"
			sleep 1
		done
		echo
		echo "accepted: strFile='$strFile'"
	done
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
	
	if $bBashDebug;then
		# eval to make $strFunctionNames have its spaces considered and each word become an entry
		eval "export SECastrBashDebugFunctionIds=($strFunctionNames)"
	fi
	
	# must not be child to be interactive
	# unset SECvarFile will force the called script to create its own var db file
	#eval "unset SECvarFile; $strExec" 
	#SECFUNCarraysExport;bash -c "unset SECvarFile;$strExec" 
	SECFUNCexecOnSubShell "unset SECvarFile;$strExec" 
fi

