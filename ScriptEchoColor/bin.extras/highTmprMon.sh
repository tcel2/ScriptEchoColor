#!/bin/bash
# Copyright (C) 2004-2012 by Henrique Abdalla
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
selfName=`basename "$0"`
lockFile="/tmp/.seclock-$selfName"
lockPid=`cat "$lockFile"`
isAlreadyRunning=false
if [[ -z "$lockPid" ]] || ! ps -p $lockPid 2>&1 >/dev/null; then
	isAlreadyRunning=false
else
	isAlreadyRunning=true
	SECFUNCvarSetFileName $lockPid
fi

#config
tmprLimit=77 #begins beepinging at 80, a bit before, prevents the annoying beeping
minPercCPU=30
if [[ -n "$1" ]]; then tmprLimit=$1; fi
if [[ -n "$2" ]]; then minPercCPU=$2; fi

topCPUtoCheckAmount=10
tmprToMonitor="temp1"
maxDelay=30 #15
minimumWait=15 #5
#useOnlyThisPID="" #empty to find the highest cpu usage one

export SEC_SAYVOL=10

################## options
SECFUNCvarSet --default isLoweringTemperature=false
while [[ "${1:0:1}" == "-" ]];do
	if [[ "${1:1:1}" == "-" ]];then
		if [[ "$1" == "--isloweringtemperature" ]];then #help
			#SECFUNCvarGet isLoweringTemperature
			if $isAlreadyRunning;then
				if $isLoweringTemperature;then
					echo "true"
					exit 0
				else
					echo "false"
					exit 1
				fi
			else
				echoc -p "not running!"
				exit 1
			fi
		elif [[ "$1" == "--help" ]];then #help
			echo "This app monitors the temperature and stop applications that are using too much cpu to let the temperature go down! And start them again after some time."
			echo "It is limited to the current user processes."
			echo "pre-alpha, later on it should monitor all temperatures etc etc.."
			echo "PARAMS: tmprLimit minPercCPU"
			grep "#help" $0 |grep -v grep
			exit
		elif [[ "$1" == "--debugtest" ]];then #help
			echo $SECvarFile
		fi
	else
		if [[ "$1" == "-d" ]];then
			echo "dummy"
		fi
	fi
	shift
done

#code
if $isAlreadyRunning; then
	echoc -p "already running!"
	exit 1
else
	echo $$ >"$lockFile"
fi

function FUNCbcToBool() {
	local iResult=`echo "$1" |bc -l`
	local bResult=false;
	if((iResult==1));then 
		bResult=true; 
	fi
	echo $bResult
}

aHighPercPidList=()
function FUNChighPercPidList() {
	local aPercPid=(`ps -A --user $USER --sort=-pcpu -o pcpu,pid |head -n $((topCPUtoCheckAmount+1)) |tail -n $topCPUtoCheckAmount |sed 's"^[ ]*""' |sed 's".*"&"'`)

	aHighPercPidList=()
	local tot=${#aPercPid[*]}
	#for item in ${aPercPid[*]}; do 
	for((i=0;i<tot;i+=2));do
		local item=${aPercPid[i]}
		local bIsHigh=`FUNCbcToBool "$item > $minPercCPU"`; 
		if $bIsHigh; then
			aHighPercPidList=(${aHighPercPidList[*]} ${aPercPid[i+1]})
		fi
	done
	#echo ${aHighPercPidList[*]}
}

function FUNClistTopPids() {
	ps -A --user $USER --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm |head -n $(($1+1))
}

function FUNCinfo() {
	#echoc -t 1 --info "$@" #too much cpu usage
	echo -n "$@";read -s -t 1 -p "";echo
}

function FUNCtempAvg() {
	local l_temperature="temp1"
	if [[ -n "$1" ]];then
		l_temperature="$1"
	fi
	count=20 #each 10 = 1second
	bc <<< `
		for((i=0;i<$count;i++)); do 
			sensors \
				|grep "$l_temperature" \
				|sed -r "s;$l_temperature(.*);\1;" \
				|tr -d ' :[:alpha:]°()=' \
				|sed -r 's"^([+-][[:digit:]]*[.][[:digit:]]).*"\1"';
			sleep 0.1;
		done |tr -d '\n' |sed "s|.*|scale=1;(0&)/$count|"`
}

function FUNCmon() {
	tmprCurrent=`sensors |grep "$tmprToMonitor" |sed "$sedTemperature"`
}
sedTemperature='s".*: *+\([0-9][0-9]\)\.[0-9]°C.*"\1"'
maxTemperature=0
prevTemperature=0
lastWarningSaidTime=0
warningDelay=60
beforeLimitWarn=1
while true; do
	FUNCmon
	if((maxTemperature<tmprCurrent));then
		maxTemperature=$tmprCurrent
	fi
	
  #echoc --info "tmprCurrent=$tmprCurrent(max=$maxTemperature)(tmprLimit=$tmprLimit)"
	FUNClistTopPids 3
  
  # warning for high temperature near limit
	if((tmprCurrent>=(tmprLimit-beforeLimitWarn)));then
		if((prevTemperature!=tmprCurrent));then
			if((SECONDS>(lastWarningSaidTime+warningDelay)));then
			  echoc --say "$tmprCurrent"
			  lastWarningSaidTime=$SECONDS
			fi
		fi
  fi
  
	if((tmprCurrent>=tmprLimit));then
		# report processes
		FUNClistTopPids $topCPUtoCheckAmount
		#echoc -x "ps -A --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm |head -n $((topCPUtoCheckAmount+1))"
	  #pidHighCPUusage=`ps --user $USER --sort=-pcpu -o pid |head -n 2 |tail -n 1`
	  #pidHCUCmdName=`ps -p $pidHighCPUusage -o comm |head -n 2 |tail -n 1`
    #echoc -x "ps -p $pidHighCPUusage -o pcpu,pid,ppid,stat,state,nice,user,comm |tail -n 1"
		
		FUNChighPercPidList
	  #echoc -x "kill -SIGSTOP $pidHighCPUusage"
	  echoc -x "kill -SIGSTOP ${aHighPercPidList[*]}"
	  
		#echoc --say "high temperature $tmprCurrent, stopping: $pidHCUCmdName"&
		echoc --say "high temperature $tmprCurrent, stopping some processes..."
		
		count=0
		SECFUNCdelay timeToCoolDown --init
		while true; do
			SECFUNCvarSet isLoweringTemperature=true
			tmprCurrentold=$tmprCurrent
			FUNCmon
			((count++))
			
			echo "current temperature: $tmprCurrent"
			FUNClistTopPids $((${#aHighPercPidList[*]}+1))
			
			if((count>maxDelay));then
				echoc --say "Time limit ($maxDelay seconds) to lower temperature reached..."
				break;
			fi
			
			#stabilized or reached a minimum old<=current
			if((count>=minimumWait && tmprCurrentold<=tmprCurrent));then
				break;
			fi
			
			echoc -x "sleep 1" #let it cooldown a bit
			echoc --say "$tmprCurrent"
		done
		SECFUNCvarSet isLoweringTemperature=false
		
		echoc --say "temperature lowered to: $tmprCurrent in `SECFUNCdelay timeToCoolDown --getsec` seconds"
				
	  #echoc -x "kill -SIGCONT $pidHighCPUusage"
	  echoc -x "kill -SIGCONT ${aHighPercPidList[*]}"
	fi

  prevTemperature=$tmprCurrent
	
  FUNCinfo "tmprCurrent=$tmprCurrent(max=$maxTemperature)(tmprLimit=$tmprLimit)"
	#sleep 1
done

