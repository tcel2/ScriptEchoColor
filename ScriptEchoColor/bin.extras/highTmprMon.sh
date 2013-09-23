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

################# INIT
eval `secLibsInit.sh`

selfName=`basename "$0"`

isAlreadyRunning=false
if SECFUNCuniqueLock --quiet; then
	SECFUNCvarSetDB -f
else
	SECFUNCvarSetDB `SECFUNCuniqueLock` #allows intercommunication between proccesses started from different parents
	isAlreadyRunning=true
fi

anIgnorePids=()

############### CONFIG
export tmprLimit=77 #begins beepinging at 80, a bit before, prevents the annoying beeping
export minPercCPU=30

export topCPUtoCheckAmount=10
export tmprToMonitor="temp1"
export maxDelay=30 #15
export minimumWait=15 #5
#export sedTemperature='s".*: *+\([0-9][0-9]\)\.[0-9]°C.*"\1"'
export sedTemperature='s"^'"$tmprToMonitor"':[[:blank:]]*[+-]([[:digit:]]*)[.][[:digit:]]*°C.*"\1"p' #use this way: sensors |sed -nr "$sedTemperature"
#useOnlyThisPID="" #empty to find the highest cpu usage one
SECFUNCvarSet --default bDebugFakeTmpr=false

export SEC_SAYVOL=10

############ FUNCTIONS
function FUNCbcToBool() {
	local iResult=`echo "$1" |bc -l`
	local bResult=false;
	if((iResult==1));then 
		bResult=true; 
	fi
	echo $bResult
}

function FUNCignoredPids() {
	SECFUNCvarReadDB anIgnorePids
	anIgnorePids=($$ ${anIgnorePids})
	local l_strIgnorePids=`echo "${anIgnorePids[@]}" |tr ' ' '|'`
	echo "$l_strIgnorePids"
} #;export -f FUNCignoredPids

aHighPercPidList=()
function FUNChighPercPidList() {
	local l_strIgnoredPids=`FUNCignoredPids`
	SECFUNCechoDbgA "l_strIgnoredPids='$l_strIgnoredPids'"
	local aPercPid=(`ps -A --no-headers --user $USER --sort=-pcpu -o pcpu,pid |egrep -v "($l_strIgnoredPids)$" |head -n $((topCPUtoCheckAmount)) |sed 's"^[ ]*""' |sed 's".*"&"'`)
	SECFUNCechoDbgA "aPercPid=(${aPercPid[@]})"

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
	SECFUNCechoDbgA "aHighPercPidList=(${aHighPercPidList[@]})"
	#echo ${aHighPercPidList[*]}
}

function FUNClistTopPids() {
	ps -A --user $USER --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm |head -n $(($1+1))
}

function FUNCinfo() {
	#echoc -t 1 --info "$@" #too much cpu usage
	echo -n "$@";read -s -t 1 -p "";echo
}

function FUNCtmprAverage() {
	local count=$1
	
	if [[ -z "$count" ]];then
		count=20 #each 10 = 1second
	fi
	
	local scale=0 #local scale=1
	bc <<< ` \
		for((i=0;i<$count;i++)); do \
			sensors |sed -nr "$sedTemperature"; \
			sleep 0.1; \
		done |tr '\n' '+' |sed "s|.*|scale=$scale;(&0)/$count|"`
}

#function FUNCmonTmpr() {
#	#tmprCurrent=`sensors |sed -nr "$sedTemperature"`
#	tmprCurrent=`FUNCtmprAverage 1`
#};export -f FUNCmonTmpr

function FUNCchildLimCpuFastLoop() {
	eval `secLibsInit.sh`
	SECFUNCvarWaitRegister pidToLimit
	SECFUNCvarWaitRegister fSigStopDelay
	SECFUNCvarWaitRegister fSigRunDelay
	
	SECFUNCdelay ${FUNCNAME}_maintenance --init
	while true; do
		if((`SECFUNCdelay ${FUNCNAME}_maintenance --getsec`>=1));then
			#SECFUNCvarSet DEBUG_${FUNCNAME} "\$\$=$$ PPID=$PPID pidToLimit=$pidToLimit BASHPID=$BASHPID"
			if ! ps -p $$ >/dev/null 2>&1; then break; fi
			if ! ps -p $PPID >/dev/null 2>&1; then break; fi
			if ! ps -p $pidToLimit >/dev/null 2>&1; then break; fi
			SECFUNCvarReadDB
			SECFUNCdelay ${FUNCNAME}_maintenance --init
		fi
		
		if [[ "$fSigStopDelay" != "0.0" ]];then
			kill -SIGSTOP $pidToLimit
			sleep $fSigStopDelay
		fi
		if [[ "$fSigRunDelay" != "0.0" ]];then
			kill -SIGCONT $pidToLimit
			sleep $fSigRunDelay
		fi
	done
}
function FUNClimitCpu() {
	#there exists this: `sudos cpulimit -v -p $pidToLimit -l 99` #but it doesnt care about temperature and also wont accept -l greater than 100 and... requires root/sudo access
	
	#echo "tmprLimit=$tmprLimit";exit
	SECFUNCvarSet pidToLimit=$1
	
	# make main process ignore the pid
	SECFUNCvarReadDB
	anIgnorePids=(${anIgnorePids[@]} $pidToLimit)
	SECFUNCvarSet anIgnorePids
	
	SECFUNCdelay showTmpr --init
	SECFUNCdelay ${FUNCNAME}_maintenance --init
	
	bForceStop=false
	bJustLimit=false
	
	nTmprStep=5
	nJustLimitThreshold=$((nTmprStep*2))
	nRunAgainThreshold=$((nJustLimitThreshold+nTmprStep))
	
	fStepMin=0.025
	fStepMax=0.5
	SECFUNCvarSet fSigStopDelay=0.0
	SECFUNCvarSet fSigRunDelay=$fStepMax
	
	FUNCchildLimCpuFastLoop& #another loop that complements this one!
	echo "pid for FUNCchildLimCpuFastLoop is $!"
	while true; do
		if((`SECFUNCdelay ${FUNCNAME}_maintenance --getsec`>=1));then
			if ! ps -p $pidToLimit >/dev/null 2>&1; then break; fi
			SECFUNCvarReadDB
			SECFUNCdelay ${FUNCNAME}_maintenance --init
		fi
		
		#echo "DEBUG: tmprCurrentFake=$tmprCurrentFake"
		if $bDebugFakeTmpr;then
			tmprCurrent=$tmprCurrentFake
		else
			if $bForceStop || $bJustLimit;then
				tmprCurrent=`FUNCtmprAverage 15`
			else
				tmprCurrent=`FUNCtmprAverage 3`
			fi
		fi
		
		if((`SECFUNCdelay showTmpr --getsec`>=3));then
			if $bForceStop;then
				echoc --say "stopped $tmprCurrent"
			elif $bJustLimit;then
				echo "just limit $tmprCurrent (stop delay $fSigStopDelay)"
			else
				echo "running $tmprCurrent"
			fi
			SECFUNCdelay showTmpr --init
		fi
		
		# from highest to lowest temperature limits
		if((tmprCurrent>=tmprLimit));then
			bForceStop=true
			SECFUNCvarSet fSigStopDelay=$fStepMax
			SECFUNCvarSet fSigRunDelay=0.0
		elif((tmprCurrent>=(tmprLimit-(nJustLimitThreshold/2))));then
			bJustLimit=true
			SECFUNCvarSet fSigStopDelay=$fStepMax
			SECFUNCvarSet fSigRunDelay=`SECFUNCbcPrettyCalc "$fStepMin+$fStepMin"`
		elif((tmprCurrent>=(tmprLimit-nJustLimitThreshold)));then
			bJustLimit=true
			SECFUNCvarSet fSigStopDelay=$fStepMin
			SECFUNCvarSet fSigRunDelay=$fStepMin
		elif((tmprCurrent<=(tmprLimit-nRunAgainThreshold)));then
			if((`FUNCtmprAverage 10`<=(tmprLimit-nRunAgainThreshold)));then #to make it sure
				bForceStop=false
				bJustLimit=false
				SECFUNCvarSet fSigStopDelay=0.0
				SECFUNCvarSet fSigRunDelay=$fStepMax
			fi
		fi
		
		sleep 0.5
	done
}

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
		elif [[ "$1" == "--debugfaketmpr" ]];then #help <FakeTemperature> set a fake temperature for debug purposes. Set FakeTemperature to "off" to disable it and use real temperature again.
			shift
			
			if [[ "$1" == "off" ]];then
				SECFUNCvarSet bDebugFakeTmpr=false
				exit
			fi
			
			if [[ -z "$1" ]];then
				echoc -p "missing fake temperature parameter"
				exit 1
			fi
			SECFUNCvarSet bDebugFakeTmpr=true
			SECFUNCvarSet tmprCurrentFake $1
			exit
		elif [[ "$1" == "--limitcpu" ]];then #help <pid> limit cpu usage for specified pid to lower temperature
			pidToLimit=$2
			if ps -p $pidToLimit >/dev/null 2>&1;then
				FUNClimitCpu $pidToLimit
			else
				echoc -p "missing valid pid"
				$0 --help |grep "\-\-limitcpu" >/dev/stderr
				exit 1
			fi
			exit
		elif [[ "$1" == "--tmpr" ]];then #help get temperature
			tmprCurrent=`FUNCtmprAverage 15`
			echo "$tmprCurrent"
			exit
		elif [[ "$1" == "--help" ]];then #help
			echo "This app monitors the temperature and stop applications that are using too much cpu to let the temperature go down! And start them again after some time."
			echo "It is limited to the current user processes."
			echo "pre-alpha, later on it should monitor all temperatures etc etc.."
			#echo "PARAMS: tmprLimit minPercCPU"
			echo
			echo "Options:"
			grep "#help" $0 |grep -v grep |sed -r 's/.*"(--[[:alnum:]]*)" \]\];then #help[ ]*(.*)/\t\1\t\t\2/'
			exit
		else
			echoc -p "invalid option: $1"
			exit 1
		fi
	else
		if [[ "$1" == "-d" ]];then
			echo "dummy"
		else
			echoc -p "invalid option: $1"
			exit 1
		fi
	fi
	shift
done
if [[ -n "$1" ]]; then tmprLimit=$1; fi
if [[ -n "$2" ]]; then minPercCPU=$2; fi

############## MAIN
if $isAlreadyRunning; then
	echoc -p "already running!"
	exit 1
#else
#	echo $$ >"$lockFile"
fi

maxTemperature=0
prevTemperature=0
lastWarningSaidTime=0
warningDelay=60
beforeLimitWarn=1
while true; do
	SECFUNCvarReadDB
	if $bDebugFakeTmpr;then
		tmprCurrent=$tmprCurrentFake
	else
		tmprCurrent=`FUNCtmprAverage 3`
	fi
	
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
		echoc --say "$tmprCurrent"
		echoc --say "high temperature, stopping some processes..."
		
		count=0
		SECFUNCdelay timeToCoolDown --init
		while true; do
			SECFUNCvarSet isLoweringTemperature=true
			tmprCurrentold=$tmprCurrent
			tmprCurrent=`FUNCtmprAverage 10` #FUNCmonTmpr
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
			
			sleep 1 #echoc -x "sleep 1" #let it cooldown a bit
			echoc --say "$tmprCurrent"
		done
		SECFUNCvarSet isLoweringTemperature=false
		
		echo "temperature lowered to: $tmprCurrent in `SECFUNCdelay timeToCoolDown --getsec` seconds"
				
	  #echoc -x "kill -SIGCONT $pidHighCPUusage"
	  echoc -x "kill -SIGCONT ${aHighPercPidList[*]}"
	fi

  prevTemperature=$tmprCurrent
	
  FUNCinfo "tmprCurrent=$tmprCurrent(max=$maxTemperature)(tmprLimit=$tmprLimit)"
	#sleep 1
done

