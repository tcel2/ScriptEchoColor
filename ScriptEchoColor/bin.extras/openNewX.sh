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

#@@@R would need to be at xterm& #trap 'ps -A |grep Xorg; ps -p $pidX1; sudo -k kill $pidX1;' INT #workaround to be able to stop the other X session

########################## INIT AND VARS #####################################
eval `secLibsInit.sh`

SECFUNCdaemonUniqueLock #SECisDaemonRunning
#SECFUNCvarShow bUseXscreensaver

#alias ps='echoc -x ps' #good to debug the bug

SECFUNCvarGet SEC_SAYVOL
if [[ -z "$SEC_SAYVOL" ]];then
	export SEC_SAYVOL=15 #from 0 to 100 #this should be controlled by external scripts...
fi

execX1="X :1"
grepX1="X :1"
selfName=`basename "$0"`
SECFUNCvarSet --default pidOpenNewX=$$
#execX1="startx -- :1"
#grepX1="/usr/bin/X :1 [-]auth /tmp/serverauth[.].*"

#redirects self output to log file!
exec > >(tee $SEC_TmpFolder/SEC.$selfName.$$.log)
exec 2>&1

# when you see "#kill=skip" at the end of commands, will prevent terminals from being killed on killall commands (usually created at other scripts)

#sedOnlyPid='s"^[ ]*\([0-9]*\) .*"\1"'
sedOnlyPid='s"[ ]*([[:digit:]]*) .*"\1"'

######################### FUNCTIONS #####################################

function FUNCxlock() {
	DISPLAY=:1 xlock -mode matrix -delay 30000 -timeelapsed -verbose -nice 19 -timeout 5 -lockdelay 0 -bg darkblue -fg yellow
}; export -f FUNCxlock

function FUNCchildScreenLockNow() {
	eval `secLibsInit.sh` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	if $bUseXscreensaver; then
		DISPLAY=:1 xscreensaver-command -lock
	else
		DISPLAY=:1 xautolock -locknow
	fi
}; export -f FUNCchildScreenLockNow

function FUNCchildScreenAutoLock() {
	eval `secLibsInit.sh` # necessary when running a child terminal, sometimes may work without this, but other times wont work properly without this!
	#SECFUNCvarShow bUseXscreensaver #@@@r
	if $bUseXscreensaver; then
		xscreensaver -display :1
	else
		DISPLAY=:1 xautolock -locker "bash -c FUNCxlock"
	fi
}; export -f FUNCchildScreenAutoLock

function FUNCisScreenLockRunning() {
	if $bUseXscreensaver; then
    #if ps -A -o comm |grep -w "^xscreensaver$" >/dev/null 2>&1;then
    if DISPLAY=:1 xscreensaver-command -time |grep "screen locked since" >/dev/null 2>&1;then
      return 0
    fi
	else
    if ps -A -o comm |grep -w "^xlock$" >/dev/null 2>&1;then
      return 0
    fi
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
#		rm -vf "$lockFile" >/dev/stderr
#		rm -vf "$lockFileReal" >/dev/stderr
#		return;
#	fi
#	
#	while ! ln -s "$lockFileReal" "$lockFile" >/dev/stderr; do #create the symlink
#		local realFile=`readlink "$lockFile"`
#		pidOfRealFile=`echo "$realFile" |sed -r "s'.*[.]([[:digit:]]*)$'\1'"`
#		if ! ps -p $pidOfRealFile >/dev/stderr;then
#			rm -vf "$realFile" >/dev/stderr
#		fi
#		if ! sleep 0.1; then return 1; fi #exit_FUNCsayStack: on sleep fail
#	done
#	echo "`SECFUNCdtTimePrettyNow`.$$" >>"$lockFileReal"
#}

function FUNCcicleGamma() {
	local nDirection=$1 #1 or -1
	
	SECFUNCvarSet --default fGamma 1.0
	SECFUNCvarGet pidOpenNewX
	
#	local lockFileGamma="/tmp/openNewX.gamma.lock"
#	local lockFileGammaReal="${lockFileGamma}.$pidOpenNewX"
#	while ! ln -s "$lockFileGammaReal" "$lockFileGamma"; do #create the symlink
#		local realFile=`readlink "$lockFileGamma"`
#		pidForRealFile=`echo "$realFile" |sed -r "s'.*[.]([[:digit:]]*)$'\1'"`
#		if ! ps -p $pidForRealFile;then
#			rm -vf "$realFile"
#		fi
#		if ! sleep 0.1; then return 1; fi #exit_FUNCsayStack: on sleep fail
#	done
#	echo "`SECFUNCdtTimePrettyNow`.$$" >>"$lockFileGammaReal"
	local lockGammaId="openNewX.gamma"
#	FUNClockFile "$lockGammaId" $pidOpenNewX
#	SECFUNCuniqueLock --pid $pidOpenNewX "$lockGammaId"
	SECFUNCuniqueLock --pid $$ "$lockGammaId"

#	SECFUNCvarSet --default gammaLock 0
#	SECFUNCvarWaitValue gammaLock 0
#	SECFUNCvarSet gammaLock $$
	
	local nIncrement="0.25"
	local nMin="0.25"
	local nMax="10.0"
	
	SECFUNCvarSet fGamma=`bc <<< "$fGamma+($nDirection*$nIncrement)"`
	if ((`bc <<< "$fGamma<$nMin"`)); then
		SECFUNCvarSet fGamma=$nMax
	fi
	if ((`bc <<< "$fGamma>$nMax"`)); then
		SECFUNCvarSet fGamma=$nMin
	fi
	
#	if [[ "$fGamma" == "0.5" ]];then
#		SECFUNCvarSet fGamma=0.75
#	elif [[ "$fGamma" == "0.75" ]];then
#		SECFUNCvarSet fGamma=1.0
#	elif [[ "$fGamma" == "1.0" ]];then
#		SECFUNCvarSet fGamma=1.25
#	elif [[ "$fGamma" == "1.25" ]];then
#		SECFUNCvarSet fGamma=1.5
#	elif [[ "$fGamma" == "1.5" ]];then
#		SECFUNCvarSet fGamma=1.75
#	elif [[ "$fGamma" == "1.75" ]];then
#		SECFUNCvarSet fGamma=2.0
#	elif [[ "$fGamma" == "2.0" ]];then
#		SECFUNCvarSet fGamma=0.5
#	fi
	
	xgamma -gamma $fGamma
#	SECFUNCvarSet gammaLock 0
#	rm -vf "$lockFileGamma"
#	FUNClockFile --unlock "$lockGammaId" $pidOpenNewX
#	SECFUNCuniqueLock --release --pid $pidOpenNewX "$lockGammaId"
	echoc --say "gamma $fGamma" #must say before releasing the lock!
	SECFUNCuniqueLock --release --pid $$ "$lockGammaId"
};export -f FUNCcicleGamma

function FUNCnvidiaCicle() {
	local nDirection=$1 # 1 or -1
	
	#eval `secLibsInit.sh` #required if using exported function on child environment
	SECFUNCvarSet --default nvidiaCurrent -1
	
	local lockId="openNewX.nvidia"
	SECFUNCuniqueLock --pid $$ "$lockId"
	
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
				echoc -w
			fi
			break
		fi
		
		((count++))
		if((count>limit));then
			echoc -w -p "there is no nvidia config file?"
			break
		fi
		
		if((nvidiaCurrent>limit));then
			SECFUNCvarSet nvidiaCurrent -1
			continue;
		fi
	done
	
	SECFUNCuniqueLock --release --pid $$ "$lockId"
	
	echoc --waitsay "n-vidia $nvidiaCurrent"
	SECFUNCvarShow nvidiaCurrent
	#echoc -w -t 10 "`SECFUNCvarShow nvidiaCurrent`"
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
	# scripts will be executed with all environment properly setup with eval `secLibsInit.sh`
	if [[ -z "$1" ]]; then
		echo "Scripts List:"
		grep "#helpScript" $0 |grep -v grep
	fi
	
  if [[ "$1" == "returnX0" ]]; then #helpScript return to :0
  	#cmdEval="xdotool key super+l"
  	echoc -x "FUNCchildScreenLockNow"
  	
  	echoc -x "xdotool key control+alt+F7"
  	#cmdEval="sudo -k chvt 7"
  	
  	echoc -x "bash"
  	return
  fi
  
  if [[ "$1" == "showHelp" ]]; then #helpScript show user custom command options and other options
    FUNCxtermDetached --waitx1exit FUNCshowHelp $DISPLAY 30&
  fi
  
  if [[ "$1" == "isScreenLocked" ]];then
    if FUNCisScreenLockRunning;then
      exit 0
    else
      exit 1
    fi
  fi
  
  if [[ "$1" == "nvidiaCicle" ]]; then #helpScript cicle through nvidia pre-setups
	  FUNCnvidiaCicle 1
  fi
  if [[ "$1" == "nvidiaCicleBack" ]]; then #helpScript cicle through nvidia pre-setups
	  FUNCnvidiaCicle -1
  fi
  
  if [[ "$1" == "cicleGamma" ]]; then #helpScript cicle gamma value
#  	while true;do
#  		if ! ps -A -o pid,comm,command |grep -v "^[ ]*$$" |grep "^[ ]*[[:digit:]]* openNewX.sh.*cicleGamma$" |grep -v grep; then
#  			break
#  		fi
#  		echoc -w -t 1 "already running, waiting other exit"
#  	done
	  FUNCcicleGamma 1
  fi
  if [[ "$1" == "cicleGammaBack" ]]; then #helpScript cicle gamma value
  	FUNCcicleGamma -1
  fi
  
  if [[ "$1" == "sayTemperature" ]]; then #helpScript say temperature
#		sedTemperature='s".*: *+\([0-9][0-9]\)\.[0-9]°C.*"\1"'
#		tmprToMonitor="temp1"
#		tmprCurrent=`sensors |grep "$tmprToMonitor" |sed "$sedTemperature"`
#		echoc --say "$tmprCurrent celcius"
#		echoc --say "`FUNCtempAvg` celcius"
		echoc --say "`highTmprMon.sh --tmpr` celcius"
  fi
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
		
		if ! ps -p $pidJWM; then
			jwm -display :1&
			pidJWM=$!
		fi
		
		sleep 5
	done
};export -f FUNCkeepJwmAlive

function FUNCwaitX1exit() {
#	while FUNCisX1running;do
	while ps -p $pidX1 >/dev/null 2>&1; do
		echo "wait X :1 exit"
		sleep 1
	done
};export -f FUNCwaitX1exit

function FUNCxtermDetached() {
	if [[ "$1" == "--waitx1exit" ]];then
		waitX1exit="FUNCwaitX1exit"
		shift
	fi
	
	# this is a trick to prevent child terminal to close when its parent closes
	local params="$@"
#	function FUNCxtermDetachedExec() {
#		$params
#	};export -f FUNCxtermDetachedExec
	
	xterm -e "echo \"TEMP xterm...\"; xterm -e \"$params;$waitX1exit\";echoc -w"&
	local pidXterm=$!
	
	# wait for the child (with the $params) to open
	while ! ps --ppid $pidXterm; do
		sleep 1
	done
	
	kill -SIGINT $pidXterm
};export -f FUNCxtermDetached

function FUNCcmdAtNewX() {
	eval "$cmdOpenNewX";
	bash;
}; export -f FUNCcmdAtNewX

function FUNCdoNotCloseThisTerminal() {
	echo "DO NOT CLOSE THIS TERMINAL, ck-launch-session";
	ck-launch-session;
	bash -c "echo \"wont reach here cuz of ck-launch-session...\""
};export -f FUNCdoNotCloseThisTerminal

function FUNCechocInitBashInteractive() {
	eval `secLibsInit.sh`
	bash -i
};export -f FUNCechocInitBashInteractive

function FUNCmaximiseWindow() {
	local windowId=$1
	wmctrl -i -r $windowId -b toggle,maximized_vert,maximized_horz
};export -f FUNCmaximiseWindow

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
  zenity --display=$1 $timeout --title "OpenNewX: your Custom Commands!" --text-info --filename="$helpFile"&
  local pidZenity=$!
  
  local windowId=""
  for windowId in `xdotool search --sync --pid $pidZenity`;do
    FUNCmaximiseWindow $windowId
  done
  
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
SECFUNCvarSet --default bUseXscreensaver=false
strGeometry=""
export strCustomCmdHelp=""
while [[ ${1:0:2} == "--" ]]; do
  if [[ "$1" == "--no-wm" ]]; then #opt SKIP WINDOW MANAGER (run pure X alone)
    useJWM=false
  elif [[ "$1" == "--no-kbd" ]]; then #opt SKIP Keyboard setup
    useKbd=false
  elif [[ "$1" == "--recreaterc" ]]; then #opt recreate $HOME/.jwmrc file
  	bRecreateRCfile=true
  elif [[ "$1" == "--xterm" ]]; then #opt use xterm instead of gnome-terminal
  	bXTerm=true
  elif [[ "$1" == "--ignorecompiz" ]]; then #opt ignore compiz finish starting
  	bWaitCompiz=false
  elif [[ "$1" == "--xscreensaver" ]]; then #opt use xscreensaver instead of xlock
  	SECFUNCvarSet bUseXscreensaver=true
  elif [[ "$1" == "--recreatercthin" ]]; then #opt recreate $HOME/.jwmrc file, but does not use /etc/jwm one!
  	bRecreateRCfile=true
  	bRecreateRCfileThin=true
  elif [[ "$1" == "--geometry" ]];then #opt size of the new screen
  	shift
    strGeometry="$1"
  elif [[ "$1" == "--returnX0" ]]; then #opt lock display at :1 and return to :0
  	bReturnToX0=true
  elif [[ "$1" == "--customcmd" ]]; then #opt custom commands, up to 10 (repeat the option) ex.: --customcmd "zenity --info" --customcmd "xterm" --customcmd "someScript.sh"
  	shift
  	customCmd=("${customCmd[@]}" "$1")
  	strCustomCmd=`echo " Meta+${#customCmd[*]} EXEC: $1"`
  	echo "$strCustomCmd"
  	strCustomCmdHelp="$strCustomCmdHelp$strCustomCmd\n"
  elif [[ "$1" == "--isRunning" ]]; then #opt check if new X :1 is already running
    if FUNCisX1running; then
      exit 0
    else
      exit 1
    fi
  elif [[ "$1" == "--script" ]]; then #opt run a internal script (without script name will show the list)
  	FUNCscript $2
		exit 0
  elif [[ "$1" == "--killX1" ]]; then #opt kill X :1
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
    if pidX1=`FUNCisX1running`;then
	    echo "pidX1=$pidX1"
      ps -p $pidX1
      echoc -x "sudo -k kill -SIGKILL $pidX1"
    fi
    
  	# kill xscreensaver if it was used at :1
#    pidXscrsv=`ps -A -o pid,command |grep "xscreensaver -display :1" |grep -v grep |sed -r "$sedOnlyPid"`
#    echo "pidXscrsv=$pidXscrsv"
#    if [[ -n "$pidXscrsv" ]];then
#      ps -p $pidXscrsv
#      kill -SIGKILL $pidXscrsv
#    fi
    if pidXscrsv=`ps -A -o pid,command |grep "xscreensaver -display :1" |grep -v grep |sed -r "$sedOnlyPid"`;then
	    echo "pidXscrsv=$pidXscrsv"
      ps -p $pidXscrsv
      kill -SIGKILL $pidXscrsv
    fi
    
    exit 0
  elif [[ "$1" == "--help" ]]; then #opt show help info
    echo "can be used at startup applications as: $0 --returnX0"
    echo "usage: options runCommand"
    
    # this sed only cleans lines that have extended options with "--" prefixed
    #sedCleanHelpLine='s"\(.*\"\)\(--.*\)\".*#opt" \2\t"' #helpskip
		sedCleanHelpLine='s;(.*")(--.*)".*#opt; \2\t;' #helpskip
    grep "#opt" $0 |grep -v "#helpskip" |sed -r "$sedCleanHelpLine"
    #echo "SCRIPTS:";    grep "#helpScript" $0 |grep -v "#helpskip" |sed "$sedCleanHelpLine"
    
    exit 0
  else
    echoc -p "invalid option $1"
    $0 --help
    exit 1
  fi
 	shift
done

#################### MAIN CODE ###########################################

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

# at this point, X1 will be managed by openNewX
if FUNCisX1running;then
	if echoc -q -t 20 "Open New X. You must stop the other session at :1 before continuing. Kill X1 now"; then
		$0 --killX1
		
		#wait really exit
		while FUNCisX1running; do
			sleep 1
		done
		
		while ! SECFUNCuniqueLock;do
			echoc -p "Unable to create unique lock..."
			echoc -w -t 3
		done
		
		SECFUNCvarSetDB -f
		#sleep 3 #Xorg seems to leave some trash on memory? how to detect it properly?
	else
		exit
	fi
fi

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
		  	head -n $((endTagAtLine-1)) /etc/jwm/system.jwmrc \
		  		>"$HOME/.jwmrc"
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
    echo -e '
          <Key mask="4" key="F1">exec:xdotool set_desktop 0</Key>
          <Key mask="4" key="F2">exec:xdotool set_desktop 1</Key>
          <Key mask="4" key="F3">exec:xdotool set_desktop 2</Key>
          <Key mask="4" key="F4">exec:xdotool set_desktop 3</Key>
          <Key mask="4" key="C">exec:xterm -e "FUNCclearCache #kill=skip"</Key>
          <Key mask="4" key="G">exec:'"xterm -e \"$0 --script nvidiaCicle\" #kill=skip"'</Key>
          <Key mask="S4" key="G">exec:'"xterm -e \"$0 --script nvidiaCicleBack\" #kill=skip"'</Key>
          <Key mask="4" key="H">exec:'"xterm -e \"$0 --script showHelp\" #kill=skip"'</Key>
          <Key mask="4" key="K">exec:xkill</Key>
          <Key mask="4" key="L">exec:bash -c "FUNCchildScreenLockNow"</Key>
          <Key mask="4" key="M">exec:'"xterm -e \"$0 --script cicleGamma\" #kill=skip"'</Key>
          <Key mask="S4" key="M">exec:'"xterm -e \"$0 --script cicleGammaBack\" #kill=skip"'</Key>
          <Key mask="4" key="P">exec:'"xterm -e \"$0 --script sayTemperature\" #kill=skip"'</Key>
          <Key mask="4" key="T">exec:xterm -e "FUNCsayTime #kill=skip"</Key>
          <Key mask="4" key="X">exec:xterm -e "FUNCechocInitBashInteractive #kill=skip"</Key>
          <Key mask="4" key="Z">exec:xterm -display :0 -e "FUNCechocInitBashInteractive #kill=skip"</Key>
          <Key mask="4" key="1">exec:'"xterm -e \"${customCmd[0]}\" #kill=skip"'</Key>
          <Key mask="4" key="2">exec:'"xterm -e \"${customCmd[1]}\" #kill=skip"'</Key>
          <Key mask="4" key="3">exec:'"xterm -e \"${customCmd[2]}\" #kill=skip"'</Key>
          <Key mask="4" key="4">exec:'"xterm -e \"${customCmd[3]}\" #kill=skip"'</Key>
          <Key mask="4" key="5">exec:'"xterm -e \"${customCmd[4]}\" #kill=skip"'</Key>
          <Key mask="4" key="6">exec:'"xterm -e \"${customCmd[5]}\" #kill=skip"'</Key>
          <Key mask="4" key="7">exec:'"xterm -e \"${customCmd[6]}\" #kill=skip"'</Key>
          <Key mask="4" key="8">exec:'"xterm -e \"${customCmd[7]}\" #kill=skip"'</Key>
          <Key mask="4" key="9">exec:'"xterm -e \"${customCmd[8]}\" #kill=skip"'</Key>
          <Key mask="4" key="0">exec:'"xterm -e \"${customCmd[9]}\" #kill=skip"'</Key>
        </JWM>' \
      >>"$HOME/.jwmrc"
      
    #if ! jwm -p; then
    if jwm -p 2>&1 |grep JWM; then
      #rm $HOME/.jwmrc
      echo -n "WARN: .jwmrc is invalid, continue anyway? (y/...)";read -t 3 -n 1 resp
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

#echo "going to execute: $@"
#@@@R runCmd="$1" #this command must be simple, if need complex put on a script file and call it!
runCmd="$@" #this command must be simple, if need complex put on a script file and call it!
export cmdOpenNewX="bash -c \"$kbdSetup; bash -c \\\"$runCmd;bash -i\\\"; bash -i;\""
echo "cmdOpenNewX=$cmdOpenNewX"

# wait for compiz to start to not mess its behavior
if [[ -n "$DISPLAY" ]] && $bWaitCompiz; then
	while ! echoc -x "qdbus org.freedesktop.compiz 1>/dev/null"; do #do not ignore the error output!
		if echoc -q -t 1 "check if CCSM D-BUS was enabled. Quit"; then 
			exit 1; 
		fi
	done
fi

# run in a thread, prevents I from ctrl+c here what breaks THIS X instace and locks keyb
pidXtermForNewX=-1
if ! FUNCisX1running; then
  cmdX1="\
  echo \"INFO: hit CTRL+C to exit the other X session and close this window\";\
  echo \"INFO: running in a thread (child proccess) to prevent ctrl+c from freezing this X session and the machine!\";\
  echo \"INFO: hit ctrl+alt+f7 to get back to this X session (f7, f8 etc, may vary..)\";\
  echo ;\
  echo \"Going to execute on another X session: $runCmd\";\
  echoc -x 'sudo -k $execX1'"

  if [[ -z "$DISPLAY" ]]; then
    #if at tty1 console there is no X already running
    eval $cmdX1&
    pidXtermForNewX=$!
  else
    xterm -e "$cmdX1"&
    pidXtermForNewX=$!
  fi
fi
#echoc -x "sudo -k chvt 8" # this line to force go to X :1 terminal

# wait for X to start
while ! FUNCisX1running; do
  sleep 1
done
varset --show pidX1=`FUNCisX1running`

if [[ -n "$strGeometry" ]];then
	xrandr -display :1 -s $strGeometry
	sleep 1
fi

# run in a thread, prevents I from ctrl+c here what breaks THIS X instace and locks keyb
if $useJWM; then
  jwm -display :1&
  pidJWM=$!
  
  #xterm -e "FUNCkeepJwmAlive $pidJWM $$ #kill=skip"&
  FUNCxtermDetached "FUNCkeepJwmAlive $pidJWM $$ $pidXtermForNewX #kill=skip"
fi

# this enables sound (and may be other things...) (see: http://askubuntu.com/questions/3981/start-a-second-x-session-with-different-resolution-and-sound) (see: https://bbs.archlinux.org/viewtopic.php?pid=637913)
#DISPLAY=:1 ck-launch-session #this makes this script stop executing...
#xterm -e "DISPLAY=:1 ck-launch-session"& #this creates a terminal at :0 that if closed will make sound at :1 stop working
xterm -geometry 1x1 -display :1 -e "FUNCdoNotCloseThisTerminal #kill=skip"&

#initializes the cicle of configurations!
xterm -display :1 -e "$0 --script nvidiaCicle" #not threaded/child so the speech does not interfere with some games sound initialization check

sleep 2 #@@@!!! TODO improve with qdbus waiting for jwm?
#SECFUNCvarShow bUseXscreensaver #@@@r
xterm -geometry 1x1 -display :1 -e "bash -ic \"FUNCchildScreenAutoLock\""&

# setxkbmap is good for games that have console access!; bash is to keep console open!

# nothing
#xterm -display :1&

# dead keys
#xterm -display :1 -e "setxkbmap -layout us -variant intl; bash"&

# good for games!
#bXTerm=true #TODO gnome-terminal is not working with this yet...

#FUNCxtermDetached --waitX1exit FUNCshowHelp :0&
FUNCxtermDetached --waitX1exit FUNCshowHelp :1&
#pidZenity0=$!

#while true; do
	pidTerm=-1
	if $bXTerm; then
#		xterm -display :1 -e "$cmdOpenNewX" -e "bash"&
		xterm -display :1 -e "bash -i -c FUNCcmdAtNewX #kill=skip"&
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
	xterm -display :1 -e "bash -ic \"$0 --script returnX0\""&
fi

##initializes the cicle of configurations!
#xterm -display :1 -e "$0 --script nvidiaCicle"&

# MUST BE THE LAST THING
# this enables sound (and may be other things...) (see: http://askubuntu.com/questions/3981/start-a-second-x-session-with-different-resolution-and-sound) (see: https://bbs.archlinux.org/viewtopic.php?pid=637913)
#DISPLAY=:1 ck-launch-session #this makes this script stop executing...
#xterm -e "DISPLAY=:1 ck-launch-session"& #this creates a terminal at :0 that if closed will make sound at :1 stop working
#xterm -geometry 1x1 -display :1 -e "FUNCdoNotCloseThisTerminal #kill=skip"&

#while FUNCisX1running; do
while ps -p $pidX1 >/dev/null 2>&1; do
	echoc --alert "ctrl+c will prevent commands, like gamma change, from working properly!"
	if echoc -q -t 60 "kill X1"; then #prevent closing what shutdown jwm and xscreensaver
		$0 --killX1
	fi
done

echoc --say "X1 closed"
#echoc -w "exit"
#echoc -x "kill $pidZenity0"
#echoc -w -t 5


