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

export SECbRunLog=true
source <(secinit)

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test

bXScreenSaverKeepAliveDaemon=false
strExample="DefaultValue"
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Without parameters, it will be a simple lock request."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--XScreenSaverKeepAliveDaemon" || "$1" == "-d" ]];then #help ~daemon starts the XScreenSaverKeepAliveDaemon
		bXScreenSaverKeepAliveDaemon=true;
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

function FUNCisXSS(){
	SECFUNCexecA -ce pgrep -f "^xscreensaver"
};export -f FUNCisXSS

if $bXScreenSaverKeepAliveDaemon;then
	SECFUNCuniqueLock --waitbecomedaemon --id "${SECstrScriptSelfName}_XScreenSaverKeepAlive"
	while true;do 
		if ! FUNCisXSS;then 
			if ! SECFUNCexecA -ce xscreensaver -nosplash;then
				echoc -p "failed to start xscreensaver, why?"
				sleep 3
			fi
		fi; 
		sleep 1;
	done
	SECFUNCechoErrA "should not have reached here..."
	exit 1
fi

#echo "SECbRunLog='$SECbRunLog'"
#xterm -e 'bash -c "while ! xscreensaver-command --lock;do echo retryAt\$SECONDS; sleep 1;done;echo locked;sleep 60"'

function FUNClockLoop(){
	source <(secinit) #this will initialize the logging inside xterm...
#	echo "SECbRunLog='$SECbRunLog'"
	
	while true;do
		if FUNCisXSS;then
			SECFUNCexecA -ce xscreensaver-command --lock;nRet=$?
			if((nRet==0));then 
				echoc --info "locked";
				break;
			fi
		
			if((nRet==255));then
				echoc --info "was already locked";
				break;
			fi
		else
			SECFUNCechoWarnA "xscreensaver not running yet"
		fi
		
		SECFUNCechoWarnA "retryAt $SECONDS"; 
		
		sleep 1;
	done;
	
	echoc -w -t 60
};export -f FUNClockLoop

SECFUNCexecA -ce xterm -e FUNClockLoop

