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
source <(secinit)

#isDaemonRunning=false
#if SECFUNCuniqueLock --quiet; then
#	SECFUNCvarSetDB -f
#else
#	SECFUNCvarSetDB `SECFUNCuniqueLock` #allows intercommunication between proccesses started from different parents
#	isDaemonRunning=true
#fi
SECFUNCuniqueLock --setdbtodaemon #--daemonwait will be set after, here is just to attach the same db of the daemon

selfName=`basename "$0"`

if [[ -z "${anIgnorePids+dummyValue}" ]];then 
	export anIgnorePids=()
	varset anIgnorePids
fi

bFUNCinterruptAsk=false
trap 'FUNCinterruptAsk' INT

############### CONFIG
export nTmprCurrent=0
export tmprLimit=77 #begins beepinging at 80, a bit before, prevents the annoying beeping
export minPercCPU=30

export strChip="k10temp-pci-*"
export topCPUtoCheckAmount=10
export tmprToMonitor="temp1"
export maxDelay=30 #15
export minimumWait=15 #5
#export sedTemperature='s".*: *+\([0-9][0-9]\)\.[0-9]°C.*"\1"'
export sedTemperature='s"^'"$tmprToMonitor"':[[:blank:]]*[+-]([[:digit:]]*)[.][[:digit:]]*°C.*"\1"p' #use this way: sensors |sed -nr "$sedTemperature"
#useOnlyThisPID="" #empty to find the highest cpu usage one
SECFUNCvarSet --default bDebugFakeTmpr=false

export SEC_SAYVOL=10
export SEC_SAYID="$selfName"

############ FUNCTIONS
function FUNCinterruptAsk() {
	bFUNCinterruptAsk=true
	
	# `reset` is to help prevent terminal bug where typed characters will not show after ctrl+c on `read -s` happens (some times only)...
	reset
}

function FUNCbcToBool() {
	local iResult=`echo "$1" |bc -l`
	local bResult=false;
	if((iResult==1));then 
		bResult=true; 
	fi
	echo $bResult
}

function FUNCignoredPidsRemove() {
	local lnCount=0
	local lbFound=false
	SECFUNCvarShow anIgnorePids
	for ignoredPid in ${anIgnorePids[@]};do 
		if((ignoredPid==$1));then
			unset anIgnorePids[lnCount]
			lbFound=true
		fi
		((lnCount++))
	done
	
	if $lbFound;then
		anIgnorePids=(${anIgnorePids[@]}) #removes the empty items
		varset --show anIgnorePids
		
		echoc --info "pid $1 removed from the ingore list."
		return 0
	else
		echoc --info "pid $1 not in the ingore list.."
		return 1
	fi
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
		ps -A --no-headers --user \`SECFUNCgetUserNameOrId\` --sort=-pcpu -o pcpu,pid 2>/dev/null \
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
			#aHighPercPidList=(${aHighPercPidList[*]} ${aPercPid[i+1]})
			aHighPercPidList+=(${aPercPid[i+1]})
		fi
	done
	SECFUNCechoDbgA "aHighPercPidList=(${aHighPercPidList[@]-})"
	#echo ${aHighPercPidList[*]-}
}

function FUNClistTopPids() {
	ps -A --user `SECFUNCgetUserNameOrId` --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm 2>/dev/null \
	|head -n $(($1+1))
}

function FUNCsleepCalcDelay() {
	local lnSleep=29
	
	# prime numbers ftw!
	if(( nTmprCurrent > (tmprLimit-50) ));then
		lnSleep=19
	fi
	if(( nTmprCurrent > (tmprLimit-40) ));then
		lnSleep=13
	fi
	if(( nTmprCurrent > (tmprLimit-30) ));then
		lnSleep=7
	fi
	if(( nTmprCurrent > (tmprLimit-20) ));then
		lnSleep=3
	fi
	if(( nTmprCurrent > (tmprLimit-10) ));then
		lnSleep=1
	fi
	if(( nTmprCurrent > (tmprLimit-5) ));then
		lnSleep=0.5
	fi
	
	echo "$lnSleep"
};export -f FUNCsleepCalcDelay

function FUNCsleep() {
	# `sleep` does not work with ctrl+c trap properly...
	read -s -t "$1" -p ""&&:
	return 0
};export -f FUNCsleep

function FUNCinfoSleep() {
	local lnSleep=$1
	shift
	
	#echo -n "$@";read -s -t $lnSleep -p "";echo
	echo -n "$@";FUNCsleep "$lnSleep";echo
	#echoc -t 1 --info "$@" #too much cpu usage
}

function FUNCtmprAverage() {
	local count=$1
	
	if [[ -z "$count" ]];then
		count=20 #each 10 = 1second
	fi
	
	local scale=0 #local scale=1
	bc <<< ` \
		for((i=0;i<$count;i++)); do \
			sensors "$strChip" |sed -nr "$sedTemperature"; \
			FUNCsleep 0.1; \
		done |tr '\n' '+' |sed "s|.*|scale=$scale;(&0)/$count|"`
}

#function FUNCmonTmpr() {
#	#nTmprCurrent=`sensors |sed -nr "$sedTemperature"`
#	nTmprCurrent=`FUNCtmprAverage 1`
#};export -f FUNCmonTmpr

function FUNCchildLimCpuFastLoop() {
	source <(secinit)
	#SECFUNCvarWaitRegister pidToLimit
#	SECFUNCvarWaitRegister fSigStopDelay
#	SECFUNCvarWaitRegister fSigRunDelay
	SECFUNCvarWaitValue --report --not pidToLimit ""
	SECFUNCvarWaitValue --report --not fSigStopDelay ""
	SECFUNCvarWaitValue --report --not fSigRunDelay ""
	
	SECFUNCdelay ${FUNCNAME}_maintenance --init
	while true; do
		if SECFUNCdelay ${FUNCNAME}_maintenance --checkorinit1 1;then
			#SECFUNCvarSet DEBUG_${FUNCNAME} "\$\$=$$ PPID=$PPID pidToLimit=$pidToLimit BASHPID=$BASHPID"
#			if ! ps -p $$ >/dev/null 2>&1; then break; fi
#			if ! ps -p $PPID >/dev/null 2>&1; then break; fi
#			if ! ps -p $pidToLimit >/dev/null 2>&1; then break; fi
			if [[ ! -d "/proc/$$"          ]]; then break; fi
			if [[ ! -d "/proc/$PPID"       ]]; then break; fi
			if [[ ! -d "/proc/$pidToLimit" ]]; then break; fi
			SECFUNCvarReadDB
#			SECFUNCdelay ${FUNCNAME}_maintenance --init
		fi
		
		if [[ "$fSigStopDelay" != "0.0" ]];then
			kill -SIGSTOP $pidToLimit&&:
			FUNCsleep $fSigStopDelay
		fi
		if [[ "$fSigRunDelay" != "0.0" ]];then
			kill -SIGCONT $pidToLimit&&:
			FUNCsleep $fSigRunDelay
		fi
	done
}
function FUNClimitCpu() {
	#there exists this: `sudos cpulimit -v -p $pidToLimit -l 99` #but it doesnt care about temperature and also wont accept -l greater than 100 and... requires root/sudo access
	
	#echo "tmprLimit=$tmprLimit";exit
	SECFUNCvarSet pidToLimit=$1
	
	# to avoid having this buffer cleared by the MAIN daemon and not clear that too
	export SEC_SAYID="$SEC_SAYID.$FUNCNAME.$$"
	secSayStack.sh --clearbuffer #to stop saying loads of useless information..
	
	# make main process ignore the pid
	SECFUNCvarReadDB
	#anIgnorePids=(${anIgnorePids[@]} $pidToLimit)
	anIgnorePids+=($$) # add self of course
	anIgnorePids+=($pidToLimit)
	SECFUNCvarSet --show anIgnorePids
	
	nCoolCPUCount=0
	nCoolCPUCountMax=3
	nMinWaitToCoolCPU=30
	SECFUNCdelay minWaitToCoolCPU --init
	SECFUNCdelay showTmpr --init
	SECFUNCdelay ${FUNCNAME}_maintenance --init
	
	# from higher to lower in order, the code depends on it...
	nTmprLimitMax=80 #$tmprLimit
	nJustLimitThreshold=$((nTmprLimitMax-3))
	nLowFpsLimitingThreshold=$((nTmprLimitMax-7))
	nRunAgainThreshold=$((nTmprLimitMax-15)) #-20 is good too
	
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
			nTmprCurrent=$tmprCurrentFake
		else
			if $bForceStop || $bJustLimit;then
				nTmprCurrent=`FUNCtmprAverage 15`
			else
				nTmprCurrent=`FUNCtmprAverage 3`
			fi
		fi
		
		if((`SECFUNCdelay showTmpr --getsec`>=3));then
			if $bForceStop;then
				if ! $bOverrideForceStopNow;then
					#nice -n 19 echoc --say "stopped $nTmprCurrent"
					nice -n 19 echoc --say "$nTmprCurrent"
				else
					echo "external application asked override to keep pid=$pidToLimit stopped temperature=$nTmprCurrent"
				fi
			elif $bJustLimit;then
				echo "just limit $nTmprCurrent (stop delay $fSigStopDelay)"
			else
				echo "running $nTmprCurrent"
			fi
			SECFUNCdelay showTmpr --init
		fi
		
		# from highest to lowest temperature limits
		bTmprOverLimit=false
		if((nTmprCurrent>=nTmprLimitMax));then
			bTmprOverLimit=true
			#SECFUNCdelay minWaitToCoolCPU --init
		fi
		if $bOverrideForceStopNow || $bTmprOverLimit;then
			# while bOverrideForceStopNow is true, proccess will be kept stopped
			SECFUNCvarSet fSigStopDelay=$fStepMax
			SECFUNCvarSet fSigRunDelay=0.0
			bForceStop=true
		fi
		
		if ! $bForceStop; then
			if((nTmprCurrent>=nJustLimitThreshold));then
				SECFUNCvarSet fSigStopDelay=$fStepMax
				if $bJustStopPid;then
					SECFUNCvarSet fSigRunDelay=0.0
					bForceStop=true
				else
					SECFUNCvarSet fSigRunDelay="`SECFUNCbcPrettyCalcA "$fStepMin+$fStepMin"`"
					bJustLimit=true
				fi
			elif $bDoLowFpsLimiting && ((nTmprCurrent>=nLowFpsLimitingThreshold));then
				# this is somewhat annoying like a lagged/low fps game...
				SECFUNCvarSet fSigStopDelay=$fStepMin
				SECFUNCvarSet fSigRunDelay=$fStepMin
				bJustLimit=true
			fi
			
			if $bForceStop;then
				SECFUNCdelay minWaitToCoolCPU --init
				(export SEC_SAYVOL=100;echoc --say "going to wait at least $nMinWaitToCoolCPU seconds to C.P.U. cool down")
			fi
		fi
		
		# check if can run normally again
		if ! $bOverrideForceStopNow;then
			# will wait user set bOverrideForceStopNow to true...
			if((nTmprCurrent<=nRunAgainThreshold));then
				nTmprCurrent=`FUNCtmprAverage 30`
				if((nTmprCurrent<=nRunAgainThreshold));then #to make it 'more sure' as temperature varies too much... 50 would be better but takes too much time..
					((nCoolCPUCount++))
					echo "nCoolCPUCount: $nCoolCPUCount of $nCoolCPUCountMax"
					if((`SECFUNCdelay minWaitToCoolCPU --getsec`>=nMinWaitToCoolCPU));then
						if((nCoolCPUCount>=nCoolCPUCountMax));then
							if $bForceStop;then
								secSayStack.sh --clearbuffer #to stop saying loads of useless information..
								echoc --waitsay "ready to run again $nTmprCurrent"
							fi
						
							bForceStop=false
							bJustLimit=false
							SECFUNCvarSet fSigStopDelay=0.0
							SECFUNCvarSet fSigRunDelay=$fStepMax
						fi
					fi
				else
					nCoolCPUCount=0
				fi
			else
				nCoolCPUCount=0
			fi
		fi
		
		#echo "bJustLimit=$bJustLimit, bForceStop=$bForceStop, bJustStopPid=$bJustStopPid, fSigStopDelay=$fSigStopDelay, fSigRunDelay=$fSigRunDelay, bOverrideForceStopNow=$bOverrideForceStopNow" #DEBUG
		if $bFUNCinterruptAsk;then
			bFUNCinterruptAsk=false
			SECFUNCvarShow bOverrideForceStopNow
			echoc -Q -t 3 "do what?@O_exit/force _stop/allow _run again";
			case "`secascii $?`" in 
				e)FUNCignoredPidsRemove $pidToLimit;exit;; 
				s)varset --show bOverrideForceStopNow=true;;
				r)varset --show bOverrideForceStopNow=false;;
			esac
		else
			FUNCsleep `FUNCsleepCalcDelay`
		fi
	done
}

function FUNCdaemon() {
#	if $SECbDaemonWasAlreadyRunning; then
#		echoc -p "daemon is already running!"
#		exit 1
#	#else
#	#	echo $$ >"$lockFile"
#	fi
	SECFUNCuniqueLock --daemonwait
	secDaemonsControl.sh --register
	
	secSayStack.sh --clearbuffer #to stop saying loads of useless information.. when this app is restarted..
	
	local maxTemperature=0
	local prevTemperature=0
	local lastWarningSaidTime=0
	local warningDelay=60
	local beforeLimitWarn=1
	anIgnorePids+=($$) # add this main daemon pid
	varset anIgnorePids
	while true; do
		SECFUNCvarReadDB
		#SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold #DO NOT hold this critical script execution!!!
		
		if $bDebugFakeTmpr;then
			nTmprCurrent=$tmprCurrentFake
		else
			nTmprCurrent=`FUNCtmprAverage 3`
		fi
		secRemoteInfo.sh --set PCIadapterTmpr $nTmprCurrent
	
		if((maxTemperature<nTmprCurrent));then
			maxTemperature=$nTmprCurrent
		fi
	
		#echoc --info "nTmprCurrent=$nTmprCurrent(max=$maxTemperature)(tmprLimit=$tmprLimit)"
		if SECFUNCdelay ShowTopPids --checkorinit 60;then
			FUNClistTopPids 3
		fi
		
		# warning for high temperature near limit
		if((nTmprCurrent>=(tmprLimit-beforeLimitWarn)));then
			if((prevTemperature!=nTmprCurrent));then
				if((SECONDS>(lastWarningSaidTime+warningDelay)));then
					echoc --say "$nTmprCurrent"
					lastWarningSaidTime=$SECONDS
				fi
			fi
		fi
		
		if $bControlCpuFrequency;then
			if $bCpuFreqUseSteps;then
				FUNCmanageCPUFrequencyBySteps
			else
				if((nTmprCurrent<=(tmprLimit-30)));then
					FUNCmanageCPUFrequency ondemand&&:
				else
					if((nTmprCurrent>=(tmprLimit-10)));then
						FUNCmanageCPUFrequency powersave&&:
					elif((nTmprCurrent>=(tmprLimit-20)));then
						FUNCmanageCPUFrequency conservative&&:
					fi
				fi
			fi
		fi
		
		#FUNChighPercPidList
		if((nTmprCurrent>=tmprLimit));then
			FUNChighPercPidList
			FUNClistTopPids 3
			if((${#aHighPercPidList[@]}==0));then
				echoc --say --alert "WARNING no high C.P.U. processes to stop! "
			else
				# report processes
				FUNClistTopPids $topCPUtoCheckAmount
				#echoc -x "ps -A --sort=-pcpu -o pcpu,pid,ppid,stat,state,nice,user,comm |head -n $((topCPUtoCheckAmount+1))"
				#pidHighCPUusage=`ps --user \`SECFUNCgetUserNameOrId\` --sort=-pcpu -o pid |head -n 2 |tail -n 1`
				#pidHCUCmdName=`ps -p $pidHighCPUusage -o comm |head -n 2 |tail -n 1`
				#echoc -x "ps -p $pidHighCPUusage -o pcpu,pid,ppid,stat,state,nice,user,comm |tail -n 1"
		
				#FUNChighPercPidList
				#echoc -x "kill -SIGSTOP $pidHighCPUusage"
				echoc -x "kill -SIGSTOP ${aHighPercPidList[*]}"
			
				#echoc --say "high temperature $nTmprCurrent, stopping: $pidHCUCmdName"&
				echoc --say "$nTmprCurrent"
				(export SEC_SAYVOL=100;echoc --say "high temperature, stopping some processes...")
		
				count=0
				SECFUNCdelay timeToCoolDown --init
				while true; do
					SECFUNCvarSet isLoweringTemperature=true
					tmprCurrentold=$nTmprCurrent
					nTmprCurrent=`FUNCtmprAverage 10` #FUNCmonTmpr
					((count++))
			
					echo "current temperature: $nTmprCurrent"
					FUNClistTopPids $((${#aHighPercPidList[*]}+1))
			
					if((count>maxDelay));then
						echoc --say "Time limit ($maxDelay seconds) to lower temperature reached..."
						break;
					fi
			
					#stabilized or reached a minimum old<=current
					if((count>=minimumWait && tmprCurrentold<=nTmprCurrent));then
						break;
					fi
			
					FUNCsleep 1 #echoc -x "FUNCsleep 1" #let it cooldown a bit
					echoc --say "$nTmprCurrent"
				done
				SECFUNCvarSet isLoweringTemperature=false
				secSayStack.sh --clearbuffer #to stop saying loads of useless information..
				#echoc --say "running $nTmprCurrent"
			
				echo "temperature lowered to: $nTmprCurrent in `SECFUNCdelay timeToCoolDown --getsec` seconds"
				
				#echoc -x "kill -SIGCONT $pidHighCPUusage"
				echoc -x "kill -SIGCONT ${aHighPercPidList[*]}"
			fi
		fi
		
		# prime numbers ftw!
		local lnDaemonSleep=`FUNCsleepCalcDelay`
		FUNCinfoSleep $lnDaemonSleep "tmpr=$nTmprCurrent; max=$maxTemperature($tmprLimit); sleep=${lnDaemonSleep}s; $strCPUFreqGovernorCurrent"
		
		prevTemperature=$nTmprCurrent
	done
}

function FUNCcheckIfDaemonRunningOrExit() {
	if ! $SECbDaemonWasAlreadyRunning;then
		echoc -p "daemon not running!"
		exit 1
	fi
}

strCPUFreqGovernorCurrent=""
astrCpuFreqSteps=(`cpufreq-info |grep "available frequency steps:" |head -n 1 |tr -d ' ' |tr ':,' '\n\n' |tail -n +2`)
nCpuFreqStepsTotal=${#astrCpuFreqSteps[@]}
echo "nCpuFreqStepsTotal='$nCpuFreqStepsTotal'"
nTmprDiffFromLimitToMaxCpuFreq=30
nCpuTmprStepToChangeFreq=$((nTmprDiffFromLimitToMaxCpuFreq/nCpuFreqStepsTotal))
echo "nCpuTmprStepToChangeFreq='$nCpuTmprStepToChangeFreq'"
nCpuFreqStepLast=-1
bSudoersList=false
bSudoersAdvised=false
strExecutableCpuFreqSet="`which cpufreq-set`"
function FUNCmanageCPUFrequencyBySteps() {
	if ! $bSudoersAdvised;then
		if ! sudo -n uptime 2>/dev/null 1>/dev/null;then #check if running with no sudo privileges
			echoc --info "It is helpful if you add these commands to your sudoers! "
			echoc --info "Review AND Understand all these commands BEFORE doing it!!! "
			echoc --alert "If you do NOT understand what these commands do, do not do it! "
			echoc --info "If you think this could be done in a better way, tell me, thanks! "
			bSudoersAdvised=true
			FUNCmanageCPUFrequencyBySteps --sudoerslist
		fi
	fi
	
	if [[ "${1-}" == "--sudoerslist" ]];then
		bSudoersList=true
		nTmprCurrentBkp=$nTmprCurrent
		
		for((nCpuFreqStepCheck=0; nCpuFreqStepCheck < nCpuFreqStepsTotal; nCpuFreqStepCheck++));do
			local lnTmprStepCheck=$(( (nCpuFreqStepCheck+1)*nCpuTmprStepToChangeFreq ))
			nTmprCurrent=$(( tmprLimit-lnTmprStepCheck+1 ));
			FUNCmanageCPUFrequencyBySteps
		done
		
		nTmprCurrent=$nTmprCurrentBkp
		bSudoersList=false
		return 0
	fi
	
	local nCpuFreqStepToSet=0
	#echo "nTmprCurrent='$nTmprCurrent'"
	
	# in case nTmprCurrent lower than $((tmprLimit-nTmprDiffFromLimitToMaxCpuFreq)), nCpuFreqStepToSet will remain 0, that is maximum speed
	for((nCpuFreqStepCheck=0; nCpuFreqStepCheck < nCpuFreqStepsTotal; nCpuFreqStepCheck++));do
		local lnTmprStepCheck=$(( (nCpuFreqStepCheck+1)*nCpuTmprStepToChangeFreq ))
		#echo "lnTmprStepCheck='$lnTmprStepCheck'"
		#echo "tmprLimit-lnTmprStepCheck='$((tmprLimit-lnTmprStepCheck))'"
		if(( nTmprCurrent>(tmprLimit-lnTmprStepCheck) ));then
			nCpuFreqStepToSet=$(( (nCpuFreqStepsTotal-1) - nCpuFreqStepCheck ))
			break
		fi
	done
	
	#echo "nCpuFreqStepToSet='$nCpuFreqStepToSet'"
	
	if ! $bSudoersList;then
		if((nCpuFreqStepLast==nCpuFreqStepToSet));then
			return 0
		fi
	fi
	
	local lstrOptEcho="--echo"
	local lstrSudoOrSudoers="sudo"
	if $bSudoersList;then
		lstrOptEcho="--justechonoquotes"
		lstrSudoOrSudoers="$USER ALL=NOPASSWD:"
	fi
	for nCPU in "${anCPUList[@]}";do
		if((nCpuFreqStepToSet==0));then
			SECFUNCexec -c $lstrOptEcho $lstrSudoOrSudoers $strExecutableCpuFreqSet --cpu $nCPU --governor ondemand
		else
			SECFUNCexec -c $lstrOptEcho $lstrSudoOrSudoers $strExecutableCpuFreqSet --cpu $nCPU --freq ${astrCpuFreqSteps[$nCpuFreqStepToSet]}
		fi
	done
	
	if ! $bSudoersList;then
		cpufreq-info |egrep "analyzing CPU|current CPU frequency is " |gawk '{strLine=$0; getline; print strLine $0;}' |gawk '{print $3 $8 $9}'
	
		nCpuFreqStepLast=$nCpuFreqStepToSet
		strCPUFreqGovernorCurrent="`cpufreq-info -o |tail -n 1 |tr -d ' '|tr '-' ' ' |gawk '{printf $3}'`"
	fi
}

anCPUList=(`lscpu -p |grep -v "^#"|cut -d, -f1`)
strCPUGovernorLast=""
function FUNCmanageCPUFrequency() {
	strCPUFreqGovernorToSet="${1-}"
	if [[ "$strCPUFreqGovernorToSet" == "$strCPUGovernorLast" ]];then
		return 0
	fi
	
	astrGovernors=(
		"powersave"
		"conservative"
		"ondemand"
		"performance" #TODO check if unnecessarily spends too much power?
	)
	
	bFound=false
	for strGovernor in "${astrGovernors[@]}";do
		if [[ "$strGovernor" == "$strCPUFreqGovernorToSet" ]];then
			for nCPU in "${anCPUList[@]}";do
				#TODO amazingly it doesnt return error value? #while ! cpufreq-selector -c $nCPU -g $strGovernor;do
				#while [[ "`cpufreq-selector -c $nCPU -g $strGovernor 2>&1`" ==	"Error calling SetGovernor: Caller is not authorized" ]];do
				if [[ "`cpufreq-selector -c $nCPU -g $strGovernor 2>&1`" ==	"Error calling SetGovernor: Caller is not authorized" ]];then
					#TODO check if seems to fail when the temperature is too high?
					echoc -p "failed for nCPU='$nCPU' strGovernor='$strGovernor'"
					#sleep 0.5
					return 1
				fi
			done
			bFound=true
			break
		fi
	done
	
	cpufreq-info -o
	
	if ! $bFound;then
		SECFUNCechoErrA "invalid strCPUFreqGovernorToSet='$strCPUFreqGovernorToSet'"
		_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
	fi
	
#	if [[ "${astrGovernors[0]}" == "$strCPUFreqGovernorToSet" ]];then
#		if [[ "$strCPUFreqGovernorToSet" != "$strCPUGovernorLast" ]];then
#			(export SEC_SAYVOL=100;echoc --say "C P U $strCPUFreqGovernorToSet")
#		fi
#	fi
	
	strCPUFreqGovernorCurrent="`cpufreq-info -o |tail -n 1 |tr -d ' '|tr '-' ' ' |gawk '{printf $3}'`"
	if [[ "$strCPUFreqGovernorCurrent" == "$strCPUFreqGovernorToSet" ]];then
		strCPUGovernorLast="$strCPUFreqGovernorToSet"
	else
		echoc -p "failed to set strCPUFreqGovernorToSet='$strCPUFreqGovernorToSet'"
	fi
}
function _FUNCmanageCPUFrequencyGradative() { #help -1 or +1 to increase or decrease governor frequency mode
	anCPUList=(`lscpu -p |grep -v "^#"|cut -d, -f1`)
	strCPUFreqGovernorCurrent="`cpufreq-info -o |tail -n 1 |tr -d ' '|tr '-' ' ' |gawk '{printf $3}'`"
	astrGovernors=(
		"powersave"
		"conservative"
		"ondemand"
		"performance" #TODO check if unnecessarily spends too much power?
	)
	
	nGovIndexCurrent=0 #if it is "userspace" will just be set to first now...
	for strGovernor in "${astrGovernors[@]}";do
		if [[ "$strGovernor" == "$strCPUFreqGovernorCurrent" ]];then
			break
		fi
		$((nGovIndexCurrent++))&&:
	done
	
	if [[ "${1-}" == "-1" ]];then
		$((nGovIndexCurrent--))&&:
	elif [[ "${1-}" == "+1" ]];then
		$((nGovIndexCurrent++))&&:
	else
		SECFUNCechoErrA "invalid option ${1-}"
		_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
	fi
	
	if((nGovIndexCurrent<0));then
		nGovIndexCurrent=0
	elif(( nGovIndexCurrent > ${#astrGivernors[@]} ));then
		nGovIndexCurrent=$(( ${#astrGivernors[@]}-1 ))&&:
	fi
	
	strGovernor=${astrGivernors[nGovIndexCurrent]}
	for nCPU in "${anCPUList}";do
		cpufreq-selector -c $nCPU -g $strGovernor
	done
	
	cpufreq-info -o
}

################## options
varset --default isLoweringTemperature=false
varset --default --allowuser bJustStopPid=false
varset --default --allowuser bDoLowFpsLimiting=false
varset --default --allowuser bOverrideForceStopNow=false
varset --default --allowuser bControlCpuFrequency=true
bCpuFreqUseSteps=false
#bDaemon=false #DO NOT USE varset on this!!! because must be only one process to use it!
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	b2ndIsParam=false
	if [[ -n "${2-}" ]] && [[ "${2:0:1}" != "-" ]];then
		b2ndIsParam=true
	fi
	
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
			if [[ "${1-}" == "off" ]];then
				SECFUNCvarSet bDebugFakeTmpr=false
				exit
			fi
		
#			if [[ -z "${1-}" ]];then
#				echoc -p "missing fake temperature parameter"
#				exit 1
#			fi
			if ! SECFUNCisNumber -dn "${1-}";then
				echoc -p "invalid fake temperature parameter '${1-}'"
				exit 1
			fi
			
			SECFUNCvarSet bDebugFakeTmpr=true
			SECFUNCvarSet tmprCurrentFake $1
			exit
		elif [[ "$1" == "--nocpufreq" ]];then #help disables cpufreq managing
			bControlCpuFrequency=false
		elif [[ "$1" == "--cpufreqsteps" ]];then #help use cpufreq steps, requires privileges
			bCpuFreqUseSteps=true
		elif [[ "$1" == "--secvarset" ]];then #help <var> <value> direct access to SEC vars; put 'help' in place of <var> to see what vars can be changed
			FUNCcheckIfDaemonRunningOrExit
			shift
#			if [[ -z "$1" ]] || [[ "${1:0:1}" == "-" ]];then
#				echoc -p "expecting <var> or 'help'"
#				exit 1
#			fi
			if [[ -z "${1-}" || "${1-}" == "help" ]];then
				echoc --info "Set these secvars to related options: ${SECvarsUserAllowed[@]}"
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
				varId="${1-}"
				shift
				varValue="${1-}"
				
#				# validate varId
#				bFound=false
#				aValidSecVars=(bJustStopPid bOverrideForceStopNow bDoLowFpsLimiting)
#				for secvarCheck in ${aValidSecVars[@]}; do
#					if [[ "$varId" == "$secvarCheck" ]];then
#						bFound=true
#						break
#					fi
#				done
#				if ! $bFound;then
#					echoc -p "invalid <var> '$varId'"
#					exit 1
#				fi
#				
#				if [[ -z "$varValue" ]] || [[ "${varValue:0:2}" == "--" ]];then
#					echoc -p "invalid <value> '$varValue'"
#					exit 1
#				fi
				
				varset --checkuser --show -- "$varId" "$varValue"
			fi
		elif [[ "$1" == "--limitcpu" ]];then #help <pid> limit cpu usage for specified pid to lower temperature
			FUNCcheckIfDaemonRunningOrExit
			shift
			pidToLimit=$1
			if ps -p $pidToLimit >/dev/null 2>&1;then
				FUNClimitCpu $pidToLimit
			else
				echoc -p "missing valid pid"
				$0 --help |grep "\-\-limitcpu" >&2
				exit 1
			fi
			exit
		elif [[ "$1" == "--tmpr" ]];then #help get temperature
			countToAvg=15
			if $b2ndIsParam; then
				countToAvg="$2"
			fi
			nTmprCurrent=`FUNCtmprAverage $countToAvg`
			echo "$nTmprCurrent"
			exit
		elif [[ "$1" == "--daemon" ]];then #help daemon keeps checking for temperature and stopping top proccesses
			FUNCdaemon
			exit
		elif [[ "$1" == "--help" ]];then #help
			echo "This app monitors the temperature and stop applications that are using too much cpu to let the temperature go down! And start them again after some time. Also it changes the cpu frequency to cool down."
			echo "It is limited to the current user processes."
			echo "TODO: monitor all temperatures as only cpu temperature is monitored for now.."
			#echo "PARAMS: tmprLimit minPercCPU"
			echo
			echo "Options:"
			#grep "#help" $0 |grep -v grep |sed -r 's/.*"(--[[:alnum:]]*)" \]\];then #help[ ]*(.*)/\t\1\t\t\2/'
			SECFUNCshowHelp
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

