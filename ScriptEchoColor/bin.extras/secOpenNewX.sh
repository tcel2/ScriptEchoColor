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

#@@@R would need to be at xterm& #trap 'ps -A |grep Xorg; ps -p $pidX1; sudo -k kill $pidX1;' INT #workaround to be able to stop the other X session

########################## INIT AND VARS #####################################
eval `secinit --extras`
SECFUNCechoDbgA "init"
SECFUNCuniqueLock --setdbtodaemon #SECFUNCdaemonUniqueLock #SECisDaemonRunning
SECFUNCechoDbgA "SECvarFile='$SECvarFile'"

#alias ps='echoc -x ps' #good to debug the bug

if [[ -z "${SEC_SAYVOL-}" ]];then
	export SEC_SAYVOL=15 #from 0 to 100 #this should be controlled by external scripts...
fi
SECFUNCvarGet SEC_SAYVOL

export execX1="X :1"
grepX1="X :1"
selfName=`basename "$0"`
strOptXtermGeom="100x1" #"1x1" causes problems with ps and others, making everything hard to be readable
#execX1="startx -- :1"
#grepX1="/usr/bin/X :1 [-]auth /tmp/serverauth[.].*"

# when you see "#kill=skip" at the end of commands, will prevent terminals from being killed on killall commands (usually created at other scripts)

#sedOnlyPid='s"^[ ]*\([0-9]*\) .*"\1"'
sedOnlyPid='s"[ ]*([[:digit:]]*) .*"\1"'

######################### FUNCTIONS #####################################

#function FUNCxlock() {
#	DISPLAY=:1 xlock -mode matrix -delay 30000 -timeelapsed -verbose -nice 19 -timeout 5 -lockdelay 0 -bg darkblue -fg yellow
#}; export -f FUNCxlock

#function FUNCCHILDScreenLockLightWeight() {
#	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
#	while true;do
#		if $bUseXscreensaver; then
#			if FUNCisScreenLockRunning;then
#				# xscreensaver spawns a child with the actual screensaver
#				if [[ "`ps --ppid $nXscreensaver1Pid -o comm --no-headers`" != "maze" ]];then
#					DISPLAY=:1 xscreensaver-command -select 1 #grants a lightweight screensaver
#					echo "set a lightweight screensaver (maze) `date`"
#				fi
#			fi
#			
#			sleep 10
#		fi
#	done
#};export -f FUNCCHILDScreenLockLightWeight

function FUNCCHILDScreenLockNow() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	if $bUseXscreensaver; then
		DISPLAY=:1 xscreensaver-command -lock
#		while true;do
#			if ! FUNCisScreenLockRunning;then
#				break
#			fi
#			
#			# xscreensaver spawns a child with the actual screensaver
#			if [[ "`ps --ppid $nXscreensaver1Pid -o comm --no-headers`" != "maze" ]];then
#				DISPLAY=:1 xscreensaver-command -select 1 #grants a lightweight screensaver?
#				echo "setting a lightweight screensaver (maze)..."
#			fi
#			
#			echoc -w -t 10
#		done
	fi
	echoc -w -t 10 "just locked screen"
};export -f FUNCCHILDScreenLockNow

function FUNCrestartPulseAudioDaemonChild() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	# restart pulseaudio daemon
	SECFUNCexecA -c --echo pulseaudio -k
	while true;do
		if ! pgrep -x pulseaudio;then
			SECFUNCexecA -c --echo pulseaudio -D	
		fi
		sleep 3
	done
};export -f FUNCrestartPulseAudioDaemonChild

function FUNCCHILDPreventAutoLock() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	while true;do
		if $bUseXscreensaver; then
			if ! FUNCisScreenLockRunning;then
				xscreensaver-command -time
				xscreensaver-command -deactivate
			fi
		fi
		sleep 60
	done
};export -f FUNCCHILDPreventAutoLock

#function FUNCCHILDScreenSaver() {
#	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
#	#SECFUNCvarShow bUseXscreensaver #@@@r
#	local strCmdXscreensaver1="xscreensaver -display :1"
#	function FUNClightWeightXscreensaver() {
#		while [[ -d "/proc/$nXscreensaver1Pid" ]];do
#			echo "check for a lightweight screensaver `date`"
#			if FUNCisScreenLockRunning;then
#				# xscreensaver spawns a child with the actual screensaver
#				if [[ "`ps --ppid $nXscreensaver1Pid -o comm --no-headers`" != "maze" ]];then
#					DISPLAY=:1 xscreensaver-command -select 1 #grants a lightweight screensaver
#					echo "set a lightweight screensaver (maze) `date`"
#				fi
#			fi
#		
#			sleep 10
#		done
#	}
#	function FUNCgetXscreensaverPid(){
#		while true;do	
#			if nXscreensaver1Pid="`pgrep -fx "$strCmdXscreensaver1"`";then
#				varset --show nXscreensaver1Pid=$nXscreensaver1Pid
#				FUNClightWeightXscreensaver
#				break;
#			fi
#			echo "waiting nXscreensaver1Pid be set..."
#			sleep 1
#		done
#	}
#	
#	while true;do #in case it is killed
#		echo "activating screen saver at `date`: '$strCmdXscreensaver1'"
#		if $bUseXscreensaver; then
#			FUNCgetXscreensaverPid&
#			$strCmdXscreensaver1
#	#	else
#	#		DISPLAY=:1 xautolock -locker "bash -c FUNCxlock"
#		fi
#		sleep 1
#	done
#}; export -f FUNCCHILDScreenSaver

function FUNCisScreenLockRunning() {
	local lstrDisplay="${1-}"
	
	if [[ -z "$lstrDisplay" ]];then
		lstrDisplay=":1"
	fi
	
	if $bUseXscreensaver; then
    #if ps -A -o comm |grep -w "^xscreensaver$" >/dev/null 2>&1;then
    if DISPLAY=$lstrDisplay xscreensaver-command -time |grep "screen locked since" >/dev/null 2>&1;then
      return 0
    fi
#	else
#    if ps -A -o comm |grep -w "^xlock$" >/dev/null 2>&1;then
#      return 0
#    fi
	fi
	return 1
};export -f FUNCisScreenLockRunning

function FUNCisX1running {
  if ps -A -o command |grep -v "grep" |grep -q -x "$grepX1";then
    ps -A -o pid,command |grep -v grep |grep -x "^[ ]*[0-9]* $grepX1" |sed -r "$sedOnlyPid"
  	return 0
  fi
  return 1
};export -f FUNCisX1running

function FUNCsayTime() {
	echoc --say "$((10#`date +"%H"`)) hours and $((10#`date +"%M"`)) minutes"
};export -f FUNCsayTime

function FUNCclearCache() {
	echoc -x "sync" #echoc -x "sudo sync"
	echoc -x "echo 3 |sudo -k tee /proc/sys/vm/drop_caches" #put on sudoers
};export -f FUNCclearCache

#function FUNClockFile() {
#	local bUnlock=false
#	if [[ "$1" == "--unlock" ]];then
#		bUnlock=true;
#		shift
#	fi
#	
#	local fileId="$1"
#	local mainPid="$2" #the main pid that all childs will use as reference
#	
#	local lockFile="/tmp/${fileId}.lock"
#	local lockFileReal="${lockFile}.$mainPid"
#	
#	if $bUnlock;then
#		rm -vf "$lockFile" >>/dev/stderr
#		rm -vf "$lockFileReal" >>/dev/stderr
#		return;
#	fi
#	
#	while ! ln -s "$lockFileReal" "$lockFile" >>/dev/stderr; do #create the symlink
#		local realFile=`readlink "$lockFile"`
#		pidOfRealFile=`echo "$realFile" |sed -r "s'.*[.]([[:digit:]]*)$'\1'"`
#		if ! ps -p $pidOfRealFile >>/dev/stderr;then
#			rm -vf "$realFile" >>/dev/stderr
#		fi
#		if ! sleep 0.1; then return 1; fi #exit_FUNCsayStack: on sleep fail
#	done
#	echo "`SECFUNCdtFmt --pretty`.$$" >>"$lockFileReal"
#}

#export strCicleGammaId="OpenNewX_CicleGammaDaemon"
#function FUNCkeepGamma() { # some games reset the gamma on each restart
#	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
#	
#	SECFUNCuniqueLock --id "$strCicleGammaId" --daemonwait
#	
#	while true; do
#		SECFUNCvarReadDB
#		xgamma -gamma ${fGamma-}
#		echo "keep gamma at ${fGamma-}"
#		sleep 60
#	done
#};export -f FUNCkeepGamma

#function FUNCcicleGamma() {
#	echo "SECvarFile='$SECvarFile'" #@@@R to help on debug
#	
#	eval `secinit --log` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
#	echo "0=$0"
#	echo "PATH='$PATH'"
#	echo "$FUNCNAME" #@@@R to help on debug
#	
#	while ! SECFUNCuniqueLock --id "$strCicleGammaId" --setdbtodaemononly;do
#		echoc -p "waiting strCicleGammaId='$strCicleGammaId'"
#		sleep 3
#	done
#			
#	SECFUNCdbgFuncInA;
#	#set -x
#	local nDirection=$1 #1 or -1
#	
#	#@@@R to help on debug
#	echo "SECvarFile='$SECvarFile'" #@@@R to help on debug
#	ls -l $SECvarFile #@@@R to help on debug
#	echo "pid=$$,PPID=$PPID" #@@@R to help on debug
#	SECFUNCppidList --comm -s "\n" -r #@@@R to help on debug
#	
#	SECFUNCvarSet --show --default fGamma 1.0
#	echo "pidOpenNewX=`SECFUNCvarGet pidOpenNewX`"
#	#SECFUNCvarGet fGamma
#	
##	local lockFileGamma="/tmp/openNewX.gamma.lock"
##	local lockFileGammaReal="${lockFileGamma}.$pidOpenNewX"
##	while ! ln -s "$lockFileGammaReal" "$lockFileGamma"; do #create the symlink
##		local realFile=`readlink "$lockFileGamma"`
##		pidForRealFile=`echo "$realFile" |sed -r "s'.*[.]([[:digit:]]*)$'\1'"`
##		if ! ps -p $pidForRealFile;then
##			rm -vf "$realFile"
##		fi
##		if ! sleep 0.1; then return 1; fi #exit_FUNCsayStack: on sleep fail
##	done
##	echo "`SECFUNCdtFmt --pretty`.$$" >>"$lockFileGammaReal"
#	local lockGammaId="openNewX.gamma"
##	FUNClockFile "$lockGammaId" $pidOpenNewX
##	SECFUNCuniqueLock --pid $pidOpenNewX --id "$lockGammaId"
#	SECFUNCuniqueLock --pid $$ --id "$lockGammaId"

##	SECFUNCvarSet --default gammaLock 0
##	SECFUNCvarWaitValue gammaLock 0
##	SECFUNCvarSet gammaLock $$
#	
#	local nIncrement="0.25"
#	local nMin="0.25"
#	local nMax="10.0"
#	
#	SECFUNCvarSet --show fGamma=`bc <<< "$fGamma+($nDirection*$nIncrement)"`
#	if ((`bc <<< "$fGamma<$nMin"`)); then
#		SECFUNCvarSet --show fGamma=$nMax
#	fi
#	if ((`bc <<< "$fGamma>$nMax"`)); then
#		SECFUNCvarSet --show fGamma=$nMin
#	fi
#	
##	if [[ "$fGamma" == "0.5" ]];then
##		SECFUNCvarSet fGamma=0.75
##	elif [[ "$fGamma" == "0.75" ]];then
##		SECFUNCvarSet fGamma=1.0
##	elif [[ "$fGamma" == "1.0" ]];then
##		SECFUNCvarSet fGamma=1.25
##	elif [[ "$fGamma" == "1.25" ]];then
##		SECFUNCvarSet fGamma=1.5
##	elif [[ "$fGamma" == "1.5" ]];then
##		SECFUNCvarSet fGamma=1.75
##	elif [[ "$fGamma" == "1.75" ]];then
##		SECFUNCvarSet fGamma=2.0
##	elif [[ "$fGamma" == "2.0" ]];then
##		SECFUNCvarSet fGamma=0.5
##	fi
#	
#	xgamma -gamma $fGamma
##	SECFUNCvarSet gammaLock 0
##	rm -vf "$lockFileGamma"
##	FUNClockFile --unlock "$lockGammaId" $pidOpenNewX
##	SECFUNCuniqueLock --release --pid $pidOpenNewX --id "$lockGammaId"
#	echoc --say "gamma $fGamma" #must say before releasing the lock!
#	SECFUNCuniqueLock --release --pid $$ --id "$lockGammaId"
#	#set +x
#	echoc -w -t 60 #@@@R to help on debug
#	SECFUNCdbgFuncOutA;
#};export -f FUNCcicleGamma

function FUNCnvidiaCicle() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	
	SECFUNCdbgFuncInA;
	local nDirection=$1 # 1 or -1
	
	#eval `secinit` #required if using exported function on child environment
	SECFUNCvarSet --default nvidiaCurrent -1
	
	local lockId="openNewX.nvidia"
	SECFUNCuniqueLock --pid $$ --id "$lockId"
	
	limit=9 #99 and 999 are too slow...
	count=0
	while true; do
		#SECFUNCvarSet nvidiaCurrent $((++nvidiaCurrent))
		SECFUNCvarSet nvidiaCurrent $((nvidiaCurrent+(nDirection)))
		
		if((nvidiaCurrent<0));then
			nvidiaCurrent=0
		fi
		
		local l_cfgFile="$HOME/.nvidia-settings-rc.`printf "%03d" $nvidiaCurrent`"
		if [[ -f "$l_cfgFile" ]]; then
			#@@@R echoc -x "nvidia-settings --config=$l_cfgFile --load-config-only" #is slow...
			strEval="nvidia-settings --config=$l_cfgFile --load-config-only"
			if ! echoc -x "$strEval"; then
				echoc -w -t 3
			fi
			break
		fi
		
		((count++))
		if((count>limit));then
			echoc -t 3 --alert "there is no nvidia config file?"
			break
		fi
		
		if((nvidiaCurrent>limit));then
			SECFUNCvarSet nvidiaCurrent -1
			continue;
		fi
	done
	
	SECFUNCuniqueLock --release --pid $$ --id "$lockId"
	
	echoc --waitsay "n-vidia $nvidiaCurrent"
	SECFUNCvarShow nvidiaCurrent
	#echoc -w -t 10 "`SECFUNCvarShow nvidiaCurrent`"
	SECFUNCdbgFuncOutA;
};export -f FUNCnvidiaCicle

#function FUNCtempAvg() {
#	count=20 #each 10 = 1second
#	tmprToMonitor="temp1"
#	bc <<< `
#		for((i=0;i<$count;i++)); do 
#			sensors \
#				|grep "$tmprToMonitor" \
#				|sed -r "s;$tmprToMonitor(.*);\1;" \
#				|tr -d ' :[:alpha:]°()=' \
#				|sed -r 's"^([+-][[:digit:]]*[.][[:digit:]]).*"\1"';
#			sleep 0.1;
#		done |tr -d '\n' |sed "s|.*|scale=1;(0&)/$count|"`
#};export -f FUNCtempAvg

function FUNCscript() {
	SECFUNCdbgFuncInA;
	# scripts will be executed with all environment properly setup with eval `secinit`
	local lscriptName="${1-}"
	shift&&:
	
	FUNCscriptHelp(){
		echo "Scripts List:"
		#grep "#helpScript" $0 |grep -v grep
		SECFUNCshowHelp --nosort "FUNCscript"
	}
	
	if [[ -z "$lscriptName" ]]; then
#		echo "Scripts List:"
#		#grep "#helpScript" $0 |grep -v grep
#		SECFUNCshowHelp "$FUNCNAME"
		FUNCscriptHelp
  elif [[ "$lscriptName" == "help" ]]; then #FUNCscript_help list these scripts
		FUNCscriptHelp
  elif [[ "$lscriptName" == "--help" ]]; then #FUNCscript_help list these scripts
		FUNCscriptHelp
  elif [[ "$lscriptName" == "returnX0" ]]; then #FUNCscript_help return to :0
  	#cmdEval="xdotool key super+l"
  	echoc -x "FUNCCHILDScreenLockNow"
  	
  	echoc -x "xdotool key control+alt+F7"
  	#cmdEval="sudo -k chvt 7"
  	
  	echoc -x "bash"
  	SECFUNCdbgFuncOutA;return
  elif [[ "$lscriptName" == "showHelp" ]]; then #FUNCscript_help show user custom command options and other options
    #FUNCxtermDetached --waitx1exit FUNCshowHelp $DISPLAY 30&
    secXtermDetached.sh FUNCshowHelp $DISPLAY #30
#  elif [[ "$lscriptName" == "keepNumlockOn" ]]; then #FUNCscript_help will check if numlock is off and turn it on
#  	function SECFUNCkeepNumlockOn(){
#			while true;do 
#				if numlockx status |grep off;then 
#					SECFUNCexecA -ce numlockx on;
#				fi;
#				sleep 1;
#			done
#		};export -f SECFUNCkeepNumlockOn
##		secXtermDetached.sh --daemon SECFUNCkeepNumlockOn
#		SECFUNCkeepNumlockOn
  elif [[ "$lscriptName" == "isScreenLocked" ]];then #FUNCscript_help [displayId] check if screen is locked
    if FUNCisScreenLockRunning ${1-};then
      exit 0
    else
      exit 1
    fi
  elif [[ "$lscriptName" == "nvidiaCicle" ]]; then #FUNCscript_help cicle through nvidia pre-setups
	  FUNCnvidiaCicle 1
  elif [[ "$lscriptName" == "nvidiaCicleBack" ]]; then #FUNCscript_help cicle through nvidia pre-setups
	  FUNCnvidiaCicle -1
#  elif [[ "$lscriptName" == "cicleGamma" ]]; then #FUNCscript_help cicle gamma value
##  	while true;do
##  		if ! ps -A -o pid,comm,command |grep -v "^[ ]*$$" |grep "^[ ]*[[:digit:]]* openNewX.sh.*cicleGamma$" |grep -v grep; then
##  			break
##  		fi
##  		echoc -w -t 1 "already running, waiting other exit"
##  	done
##	  FUNCcicleGamma 1
#	  secGammaChange.sh --say --up
#  elif [[ "$lscriptName" == "cicleGammaBack" ]]; then #FUNCscript_help cicle gamma value
##  	FUNCcicleGamma -1
#  	secGammaChange.sh --say --down
  elif [[ "$lscriptName" == "sayTemperature" ]]; then #FUNCscript_help say temperature
#		sedTemperature='s".*: *+\([0-9][0-9]\)\.[0-9]°C.*"\1"'
#		tmprToMonitor="temp1"
#		tmprCurrent=`sensors |grep "$tmprToMonitor" |sed "$sedTemperature"`
#		echoc --say "$tmprCurrent celcius"
#		echoc --say "`FUNCtempAvg` celcius"
		echoc --say "`highTmprMon.sh --tmpr` celcius"
  elif [[ "$lscriptName" == "autoStopContOnScreenLock" ]]; then #FUNCscript_help <lnGamePid> auto stop application running at X1 if the screen is locked there
  	#DOES NOT REQUIRES ANYMORE: requires `highTmprMon.sh --limitcpu $lnGamePid` to work.
  	local lnGamePid="$1"
  	shift
  	
		local ldelay=10
		local lbStopped=false
		SECONDS=0
		local lbOverrideContinueRunning=false
		while true;do
			SECFUNCvarReadDB
			#if openNewX.sh --script isScreenLocked;then
			local lbStopOnScreenLock=false
			if FUNCisScreenLockRunning;then
				lbStopOnScreenLock=true
			fi
			if $lbOverrideContinueRunning;then
				lbStopOnScreenLock=false
			fi
			
			if $lbStopOnScreenLock;then
				if ! $lbStopped;then
					echoc --say "stopping"
				fi
			  #highTmprMon.sh --secvarset bOverrideForceStopNow true
			  if kill -SIGSTOP $lnGamePid;then
			  	echo "stopped..."
			  fi
				lbStopped=true
			  ldelay=1
			else
			  #highTmprMon.sh --secvarset bOverrideForceStopNow false
			  if kill -SIGCONT $lnGamePid;then
			  	echo "running..."
			  fi
				lbStopped=false
			  ldelay=10
			fi
			
#			if ! ps -p $lnGamePid >/dev/null 2>&1;then
			if [[ ! -d "/proc/$lnGamePid" ]];then
				echoc -w -t 3 "pid $lnGamePid stopped running, exiting..."
				break
			fi
			
			echo -e "exit if game exits...(${SECONDS}s)\r"
			
#			sleep $ldelay
			if $lbOverrideContinueRunning;then
				if $lbStopped;then
					echo "sleep $ldelay"
					sleep $ldelay
				else
					if echoc -t $ldelay -q "disable override that makes it continue running?";then
						lbOverrideContinueRunning=false
					fi
				fi
			else
				if $lbStopped;then
					if echoc -t $ldelay -q "override and continue running?";then
						lbOverrideContinueRunning=true
					fi
				else
					echo "sleep $ldelay"
					sleep $ldelay
				fi
			fi
			
		done
	else
		echoc -p "invalid script '$lscriptName'"
		echoc -w
		SECFUNCdbgFuncOutA;return 1
  fi
  SECFUNCdbgFuncOutA;
};export -f FUNCscript

function FUNCkeepJwmAlive() {
	local pidJWM=$1
	local pidOpenNewX=$2 #ignored
	local pidXtermForNewX=$3
	
	while true; do
		if ! ps -p $pidX1; then
			break
		fi
		
		if ! ps -p $pidXtermForNewX; then
			break
		fi
		
		if ! ps --no-headers -p $pidJWM; then
			jwm -display :1&
			pidJWM=$!
		fi
		
		sleep 10
	done
};export -f FUNCkeepJwmAlive

#function FUNCwaitX1exit() {
##	while FUNCisX1running;do
#	while [[ -d "/proc/$pidX1" ]]; do
#		echo "wait X :1 exit"
#		sleep 1
#	done
#};export -f FUNCwaitX1exit

#function FUNCxtermDetached() {
#	local lcmdWaitX1exit=""
#	if [[ "$1" == "--waitx1exit" ]];then
#		lcmdWaitX1exit="FUNCwaitX1exit;"
#		shift
#	fi
#	
#	# this is a trick to prevent child terminal to close when its parent closes
#	local params="$@"
##	function FUNCxtermDetachedExec() {
##		$params
##	};export -f FUNCxtermDetachedExec
#	
#	xterm -e "echo \"TEMP xterm...\"; xterm -e \"$params;$lcmdWaitX1exit\";echoc -w"&
#	local pidXterm=$!
#	
#	# wait for the child (with the $params) to open
#	while ! ps --ppid $pidXterm; do
#		sleep 1
#	done
#	
#	kill -SIGINT $pidXterm
#};export -f FUNCxtermDetached

function FUNCcmdAtNewX() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	eval "$cmdOpenNewX";
	bash;
}; export -f FUNCcmdAtNewX

function FUNCfixPulseaudioThruTCP() {
#	if $bFixPulseaudioAtX1;then
		# play thru TCP using pulseaudio! see: http://billauer.co.il/blog/2014/01/pa-multiple-users/; http://askubuntu.com/a/589607/46437
		local lstrPathPulseUser="$HOME/.pulse/"
		mkdir -vp "$lstrPathPulseUser"
		
		local lstrFileDefaultPA="$lstrPathPulseUser/default.pa"
		local lstrDefaultPAcfg="load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1"
		if [[ ! -f "$lstrPathPulseUser/default.pa" ]];then
			SECFUNCexecA -c --echo cp -v /etc/pulse/default.pa "$lstrPathPulseUser"
			echo "$lstrDefaultPAcfg" >>"$lstrFileDefaultPA"
		else
			if ! grep "$lstrDefaultPAcfg" "$lstrFileDefaultPA";then
				if echoc -q "missing pulseaudio TCP configuration at: default.pa, recreate it on next run?";then
					SECFUNCexecA -c --echo mv -vf "$lstrFileDefaultPA" "${lstrFileDefaultPA}.`SECFUNCdtFmt --filename`.bkp"
					exit 1
				fi
			fi
		fi
		
		local lstrFileClientPA="$lstrPathPulseUser/client.conf"
		local lstrClientPAcfg="default-server = 127.0.0.1"
		if [[ ! -f "$lstrFileClientPA" ]];then
			echo "$lstrClientPAcfg" >"$lstrFileClientPA"
		else
			if ! grep "$lstrClientPAcfg" "$lstrFileClientPA";then
				if echoc -q "missing pulseaudio TCP configuration at: client.conf, recreate it on next run?";then
					SECFUNCexecA -c --echo mv -vf "$lstrFileClientPA" "${lstrFileClientPA}.`SECFUNCdtFmt --filename`.bkp"
					exit 1
				fi
			fi
		fi
#	fi	
}

function FUNCsoundEnablerDoNotCloseThisTerminal() {
	echoc --info "this makes sound work on X :1"
	
	SECFUNCexecA -c --echo pax11publish -D :1 -e
	
	echo "DO NOT CLOSE THIS TERMINAL, ck-launch-session";
	ck-launch-session;
	
	bash -c "echo \"wont reach here cuz of ck-launch-session...\""
};export -f FUNCsoundEnablerDoNotCloseThisTerminal

function FUNCechocInitBashInteractive() {
	eval `secinit` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	bash -i
};export -f FUNCechocInitBashInteractive

#function FUNCmaximiseWindow() {
#	local windowId=$1
#	wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz
#};export -f FUNCmaximiseWindow

function FUNCshowHelp() {
  local timeout=""
  if [[ -n "$2" ]];then
    timeout="--timeout=$2"
  fi
  
  local helpFile="/tmp/SEC.$selfName.$$.keysHelpText.txt"
  
  local strJwmrcKeys=`\
    cat ~/.jwmrc |\
    grep "Key mask" |\
    sed -r 's;[[:blank:]]*<Key (mask=".*") (key=".*")>(.*)</Key>;\1\t\2 \t\3 ;' |\
    tr '\n' '\0x00' |\
    sed -r 's"\x00"\\n"g'`;
    #grep -v "key=\"[[:digit:]]\"" |
    
  echo -e "Custom Commands:\n${strCustomCmdHelp}\n\nCommands:\n${strJwmrcKeys}\n" >"$helpFile";
  
  #zenity --display=$1 $timeout --info --title "OpenNewX: your Custom Commands!" --text="$strCustomCmdHelp"&
#  zenity --display=$1 $timeout --title "OpenNewX: your Custom Commands!" --text-info --filename="$helpFile"&
	strTitleRegex="OpenNewX: your Custom Commands! ppid$$"
	SECFUNCCwindowCmd --ontop --maximize "$strTitleRegex"
#	SECFUNCCwindowCmd --maximize "$strTitleRegex"
  SECFUNCexec --echo -c zenity --display=$1 $timeout --title "$strTitleRegex" --text-info --filename="$helpFile"
	# will wait zenity exit
  SECFUNCCwindowCmd --stop "$strTitleRegex"
#  local pidZenity=$!
#  
#  local windowId=""
#  for windowId in `xdotool search --sync --pid $pidZenity`;do
#    FUNCmaximiseWindow $windowId
#  done
  
#  while ps -p $pidZenity 2>&1 >/dev/null;do
#    echo "wait zenity exit..."
#    if ! sleep 1;then break;fi
#  done
  
  rm -v "$helpFile"
};export -f FUNCshowHelp

######################## OPTIONS/PARAMETERS #####################################

useJWM=true
useKbd=true
customCmd=()
bRecreateRCfile=false
bRecreateRCfileThin=false
bXTerm=false
bReturnToX0=false
bWaitCompiz=true
SECFUNCvarSet --default bUseXscreensaver=true #varset exports it what is required if going to be used on child shell
bScreenSaverOnlyLockByHand=false
bInitNvidia=false
strGeometry=""
bFixPulseaudioAtX1=false
export strCustomCmdHelp=""
strJWMGroupMatchWindowExecutableName="dummy-none" # if empty, will match all
while ! ${1+false} && [[ ${1:0:2} == "--" ]]; do
  if [[ "$1" == "--no-wm" ]]; then #help SKIP WINDOW MANAGER (run pure X alone)
    useJWM=false
  elif [[ "$1" == "--no-kbd" ]]; then #help SKIP Keyboard setup
    useKbd=false
  elif [[ "$1" == "--recreaterc" ]]; then #help recreate $HOME/.jwmrc file
  	bRecreateRCfile=true
  elif [[ "$1" == "--jwmfixwindow" ]]; then #help <strJWMGroupMatchWindowExecutableName> a window that matches this executable name will be fixed/adjusted/improved like noborder etc...
  	shift
  	strJWMGroupMatchWindowExecutableName="${1-$strJWMGroupMatchWindowExecutableName}"
  elif [[ "$1" == "--xterm" ]]; then #help use xterm instead of gnome-terminal
  	bXTerm=true
  elif [[ "$1" == "--ignorecompiz" ]]; then #help ignore compiz finish starting
  	bWaitCompiz=false
  elif [[ "$1" == "--noautolock" ]]; then #help prevent screensaver from auto-locking the screen (may be required with some games where user activity is not detected)
  	bScreenSaverOnlyLockByHand=true
  elif [[ "$1" == "--initgfxcfg" ]]; then #help initializes user configured graphics options (currently supported nvidia)
  	bInitNvidia=true
  elif [[ "$1" == "--xscreensaver" ]]; then #help deprecated
  	#SECFUNCvarSet bUseXscreensaver=true
  	SEC_WARN=true SECFUNCechoWarnA "'$1' is useless as xscreensaver is the default now."
  	#_SECFUNCcriticalForceExit
  elif [[ "$1" == "--recreatercthin" ]]; then #help recreate $HOME/.jwmrc file, but does not use /etc/jwm one!
  	bRecreateRCfile=true
  	bRecreateRCfileThin=true
  elif [[ "$1" == "--geometry" ]];then #help size of the new screen
  	shift
    strGeometry="$1"
  elif [[ "$1" == "--returnX0" ]]; then #help lock display at :1 and return to :0
  	bReturnToX0=true
  elif [[ "$1" == "--bFixPulseaudioAtX1" ]]; then #help <bFixPulseaudioAtX1> plays sound thru TCP
  	bFixPulseaudioAtX1=true
  elif [[ "$1" == "--customcmd" ]]; then #help custom commands, up to 10 (repeat the option) ex.: --customcmd "zenity --info" --customcmd "xterm" --customcmd "someScript.sh"
  	shift
  	#customCmd=("${customCmd[@]-}" "$1")
  	customCmd+=("$1")
  	strCustomCmd=`echo " Meta+${#customCmd[*]} EXEC: $1"`
  	echo "$strCustomCmd"
  	strCustomCmdHelp="$strCustomCmdHelp$strCustomCmd\n"
  elif [[ "$1" == "--isRunning" ]]; then #help check if new X :1 is already running
    if FUNCisX1running; then
      exit 0
    else
      exit 1
    fi
  elif [[ "$1" == "--script" ]]; then #help run a internal script (without script name will show the list)
  	shift&&:
  	scriptName="${1-}"
  	shift&&:
  	FUNCscript $scriptName "$@"
		exit 0
  elif [[ "$1" == "--killX1" ]]; then #help kill X :1
  	# kill X
    #pidX1=`ps -A -o pid,command |grep -v grep |grep -x "^[ ]*[0-9]* $grepX1" |sed -r "$sedOnlyPid"`
    
#    pidX1=`FUNCisX1running`
#    echo "pidX1=$pidX1"
#    #read -n 1
#    if [[ -n "$pidX1" ]];then
#      ps -p $pidX1
#      echoc -x "sudo -k kill -SIGKILL $pidX1"
#      #read -n 1
#    fi
    if varset --show pidX1="`FUNCisX1running`";then
	    #echo "pidX1=$pidX1"
	    if [[ -n "$pidX1" ]];then
		    echoc -x "ps -p $pidX1"
		    if [[ "$pidX1" == "`pgrep -t tty8,tty9 -x Xorg`" ]];then
			    echoc -x "sudo -k pkill -t tty8,tty9 -x Xorg"
			  else
			    echoc -x "sudo -k kill -SIGKILL $pidX1"
		    fi
		  fi
    fi
    
  	# kill xscreensaver if it was used at :1
#    pidXscrsv=`ps -A -o pid,command |grep "xscreensaver -display :1" |grep -v grep |sed -r "$sedOnlyPid"`
#    echo "pidXscrsv=$pidXscrsv"
#    if [[ -n "$pidXscrsv" ]];then
#      ps -p $pidXscrsv
#      kill -SIGKILL $pidXscrsv
#    fi
    if pidXscrsv=`ps -A -o pid,command |grep "xscreensaver -display :1" |grep -v grep |sed -r "$sedOnlyPid"`;then
    	if [[ -n "$pidXscrsv" ]];then
			  echo "pidXscrsv=$pidXscrsv"
		    ps -p $pidXscrsv&&:
		    kill -SIGKILL $pidXscrsv
		  fi
    fi
    
    exit 0
  elif [[ "$1" == "--help" ]]; then #help show help info
		echo "Lets you open a new X session. It is light weight: no effects but still optionally window managed with JWM. Very usefull to run 3D intensive applications and games with stability and in a non obstrusive way."
    echo "Can be used at startup applications as: $0 --returnX0"
    echo "Usage: options runCommand"
    
    # this sed only cleans lines that have extended options with "--" prefixed
    #sedCleanHelpLine='s"\(.*\"\)\(--.*\)\".*#opt" \2\t"' #helpskip
    #echo "SCRIPTS:";    grep "#helpScript" $0 |grep -v "#helpskip" |sed "$sedCleanHelpLine"
		#sedCleanHelpLine='s;(.*")(--.*)".*#opt; \2\t;' #helpskip
    #grep "#opt" $0 |grep -v "#helpskip" |sed -r "$sedCleanHelpLine"
    SECFUNCshowHelp
    
    exit 0
  else
    echoc -p "invalid option $1"
    $0 --help
    exit 1
  fi
 	shift
done

#echo "going to execute: $@"
#@@@R runCmd="$1" #this command must be simple, if need complex put on a script file and call it!
export runCmd="$@" #this command must be simple, if need complex put on a script file or exported function and call it!

#################### MAIN CODE ###########################################

if $bFixPulseaudioAtX1;then
	FUNCfixPulseaudioThruTCP;
fi

if ! groups |tr ' ' '\n' |egrep "^audio$";then
	echoc -p "$USER is not on 'audio' group, sound will not work at new X"
	echoc --info "Fix with: \`usermod -a -G audio $USER\`"
	exit 1
fi

if $useJWM;then
	if ! which jwm;then
		echoc -p "requires jwm to run"
		exit 1
	fi
fi

# validate options
if((${#customCmd[@]}>0));then
	if ! $bRecreateRCfile; then
		echoc -p -- "--customcmd requires --recreaterc"
		exit 1
	fi
fi

#if ! echoc -q -t 2 "use JWM window manager@Dy"; then
#  useJWM=false
#fi

function FUNCcurrentWM(){
	wmctrl -m |grep Name |cut -d' ' -f2-
};export -f FUNCcurrentWM

#bCompizOff=false
#if pgrep -x "^compiz$";then
#	if ! pgrep -x "^metacity$";then
if [[ "`FUNCcurrentWM`" == "Compiz" ]];then
		echoc --alert "3D application? stop compiz!"
		echoc --info "if you are going to run a 3D application, it is strongly advised to not leave another one on the current X session (like the very compiz unity), it may crash when coming back..."
#		if echoc -q "run 'metacity'?";then
#			secXtermDetached.sh metacity --replace
#			bCompizOff=true
#		fi
		bWaitChangeWM=false
		type xfwm4
		type metacity
		ScriptEchoColor -Q "replace window manager?@O_metacity/_xfwm4@Dm"&&:; case "`secascii $?`" in 
			m)secXtermDetached.sh metacity --replace;bWaitChangeWM=true;; 
			x)secXtermDetached.sh xfwm4 --replace;bWaitChangeWM=true;; 
		esac
		
		if $bWaitChangeWM;then
			while [[ "`FUNCcurrentWM`" == "Compiz" ]];do
				echoc -w -t 1
			done
		fi
fi
#	fi
##else
##	bCompizOff=true
#fi

strCurrentWindowManager="`FUNCcurrentWM`"
echo "strCurrentWindowManager='$strCurrentWindowManager'"
bCompizOff=false
if [[ "$strCurrentWindowManager" != "Compiz" ]];then
	bCompizOff=true
fi

# at this point, X1 will be managed by openNewX
while FUNCisX1running;do
	if echoc -q -t 3 "Open New X. You must stop the other session at :1 before continuing. Kill X1 now?"; then
		echoc -x "$0 --killX1"
	fi
done
ls -l $SECvarFile
SECFUNCuniqueLock --waitbecomedaemon
SECFUNCvarSet --default pidOpenNewX=$$
ls -l $SECvarFile

#redirects self output to log file!
exec >> >(tee $SEC_TmpFolder/SEC.$selfName.$$.log)
exec 2>&1

#while true; do
#	if FUNCisX1running;then
#		if echoc -q -t 3 "Open New X. You must stop the other session at :1 before continuing. Kill X1 now?"; then
#			echoc -x "$0 --killX1"
#		fi
#	else
#		while ! SECFUNCuniqueLock;do
#			echoc -p "Unable to create unique lock..."
#			echoc -w -t 3
#		done
#	
#		SECFUNCvarSetDB -f
#		#sleep 3 #Xorg seems to leave some trash on memory? how to detect it properly?
#		
#		break
#	fi
#done

if $useJWM; then
  if $bRecreateRCfile || [[ ! -f "$HOME/.jwmrc" ]]; then
  	if [[ ! -f /etc/jwm/jwmrc ]]; then
  		bRecreateRCfileThin=true
  	fi
  	
  	if $bRecreateRCfileThin; then 
	  	
	  	if [[ -f "/etc/jwm/system.jwmrc" ]];then
		  	# reuse defaults if possible
		  	endTagAtLine=`grep "</JWM>" -n /etc/jwm/system.jwmrc |sed -r 's"([[:digit:]]*):.*"\1"'`
		  	
		  	# copy the beggining of cfg file
		    # disable desktop navigation Alt+Left ... as is conflicts with browsers and some IDEs.
		  	head -n $((endTagAtLine-1)) /etc/jwm/system.jwmrc \
		  		|egrep -v '<Key mask="A" key="(Right|Left|Up|Down)">' >"$HOME/.jwmrc"
			else
				#create a new thin one
				echo -e '
					<?xml version="1.0"?>
				    <JWM>
							<Key mask="A" key="Tab">nextstacked</Key>
							<Key mask="A" key="Tab">next</Key>' \
		    	>"$HOME/.jwmrc"
	  	fi
  		
  	else 
  		#use default as base
  		mv -vf "$HOME/.jwmrc" "$HOME/.jwmrc.bkp"
	  	cp -vf /etc/jwm/jwmrc "$HOME"
  		mv -vf "$HOME/jwmrc" "$HOME/.jwmrc"
  		
  		# open closing tag to add stuff
			sedUncloseTag='s"</JWM>""'
			sed -i "$sedUncloseTag" "$HOME/.jwmrc"
	 	fi
  	
  	#@@@R <Key mask="S4" key="G">exec:'"xterm -e \"$cmdNvidiaNormal\""'</Key>
    #@@@R <Key mask="4" key="G">exec:'"xterm -e \"FUNCnvidiaCicle\""'</Key>
    #@@@R      <Key mask="4" key="L">exec:bash -c "FUNCCHILDScreenLockNow"</Key>
#          <Key mask="4" key="M">exec:'"xterm -e \"$0 --script cicleGamma\" #kill=skip"'</Key>
#          <Key mask="S4" key="M">exec:'"xterm -e \"$0 --script cicleGammaBack\" #kill=skip"'</Key>
    
    # DOCUMENTATION FROM JWM:
		#	A - Alt (mod1)
		#	C - Control
		#	S - Shift
		#	1 - mod1
		#	2 - mod2
		#	3 - mod3
		#	4 - mod4 (meta/super)
		#	5 - mod5
    echo -e '
	        <Key key="XF86AudioRaiseVolume">exec:amixer set Master 5%+</Key>
	        <Key key="XF86AudioLowerVolume">exec:amixer set Master 5%-</Key>
	        <Key key="XF86AudioMute">exec:amixer set Master toggle</Key>
          <Key mask="4" key="F1">exec:xdotool set_desktop 0</Key>
          <Key mask="4" key="F2">exec:xdotool set_desktop 1</Key>
          <Key mask="4" key="F3">exec:xdotool set_desktop 2</Key>
          <Key mask="4" key="F4">exec:xdotool set_desktop 3</Key>
          <Key mask="4" key="C">exec:xterm -e "FUNCclearCache #kill=skip"</Key>
          <Key mask="4" key="G">exec:'"xterm -e \"$0 --script nvidiaCicle\" #kill=skip"'</Key>
          <Key mask="S4" key="G">exec:'"xterm -e \"$0 --script nvidiaCicleBack\" #kill=skip"'</Key>
          <Key mask="4" key="H">exec:'"xterm -e \"$0 --script showHelp\" #kill=skip"'</Key>
          <Key mask="4" key="K">exec:xkill</Key>
          <Key mask="4" key="L">exec:'"xterm -e \"bash -c FUNCCHILDScreenLockNow\" #kill=skip"'</Key>
          <Key mask="4"  key="M">exec:'"xterm -e \"secGammaChange.sh --say --up\" #kill=skip"'</Key>
          <Key mask="S4" key="M">exec:'"xterm -e \"secGammaChange.sh --say --down\" #kill=skip"'</Key>
          <Key mask="C4" key="M">exec:'"xterm -e \"secGammaChange.sh --say --reset\" #kill=skip"'</Key>
          <Key mask="4" key="P">exec:'"xterm -e \"$0 --script sayTemperature\" #kill=skip"'</Key>
          <Key mask="4" key="T">exec:xterm -e "FUNCsayTime #kill=skip"</Key>
          <Key mask="4" key="X">exec:xterm -e "FUNCechocInitBashInteractive #kill=skip"</Key>
          <Key mask="4" key="Z">exec:xterm -display :0 -e "FUNCechocInitBashInteractive #kill=skip"</Key>
          <Key mask="4" key="1">exec:'"xterm -e \"${customCmd[0]-}\" #kill=skip"'</Key>
          <Key mask="4" key="2">exec:'"xterm -e \"${customCmd[1]-}\" #kill=skip"'</Key>
          <Key mask="4" key="3">exec:'"xterm -e \"${customCmd[2]-}\" #kill=skip"'</Key>
          <Key mask="4" key="4">exec:'"xterm -e \"${customCmd[3]-}\" #kill=skip"'</Key>
          <Key mask="4" key="5">exec:'"xterm -e \"${customCmd[4]-}\" #kill=skip"'</Key>
          <Key mask="4" key="6">exec:'"xterm -e \"${customCmd[5]-}\" #kill=skip"'</Key>
          <Key mask="4" key="7">exec:'"xterm -e \"${customCmd[6]-}\" #kill=skip"'</Key>
          <Key mask="4" key="8">exec:'"xterm -e \"${customCmd[7]-}\" #kill=skip"'</Key>
          <Key mask="4" key="9">exec:'"xterm -e \"${customCmd[8]-}\" #kill=skip"'</Key>
          <Key mask="4" key="0">exec:'"xterm -e \"${customCmd[9]-}\" #kill=skip"'</Key>
          
					<Group>
						<Name>'"$strJWMGroupMatchWindowExecutableName"'</Name>
						<Option>maximized</Option>
						<Option>noborder</Option>
						<Option>notitle</Option>
						<Option>layer:8</Option>
					</Group>          
          
        </JWM>' \
      >>"$HOME/.jwmrc"

	#TODO volume up and down? find keycodes with xev
	#          <Key key="XF86AudioRaiseVolume">exec:'"xterm -e \"\" #kill=skip"'</Key>
	#          <Key key="XF86AudioLowerVolume">exec:'"xterm -e \"\" #kill=skip"'</Key>

    SECFUNCexecA -c --echo jwm -p&&:
    strJwmMessages="`jwm -p 2>&1`"&&:
    # ignore non problematic messages
    strJwmMessages="`echo "$strJwmMessages" |egrep -v "JWM: warning: .* could not open include: /etc/jwm/debian-menu$"`"&&:
    #if ! jwm -p; then
    if echo "$strJwmMessages" |grep "^JWM:"; then
      #rm $HOME/.jwmrc
      echo -n "WARN: .jwmrc is invalid, continue anyway? (y/...)";read -t 3 -n 1 resp&&:
      if [[ ! -z "$resp" ]]; then #default is to continue
      	echo
		    if [[ "$resp" != "y" ]]; then
		    	exit 1
		    fi
		  else
		  	echo yes
		  fi
    else
      echo "see http://joewing.net/programs/jwm/config.shtml#keys"
      echo "with Super+L you can lock the screen now"
    fi
  else
  	echoc "@{LYnb} WARNING: .jwmrc was not recreated! "
  fi
fi

kbdSetup="echo \\\"SKIP: kbd setup\\\""
if $useKbd; then
  kbdSetup="setxkbmap -layout us"
fi

if [[ -z "$runCmd" ]];then
	runCmd="echo JustOpenNewX"
fi
export cmdOpenNewX="bash -c \"$kbdSetup; bash -c \\\"$runCmd;bash -i\\\"; bash -i;\""
echo "cmdOpenNewX=$cmdOpenNewX"

# wait for compiz to start to not mess its behavior
if ! $bCompizOff;then
	if [[ -n "$DISPLAY" ]] && $bWaitCompiz; then
		while ! echoc -x "qdbus org.freedesktop.compiz 1>/dev/null"; do #do not ignore the error output!
			if echoc -q -t 1 "check if CCSM D-BUS was enabled. Quit"; then 
				exit 1; 
			fi
		done
	fi
fi

# run in a thread, prevents I from ctrl+c here what breaks THIS X instace and locks keyb
pidXtermForNewX=-1
if ! FUNCisX1running; then
	function FUNCexecCmdX1(){
		echo "INFO: hit CTRL+C to exit the other X session and close this window";
		echo "INFO: running in a thread (child proccess) to prevent ctrl+c from freezing this X session and the machine!";
		echo "INFO: hit ctrl+alt+f7 to get back to this X session (f7, f8 etc, may vary..)";
		echo ;
		echo "Going to execute on another X session: $runCmd";
		echoc -x "sudo -k $execX1"
	};export -f FUNCexecCmdX1
#  cmdX1="\
#  echo \"INFO: hit CTRL+C to exit the other X session and close this window\";\
#  echo \"INFO: running in a thread (child proccess) to prevent ctrl+c from freezing this X session and the machine!\";\
#  echo \"INFO: hit ctrl+alt+f7 to get back to this X session (f7, f8 etc, may vary..)\";\
#  echo ;\
#  echo \"Going to execute on another X session: $runCmd\";\
#  echoc -x 'sudo -k $execX1'"

  if [[ -z "$DISPLAY" ]]; then
    # if at tty1 console there is no X already running
    #eval $cmdX1&
    bash -c "FUNCexecCmdX1"&
    pidXtermForNewX=$!
  else
    #xterm -e "$cmdX1"&
    secXtermDetached.sh --logonly "FUNCexecCmdX1"
    pidXtermForNewX=$!
  fi
fi
#echoc -x "sudo -k chvt 8" # this line to force go to X :1 terminal

# wait for X to start
while ! FUNCisX1running; do
  sleep 1
done
varset --show pidX1=`FUNCisX1running`

################################################################################
################################################################################
########################### X1 only running after here #########################
################################################################################
################################################################################

# say in what tty it is running
echoc --say "X at `ps -A -o tty,comm |grep Xorg |grep -v tty7 |grep -o "tty." |sed 's"."& "g'`"

if [[ -n "$strGeometry" ]];then
#	zenity --timeout=5 --display=:1 --info --title "$SECstrScriptSelfName" \
#		--text "This is a dummy window to let Xorg initialize\nproperly before changing resolution..."
	
	nBlindDelay=5
	
	strMsg="New resolution: $strGeometry.\n"
	strMsg+="This is a dummy window to help Xorg initialize\n"
	strMsg+=" properly while changing resolution.\n"
	#strMsg+="Click here to continue...\n"
	#strMsg+="(this window must receive focus for this workaround to work...)\n"
	zenity --timeout=60 --display=:1 --info --title "$SECstrScriptSelfName" --text "$strMsg"&
	
	zenity --timeout=$nBlindDelay --display=:1 --info --title "$SECstrScriptSelfName" \
		--text "Holding ${nBlindDelay}s\n$strMsg"&&: # to try to let Xorg stabilize b4 xrandr
	
#	echoc -w -t $nBlindDelay	"sleep ${nBlindDelay}s safety" #TODO this is a blind sleep to help on avoiding issues... find a way to let Xorg initialize properly with specified geometry...
	
	# if the resolution is not set properly, the desktop will be bigger and scrolling and xgamma will not work either.
#	echoc -w -t 5 "sleep safety" #TODO this is a blind sleep to help on avoiding issues... find a way to let Xorg initialize properly with specified geometry

	SECFUNCexecA -ce xrandr -display :1 -s "$strGeometry"
#	echoc -w -t $nBlindDelay "sleep ${nBlindDelay}s safety" #TODO this is a blind sleep to help on avoiding issues... find a way to let Xorg initialize properly with specified geometry...
	
	#zenity --display=:1 --info --title "$SECstrScriptSelfName" --text "One more time...\n$strMsg"&
	
#	echoc -w -t 5
	
#	echoc -w -t 5 "sleep safety" #TODO this is a blind sleep to help on avoiding issues... find a way to let Xorg initialize properly with specified geometry
	
#	zenity --timeout=5 --display=:1 --info --title "$SECstrScriptSelfName" \
#		--text "This is a dummy window to let Xorg initialize\nproperly after changing resolution..."
	
	# if the resolution is not set properly, the desktop will be bigger and scrolling and xgamma will not work either.
#	echoc -w -t 3 "sleep safety" #TODO this is a blind sleep to help on avoiding issues... find a way to let Xorg initialize properly with specified geometry
	
#	while ! DISPLAY=:1 xrandr |egrep "[*]" |grep "$strGeometry";do
#		echoc -w -t 3 "waiting X :1 resolution be set..."
#	done
fi

#FUNCxtermDetached --waitX1exit FUNCshowHelp :0&
#FUNCxtermDetached --waitX1exit FUNCshowHelp :1&
secXtermDetached.sh --display :1 FUNCshowHelp :1 #30
#pidZenity0=$!

#secXtermDetached.sh --display :1 bash -ic "FUNCrestartPulseAudioDaemonChild"
secXtermDetached.sh --display :1 FUNCrestartPulseAudioDaemonChild

# run in a thread, prevents I from ctrl+c here what breaks THIS X instace and locks keyb
if $useJWM; then
  jwm -display :1&
  pidJWM=$!
  
  #xterm -e "FUNCkeepJwmAlive $pidJWM $$ #kill=skip"&
  #FUNCxtermDetached "FUNCkeepJwmAlive $pidJWM $$ $pidXtermForNewX #kill=skip"
  secXtermDetached.sh --killskip --display :1 --xtermopts "-bg orange -geometry $strOptXtermGeom" FUNCkeepJwmAlive $pidJWM $$ $pidXtermForNewX
fi

#initializes the cicle of configurations!
if $bInitNvidia;then
	#xterm -display :1 -e "$0 --script nvidiaCicle; #kill=skip" #not threaded/child so the speech does not interfere with some games sound initialization check
	secXtermDetached.sh --killskip --display :1 $0 --script nvidiaCicle #not threaded/child so the speech does not interfere with some games sound initialization check
fi

sleep 2 #TODO improve with qdbus waiting for jwm? 
#SECFUNCvarShow bUseXscreensaver #@@@r
#xterm -geometry $strOptXtermGeom -display :1 -e "bash -ic \"FUNCCHILDScreenSaver; #kill=skip\""&
#xterm -geometry $strOptXtermGeom -display :1 -e "FUNCCHILDScreenSaver; #kill=skip"&
xscreensaver -display :1&
if $bScreenSaverOnlyLockByHand;then
	#xterm -bg darkgreen -geometry $strOptXtermGeom -display :1 -e "FUNCCHILDPreventAutoLock; #kill=skip"&
	secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkgreen -geometry $strOptXtermGeom" "FUNCCHILDPreventAutoLock"
else
	# interactive window, do not shrink..
	#xterm -bg darkgreen -display :1 -e "export SECbRunLog=true;secAutoScreenLock.sh --monitoron --xscreensaver --forcelightweight; #kill=skip"&
	(export SECbRunLog=true;secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkgreen" secAutoScreenLock.sh --monitoron --xscreensaver --forcelightweight)
fi
#xterm -geometry $strOptXtermGeom -display :1 -e "FUNCCHILDScreenLockLightWeight; #kill=skip"&

# this enables sound (and may be other things...) (see: http://askubuntu.com/questions/3981/start-a-second-x-session-with-different-resolution-and-sound) (see: https://bbs.archlinux.org/viewtopic.php?pid=637913)
#DISPLAY=:1 ck-launch-session #this makes this script stop executing...
#xterm -e "DISPLAY=:1 ck-launch-session"& #this creates a terminal at :0 that if closed will make sound at :1 stop working
#xterm -bg darkred -geometry $strOptXtermGeom -display :1 -e "FUNCsoundEnablerDoNotCloseThisTerminal; #kill=skip"&
#if $bFixPulseaudioAtX1;then
	secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkred -geometry $strOptXtermGeom" "FUNCsoundEnablerDoNotCloseThisTerminal"
#fi

#xterm -bg darkblue -geometry $strOptXtermGeom -display :1 -e "FUNCkeepGamma; #kill=skip"&
#secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkblue -geometry $strOptXtermGeom" "FUNCkeepGamma"
secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkblue -geometry $strOptXtermGeom" secGammaChange.sh --reset #this one will exit
secXtermDetached.sh --killskip --display :1 --xtermopts "-bg darkblue -geometry $strOptXtermGeom" secGammaChange.sh --keep

# setxkbmap is good for games that have console access!; bash is to keep console open!

# nothing
#xterm -display :1&

# dead keys
#xterm -display :1 -e "setxkbmap -layout us -variant intl; bash"&

# good for games!
#bXTerm=true #TODO gnome-terminal is not working with this yet...

#while true; do
	pidTerm=-1
	if $bXTerm; then
#		xterm -display :1 -e "$cmdOpenNewX" -e "bash"&
#		xterm -display :1 -e "bash -i -c FUNCcmdAtNewX #kill=skip"&
		secXtermDetached.sh --killskip --display :1 bash -i -c FUNCcmdAtNewX
		pidTerm=$!
	else
		gnome-terminal --display=:1 -e "bash -i -c FUNCcmdAtNewX #kill=skip"&
		pidTerm=$!
	fi
	#xterm -display :1 -e "$kbdSetup; bash -c \"$@\"; bash"&
	
#	# sometimes the terminal dies (WHY!!??!?!), so re-run it :(
#	maxCount=10
#	for((i=0;i<maxCount;i++)); do
#		#if ! ps -p $pidTerm 2>&1 >/dev/null; then
#		echo
#		if ! ps -p $pidTerm; then
#			echo "terminal died... :("
#			break
#		fi
#		sleep 1
#	done
#	if((i==maxCount));then
#		break
#	fi
#done

if $bReturnToX0; then
	#xterm -display :1 -e "bash -ic \"$0 --script returnX0\""&
	secXtermDetached.sh --display :1 bash -ic "$0 --script returnX0"
fi

##initializes the cicle of configurations!
#xterm -display :1 -e "$0 --script nvidiaCicle"&

# MUST BE THE LAST THING
# this enables sound (and may be other things...) (see: http://askubuntu.com/questions/3981/start-a-second-x-session-with-different-resolution-and-sound) (see: https://bbs.archlinux.org/viewtopic.php?pid=637913)
#DISPLAY=:1 ck-launch-session #this makes this script stop executing...
#xterm -e "DISPLAY=:1 ck-launch-session"& #this creates a terminal at :0 that if closed will make sound at :1 stop working
#xterm -geometry $strOptXtermGeom -display :1 -e "FUNCsoundEnablerDoNotCloseThisTerminal #kill=skip"&

#while FUNCisX1running; do
while ps -p $pidX1 >/dev/null 2>&1; do
	echoc --alert "ctrl+c will prevent commands, like gamma change, from working properly!"
	if echoc -q -t 60 "kill X1"; then #prevent closing what shutdown jwm and xscreensaver
		$0 --killX1
	fi
done

if $bCompizOff;then
	if ! ps -A |grep -q -x compiz;then
		if echoc -q "restore compiz?";then
#			(cd "$HOME";secXtermDetached.sh compiz --replace) #$HOME to move away from any unmountable media
			(cd "$HOME";secXtermDetached.sh secFixWindow.sh --fixcompiz) #$HOME to move away from any unmountable media
		fi
	fi
fi

echoc --say "X1 closed"
#echoc -w "exit...."
#echoc -x "kill $pidZenity0"
#echoc -w -t 5

