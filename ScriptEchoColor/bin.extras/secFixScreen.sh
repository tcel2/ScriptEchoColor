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

: ${CFGfSleep:=5.0}
export CFGfSleep #help after each action

: ${CFGstrExec:="sudo"}
export CFGstrExec #help change to "exec" if you put such commands at sudoers

: ${CFGstrDisplay:=":1"}
export CFGstrDisplay #help the display for the new X

: ${CFGbUseNewXTrick:=true}
export CFGbUseNewXTrick #help opens a new X on each fix attempt

strExample="DefaultValue"
#CFGstrTest="Test"
astrRemainingParams=()
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
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
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
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

alias execA="SECFUNCexecA -ce $CFGstrExec"

astrRes=(`xrandr |egrep " [[:digit:]]+x[[:digit:]]+ " -o`)

trap 'sudo -k;echo "exit...;"' INT
if $CFGbUseNewXTrick && [[ "$CFGstrExec" == "sudo" ]];then
	execA uptime #just to activate sudo in case it is being used
fi
for strRes in "${astrRes[@]}";do
	echoc --info "if you can read this..."
	echoc --alert "HIT CTRL+C NOW!!!"	
	
	strSay="`echo "$strRes" |sed 's"x" by "'`"
	echoc --waitsay "$strSay"
	SECFUNCexecA -ce xrandr -s "$strRes"
	SECFUNCexecA -ce sleep $CFGfSleep
	
	if $CFGbUseNewXTrick;then
		execA X $CFGstrDisplay& 
		echoc --waitsay "starting X1"; 
		SECFUNCexecA -ce sleep $CFGfSleep
	
		execA pkill -f "X $CFGstrDisplay"
		echoc --waitsay "kill X $CFGstrDisplay"; 
		SECFUNCexecA -ce sleep $CFGfSleep
	fi
done
sudo -k #remove sudo permission promptly
echoc --waitsay "finished, unsuccessfully?"

