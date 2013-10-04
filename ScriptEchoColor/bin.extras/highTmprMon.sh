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

isDaemonRunning=false
if SECFUNCuniqueLock --quiet; then
	SECFUNCvarSetDB -f
else
	SECFUNCvarSetDB `SECFUNCuniqueLock` #allows intercommunication between proccesses started from different parents
	isDaemonRunning=true
fi

if [[ -z "${anIgnorePids+dummyValue}" ]];then 
	export anIgnorePids=()
	varset anIgnorePids
fi

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
	#anIgnorePids=($$ ${anIgnorePids})
	local l_strIgnorePids=`echo "${anIgnorePids[@]}" |tr ' ' '|'`
	echo "$l_strIgnorePids"
} #;export -f FUNCignoredPids

aHighPercPidList=()
function FUNChighPercPidList() {
	local l_strIgnoredPids=`FUNCignoredPids`
	SECFUNCechoDbgA "l_strIgnoredPids='$l_strIgnoredPids'"
	local aPercPid=(`\
		ps -A --no-headers --user $USER --sort=-pcpu -o pcpu,pid 2>/dev/null \
		|egrep -v "($l_strIgnoredPids)$" \
		|head -n $((topCPUtoCheckAmount)) \
		|sed 's"^[ ]*""' \
		|sed 's".*"&"'`)
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
	ps -A --user $USER --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm 2>/dev/null \
	|head -n $(($1+1))
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
	#anIgnorePids=(${anIgnorePids[@]} $pidToLimit)
	anIgnorePids+=($$) # add self of course
	anIgnorePids+=($pidToLimit)
	SECFUNCvarSet anIgnorePids
	
	SECFUNCdelay showTmpr --init
	SECFUNCdelay ${FUNCNAME}_maintenance --init
	
	# from higher to lower in order, the code depends on it...
	nTmprLimitMax=80 #$tmprLimit
	nJustLimitThreshold=$((nTmprLimitMax-3))
	nLowFpsLimitingThreshold=$((nTmprLimitMax-7))
	nRunAgainThreshold=$((nTmprLimitMax-15))
	
	fStepMin=0.025
	fStepMax=3.0
	SECFUNCvarSet fSigStopDelay=0.0
	SECFUNCvarSet fSigRunDelay=$fStepMax
	
	bForceStop=false
	bJustLimit=false
	
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
				if ! $bOverrideForceStopNow;then
					nice -n 19 echoc --say "stopped $tmprCurrent"
				else
					echo "external application asked override to keep pid=$pidToLimit stopped temperature=$tmprCurrent"
				fi
			elif $bJustLimit;then
				echo "just limit $tmprCurrent (stop delay $fSigStopDelay)"
			else
				echo "running $tmprCurrent"
			fi
			SECFUNCdelay showTmpr --init
		fi
		
		# from highest to lowest temperature limits
		if $bOverrideForceStopNow || ((tmprCurrent>=nTmprLimitMax));then
			# while bOverrideForceStopNow is true, proccess will be kept stopped
			SECFUNCvarSet fSigStopDelay=$fStepMax
			SECFUNCvarSet fSigRunDelay=0.0
			bForceStop=true
		fi
		
		if ! $bForceStop; then
			if((tmprCurrent>=nJustLimitThreshold));then
				SECFUNCvarSet fSigStopDelay=$fStepMax
				if $bJustStopPid;then
					SECFUNCvarSet fSigRunDelay=0.0
					bForceStop=true
				else
					SECFUNCvarSet fSigRunDelay=`SECFUNCbcPrettyCalc "$fStepMin+$fStepMin"`
					bJustLimit=true
				fi
			elif $bDoLowFpsLimiting && ((tmprCurrent>=nLowFpsLimitingThreshold));then
				# this is somewhat annoying like a lagged/low fps game...
				SECFUNCvarSet fSigStopDelay=$fStepMin
				SECFUNCvarSet fSigRunDelay=$fStepMin
				bJustLimit=true
			fi
		fi
		
		# check if can run normally again
		if ! $bOverrideForceStopNow;then
			# will wait user set bOverrideForceStopNow to true...
			if((tmprCurrent<=nRunAgainThreshold));then
				if((`FUNCtmprAverage 10`<=nRunAgainThreshold));then #to make it sure
					bForceStop=false
					bJustLimit=false
					SECFUNCvarSet fSigStopDelay=0.0
					SECFUNCvarSet fSigRunDelay=$fStepMax
				fi
			fi
		fi
		
		#echo "bJustLimit=$bJustLimit, bForceStop=$bForceStop, bJustStopPid=$bJustStopPid, fSigStopDelay=$fSigStopDelay, fSigRunDelay=$fSigRunDelay, bOverrideForceStopNow=$bOverrideForceStopNow" #DEBUG
		sleep 0.5
	done
}

function FUNCdaemon() {
	if $isDaemonRunning; then
		echoc -p "daemon is already running!"
		exit 1
	#else
	#	echo $$ >"$lockFile"
	fi

	local maxTemperature=0
	local prevTemperature=0
	local lastWarningSaidTime=0
	local warningDelay=60
	local beforeLimitWarn=1
	anIgnorePids+=($$) # add this main daemon pid
	varset anIgnorePids
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
}

function FUNCcheckIfDaemonRunningOrExit() {
	if ! $isDaemonRunning;then
		echoc -p "daemon not running!"
		exit 1
	fi
}

################## options
SECFUNCvarSet --default isLoweringTemperature=false
varset --default bJustStopPid=false
varset --default bDoLowFpsLimiting=false
varset --default bOverrideForceStopNow=false
#bDaemon=false #DO NOT USE varset on this!!! because must be only one process to use it!
while [[ "${1:0:1}" == "-" ]];do
	if [[ "${1:1:1}" == "-" ]];then
		if [[ "$1" == "--isloweringtemperature" ]];then #help
			FUNCcheckIfDaemonRunningOrExit
			#SECFUNCvarGet isLoweringTemperature
			if $isLoweringTemperature;then
				echo "true"
				exit 0
			else
				echo "false"
				exit 1
			fi
		elif [[ "$1" == "--debugfaketmpr" ]];then #help <FakeTemperature> set a fake temperature for debug purposes. Set FakeTemperature to "off" to disable it and use real temperature again.
			FUNCcheckIfDaemonRunningOrExit
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
		elif [[ "$1" == "--secvarset" ]];then #help <var> <value>, direct access to SEC vars; put 'help' in place of <var> to see what vars can be changed
			FUNCcheckIfDaemonRunningOrExit
			shift
			if [[ -z "$1" ]] || [[ "${1:0:1}" == "-" ]];then
				echoc -p "expecting <var> or 'help'"
				exit 1
			fi
			if [[ "$1" == "help" ]];then
				echoc --info "Set these secvars to related options:"
				echo
				echoc "@c--limitcpu: @wInstead of alternating between running and stopping pid, will just stop it until temperature lowers properly."
				echoc "@g`SECFUNCvarShow bJustStopPid`"
				echo
				echoc "@c--limitcpu: @wset this variable to 'true' to stop <pid> and keep it stopped until this variable is set again to 'false' when stopping will be automatic again based on temperature."
				echoc "@g`SECFUNCvarShow bOverrideForceStopNow`"
				echo
				echoc "@c--limitcpu: @wset this variable to 'true' to use the fast stop/continue mode that so simulates a low fps behavior."
				echoc "@g`SECFUNCvarShow bDoLowFpsLimiting`"
				echo
				exit
			else
				varId="$1"
				shift
				varValue="$1"
				
				# validate varId
				bFound=false
				aValidSecVars=(bJustStopPid bOverrideForceStopNow bDoLowFpsLimiting)
				for secvarCheck in ${aValidSecVars[@]}; do
					if [[ "$varId" == "$secvarCheck" ]];then
						bFound=true
						break
					fi
				done
				if ! $bFound;then
					echoc -p "invalid <var> '$varId'"
					exit 1
				fi
				
				if [[ -z "$varValue" ]] || [[ "${varValue:0:2}" == "--" ]];then
					echoc -p "invalid <value> '$varValue'"
					exit 1
				fi
				
				varset --show "$varId" "$varValue"
			fi
		elif [[ "$1" == "--limitcpu" ]];then #help <pid> limit cpu usage for specified pid to lower temperature
			FUNCcheckIfDaemonRunningOrExit
			shift
			pidToLimit=$1
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
		elif [[ "$1" == "--daemon" ]];then #help daemon keeps checking for temperature and stopping top proccesses
			FUNCdaemon
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
			echo "dummy" #TODO can a param --daemon be added to be shifted?
		else
			echoc -p "invalid option: $1"
			exit 1
		fi
	fi
	shift
done
#if [[ -n "$1" ]]; then tmprLimit=$1; fi
#if [[ -n "$2" ]]; then minPercCPU=$2; fi

