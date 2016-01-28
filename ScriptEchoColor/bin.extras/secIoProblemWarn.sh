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

eval `secinit`

SECFUNCuniqueLock --waitbecomedaemon

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "If IO has problems and is not responding, this will warn the user about it."
		SECFUNCshowHelp
		exit 0
#	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
#		shift
#		strExample="${1-}"
#	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
#		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
#			shift
#			CFGstrTest="$1"
#		fi
#		
#		bCfgTest=true
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
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

strAudioFile="`SEC_SAYVOL=0 secSayStack.sh --stdout "problem with IO"`"
nPidDaemon=$$
nMainSleep=10
echo "nPidDaemon='$nPidDaemon'"

function FUNCCchecker(){
	echo "FUNCCchecker pid '$BASHPID'"
	while true;do
		echo "`SECFUNCdtFmt --logmessages`: checking IO..."
		echo "$RANDOM" >"/tmp/.$SECstrScriptSelfName.IO-check.tmp"
		kill -SIGUSR1 "$nPidDaemon"
		sleep $((nMainSleep/2))
	done
}

# Main code
trap "bPlayWarning=false" USR1
FUNCCchecker&
#nCheckerPid=$?
#echo "nCheckerPid='$nCheckerPid'"
while true;do
	bPlayWarning=true
	
	sleep $nMainSleep
	if $bPlayWarning;then
		echo "`SECFUNCdtFmt --logmessages`: play IO warning message strAudioFile='$strAudioFile'"
		play "$strAudioFile"
	else
		echo "`SECFUNCdtFmt --logmessages`: IO seems ok..."
	fi
done

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

