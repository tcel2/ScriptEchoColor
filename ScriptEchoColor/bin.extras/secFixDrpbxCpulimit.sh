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

source <(secinit)

#strSelfName="`basename "$0"`"
#strLogFile="/tmp/.${strSelfName}.log"

nCpuLimitPercentual=1
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		echo "log at '$SECstrRunLogFile'"
		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--perc" ]];then #help <nCpuLimitPercentual> set percentual
		shift
		nCpuLimitPercentual="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if ! SECFUNCisShellInteractive;then
	exec 2>>"$SECstrRunLogFile"
	exec 1>&2
fi

if ! SECFUNCisNumber -dn "$nCpuLimitPercentual";then
	echoc -p "invalid nCpuLimitPercentual='$nCpuLimitPercentual'"
	exit 1
fi

nPidCurrent="`pgrep -fx "cpulimit -p $(pgrep dropbox) -l .*"`"&&:
if [[ -n "$nPidCurrent" ]];then
	ps -p "$nPidCurrent"&&:
fi

SECFUNCuniqueLock --daemonwait

#while true;do #MainLoop
#	#nPidDropbox=`ps -A -o pid,comm |egrep " dropbox$" |sed -r "s'^ *([[:digit:]]*) .*'\1'"`
#	nPidDropbox="`pgrep -f "/dropbox$|/dropbox /newerversion$" |head -n 1`"&&:
#	if [[ -n "$nPidDropbox" ]];then
#		#ps -o pid,cmd -p `pgrep -f "/dropbox "`&&:
#		SECFUNCexecA -ce renice -n 19 `ps --no-headers -L -p $nPidDropbox -o lwp |tr "\n" " "` # several pids, do not surround with "
#		
#		strCmd="cpulimit -p $nPidDropbox -l $nCpuLimitPercentual"
#		SECFUNCexecA -ce $strCmd &&: & nSubShellPid=$!
#		SECFUNCppidList --child --pid $nSubShellPid --comm --addself &&:
#		nCpuLimitPid="-1"; #must be initialized to an invalid pid, therefore an invalid folder
#		while [[ ! -d "/proc/$nCpuLimitPid" ]];do 
#			if [[ ! -d "/proc/$nSubShellPid" ]];then continue 2;fi #if cpulimit exits for any reason, continues at MainLoop
#			nCpuLimitPid="`pgrep -fx "$strCmd"`"&&:
#			echoc -w -t 1 "waiting '$strCmd'";
#		done
#		
##		SECFUNCexecA -ce ps -o ppid,pid,cmd -p `pgrep cpulimit`&&:
#		SECFUNCexecA -ce ps -o ppid,pid,cmd -p "${nCpuLimitPid}" &&:
#		while pgrep -fx "$strCmd";do
#			if echoc -t 60 -q "suspend limitation?";then
#				SECFUNCexecA -ce kill -SIGKILL "$nCpuLimitPid"
#				SECFUNCexecA -ce ps -o ppid,pid,cmd -p `pgrep cpulimit`&&: 2>>/dev/null
#				SECFUNCexecA -ce kill -SIGCONT $nPidDropbox
#				if echoc -t 60 -q "resume limitation?";then
#					continue;
#				fi
#			fi
#		done
#	fi
#	
#	echoc -t 60 -w "waiting for dropbox to start"
#done

#bSuspendingLimitation=false
#while true;do #MainLoop
#	nPidDropbox="`pgrep -f "/dropbox$|/dropbox /newerversion$" |head -n 1`"&&:
#	if [[ -n "$nPidDropbox" ]];then
#		strCpuLimitCmd="cpulimit -p $nPidDropbox -l $nCpuLimitPercentual"
#		SECFUNCexecA -ce $strCpuLimitCmd &&: & nSubShellPid=$! # starts cpulimit as child subshell
#		while true;do
#			if [[ -d "/proc/$nSubShellPid" ]];then 
#				nCpuLimitPid="`pgrep -fx "$strCpuLimitCmd"`"&&:
#				if $bSuspendingLimitation;then
#					if echoc -t 60 -q "resume limitation?";then
#						continue 2; #continues at MainLoop to start cpulimit
#					fi
#				else
#					if [[ -n "$nCpuLimitPid" ]];then
#						if echoc -t 60 -q "suspend limitation?";then
#							SECFUNCexecA -ce kill -SIGKILL "$nCpuLimitPid"
#							SECFUNCexecA -ce kill -SIGCONT $nPidDropbox
#							bSuspendingLimitation=true
#						fi
#					fi
#				fi
#			
#				if ! $bSuspendingLimitation;then
#					echoc -w -t 3 "waiting '$strCpuLimitCmd'";
#				fi
#			else
#				echoc -w -t 3 "waiting '$strCpuLimitCmd'";
#				break; #if subshell with cpulimit exits for any reason, continues at MainLoop
#			fi
#		done
#	else
#		echoc -t 3 -w "waiting for dropbox pid"
#	fi
#done
#	if [[ ! -d "/proc/$nSubShellPid" ]];then echoc -t 3 -w "subshell exited (with '$strCpuLimitCmd')"; continue;fi

bSuspendingLimitation=false
nQuestionSleep=60
while true;do #MainLoop
	# look for drop box
	nPidDropbox="`pgrep -f "/dropbox$|/dropbox /newerversion$" |head -n 1`"&&:
	if [[ -z "$nPidDropbox" ]];then echoc -t 3 -w "waiting for dropbox pid"; continue;fi
	
	while ! SECFUNCexecA -ce renice -n 19 `ps --no-headers -L -p $nPidDropbox -o lwp |tr "\n" " "`;do # several pids, do not surround with "
		SECFUNCechoWarnA "renice failed, some of dropbox child pid died?"
		echoc -w -t 3 "retrying"
	done
	
	ps --no-headers -p $nPidDropbox
	strCpuLimitCmd="cpulimit -p $nPidDropbox -l $nCpuLimitPercentual"
	
	# start cpulimit
	SECFUNCexecA --child -ce $strCpuLimitCmd
#	strChildCmdRef="`SECFUNCexecA --child -ce $strCpuLimitCmd`"
	if SECFUNCexecA --readchild "$SEClstrFuncExecLastChildRef" "chk:exit";then cat "$SEClstrFuncExecLastChildRef" >&2;continue;fi # continues at MainLoop, as it should not have exited
#	SECFUNCexecA -ce $strCpuLimitCmd &&: & nSubShellPid=$! # starts cpulimit as child subshell
#	while true;do
#		if [[ ! -d "/proc/$nSubShellPid" ]];then 
#			echoc -t 3 -w "subshell with cpulimit exited";
#			continue 2; # continues at MainLoop. If cpulimit exits for any reason, the subshell will exit too
#		fi 
#		
#		if pgrep -fx "$strCpuLimitCmd";then break;fi
#		echoc -w -t 3 "waiting '$strCpuLimitCmd'"
#	done
	
	# user control/interaction
	while true;do
		if $bSuspendingLimitation;then
			if echoc -t $nQuestionSleep -q "resume limitation?";then
				bSuspendingLimitation=false
				continue 2; #continues at MainLoop to start cpulimit
			fi
		else
#			if ! pgrep -fx "$strCpuLimitCmd";then continue 2;fi # continues at MainLoop to start cpulimit if it have exited for any reason
			if SECFUNCexecA --readchild "$SEClstrFuncExecLastChildRef" "chk:exit";then cat "$SEClstrFuncExecLastChildRef" >&2;continue 2;fi # continues at MainLoop to start cpulimit if it have exited for any reason
			
			if echoc -t $nQuestionSleep -q "suspend limitation?";then
				SECFUNCexecA -ce kill -SIGKILL `pgrep -fx "$strCpuLimitCmd"`
				SECFUNCexecA -ce kill -SIGCONT $nPidDropbox
				bSuspendingLimitation=true
			fi
		fi
	done
done

