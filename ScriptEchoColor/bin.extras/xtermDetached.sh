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

#echo "All Params: $@"

#echo "SECvarFile=$SECvarFile";ls -l "$SECvarFile"
eval `secinit`
#echo "SECvarFile=$SECvarFile";ls -l "$SECvarFile";echoc -w 

#echo "parms: $@";echoc -w

bDoNotClose=false
bSkipCascade=false
bWaitDBsymlink=true
export nExitWait=0
varset strTitle="Xterm_Detached"
while [[ "${1:0:2}" == "--" ]]; do
	#echo "Param: $1"
	if [[ "$1" == "--help" ]];then #help show this help
		#grep "#help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #help (.*)'\t\1\t\2'"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--title" ]];then #help hack to set the child xterm title, must NOT contain espaces... must be exclusively alphanumeric and '_' is allowed too...
		shift
		varset strTitle="$1"
		if [[ -n `echo "$strTitle" |tr -d "[:alnum:]_"` ]];then
			echoc -p "title '$strTitle' contains invalid characters..."
			echoc -w "exiting..."
			exit 1
		fi
	elif [[ "$1" == "--donotclose" ]];then #help keep xterm running after execution completes
		bDoNotClose=true
	elif [[ "$1" == "--waitonexit" ]];then #help <seconds> wait seconds before exiting
		shift
		nExitWait="$1"
	elif [[ "$1" == "--skipcascade" ]];then #help to xterm not be auto organized 
		bSkipCascade=true
	elif [[ "$1" == "--log" ]];then #TODO
		echo "TODO: implement auto-log"
		echoc -p "not implemented yet"
		echoc -w
		exit 1
	elif [[ "$1" == "--skipchilddb" ]];then #help do not wait for a child to have its SEC DB symlinked to this SEC DB; this is necessary if a child will not use SEC DB, or if it will have a new SEC DB real file forcedly created.
		bWaitDBsymlink=false
	else
		SECFUNCechoErrA "invalid option $1"
		exit 1
	fi
	shift
	#echo "NextParam: $1"
done

#echo "Remaining Params: $@"

# to avoid error message
eval "function $strTitle () { local ln=0; };export -f $strTitle"
#type $strTitle

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
	eval `secinit`
	
	echo "$FUNCNAME:Exec: $strFUNCexecParams"
	eval $strFUNCexecParams
	
	if((nExitWait>0));then
		echoc -w -t $nExitWait #wait some time so any log can be read..
	fi
	#echoc -w
};export -f FUNCexecParams
#strExec="echo \"TEMP xterm...\"; xterm -e \"$params\"; read -n 1"
#strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -e 'echo \"$1\";FUNCexecParams${strDoNotClose}${strSkipCascade}'\"; read -n 1"
strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -e '$strTitle;FUNCexecParams${strDoNotClose}${strSkipCascade}'\"; read -n 1"
echo "Exec: $strExec"
#echo -e "$strExec"

xterm -e "$strExec"&
pidXtermTemp=$!
# wait for the child to open (it has xterm temp as parent!)
while ! ps --ppid $pidXtermTemp; do
    sleep 1
done
if $bWaitDBsymlink;then
#	nCountFindDBsLinked=0
	function FUNCfindSymlinks() {
		find /run/shm/ -lname "$SECvarFile"
	}
	while true;do #wait for some child to link to the DB file
		nBDsLinked=`FUNCfindSymlinks |wc -l`
		if((nBDsLinked>0));then
			echoc --info "DBs Linked:"
			FUNCfindSymlinks
			break;
		fi
		if ! ps -p $pidXtermTemp >/dev/null 2>&1;then
			break;
		fi
#		((nCountFindDBsLinked++))
#		if((nCountFindDBsLinked>60));then #DB linking should happen fast...
#			break;
#		fi
		echoc --info "waiting for child SEC DBs to create a symlink to this: $SECvarFile"
		sleep 1
	done
fi
#echoc -w -t 60 "waiting 60s so child shells have a chance to hook on the SEC DB..."
#echoc -x "kill -SIGINT $pidXtermTemp"
kill -SIGINT $pidXtermTemp
#echoc -w -t 5

