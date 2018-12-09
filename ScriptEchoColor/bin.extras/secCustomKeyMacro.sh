#!/bin/bash
# Copyright (C) 2018 by Henrique Abdalla
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

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
declare -A CFGastrCmdList
CFGastrCmdList=()
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t[strKeysPressed] will execute bound command for it"
    SECFUNCshowHelp --colorize "\tput at xbindkeys-config a command like ex.: $0 ALT+F8"
    SECFUNCshowHelp --colorize "\tnow every application can set/clear their custom binds for macros(scripts) and they will be run"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-b" || "$1" == "--bind" ]];then #help ~single <strKeyAndMod> <astrCommand>... will bind a key (with modifiers if set ex.: "ALT+F8") to a command
		shift
    strKeyAndMod="$1";shift
    astrCommand=("$@")
    sedGetArrayData="s@[^']*'(.*)'@\1@"
    CFGastrCmdList[$strKeyAndMod]="`declare -p astrCommand |sed -r "$sedGetArrayData"`"
    SECFUNCcfgWriteVar CFGastrCmdList
    declare -p CFGastrCmdList >&2
    exit 0
	elif [[ "$1" == "-l" || "$1" == "--listbindings" ]];then #help ~single
		declare -p CFGastrCmdList >&2
    exit 0
	elif [[ "$1" == "-c" || "$1" == "--clear" ]];then #help ~single <strKeyAndMod>... the keybinding
    shift
    for strKeyAndMod in "$@";do
      declare -p strKeyAndMod
      unset CFGastrCmdList[$strKeyAndMod]
    done
    SECFUNCcfgWriteVar CFGastrCmdList
    declare -p CFGastrCmdList >&2
    exit 0
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift&&: #will consume all remaining params
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

# Main code
strKeysPressed="$1"
#echo ">>>${CFGastrCmdList[$strKeysPressed]}<<<"
#echo "declare -a astrCmdToRun='${CFGastrCmdList[$strKeysPressed]}'"
eval "declare -a astrCmdToRun='${CFGastrCmdList[$strKeysPressed]}'"
#declare -p astrCmdToRun
if ! SECFUNCexecA -ce "${astrCmdToRun[@]}";then
  SECFUNCechoErrA "cmd failed with error $?: ${astrCmdToRun[*]}"
  exit 1
fi

# if a daemon or to prevent simultaneously running it: SECFUNCuniqueLock --waitbecomedaemon

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
