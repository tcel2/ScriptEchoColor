#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

source <(secinit --extras)

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
CFGstrTest="Test"
bSpeak=true
astrRemainingParams=()
bGetLogFile=false;
bChkIsRunning=false
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--getlogfile" || "$1" == "-g" ]];then #help 
		bGetLogFile=true
	elif [[ "$1" == "--isrunning" || "$1" == "-i" ]];then #help 
		bChkIsRunning=true
	elif [[ "$1" == "--nospeak" ]];then #help will not speak when ready
		bSpeak=false
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars --noshow #this will also show all config vars

strUnityLogDaemonId="${SECstrScriptSelfName}_UnityLog_Display${DISPLAY}"
strUnityLogDaemonId="`SECFUNCfixIdA -f -- "$strUnityLogDaemonId"`"
SECFUNCcfgWriteVar CFGstrUnityLogFile="$SECstrTmpFolderLog/.${strUnityLogDaemonId}.UnitySession.log"
#SECFUNCcfgWriteVar CFGstrUnityLogFile="$SECstrTmpFolderLog/.${SECstrScriptSelfName}_Display`SECFUNCfixIdA -f -- $DISPLAY`.UnitySession.log"

bWasAlreadyRunning=false
if SECFUNCuniqueLock --id "$strUnityLogDaemonId" --isdaemonrunning;then 
	bWasAlreadyRunning=true;
fi

if $bChkIsRunning;then
	if $bWasAlreadyRunning;then
		exit 0
	fi
	exit 1
elif $bGetLogFile;then
#	if $bWasAlreadyRunning;then
		echo "$CFGstrUnityLogFile"
		exit 0
#	else
#		echoc -p "Unity log monitor daemon not running yet!!!"
#		exit 1
#	fi
else
	if $bWasAlreadyRunning;then
		echoc --info "already running: $strUnityLogDaemonId"
		exit 0;
	else
		while true;do
			# START THE LOG
			# after this, user can safely screen lock
			SECFUNCuniqueLock --id "$strUnityLogDaemonId" --waitbecomedaemon
	#		SECFUNCcfgWriteVar CFGstrUnityLogFile="$SECstrTmpFolderLog/.$SECstrScriptSelfName.UnitySession.$$.log"
		
			strDBusUnityDestination="com.canonical.Unity.Launcher"
			strDBusUnityObjPath="/com/canonical/Unity/Session"
			astrCmd=(gdbus monitor -e -d "$strDBusUnityDestination" -o "$strDBusUnityObjPath")
#			"${astrCmd[@]}" >"$CFGstrUnityLogFile"&
			if $bSpeak;then
				strSayLogStarted="`SECFUNCseparateInWords --notype "${SECstrScriptSelfName%.sh}"` log starting."
				echoc --info --say "$strSayLogStarted"

				SECFUNCCwindowCmd --ontop --delay 1 "^$SECstrScriptSelfName$"
				SECFUNCexecA -c --echo zenity --timeout 10 --info --title "$SECstrScriptSelfName" --text "$strSayLogStarted"&
			fi

#			"${astrCmd[@]}"&&: >"$CFGstrUnityLogFile"
			"${astrCmd[@]}" |tee "$CFGstrUnityLogFile"
			
#			while pgrep -fx "${astrCmd[*]}";do # [*] to be one param only
#				echo "pid for cmd='${astrCmd[*]}'" >&2
#				sleep 5;
#			done
			SECFUNCechoErrA "Unity log monitor exited, restarting... cmd='${astrCmd[*]}'"
		done
	fi
fi

