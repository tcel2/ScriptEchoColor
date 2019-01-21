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

source <(secinit)

bGtk=false
lbStopParams=false
bListProfiles=false
bForce1st=false
strProfile=""
bDaemon=false
bWait=true
varset --allowuser --default nDaemonSleep=60
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help show this help
		echo "runs unison with a pre-set of params"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--gtk" ]];then #help use the frontend, it will open anyway if there is no profile (or even with a profile)
		bGtk=true
	elif [[ "$1" == "--list" ]];then #help list profiles
		bListProfiles=true;
	elif [[ "$1" == "--daemon" ]];then #help keeps running endlessly
		bDaemon=true;
		bWait=false
	elif [[ "$1" == "--delay" ]];then #help <nDaemonSleep> changes the --daemon delay
		shift
		varset --show nDaemonSleep="${1-}"
	elif [[ "$1" == "--profile" ]];then #help <"profile name"> see --list
		shift
		strProfile="${1-}"
	elif [[ "$1" == "--force1st" ]];then #help forces propagate from 1st root to 2nd, makes it work like a "one way" mirroring/backuper, and do not ask questions to user
		bForce1st=true
	elif [[ "$1" == "--nowait" ]];then #help will not wait for user review of unison command (daemon will already not wait)
		bWait=false
	elif [[ "$1" == "--" ]];then #help remaining params after this are considered as not being options
		lbStopParams=true;
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
	if $lbStopParams;then
		break;
	fi
done

#if [[ -z "$nDaemonSleep" ]] || [[ -n "`echo "$nDaemonSleep" |tr -d "[:digit:]"`" ]];then
if ! SECFUNCisNumber -dn "$nDaemonSleep";then
	echoc -p "invalid nDaemonSleep='$nDaemonSleep'"
	exit 1
fi

if $bListProfiles;then
	cd "$HOME/.unison/"
	ls -1 *".prf" |sed 's".prf$""' |sed 's;.*;"&";'
	exit
fi

strFileProfile=""
if [[ -n "$strProfile" ]];then
	strFileProfile="$HOME/.unison/${strProfile}.prf"
	if [[ ! -f "$strFileProfile" ]];then
		echoc -p "no strProfile='$strProfile'"
		exit 1
#	else
#		#escape spaces
#		strProfile=$(echo "${strProfile}" |sed -r 's" "\\ "g')
	fi
fi

strCmdForce1st=""
if $bForce1st;then
	if [[ ! -f "$strFileProfile" ]];then
		echoc -p "bForce1st requires a profile"
		exit 1
	fi
	str1stRoot="`grep "^root = " "$strFileProfile" |head -n 1 |sed 's"root = ""'`"
	str1stRoot="`echo "$str1stRoot" |sed 's" "\ "g'`" #to escape spaces
	strCmdForce1st="-batch -force $str1stRoot"
fi

bAutoRun=false
if [[ -z "$strProfile" ]];then
	echoc --alert "without a profile, gtk mode is enabled"
	bGtk=true
	bAutoRun=true
fi

strUiMode="-ui text"
strExecutable="unison"
if $bGtk;then
	strExecutable="unison-gtk"
	strUiMode=""
fi

function FUNCrun() {
	# strProfile must be without quotes so an empty profile will not be evaluated as a parameter
	#echo "<$strProfile>"
  local lastrCmdRun=()
	if [[ -z "$strProfile" ]];then
    lastrCmdRun+=($strExecutable               -fastcheck true -times -retry 2 $strUiMode $strCmdForce1st "$@")
	else
    lastrCmdRun+=($strExecutable "$strProfile" -fastcheck true -times -retry 2 $strUiMode $strCmdForce1st "$@")
	fi
  local lstrEcho=$(SECFUNCparamsToEval "${lastrCmdRun[@]}")
	local lbRun=false
	
	if $bAutoRun;then
		lbRun=true
	else
		if $bWait;then
			echoc --info "$lstrEcho"
			if echoc -q "Run it?";then
				lbRun=true
			fi
		else
			lbRun=true
		fi
	fi

	if $lbRun;then
    if ! SECFUNCexecA -ce "${lastrCmdRun[@]}";then
			SECFUNCechoErrA "failed running '${lastrCmdRun[@]}' fix it or bug report"
			exit 1
		fi
	else
		exit
	fi
}

if $bDaemon;then
  SECFUNCuniqueLock --waitbecomedaemon
  
	while true; do
		FUNCrun "$@"
		echoc -w -t $nDaemonSleep
	done
else
	FUNCrun "$@"
fi

