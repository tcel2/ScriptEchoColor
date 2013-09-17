#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

eval `echoc --libs-init`

#echo "parms: $@";echoc -w

bDoNotClose=false
bSkipCascade=false
while [[ "${1:0:2}" == "--" ]]; do
	if [[ "$1" == "--help" ]];then #help show this help
		grep "#help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #help (.*)'\t\1\t\2'"
		exit
	elif [[ "$1" == "--donotclose" ]];then #help keep xterm running after execution completes
		bDoNotClose=true
	elif [[ "$1" == "--skipcascade" ]];then #help keep xterm running after execution completes
		bSkipCascade=true
	else
		SECFUNCechoErrA "invalid option $1"
		exit 1
	fi
	shift
done


# konsole handles better ctrl+s ctrl+q BUT is 100% buggy to exec cmds :P
#xterm -e "echo \"TEMP xterm...\"; konsole --noclose -e bash -c \"FUNCinit;FUNCcheckLoop\""&

#xterm -e "echo \"TEMP xterm...\"; xterm -maximized -e \"FUNCFireWall\""& #maximize dont work properly...

#params="$@"
strDoNotClose=""
if $bDoNotClose;then
	strDoNotClose=";bash;"
fi

strSkipCascade=""
if $bSkipCascade;then
	strSkipCascade=" #skipCascade"
fi

#params=`SECFUNCparamsToEval --escapequotes "$@"`"${strDoNotClose}${strSkipCascade}"
export strFUNCexecParams=`SECFUNCparamsToEval "$@"`
function FUNCexecParams() {
	echo "Exec: $strFUNCexecParams"
	eval $strFUNCexecParams
	echoc -w -t 60
};export -f FUNCexecParams
#strExec="echo \"TEMP xterm...\"; xterm -e \"$params\"; read -n 1"
strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -e 'echo \"$1\";FUNCexecParams${strDoNotClose}${strSkipCascade}'\"; read -n 1"
echo "Exec: $strExec"
#echo -e "$strExec"

xterm -e "$strExec"&
# wait for the child to open
while ! ps --ppid $!; do
    sleep 1
done
kill -SIGINT $!

