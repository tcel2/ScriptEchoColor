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

#: ${SECbTermLog:=false}
#if [[ "$SECbTermLog" != "true" ]];then
#	export SECbTermLog=false
#fi

#bDoNotClose=false
export SECXbDoNotClose=false
bSkipCascade=false
bWaitDBsymlink=true
bKillSkip=false
export SECXbDaemon=false
export SECXnNice=0
nDisplay="$DISPLAY"
export SECXnExitWait=0
strTitleDefault="Xterm_Detached" #TODO check if this is useless?
varset strTitle="$strTitleDefault"
strTitleForce=""
#export bLog=$SECbTermLog
#export strLogFile=""
echoc --info "Options: $@"
export SECXbLogOnly=false
export SECXbNoHup=false
export SECXstrXtermOpts=""
bOnTop=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
	SECFUNCsingleLetterOptionsA
	#echo "Param: $1"
	if [[ "$1" == "--help" ]];then #help show this help
		echo "Opens a terminal that will keep running after its parent terminal ends execution."
		echo -e "\t[options] <CommandToBeRun>"
#		echo "User can set:"
#		echo -e "\tSECbTermLog=<<true>|<false>> so log file will be automatically created."
		echo
		#grep "#help" $0 |grep -v grep |sed -r "s'.*(--.*)\" ]];then #help (.*)'\t\1\t\2'"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--nice" ]];then #help <SECXnNice> negative value will require sudo
		shift
		SECXnNice="${1-}"
	elif [[ "$1" == "--display" ]];then #help <nDisplay>
		shift
		nDisplay="${1-}"
	elif [[ "$1" == "--daemon" ]];then #help enforce the execution to be uniquely run (no other instances of same command)
		SECXbDaemon=true
	elif [[ "$1" == "--title" ]];then #help hack to set the child xterm title, must NOT contain espaces... must be exclusively alphanumeric and '_' is allowed too...
		shift
#		strTitleForce="`SECFUNCfixId "$1"`"
		strTitleForce="${1-}"
#		if [[ -n `echo "$strTitle" |tr -d "[:alnum:]_"` ]];then
#			echoc -p "title '$strTitle' contains invalid characters..."
#			echoc -w "exiting..."
#			exit 1
#		fi
	elif [[ "$1" == "--ontop" ]];then #help set xterm on top
		bOnTop=true
	elif [[ "$1" == "--donotclose" ]];then #help keep xterm running after execution completes
		#bDoNotClose=true
		SECXbDoNotClose=true
	elif [[ "$1" == "--logonly" ]];then #help the shown xterm will be just a log monitoring, unable to interact with the application running on it, with options to manage it
		SECXbLogOnly=true
	elif [[ "$1" == "--nohup" ]];then #help the command will be executed with nohup, so will keep running even if terminal closes. It is more interesting to use --logonly as you will be able to manage that pid.
		SECXbNoHup=true
	elif [[ "$1" == "--xtermopts" ]];then #help <SECXstrXtermOpts> pass the next param as options to xterm
		shift
		SECXstrXtermOpts="${1-}"
	elif [[ "$1" == "--waitonexit" || "$1" == "-w" ]];then #help <SECXnExitWait> wait seconds before exiting
		shift
		SECXnExitWait="${1-}"
	elif [[ "$1" == "--skiporganize" || "$1" == "--skipcascade" ]];then #help to xterm not be auto organized 
		bSkipCascade=true
	elif [[ "$1" == "--killskip" ]];then #help to xterm not be killed
		bKillSkip=true
#	elif [[ "$1" == "--log" ]];then #help log all the output to automatic file
#		bLog=true
#	elif [[ "$1" == "--nolog" ]];then #help disable automatic log
#		bLog=false
#	elif [[ "$1" == "--logcustom" ]];then #help <logFile>
#		shift
#		strLogFile="$1"
#		bLog=true
	elif [[ "$1" == "--skipchilddb" ]];then #help do not wait for a child to have its SEC DB symlinked to this SEC DB; this is necessary if a child will not use SEC DB, or if it will have a new SEC DB real file forcedly created.
		bWaitDBsymlink=false
	else
		SECFUNCechoErrA "invalid option $1"
		exit 1
	fi
	shift&&:
	#echo "NextParam: $1"
done

#echo "Remaining Params: $@"
if [[ -z "${1-}" ]];then
	echoc -p "missing command to exec"
	exit 1
fi

if ! SECFUNCisNumber -dn $SECXnExitWait;then
	echoc -p "invalid SECXnExitWait='$SECXnExitWait'"
	exit 1
fi

if [[ -n "$strTitleForce" ]];then
#	varset strTitle="$strTitleForce"
	varset strTitle="`SECFUNCfixId "$strTitleForce"`" #if user puts a title with invalid characters it will be said by not using --justfix option
else # strTitle is set to the command that is the first parameter
	# $1 must NOT be consumed (shift) here!!! $@ will consume all executable parameters later!!!
	varset strTitle="`SECFUNCfixId --justfix "$1"`"
	#shift # !!!ALERT!!! do NOT use shift here!!!
fi

export strSudoPrefix=""
if((SECXnNice<0));then
	strSudoPrefix="sudo -k nice -n $SECXnNice "
fi

strSkipCascade=""
if $bSkipCascade;then
	strSkipCascade=" #skipOrganize"
fi

strKillSkip=""
if $bKillSkip;then
	strKillSkip="#kill=skip"
fi

#cmdLogFile=""
#if $bLog;then
#	if [[ -z "$strLogFile" ]];then
#		strLogFile="$HOME/.ScriptEchoColor/SEC.App.log/$strTitle.log"		
#	fi
#	
##	if [[ -x "$strLogFile" ]];then
##		# may cause trouble on non linux fs
##		echoc -p "invalid log file '$strLogFile' is executable..."
##		exit 1
##	fi
#	
#	if [[ -n "$strLogFile" ]];then
#		mkdir -vp "`dirname "$strLogFile"`"
#		
#		# create file
#		echo -n >>"$strLogFile"
#		
#		if [[ ! -f "$strLogFile" ]];then
#			echoc -p "invalid log file '$strLogFile'"
#			exit 1
#		fi
#		
#		cmdLogFile=" 2>&1 |tee \"$strLogFile\""
#	fi
#	
#	echoc --info "Log at: '$strLogFile'"
#fi

#strCmdDoNotClose=""
#if $bDoNotClose;then
#	strCmdDoNotClose=";SECFUNCechoWarnA 'Will not close this terminal';bash"
#	#strCmdDoNotClose=";bash"
#fi

# trick to avoid error message where function id may conflict (may already exist) #TODO unnecessary?
strPseudoFunctionId="${strTitle}_pid$$_Title"
while [[ -n "`type -t "$strPseudoFunctionId"`" ]];do
	# the identifier must not be being used already by file, function, alias etc...
	strPseudoFunctionId="${strPseudoFunctionId}_"
done
#eval "function $strPseudoFunctionId () { local ln=0; };export -f $strPseudoFunctionId"
#eval "function $strPseudoFunctionId () { FUNCexecParams${cmdLogFile}${strCmdDoNotClose}; };export -f $strPseudoFunctionId"
#eval "function $strPseudoFunctionId () { eval \`secinit\`;FUNCexecParams${strCmdDoNotClose}; };export -f $strPseudoFunctionId"
#eval "function $strPseudoFunctionId () { eval \`secinit\`;FUNCexecParams; };export -f $strPseudoFunctionId"
eval "function $strPseudoFunctionId () { FUNCexecParams; };export -f $strPseudoFunctionId"
#type $strPseudoFunctionId

# konsole handles better ctrl+s ctrl+q BUT is 100% buggy to exec cmds :P
#xterm -e "echo \"TEMP xterm...\"; konsole --noclose -e bash -c \"FUNCinit;FUNCcheckLoop\""&

#xterm -e "echo \"TEMP xterm...\"; xterm -maximized -e \"FUNCFireWall\""& #maximize dont work properly...

#params="$@"
if $SECXbDaemon;then
	if [[ "$strTitle" == "$strTitleDefault" ]];then
		# actually this will never be reached because of the automatic strTitle being the command...
		echoc -p "Daemons requires non default title to create the unique lock..."
		echoc -w -t 60
		exit 1
	fi
fi

#params=`SECFUNCparamsToEval --escapequotes "$@"`"${strCmdDoNotClose}${strSkipCascade}"
############# THIS FUNCTION MUST BE HERE AFTER OPTIONS #######
export strFUNCexecMainCmd="$1"
export strFUNCexecParams=`SECFUNCparamsToEval "$@"`
function FUNCexecParams() {
	eval `secinit`
	
	if $SECXbDaemon;then
		while true;do
			#SECFUNCuniqueLock --id "$strTitle" --isdaemonrunning
			SECFUNCuniqueLock --id "$strTitle" --setdbtodaemon #SECFUNCdaemonUniqueLock $strTitle
			
			if $SECbDaemonWasAlreadyRunning;then
				echoc --info "waiting other daemon exit"
				sleep 1
				continue;
			fi	
			
			break
		done
	fi

	local lstrFileLogCmd="$SECstrTmpFolderLog/$SECstrScriptSelfName.`SECFUNCfixIdA -f "$strFUNCexecMainCmd"`.$$.log"
	if $SECXbLogOnly || $SECXbNoHup;then
		echo "lstrFileLogCmd='$lstrFileLogCmd'" >>/dev/stderr
		tail -F "$lstrFileLogCmd"&
	fi
	
	echo "$FUNCNAME:Exec: ${strSudoPrefix}${strFUNCexecParams}"
	if $SECXbLogOnly;then
		# stdout must be redirected or the terminal wont let it be a detached child...
		#(eval "${strSudoPrefix} ${strFUNCexecParams}" 2>"$lstrFileLogCmd" >>/dev/stderr)&disown
		#(bash -c "${strSudoPrefix} ${strFUNCexecParams}" 2>"$lstrFileLogCmd" >>/dev/stderr)&disown
		#nohup bash -c "eval '${strSudoPrefix} ${strFUNCexecParams}'" 2>"$lstrFileLogCmd" >>/dev/stderr&
		SECFUNCexecA -ce bash -c "eval '${strSudoPrefix} ${strFUNCexecParams}'" 2>"$lstrFileLogCmd" >>/dev/stderr & disown
		nPidCmd=$!
		
		while true;do
			echoc --info "monitoring lstrFileLogCmd='$lstrFileLogCmd'"
			echoc -x "ps --no-headers -o pid,ppid,cpu,stat,cmd -p $nPidCmd"
			ScriptEchoColor -t 10 -Q "do what?@O_exit/_kill/force_Kill/_stop/_continue"&&:; case "`secascii $?`" in 
				e) break;
					;; 
				k) kill $nPidCmd
					;; 
				K) kill -SIGKILL $nPidCmd
					;; 
				s) kill -SIGSTOP $nPidCmd
					;; 
				c) kill -SIGCONT $nPidCmd
					;; 
			esac
			
			if [[ ! -d "/proc/$nPidCmd" ]];then
				echo "nPidCmd='$nPidCmd' exited" >>/dev/stderr
				break;
			fi
		done
	else
		if $SECXbNoHup;then
			SECFUNCexecA -ce nohup bash -c "${strSudoPrefix} ${strFUNCexecParams}" 2>"$lstrFileLogCmd" >>/dev/stderr;nRet=$?
		else
			SECFUNCexecA -ce bash -c "${strSudoPrefix} ${strFUNCexecParams}";nRet=$?
		fi
		
		if((nRet!=0));then
			echoc -p "returned $nRet"
			echoc -w -t 60
		fi
	fi
	
	if((SECXnExitWait>0));then
		echoc -w -t $SECXnExitWait #wait some time so any log can be read..
	fi
	
	if $SECXbDoNotClose;then
		echoc --info "This terminal will not be auto-closed!"
		SECFUNCexecA -ce bash #this is better than `xterm -hold` as terminal can still be used for other commands
	fi
	
	#echoc -w -t 60
};export -f FUNCexecParams
#strExec="echo \"TEMP xterm...\"; xterm -e \"$params\"; read -n 1"
#strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -e 'echo \"$1\";FUNCexecParams${strCmdDoNotClose}${strSkipCascade}'\"; read -n 1"

#function FUNCwatchLog() {
#	if $bLog;then
#		#if echoc -q "watch log?";then
#		tail -f "$strLogFile"
#		#fi
#	fi
#};export -f FUNCwatchLog

#strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm -display $nDisplay -e '$strTitle;FUNCexecParams${cmdLogFile}${strCmdDoNotClose}${strSkipCascade}${strKillSkip}'\"; read -n 1"

strExec="echo \"TEMP xterm...\"; bash -i -c \"xterm $SECXstrXtermOpts -display $nDisplay -e '$strPseudoFunctionId;${strSkipCascade}${strKillSkip}'\"; read -n 1"
echo "Exec: $strExec"
xterm -display "$nDisplay" -e "$strExec"&

#strExec="$strPseudoFunctionId;${strSkipCascade}${strKillSkip}"
#echo "Exec: $strExec"
#nohup bash -c "xterm $SECXstrXtermOpts -display $nDisplay -e '$strExec'" >>/dev/stderr 2>&1 & disown

pidXtermTemp=$!

while ! ps --ppid $pidXtermTemp; do
		if ! ps -p $pidXtermTemp;then
			break
		fi
		ps -o pid,ppid,comm -p $pidXtermTemp
		echoc -w -t 1 "waiting for the child to open (it has xterm temp as parent!).."
done

if $bWaitDBsymlink;then
#	nCountFindDBsLinked=0
	function FUNCfindSymlinks() {
		#find /run/shm/ -lname "$SECvarFile"
		find "$SEC_TmpFolder/" -lname "$SECvarFile"
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

if $bOnTop;then
	#TODO wait xterm window become responsive to accept ontop command, or test if it is ontop before exiting...
	SECFUNCCwindowOnTop --delay 1 "${strPseudoFunctionId}.*" #must be here because the xterm window may still not be ready to receive the command!
	#SECFUNCCwindowOnTop --stop "${strPseudoFunctionId}.*"
fi

if [[ -d "/proc/$pidXtermTemp" ]];then #it may have run so fast that doesnt exist anymore
	kill -SIGINT $pidXtermTemp
fi
#fi
#echoc -w -t 5

