#!/bin/bash
# Copyright (C) 2013-2014 by Henrique Abdalla
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

#TODO check at `info at` if the `at` command can replace this script?

eval `secinit --nochild --extras`

echo " SECstrRunLogFile='$SECstrRunLogFile'" >>/dev/stderr
echo " \$@='$@'" >>/dev/stderr

#strFullSelfCmd="`basename $0` $@"
export strFullSelfCmd="`ps --no-headers -o cmd -p $$`"
echo " strFullSelfCmd='$strFullSelfCmd'" >>/dev/stderr

SECFUNCcfgReadDB
echo "SECcfgFileName='$SECcfgFileName'"

SECFUNCcfgWriteVar SECCFGbOverrideRunAllNow=false #this grants startup always obbeying sleep
varset bCheckPointConditionsMet=false
export bWaitCheckPoint=false
export nDelayAtLoops=1
export bCheckPointDaemon=false
export bCheckIfAlreadyRunning=true
export nSleepFor=0
export bListAlreadyRunningAndNew=false
export bListIniCommands=false
export bStay=false
export bListWaiting=false
export bCheckPointDaemonHold=false
export bRunAllNow=false
export bRespectedSleep=false
export bXterm=false
export strCheckPointCustomCmd
export astrXtermOpts=()
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "[options] <command> [command params]..."
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--sleep" || "$1" == "-s" ]];then #help <nSleepFor> seconds before executing the command with its params.
		shift
		nSleepFor="${1-}"
	elif [[ "$1" == "--respectedsleep" || "$1" == "-r" ]];then #help with this, sleep delay will be respected and --SECCFGbOverrideRunAllNow will be ignored.
		bRespectedSleep=true
	elif [[ "$1" == "--delay" ]];then #help set a delay (can be float) to be used at LOOPs
		shift
		nDelayAtLoops="${1-}"
	elif [[ "$1" == "--checkpointdaemon" ]];then #help "<command> <params>..." ~daemon when the custom command return true (0), allows waiting instances to run; so must return non 0 to keep holding them.
		shift
		strCheckPointCustomCmd="${1-}"
		bCheckPointDaemon=true
	elif [[ "$1" == "--checkpointdaemonhold" ]];then #help "<command> <params>..." ~daemon like --checkpointdaemon, but will also prompt user before releasing the scripts
		shift
		strCheckPointCustomCmd="${1-}"
		bCheckPointDaemon=true
		bCheckPointDaemonHold=true
	elif [[ "$1" == "--waitcheckpoint" || "$1" == "-w" ]];then #help ~loop after nSleepFor, also waits checkpoint tmp file to be removed
		bWaitCheckPoint=true
	elif [[ "$1" == "--nounique" ]];then #help skip checking if this exactly same command is already running, otherwise, will wait the other command to end
		bCheckIfAlreadyRunning=false
	elif [[ "$1" == "--shouldnotexit" || "$1" == "-d" ]];then #help ~daemon indicated that the command should not exit normally (it should stay running like a daemon), if it does, it logs 'Sne' (Should not exit)
		bStay=true
	elif [[ "$1" == "--listconcurrent" ]];then #help list pids that are already running and new pids trying to run the same command
		bListAlreadyRunningAndNew=true
	elif [[ "$1" == "--listcmdsini" ]];then #help list commands that entered (ini) the log file
		bListIniCommands=true
	elif [[ "$1" == "--listwaiting" ]];then #help list commands that entered (ini) the log file but havent RUN yet
		bListWaiting=true
	elif [[ "$1" == "--xterm" || "$1" == "-x" ]];then #help use xterm to run the command
		bXterm=true
	elif [[ "$1" == "--xtermopts" ]];then #help "<astrXtermOpts>" options to xterm like background color etc.
		shift
		astrXtermOpts=(${1-})
	elif [[ "$1" == "--SECCFGbOverrideRunAllNow" ]];then #help <SECCFGbOverrideRunAllNow> set to 'true' to skip sleep delays of all tasks, and exit.
		shift
		varset bRunAllNow=true;varset bRunAllNow="${1-}" #this is fake, just to easy (lazy me) validate boolean... cfg vars should use the same as vars code... onde day..
	else
		SECFUNCechoErrA "invalid option '$1'" >>/dev/stderr
		exit 1
	fi
	shift&&:
done

export strItIsAlreadyRunning="IT IS ALREADY RUNNING"
export strExecGlobalLogFile="/tmp/.$SECstrScriptSelfName.`id -un`.log" #to be only used at FUNClog

function FUNCcheckIfWaitCmdsHaveRun() {
	#grep "^ ini -> [[:alnum:]+.]*;w+[[:alnum:]]*s;pid=" "$strExecGlobalLogFile" \
	echoc --info "Commands that have not been run yet:"
	grep "^ ini -> .*;w+[[:alnum:]]*s;pid='" "$strExecGlobalLogFile" \
		|sed -r "s@.*;pid='([[:alnum:]]*)';.*@\1@" \
		| { 
			local lbAllRun=true
		
			while read nPid;do 
				if [[ ! -d "/proc/$nPid" ]];then
					continue
				fi
				if ! grep -q "^ RUN -> .*;pid='$nPid';" "$strExecGlobalLogFile";then
					echo " nPid='$nPid';cmd='`ps --no-headers -o cmd -p $nPid`'"
					lbAllRun=false
				fi
			done
		
			if ! $lbAllRun;then
				return 1
			fi
			
			return 0
		}
	
	return $?
}

if $bRunAllNow;then
	echoc --info "hit ctrl+c to end."
	while true;do 
		SECFUNCcfgReadDB; 
#		echo "`SECFUNCdtFmt --alt`/SECCFGbOverrideRunAllNow='$SECCFGbOverrideRunAllNow', bCheckPointConditionsMet='$bCheckPointConditionsMet'";
		echo "`SECFUNCdtFmt --alt`/SECCFGbOverrideRunAllNow='$SECCFGbOverrideRunAllNow'";
		SECFUNCcfgWriteVar SECCFGbOverrideRunAllNow=true
#		varset bCheckPointConditionsMet=true
		
		if SECFUNCdelay --checkorinit 5 "SECCFGbOverrideRunAllNow";then
			if FUNCcheckIfWaitCmdsHaveRun;then
				break;
			fi
		fi
		
		sleep 1;
	done
	
	exit 0
fi

if $bListIniCommands;then
	SEC_WARN=true SECFUNCechoWarnA "this output still needs more cleaning..."
	cat "$strExecGlobalLogFile" \
		|grep ini \
		|grep -o 'sec[[:upper:]][[:alnum:]_]*[.]sh[^.].*' \
		|sort -u \
		|sed -r 's@^(.*)[\]""[[:blank:]]*$@\1@'	\
		|cat #this cat is dummy just to help coding...
	exit
fi

if ! SECFUNCisNumber -dn "$nDelayAtLoops";then
	echoc -p "invalid nDelayAtLoops='$nDelayAtLoops'"
	exit 1
elif((nDelayAtLoops<1));then
	nDelayAtLoops=1
fi

export strWaitCheckPointIndicator=""
if $bWaitCheckPoint;then
	strWaitCheckPointIndicator="w+"
fi
export strToLog="${strWaitCheckPointIndicator}${nSleepFor}s;pid='$$';`SECFUNCparamsToEval "$@"`"

function FUNClog() { #params: <type with 3 letters> [comment]
	local lstrType="$1"
	local lstrLogging=" $lstrType -> `date "+%Y%m%d+%H%M%S.%N"`;$strToLog"
	local lstrComment="${@:2}" #"${2-}" fails to '$@' as param when calling this function
	
	if [[ -n "$lstrComment" ]];then
		lstrLogging+="; # $lstrComment"
	fi
	
	case "$lstrType" in	"wrn"|"Err"|"Sne"|"ini"|"RUN"|"end");; #recognized ok
		*) SECFUNCechoErrA "invalid lstrType='$lstrType'" >>/dev/stderr;
			 _SECFUNCcriticalForceExit;;
	esac
	
	if [[ "$lstrType" == "wrn" ]];then
		SEC_WARN=true SECFUNCechoWarnA "$lstrLogging"
	fi
	case "$lstrType" in "Err"|"Sne")
		SECFUNCechoErrA "$lstrLogging";;
	esac
	
	echo "$lstrLogging" >>/dev/stderr
	echo "$lstrLogging" >>"$strExecGlobalLogFile"
};export -f FUNClog

if $bListWaiting;then
	FUNCcheckIfWaitCmdsHaveRun&&:
	#echo "returned $?"
	exit 0
fi

if $bCheckPointDaemon;then
	echo "see Global Exec log for '`id -un`' at: $strExecGlobalLogFile" >>/dev/stderr
	
	if [[ -z "$strCheckPointCustomCmd" ]];then
		FUNClog Err "invalid empty strCheckPointCustomCmd"
		exit 1
	fi
	
	SECFUNCuniqueLock --waitbecomedaemon
	SECFUNCuniqueLock --getuniquefile
	SECFUNCuniqueLock --getdaemonpid
	
	SECONDS=0
	echo "Conditional command to activate checkpoint: $strCheckPointCustomCmd"
	while true;do
#		if ! $bCheckPointConditionsMet;then
			echo "Check at `date "+%Y%m%d+%H%M%S.%N"` (${SECONDS}s)"
			if bash -c "$strCheckPointCustomCmd";then
				# hold just after checkpoint condition is met
				if $bCheckPointDaemonHold;then
					echoc --say "run?"
					strTitle="$SECstrScriptSelfName[$$], hold waiting instances."
					while true;do
						SECFUNCCwindowOnTop "$strTitle"
						if zenity --question --title "$strTitle" --text "allow waiting instances to be run?";then
							break;
						fi
					done
				fi
				varset bCheckPointConditionsMet=true
				echo "Check Point reached at `date "+%Y%m%d+%H%M%S.%N"`"
				echo "'waiting commands' will only run if this one remain active!!! "
				break
			fi
#		fi
		sleep $nDelayAtLoops
	done
	
	# this wait is necessary so other instances have time to confirm the checkpoint
	strIdShowDelay="ShowDelay"
	SECFUNCdelay "$strIdShowDelay" --init
	while true;do
		if SECFUNCdelay "WaitCmds" --checkorinit1 10;then
			if FUNCcheckIfWaitCmdsHaveRun;then
				break;
			fi
			echoc --info "waiting all commands be actually RUN"
		fi
		sleep 3 #1s is too much cpu usage
		echo "waiting for: `SECFUNCdelay "$strIdShowDelay" --get`s"
	done
	
	exit 0
fi

if $bListAlreadyRunningAndNew;then
	echoc --info "New,Old,CMD"
	grep -o "${strItIsAlreadyRunning}.*" "$strExecGlobalLogFile" \
		|sort -u \
		|sed -r 's".*nPidSelf=([[:digit:]]*) nPidOther=([[:digit:]]*)"\1 \2"' \
		|while read strLine;do
			anPids=($strLine)
			if [[ -d "/proc/${anPids[0]}" ]] && [[ -d "/proc/${anPids[1]}" ]];then
				echo " New ${anPids[0]}, Old ${anPids[1]}, `ps --no-headers -o cmd -p ${anPids[0]}`"
			fi
		done
	exit
fi

####################### MAIN "RUN IT" CODE ##########################

if ! SECFUNCisNumber -dn $nSleepFor;then
	FUNClog Err "invalid nSleepFor='$nSleepFor'"
	exit 1
fi

if [[ -z "$@" ]];then
	FUNClog Err "invalid command '$@'"
	exit 1
fi

FUNClog ini

#if $bWaitCheckPoint;then
#	SECONDS=0
#	while ! SECFUNCuniqueLock --isdaemonrunning;do
#		echo -ne "$SECstrScriptSelfName: waiting daemon (${SECONDS}s)...\r"
#		sleep $nDelayAtLoops
#	done
#	
#	SECFUNCuniqueLock --setdbtodaemon
#	
#	SECONDS=0
#	while true;do
#		SECFUNCvarReadDB
#		if $bCheckPointConditionsMet;then
#			break
#		fi
#		echo -ne "$SECstrScriptSelfName: waiting checkpoint be activated at daemon (${SECONDS}s)...\r"
#		sleep $nDelayAtLoops
#	done
#	
#	echo
#fi
if $bWaitCheckPoint;then
	SECFUNCdelay bWaitCheckPoint --init
	nPidDaemon=-1
	strFileUnique="`SECFUNCuniqueLock --getuniquefile`"
	while true;do
		echo -ne "$SECstrScriptSelfName: waiting checkpoint be activated at daemon (`SECFUNCdelay bWaitCheckPoint --getsec`s)...\r"

#		if SECFUNCuniqueLock --isdaemonrunning;then
#			SECFUNCuniqueLock --setdbtodaemon	#SECFUNCvarReadDB
#			if $bCheckPointConditionsMet;then
#				break
#			fi
#		fi
		
		if [[ ! -f "$strFileUnique" ]];then #TODO after the daemon exited, another script pid (not daemon one) was considered as being daemon, but how?
			nPidDaemon=-1 
		fi
		
		if [[ -d "/proc/$nPidDaemon" ]];then
			SECFUNCvarReadDB bCheckPointConditionsMet
			if $bCheckPointConditionsMet;then
				break
			else
				sleep 3 #this extra sleep is to lower the cpu usage when several scripts are running this same check at once
			fi
		else
			nPidDaemon=-1 # this helps (but is not 100% garanteed) on preventing other process that could have get the same pid
			if SECFUNCuniqueLock --isdaemonrunning;then
#				SECFUNCuniqueLock --setdbtodaemon # if daemon was NOT running, this would become the daemon
#				if $SECbDaemonWasAlreadyRunning;then
#					nPidDaemon="$SECnDaemonPid"
#				else
#					nPidDaemon=-1
#				fi
				if SECFUNCuniqueLock --setdbtodaemononly;then
					nPidDaemon="$SECnDaemonPid"
				fi
			else
				sleep 3 #this extra sleep is to lower the cpu usage when several scripts are running this same check at once
			fi
		fi
		
		sleep $nDelayAtLoops
	done
	
	echo
fi

#sleep $nSleepFor #timings are adjusted against each other, the checkpoint is actually a starting point
function FUNCsleep() { #timings are adjusted against each other, the checkpoint is actually a starting point
	local lnSleepFor="$1"
	
#	SECONDS=0
	while true;do
		SECFUNCcfgReadDB SECCFGbOverrideRunAllNow
#		SECFUNCvarShow SECCFGbOverrideRunAllNow
		if ! $bRespectedSleep;then
			echo "SECCFGbOverrideRunAllNow='$SECCFGbOverrideRunAllNow'"
			if $SECCFGbOverrideRunAllNow;then
				break;
			fi
		fi
		
		local lnSleepStep=5
		if((lnSleepFor>lnSleepStep));then
			((lnSleepFor-=lnSleepStep))&&:
		else
			lnSleepStep=$lnSleepFor
			lnSleepFor=0
		fi
		
		echo "sleeping for: $lnSleepStep of $nSleepFor"
		sleep $lnSleepStep
		
		if((lnSleepFor==0));then 
			break;
		fi
	done
}
FUNCsleep $nSleepFor

if $bCheckIfAlreadyRunning;then
	while true;do
	#	if ! ps -A -o pid,cmd |grep -v "^[[:blank:]]*[[:digit:]]*[[:blank:]]*grep" |grep -q "$strFullSelfCmd";then
	#	if ! pgrep -f "$strFullSelfCmd";then
		nPidOther=""
		anPidList=(`pgrep -fx "${strFullSelfCmd}$"`)&&:
		#echo "$$,${anPidList[@]}" >>/dev/stderr
		if anPidOther=(`echo "${anPidList[@]-}" |tr ' ' '\n' |grep -vw $$`);then #has not other pids than self
			#echo " anPidOther[@]=(${anPidOther[@]})" >>/dev/stderr
			bFound=false
			if((`SECFUNCarraySize anPidOther`>0));then
				for nPidOther in ${anPidOther[@]};do
					#echo "\"^ RUN -> .*;pid='$nPidOther';\"" >>/dev/stderr
					#if grep -q "^ RUN -> .*;pid='$nPidOther';" "$strExecGlobalLogFile";then
					if grep -q " RUN -> .*;pid='$nPidOther';" "$strExecGlobalLogFile";then
						bFound=true
						break;
					fi
				done
			fi
			if ! $bFound;then break;fi
		else
			if ! echo "${anPidList[@]-}" |grep -qw "$$";then
				FUNClog wrn "could not find self! "
			fi
			break;
		fi
		FUNClog wrn "$strItIsAlreadyRunning nPidSelf=$$ nPidOther=$nPidOther"
		#sleep 60
		#if echoc -q -t 60 "skip check if already running?";then
		bKillOther=false
		if SECFUNCisShellInteractive;then
			if echoc -q -t 60 "kill the nPidOther='$nPidOther' that is already running?";then
				if [[ -d "/proc/$nPidOther" ]];then
					bKillOther=true
				else
					echoc --info "no nPidOther='$nPidOther'"
				fi
			fi
		else
			strTitle="$SECstrScriptSelfName[$$], multiple instances running."
			SECFUNCCwindowOnTop "$strTitle"
			if zenity --question --title "$strTitle" --text "$strFullSelfCmd\n\nnPidSelf=$$; kill the nPidOther='$nPidOther' that is already running?";then
				bKillOther=true
			fi
		fi
		if $bKillOther;then
			#echoc -x "kill -SIGKILL $nPidOther"
			echoc -x "pstree -l -p $nPidOther"&&:
			anPidList=(`SECFUNCppidList --pid $nPidOther --child --addself`)
			for nPid in "${anPidList[@]}";do
				if [[ -d "/proc/$nPid" ]];then
					echoc -x "kill -SIGTERM $nPid"&&:
				fi
			done
			sleep 1
			for nPid in "${anPidList[@]}";do
				if [[ -d "/proc/$nPid" ]];then
					echoc -x "kill -SIGKILL $nPid"&&:
				fi
			done
			break
		fi
	done
fi

export astrRunParams=("$@")
function FUNCrun(){
#	eval `secinit`
#	SECFUNCarraysRestore
	nRunTimes=0
	local lbDevMode=false
	while true;do
		((nRunTimes++))&&:
		
		# do RUN
		FUNClog RUN "$nRunTimes time(s)"
		SECFUNCdelay RUN --init
		
#		# also `env -i bash -c "\`SECFUNCparamsToEval "$@"\`"` did not fully work as vars like TERM have not required value (despite this is expected)
#		# nothing related to SEC will run after SECFUNCcleanEnvironment unless if reinitialized
#		( SECbRunLog=true SECFUNCcheckActivateRunLog; #forced log!
#			SECFUNCcleanEnvironment; #all SEC environment will be cleared
#			#"$@";
#			"${astrRunParams[@]}"
#		)&&:;nRet=$?
		
		export strFileRetVal=$(mktemp)
		function FUNCrunAtom(){
			eval `secinit` #this will apply the exported arrays
			# also, this command: `env -i bash -c "\`SECFUNCparamsToEval "$@"\`"` did not fully work as vars like TERM have not required value (despite this is expected)
			# nothing related to SEC will run after SECFUNCcleanEnvironment unless if reinitialized
			( SECbRunLog=true SECFUNCcheckActivateRunLog -v; #forced log!
				SECFUNCcleanEnvironment; #all SEC environment will be cleared
				#"$@";
				declare -p PATH >>/dev/stderr
				echo "$FUNCNAME Running Command: ${astrRunParams[@]}"
				"${astrRunParams[@]}"
			)&&:;local lnRetAtom=$?
			echo "$lnRetAtom" >"$strFileRetVal";
		};export -f FUNCrunAtom
		
		astrCmdToRun=(bash -c)
		if $lbDevMode;then
			astrCmdToRun=(secBashForScriptEchoColorDevelopment.sh --exit)
		fi
		astrCmdToRun+=(FUNCrunAtom)
		
		SECFUNCarraysExport
		if $bXterm;then
			astrTmp=("${astrRunParams[@]}")
			astrTmp[0]="`basename "${astrTmp[0]}"`"
			strTitle="${astrTmp[@]}_pid$$"
			strTitle="`SECFUNCfixIdA -f "$strTitle"`"
			if [[ "$TERM" != "dumb" ]];then
				echoc --info "if on a terminal, to detach this from xterm, do not hit ctrl+C, simply close this one and xterm will keep running..."&&:
			fi
			strCmd="${astrCmdToRun[@]}"
			SECFUNCexecA -ce xterm -title "$strTitle" ${astrXtermOpts[@]-} -e "$strCmd"
		else
#			declare -p astrRunParams
			SECFUNCexecA -ce "${astrCmdToRun[@]}"
		fi		
		local lnRet=$(cat "$strFileRetVal");rm "$strFileRetVal"
		
		local lbErr=false
		local lstrTxt=""
		if $bStay;then
			lstrTxt+="(Sne) should not have exited! (daemon)\n"
			lstrTxt+="\n";
		fi
		
		if((lnRet!=0));then
			lbErr=true
			
			FUNClog Err "lnRet='$lnRet', `SECFUNCerrCodeExplained $lnRet`"
			
			lstrTxt+="(Err) exited with error!\n"
#			lstrTxt+="\n";
			lstrTxt+="\tExitValue:$lnRet\n";
			lstrTxt+="\t`SECFUNCerrCodeExplained $lnRet`\n";
			lstrTxt+="\n";
			lstrTxt+="At: `SECFUNCdtFmt --pretty`\n";
			lstrTxt+="\n";
		fi
		
		if $bStay;then
			FUNClog Sne "Should not have exited..."
		fi
		
		# end Log
		FUNClog end "RunDelay=`SECFUNCdelay RUN --getpretty`"
		
		if $bStay || $lbErr;then
			lstrTxt+="RunCommand(astrRunParams[@]):\n"
			lstrTxt+="\t`SECFUNCparamsToEval "${astrRunParams[@]}"`\n";
			lstrTxt+="\n";
			lstrTxt+="LogInfoDbgCmd:\n";
			lstrTxt+="\tsecMaintenanceDaemon.sh --dump $$\n";
			lstrTxt+="\n";
			lstrTxt+="DbgInfo:\n";
			lstrTxt+="\tTERM=$TERM\n";
			lstrTxt+="\tPATH='$PATH'\n";
			lstrTxt+="\tlbDevMode='$lbDevMode'\n";
			lstrTxt+="\n";
#			lstrTxt+="Tips:\n";
#			lstrTxt+="\tif TERM is dumb, put this on eval 'bXterm=true'\n";
#			lstrTxt+="\n";
			lstrTxt+="QUESTION:\n";
			lstrTxt+="\tDo you want to try to run it again?\n";
			lstrTxt+="\n";
			
			#TODO how t f can this fail when term is dump/closed ?????: if which yad;then
			if SECFUNCexecA -ce yad --version;then
				local lbEvalCode=false
				: ${strCodeToEval:=""}
				# annoying: --on-top
				# the first button will be the default when hitting Enter...
				astrYadFields=(
					bXterm #0
					strCodeToEval #1
				)
				strYadOutput="`
					yad --title "$SECstrScriptSelfName[$$]" --text "$lstrTxt" \
						--separator="\n" \
						--sticky --center --selectable-labels \
						--form \
						--field "[${astrYadFields[0]}] Use Xterm:chk" \
						--field "[${astrYadFields[1]}]" \
						--button="retry:0" \
						--button="retry-DEV:2" \
						--button="gtk-close:1" \
						"${!astrYadFields[0]}" \
						"${!astrYadFields[1]}" 
					`"&&:;nRet=$? #bXterm value will be used to set the default of the 1st available field (the checkbox)
#						--field "[${astrYadFields[1]}] (use '\x7C' instead of '|')" \
#						--button="retry(EvalCode):4" \
#						--button="retry-DEV(EvalCode):3" \
#				IFS=$'\n' read -d '|' -r -a astrYadReturnValues < <(echo "$strYadOutput")&&:
				IFS=$'\n' read -d '' -r -a astrYadReturnValues < <(echo "$strYadOutput")&&:
				declare -p astrYadReturnValues
				if((`SECFUNCarraySize astrYadReturnValues`>0));then
					if [[ "${astrYadReturnValues[0]-}" == "TRUE" ]];then bXterm=true;else bXterm=false;fi
					strCodeToEval="${astrYadReturnValues[1]-}"
#					strCodeToEval="`echo "$strCodeToEval" |sed -r 's"[\]x7[Cc]"|"g'`"
				fi
				case $nRet in 
					0)lbDevMode=false;; #normal retry
					1)break;; #do not retry, end. The close button.
					2)lbDevMode=true;; #retry in development mode (path)
					252)break;; #do not retry, end. Closed using the "window close" title button.
#					3)lbDevMode=true;lbEvalCode=true;; #retry in development mode (path)
#					4)lbDevMode=false;lbEvalCode=true;; #normal retry
				esac
				
#				if $lbEvalCode;then
#					local lstrCodeToEval="`zenity --entry \
#						--title "$SECstrScriptSelfName[$$]" \
#						--text "type code to eval b4 retry:\n$(SECFUNCparamsToEval "${astrRunParams[@]}")"`"&&:
#					echo "eval: $lstrCodeToEval" >>/dev/stderr
#					eval "$lstrCodeToEval"
#				fi
				if [[ -n "$strCodeToEval" ]];then
					eval "$strCodeToEval"
				fi
				
			else
				if ! zenity --question --title "$SECstrScriptSelfName[$$]" --text "$lstrTxt";then
					break;
				fi
			fi
		else
			break;
		fi
	done
	
	return $lnRet
};export -f FUNCrun

#if $bXterm;then
#	strTitle="${astrRunParams[@]}"
#	strTitle="`SECFUNCfixIdA -f "$strTitle"`"
#	SECFUNCarraysExport;SECFUNCexecA -ce xterm -title "$strTitle" -e 'bash -c "eval `secinit`:;FUNCrun"' >>/dev/stderr & disown # stdout must be redirected or the terminal wont let it be disowned...
#else
#	SECFUNCexecA -ce FUNCrun
#fi
#SECFUNCexecA -ce FUNCrun #>>/dev/stderr & disown # stdout must be redirected or the terminal wont let it be disowned...
if ! SECFUNCexecA -ce FUNCrun;then
	SECFUNCechoErrA "exited with error..."
fi
#nohup SECFUNCexecA -ce FUNCrun </dev/null >/dev/null 2>&1 & # completely detached from terminal 
#sleep 10

