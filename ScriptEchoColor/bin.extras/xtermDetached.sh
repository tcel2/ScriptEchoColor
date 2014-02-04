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
#selfName="`basename "$0"`" #TODO why became the caller script name?
#echo "SECvarFile=$SECvarFile";ls -l "$SECvarFile";echoc -w 

#echo "parms: $@";echoc -w

: ${SECbTermLog:=false}
if [[ "$SECbTermLog" != "true" ]];then
	export SECbTermLog=false
fi

bDoNotClose=false
bSkipCascade=false
bWaitDBsymlink=true
bKillSkip=false
export bDaemon=false
export nNice=0
nDisplay="$DISPLAY"
export nExitWait=0
strTitleDefault="Xterm_Detached" #useless?
varset strTitle="$strTitleDefault"
strTitleForce=""
export bLog=$SECbTermLog
export strLogFile=""
echoc --info "Options: $@"
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	#echo "Param: $1"
	if [[ "$1" == "--help" ]];then #help show this help
		echo "Opens a terminal that will keep running after its parent terminal ends execution."
		echo -e "\t[options] <CommandToBeRun>"
		echo "User can set:"
		echo -e "\tSECbTermLog=<<true>|<false>> so log file will be automatically created."
		echo
		#grep "#help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #help (.*)'\t\1\t\2'"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--nice" ]];then #help <nice>
		shift
		nNice=$1
	elif [[ "$1" == "--display" ]];then #help <display>
		shift
		nDisplay=$1
	elif [[ "$1" == "--daemon" ]];then #help <display>
		bDaemon=true
	elif [[ "$1" == "--title" ]];then #help hack to set the child xterm title, must NOT contain espaces... must be exclusively alphanumeric and '_' is allowed too...
		shift
		strTitleForce="`SECFUNCfixId "$1"`"
#		if [[ -n `echo "$strTitle" |tr -d "[:alnum:]_"` ]];then
#			echoc -p "title '$strTitle' contains invalid characters..."
#			echoc -w "exiting..."
#			exit 1
#		fi
	elif [[ "$1" == "--donotclose" ]];then #help keep xterm running after execution completes
		bDoNotClose=true
	elif [[ "$1" == "--waitonexit" ]];then #help <seconds> wait seconds before exiting
		shift
		nExitWait="$1"
	elif [[ "$1" == "--skipcascade" ]];then #help to xterm not be auto organized 
		bSkipCascade=true
	elif [[ "$1" == "--killskip" ]];then #help to xterm not be killed
		bKillSkip=true
	elif [[ "$1" == "--log" ]];then #help log all the output to automatic file
		bLog=true
	elif [[ "$1" == "--nolog" ]];then #help disable automatic log
		bLog=false
	elif [[ "$1" == "--logcustom" ]];then #help <logFile>
		shift
		strLogFile="$1"
		bLog=true
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

if [[ -n "$strTitleForce" ]];then
	varset strTitle="$strTitleForce"
else
	# $1 must NOT be consumed (shift) here!!! $@ will consume all executable parameters later!!!
	varset strTitle="`SECFUNCfixId "$1"`"
	#shift # do NOT use shift here!!!
fi

export strSudoPrefix=""
if((nNice<0));then
	strSudoPrefix="sudo -k nice -n $nNice "
fi

strSkipCascade=""
if $bSkipCascade;then
	strSkipCascade=" #skipCascade"
fi

strKillSkip=""
if $bKillSkip;then
	strKillSkip="#kill=skip"
fi

cmdLogFile=""
if $bLog;then
	if [[ -z "$strLogFile" ]];then
		strLogFile="$HOME/.ScriptEchoColor/SEC.App.log/$strTitle.log"		
	fi
	
#	if [[ -x "$strLogFile" ]];then
#		# may cause trouble on non linux fs
#		echoc -p "invalid log file '$strLogFile' is executable..."
#		exit 1
#	fi
	
	if [[ -n "$strLogFile" ]];then
		mkdir -vp "`dirname "$strLogFile"`"
		
		# create file
		echo -n >>"$strLogFile"
		
		if [[ ! -f "$strLogFile" ]];then
			echoc -p "invalid log file '$strLogFile'"
			exit 1
		fi
		
		cmdLogFile=" 2>&1 |tee \"$strLogFile\""
	fi
	
	echoc --info "Log at: '$strLogFile'"
fi

strDoNotClose=""
if $bDoNotClose;then
	strDoNotClose=";bash"
fi

# trick to avoid error message
strPseudoFunctionId="${strTitle}_Title"
while [[ -n "`type -t "$strPseudoFunctionId"`" ]];do
	# the identifier must not be being used already by file, function, alias etc...
	strPseudoFunctionId="${strPseudoFunctionId}_"
done
#eval "function $strPseudoFunctionId () { local ln=0; };export -f $strPseudoFunctionId"
eval "function $strPseudoFunctionId () { FUNCexecParams${cmdLogFile}${strDoNotClose}; };export -f $strPseudoFunctionId"
#type $strPseudoFunctionId

# konsole handles better ctrl+s ctrl+q BUT is 100% buggy to exec cmds :P
#xterm -e "echo \"TEMP xterm...\"; konsole --noclose -e bash -c \"FUNCinit;FUNCcheckLoop\""&

#xterm -e "echo \"TEMP xterm...\"; xterm -maximized -e \"FUNCFireWall\""& #maximize dont work properly...

#params="$@"
if $bDaemon;then
	if [[ "$strTitle" == "$strTitleDefault" ]];then
		echoc -p "Daemons requires non default title to create the unique lock..."
		echoc -w 
		exit 1
	fi
fi

#params=`SECFUNCparamsToEval --escapequotes "$@"`"${strDoNotClose}${strSkipCascade}"
############# THIS FUNCTION MUST BE HERE AFTER OPTIONS #######
export strFUNCexecParams=`SECFUNCparamsToEval "$@"`
function FUNCexecParams() {
	eval `secinit`
	
	if $bDaemon;then
		while true;do
			SECFUNCuniqueLock --daemon $strTitle #SECFUNCdaemonUniqueLock $strTitle
			if ! $SECbDaemonWasAlreadyRunning;then
				break
			fi
		done
	fi
	
	echo "$FUNCNAME:Exec: ${strSudoPrefix}${strFUNCexecParams}"
	eval ${strSudoPrefix} $strFUNCexecParams
	
	if((nExitWait>0));then
		echoc -w -t $nExitWait #wait some time so any log can be read..
	fi
	#echoc -w
};export -f FUNCexecParams
#strExec="echo \"TEMP xterm...\"; xterm -e \"$params\"; read -n 1"
#strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -e 'echo \"$1\";FUNCexecParams${strDoNotClose}${strSkipCascade}'\"; read -n 1"

#function FUNCwatchLog() {
#	if $bLog;then
#		#if echoc -q "watch log?";then
#		tail -f "$strLogFile"
#		#fi
#	fi
#};export -f FUNCwatchLog

#strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -display $nDisplay -e '$strTitle;FUNCexecParams${cmdLogFile}${strDoNotClose}${strSkipCascade}${strKillSkip}'\"; read -n 1"
strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -display $nDisplay -e '$strPseudoFunctionId;${strSkipCascade}${strKillSkip}'\"; read -n 1"
echo "Exec: $strExec"
#echo -e "$strExec"

xterm -display "$nDisplay" -e "$strExec"&
pidXtermTemp=$!
# wait for the child to open (it has xterm temp as parent!)
while ! ps --ppid $pidXtermTemp; do
		ps -o pid,ppid,comm -p $pidXtermTemp
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
#if ! $bLog;then
kill -SIGINT $pidXtermTemp
#fi
#echoc -w -t 5

