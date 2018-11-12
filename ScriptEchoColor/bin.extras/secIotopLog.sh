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

source <(secinit --fast) #TODO --fast breaks SECFUNCcfgReadDB

#TODO : ${strEnvVarUserCanModify:="test"}
#TODO export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
#TODO export strEnvVarUserCanModify2 #help test
#TODO strExample="DefaultValue"
#TODO CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
#TODO SECFUNCcfgReadDB #after default variables value setup above
bDaemon=false

# these variables can be set b4 run by the user
: ${CFGnMinKB:=1000}
: ${CFGnMinPerc:=50}

: ${CFGnRMinKB:=$CFGnMinKB}
: ${CFGnRMinPerc:=$CFGnMinPerc}

: ${CFGnWMinKB:=$CFGnMinKB}
: ${CFGnWMinPerc:=$CFGnMinPerc}

declare -p CFGnMinKB CFGnMinPerc CFGnRMinKB CFGnRMinPerc CFGnWMinKB CFGnWMinPerc

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\tYou can change the variables options before running the script."
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
	elif [[ "$1" == "--daemon" ]];then #help
		bDaemon=true;
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
# moved to the end to not impact performance on critical moments... SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code
if $bDaemon;then
  SECFUNCuniqueLock --waitbecomedaemon
	while true;do # loop to keep retrying if iotop errors out, iotop will keep running delay=1 4eva
		if ! sudo /usr/sbin/iotop --batch --time --only --quiet --delay=1 --kilobytes 2>&1 |tee $HOME/log/iotop.log;then
			echoc -p "iotop error"
		fi
    echoc -w -t 1
	done
	exit #should not be reached
fi

#####
### below will just show a filtered log
#####

#~ tail -n 10000 $HOME/log/iotop.log \
	#~ |egrep -v "Total|Actual" \
	#~ |sed -r "s@(.{`tput cols`}).*@\1@" \
	#~ |awk "( \$5 > $nMinKB || \$7 > $nMinKB ) && ( \$9 > $nMinPerc || \$11 > $nMinPerc )"

#: ${CFGnColumns:=`tput cols`}
#nColumns=`stty -a |egrep "columns [[:digit:]]*" -o |cut -d ' ' -f2`
#nColumns=`stty size 2>/dev/null |cut -d" " -f2`
read nRows nColumns < <(stty size)

#TIME    TID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN      IO    COMMAND
tail -n 10000 $HOME/log/iotop.log \
	|egrep -v "Total|Actual" \
	|sed -r "s@(.{$nColumns}).*@\1@" \
	|awk "\$5 >= $CFGnRMinKB || \$7 >= $CFGnWMinKB || \$9 >= $CFGnRMinPerc || \$11 >= $CFGnWMinPerc"
#	|awk "\$5 >= $nRMinKB && \$7 >= $nWMinKB && \$9 >= $nRMinPerc && \$11 >= $nWMinPerc"
egrep "TIME.*DISK READ.*DISK WRITE.*IO.*COMMAND" $HOME/log/iotop.log #to help knowing what columns are at the end!

#TODO source <(secinit) #TODO --fast at beggining should be enough? or may be some simple function to init what is required there?
#TODO SECFUNCcfgAutoWriteAllVars #this will also show all config vars

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
