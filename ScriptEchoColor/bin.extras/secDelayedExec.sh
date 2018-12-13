#!/bin/bash
# Copyright (C) 2013-2018 by Henrique Abdalla
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

astrOriginalOptions=( "$@" );export astrOriginalOptions

###################################################################
###################################################################
# THIS BELOW MUST BE BEFORE secinit!!!
if [[ "${1-}" == "--rc" ]];then #help ~exclusive if used, this option must be the FIRST option. It will grant .bashrc will be loaded previously to executing the command. Useful in case this project was installed for a single user only.
	shift
	export SECstrScriptSelfNameTmp="$0"
	function SECFUNCrcTmp() {
		echo "$FUNCNAME: $SECstrScriptSelfNameTmp $@" >&2
		$SECstrScriptSelfNameTmp "$@"
	};export -f SECFUNCrcTmp
#	echo "INFO: Granting .bashrc will be loaded previously to executing the command." >&2
	astrCmd=(bash -i -c 'SECFUNCrcTmp $0 "$@"' "$@"); #TODO shouldnt suffice this and also avoid '-i'?: bash --rcfile ~/.bashrc -c ...
	echo "Exec: ${astrCmd[@]}" >&2
	"${astrCmd[@]}"
	exit $?
fi
# THIS ABOVE MUST BE BEFORE secinit!!!
###################################################################
###################################################################

#source <(secinit --nochild --extras)
source <(secinit --extras)
export strExecGlobalLogFile="/tmp/.$SECstrScriptSelfName.`id -un`.log" #to be only used at FUNClog
#####################################
#####################################
# THIS BELOW MUST BE JUST AFTER secinit!!!
if [[ "${1-}" == "-G" || "${1-}" == "--getgloballogfile" ]];then #help ~exclusive
  #SECFUNCfdReport
  echo "$strExecGlobalLogFile" # no echo to stderr or stdout must happen before this! if running under nohup it is worse because both fd1 and fd2 will point to the same pipe!!! :(
  exit 0
fi
# THIS ABOVE MUST BE JUST AFTER secinit!!!
#####################################
#####################################

echo " SECstrRunLogFile='$SECstrRunLogFile'" >&2
echo " \$@='$@'" >&2

#strFullSelfCmd="`basename $0` $@"
export strFullSelfCmd="`ps --no-headers -o cmd -p $$`"
echo " strFullSelfCmd='$strFullSelfCmd'" >&2

SECFUNCcfgReadDB
echo " SECcfgFileName='$SECcfgFileName'" >&2

function FUNCcpuResourcesAvailable(){ #TODO use this to hold processes execution. create a queue manager and executor. each of this script call will be just a queue entry on the manager.
	local lstrCpusIdle="$(mpstat 2 1 |grep average -i |tr ' ' '\n' |tail -n 1)" #this takes 2 seconds
	local lstrLoadAvg="$(cat /proc/loadavg |cut -d' ' -f3)"
	local lfLoadLimit="($(nproc) -0.5)" #the number of enabled cores less 0.5f
	lobal lnRetBC="`bc <<< "($lstrLoadAvg < $lfLoadLimit) && ($lstrCpusIdle > 25.0)"`" 
	if ! `exit $lnRetBC`;then #bc outputs 1 on success and 0 on failure, so invert the return status
		return 0;
	fi 
	
	return 1
}
#TODO if ! `exit $(bc <<< "($(cat /proc/loadavg |cut -d' ' -f3) < 3.5) && ($(mpstat 2 1 |grep average -i |tr ' ' '\n' |tail -n 1) > 25.0)")`;then echo ok;fi

#ls -l --color=always "/proc/$$/fd" >&2

: ${CFGbUseSequentialScript:=false} 
export CFGbUseSequentialScript #help if true, this will allow use the sequential script

: ${SECCFGbOverrideRunAllNow:=false} 
export SECCFGbOverrideRunAllNow #help if false, this grants startup always obbeying sleep. Set to 'true' to skip sleep delays of all tasks, and exit.

: ${SECCFGbOverrideRunThisNow:=false} 
export SECCFGbOverrideRunThisNow #help if true will ignore wait and sleep options

SECFUNCcfgWriteVar SECCFGbOverrideRunAllNow=false # override WRITE to grant it will work properly on next boot w/o using an old cfg value from the cfg file TODO deprecate all this work and use sequential mode (other script)
varset bCheckPointConditionsMet=false
export bWaitCheckPoint=false
export nDelayAtLoops=1
export bCheckPointDaemon=false
export bCheckIfAlreadyRunning=true
export nSleepFor=0
export bListAlreadyRunningAndNew=false
export bListIniCommands=false
export bStay=false
export bStayForce=false
export strEvalStayForce=""
export bListWaiting=false
export bCheckPointDaemonHold=false
export bRunAllNow=false
export bRespectedSleep=false
export bXterm=false
export strCheckPointCustomCmd
export bEnableSECWarnMessages=false #initially false to not mess output
export bCleanSECenv=true;
#~ export bGetGlobalLogFile=false;
export nAutoRetryDelay=-1
export bAutoRetryAlways=false
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
export astrXtermOpts=()
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "[options] <command> [command params]..."
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--SequentialCfg" ]];then #help will not execute anything, it is just to let the sequential script use this command as reference, only if CFGbUseSequentialScript=true
    if $CFGbUseSequentialScript;then exit 0;fi #as fast as possible
	elif [[ "$1" == "-s" || "$1" == "--sleep" ]];then #help <nSleepFor> seconds before executing the command with its params, can be like 00010 00120, will be considered as decimal, and is good for sorting
		shift
		nSleepFor="$((10#${1-}))" # make it sure the number will be in decimal
	elif [[ "$1" == "-r" || "$1" == "--respectedsleep" ]];then #help with this, sleep delay will be respected and SECCFGbOverrideRunAllNow will be ignored.
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
	elif [[ "$1" == "-w" || "$1" == "--waitcheckpoint" ]];then #help ~loop after nSleepFor, also waits checkpoint tmp file to be removed
		bWaitCheckPoint=true
	elif [[ "$1" == "--nounique" ]];then #help skip checking if this exactly same command is already running, otherwise, will wait the other command to end
		bCheckIfAlreadyRunning=false
	elif [[ "$1" == "-d" || "$1" == "--shouldnotexit" ]];then #help ~daemon indicated that the command should not exit normally (it should stay running like a daemon), if it does, it logs 'Sne' (Should not exit)
		bStay=true
	elif [[ "$1" == "-D" || "$1" == "--checkstillrunning" ]];then #help ~daemon <strEvalStayForce> like -d but as the app will detach itself, this grants it will be re-run if it exits.  strEvalStayForce will be run to test if it is still running ex.: 'qdbus |grep SomeAppCommand'
    shift;strEvalStayForce="$1"
		bStayForce=true
	elif [[ "$1" == "--autoretry" ]];then #help <nAutoRetryDelay> for the daemon mode, if the command exits with error, will auto retry after delay if it is >= 0
    shift
		nAutoRetryDelay="${1-}"
	elif [[ "$1" == "--autoretryalways" ]];then #help <nAutoRetryDelay> for the daemon mode, if the command exits BY ANY REASON, will auto retry after delay if it is >= 0
    shift
		nAutoRetryDelay="${1-}"
    bAutoRetryAlways=true
	elif [[ "$1" == "--listconcurrent" ]];then #help list pids that are already running and new pids trying to run the same command
		bListAlreadyRunningAndNew=true
	elif [[ "$1" == "--listcmdsini" ]];then #help list commands that entered (ini) the log file
		bListIniCommands=true
	elif [[ "$1" == "--listwaiting" ]];then #help list commands that entered (ini) the log file but havent RUN yet
		bListWaiting=true
	elif [[ "$1" == "-x" || "$1" == "--xterm" ]];then #help use xterm (tho prefers mrxvt if installed) to run the command
		bXterm=true
	#~ elif [[ "$1" == "-G" || "$1" == "--getgloballogfile" ]];then #help 
		#~ bGetGlobalLogFile=true
	elif [[ "$1" == "-O" || "$1" == "--order" ]];then #help <NUMBER> dummy option and dummy "required" parameter (ex.: 00023). Only used to easily sort all the commands being run by this script
		:
	elif [[ "$1" == "--xtermopts" ]];then #help "<astrXtermOpts>" options to xterm like background color etc.
		shift
		astrXtermOpts=(${1-})
	elif [[ "$1" == "--runallnow" ]];then #help <bRunAllNow> set to 'true' to skip sleep delays of all tasks, and exit.
		shift
		varset bRunAllNow=true;varset bRunAllNow="${1-}" #this is fake, just to easy (lazy me) validate boolean... cfg vars should use the same as vars code... onde day..
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		SECFUNCechoErrA "invalid option '$1'" >&2
		exit 1
	fi
	shift&&:
done

export strItIsAlreadyRunning="IT IS ALREADY RUNNING"

#if $bGetGlobalLogFile;then
##  (
#    #~ SECFUNCfdReport
#    #~ SECFUNCfdRestoreOrBkp --bkp
#    #~ SECFUNCfdReport
#    #~ SECFUNCrestoreDefaultOutputs;
#    #~ SECFUNCfdReport
#    
#    #~ SECFUNCfdReport
#    #~ SECFUNCfdBkp
#    #~ SECFUNCfdReport
#    #~ SECFUNCfdRestore
#    SECFUNCfdReport
#    echo "$strExecGlobalLogFile"
#    #~ SECFUNCfdReport
##  )
#  exit 0
#fi

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
		*) SECFUNCechoErrA "invalid lstrType='$lstrType'" >&2;
			 _SECFUNCcriticalForceExit;;
	esac
	
	if [[ "$lstrType" == "wrn" ]];then
		SEC_WARN=true SECFUNCechoWarnA "$lstrLogging"
	fi
	case "$lstrType" in "Err"|"Sne")
		SECFUNCechoErrA "$lstrLogging";;
	esac
	
	echo "$lstrLogging" >&2
	echo "$lstrLogging" >>"$strExecGlobalLogFile"
};export -f FUNClog

if $bListWaiting;then
	FUNCcheckIfWaitCmdsHaveRun&&:
	#echo "returned $?"
	exit 0
fi

if $bCheckPointDaemon;then
	echo "see Global Exec log for '`id -un`' at: $strExecGlobalLogFile" >&2
	
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
						if yad --question --title "$strTitle" --text "allow waiting instances to be run?";then
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

if $bWaitCheckPoint && ! $SECCFGbOverrideRunThisNow;then
	SECFUNCdelay bWaitCheckPoint --init
	nPidDaemon=-1
	strFileUnique="`SECFUNCuniqueLock --getuniquefile`"
	while true;do
		echo -e "$SECstrScriptSelfName: waiting checkpoint be activated at daemon (`SECFUNCdelay bWaitCheckPoint --getsec`s)..."

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
	
  if $SECCFGbOverrideRunThisNow;then return 0;fi
  
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
		
		echo "sleep ${lnSleepStep}s remaining ${lnSleepFor}s tot ${nSleepFor}s"
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
		#echo "$$,${anPidList[@]}" >&2
		if anPidOther=(`echo "${anPidList[@]-}" |tr ' ' '\n' |grep -vw $$`);then #has not other pids than self
			#echo " anPidOther[@]=(${anPidOther[@]})" >&2
			bFound=false
			if((`SECFUNCarraySize anPidOther`>0));then
				for nPidOther in ${anPidOther[@]};do
					#echo "\"^ RUN -> .*;pid='$nPidOther';\"" >&2
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
			if echoc -q -t 10 "kill the nPidOther='$nPidOther' that is still running?";then
				if [[ -d "/proc/$nPidOther" ]];then
					bKillOther=true
				else
					echoc --info "no nPidOther='$nPidOther'"
				fi
			fi
		else
			strTitle="$SECstrScriptSelfName[$$], multiple instances running."
			SECFUNCCwindowOnTop "$strTitle"
      bKillOther=false
      bOtherExited=false
      while true;do
        nTot=10;for((i=0;i<nTot;i++));do echo $((i*(100/nTot)));sleep 1;done \
          |yad --auto-close --progress ----percentage=0 --question --title "$strTitle" \
            --text "$strFullSelfCmd\n\nnPidSelf=$$;\nKILL THE OTHER PID nPidOther='$nPidOther'?" \
            --button="OK:2" \
            --button="Cancel:1" &&:;nRet=$?
        case $nRet in
          2)bKillOther=true;break;;
          1)break;;
          0)
            if [[ ! -d "/proc/$nPidOther" ]];then
              bOtherExited=true
            fi
            ;; # timed out
        esac
        #~ yad --timeout 10 --question --title "$strTitle" --text "$strFullSelfCmd\n\nnPidSelf=$$;\nKILL THE OTHER PID nPidOther='$nPidOther'?"&&:;nRet=$?
        #~ case $nRet in
          #~ 0)bKillOther=true;break;;
          #~ 1)break;;
          #~ 70)
            #~ if [[ ! -d "/proc/$nPidOther" ]];then
              #~ bOtherExited=true
            #~ fi
            #~ ;; # timed out
        #~ esac
      done
			#~ if yad --timeout 10 --question --title "$strTitle" --text "$strFullSelfCmd\n\nnPidSelf=$$;\nKILL THE OTHER PID nPidOther='$nPidOther'?";then
				#~ bKillOther=true
      #~ else
      if ! $bOtherExited && ! $bKillOther;then
        if yad --question --title "$strTitle" --text "$strFullSelfCmd\n\nnPidSelf=$$;\nThe other pid will continue running nPidOther='$nPidOther'.\n DO EXIT THIS ONE?";then
          exit 0
        fi
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
declare -p astrRunParams
function FUNCrun(){
#	source <(secinit)
#	SECFUNCarraysRestore
	nRunTimes=0
	local lbDevMode=false
 	local lbRestartSelfFullDev=false
  
  local lastrRestart=()
  lastrRestart+=(secTerm.sh -- -e)
  lastrRestart+=(secEnvDev.sh --exit)
  lastrRestart+=(secNoHup.sh)
  lastrRestart+=(eval "export SECCFGbOverrideRunThisNow=true" "&&") # only works with eval, otherwise could try appending --cfg to this script options
  lastrRestart+=("`basename "$0"`" "${astrOriginalOptions[@]}") #astrRestart+=(secDelayedExecSequential.sh --filter "${astrRunParams[0]}")
  
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
    export SEC_WARN=$bEnableSECWarnMessages
		function FUNCrunAtom(){
      declare -p astrRunParams&&:
			source <(secinit) #this will apply the exported arrays
      declare -p astrRunParams&&:
      
			# also, this command: `env -i bash -c "\`SECFUNCparamsToEval "$@"\`"` did not fully work as vars like TERM have not required value (despite this is expected)
			# nothing related to SEC will run after SECFUNCcleanEnvironment unless if reinitialized
			( SECbRunLog=true SECFUNCcheckActivateRunLog -v; #forced log!
        declare -p astrRunParams&&:
      
        evalCleanEnv=":";
        if $bCleanSECenv;then
          evalCleanEnv="SECFUNCcleanEnvironment;" #all SEC environment will be cleared TODO explain why this is important/useful!?
        fi
        eval "$evalCleanEnv" # TODO this way prevents problems caused if being called inside the 'if' block?
        declare -p astrRunParams&&:
        
        evalSECWarn=":"
        if ! $bCleanSECenv;then # with SEC env cleaned, SEC_WARN shouldnt be there too
          evalSECWarn="export SEC_WARN=$bEnableSECWarnMessages"
        fi
        eval "$evalSECWarn"
        
				#"$@";
				declare -p PATH >&2
				echo "$FUNCNAME Running Command: ${astrRunParams[@]-}"
#        anSPidB4=(`ps --no-headers -o pid --sid $$`)
        #yad --info --text "$0:$LINENO"
				#~ "${astrRunParams[@]}"
#        anSPidAfter=(`ps --no-headers -o pid --sid $$`)
        if $bStayForce;then
          strInfoSF="${astrRunParams[@]-} #strEvalStayForce='$strEvalStayForce'"
          if eval "$strEvalStayForce";then
            echo "Already running: $strInfoSF"
          else
            echo "astrRunParams='${astrRunParams[@]-}' $LINENO"
            "${astrRunParams[@]}"
            while ! eval "$strEvalStayForce";do
              echo "Wating it start: $strInfoSF"
            done
          fi
          
          while true;do
            if ! eval "$strEvalStayForce";then break;fi
#            anPGrep=(`pgrep -fx "^${astrRunParams[@]}$"`)
            echo "Still running: $strInfoSF"
            sleep 5
          done
        else
          echo "astrRunParams='${astrRunParams[@]-}' $LINENO"
          "${astrRunParams[@]}"
        fi
			)&&:;local lnRetAtom=$?
			echo "$lnRetAtom" >"$strFileRetVal";
		};export -f FUNCrunAtom
		
		astrCmdToRun=(bash -c)
		if $lbDevMode;then
			astrCmdToRun=(secEnvDev.sh --exit)
		fi
		astrCmdToRun+=(FUNCrunAtom)
		
		SECFUNCarraysExport
		if $bXterm;then
			astrTmpTitle=("${astrRunParams[@]}")
			astrTmpTitle[0]="`basename "${astrTmpTitle[0]}"`"
			strTitle="${astrTmpTitle[@]}_pid$$"
			strTitle="`SECFUNCfixIdA -f -- "$strTitle"`"
			strTitle="`echo "$strTitle" |sed -r 's"(_)+"\1"g'`" #sed removes duplicated '_'
      
			if [[ "$TERM" != "dumb" ]];then
				echoc --info "if on a terminal, to detach this from xterm, do not hit ctrl+C, simply close this one and xterm will keep running..."&&:
			fi
      declare -p TERM
      #aCmdTerm=(xterm)
      #if which mrxvt >/dev/null 2>&1;then aCmdTerm=(mrxvt -aht +showmenu);fi # rxvt does not kill child proccesses when it is closed but mrxvt does!
      #SECFUNCexecA -ce "${aCmdTerm[@]}" -sl 1000 -title "$strTitle" ${astrXtermOpts[@]-} -e "${astrCmdToRun[@]}"
      SECFUNCexecA -ce secTerm.sh -- -sl 1000 -title "$strTitle" ${astrXtermOpts[@]-} -e "${astrCmdToRun[@]}"
		else
#			declare -p astrRunParams
			SECFUNCexecA -ce "${astrCmdToRun[@]}" #1>/dev/stdout 2>/dev/stderr
		fi		
		local lnRet=$(cat "$strFileRetVal");rm "$strFileRetVal"
		
		# BEWARE! `yad --version` returns 252!!!!!!! bYad=false;if SECFUNCexecA -ce yad --version;then bYad=true;fi
		bYad=false;if which yad;then bYad=true;fi
			
		local lbErr=false
		local lstrTxt=""
		if $bStay || $bStayForce;then
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
		fi
		
    astrYadBasicOpts=(
      --title "SDE(${astrRunParams[0]}) - $SECstrScriptSelfName[$$]" 
      --separator="\n"
      --sticky
      --center
      --selectable-labels
    )
    
    if ( $lbErr || $bAutoRetryAlways ) && ((nAutoRetryDelay>=0));then
      strRetryMsg=""
      strRetryMsg+="Daemon Stopped, command:\n"
      strRetryMsg+="${astrRunParams[@]}\n"
      strRetryMsg+="\n"
      strRetryMsg+="Exited with error $lnRet\n"
      strRetryMsg+="\n"
      strRetryMsg+="Click OK or close this dialog to open the detailed retry dialog instead."
      strRetryMsg+="\n"
      
      nStep=$((100/nAutoRetryDelay));
      (
        i=0;
        while true;do 
          if((i<100));then echo $i;fi; 
          sleep 1; 
          ((i+=nStep))&&:; 
          if((i>=100));then echo 99.9;sleep 1;break;fi; # --auto-close will make yad exit on 100, so this looks better at least
        done
      ) | yad "${astrYadBasicOpts[@]}" --auto-close --button="OK - Just Retry Now:0" --text="$strRetryMsg" --progress ----percentage=0;nYadRetryRet=$?
#      ) | yad "${astrYadBasicOpts[@]}" --auto-close --progress-text="$strRetryMsg" --progress ----percentage=0;nYadRetryRet=$?
        
        if((nYadRetryRet==0));then continue;fi
    fi
    
		if $bStay || $bStayForce;then
			FUNClog Sne "Should not have exited..."
		fi
		
		# end Log
		FUNClog end "RunDelay=`SECFUNCdelay RUN --getpretty`"
		
    strDumpRetryBtnTxt="dump;retry"
    
    strRetryFull="RetrySelfFull-DEV"
		if $bStay || $bStayForce || $lbErr;then
			lstrTxt+="QUESTION:\n";
			lstrTxt+="\tDo you want to try to run it again?\n";
			lstrTxt+="\n";
			lstrTxt+="button Retry, simple run command (the simple DEV mode just prepends secEnvDev.sh):\n"
			lstrTxt+="\t`SECFUNCparamsToEval "${astrRunParams[@]}"` #astrRunParams[@]\n";
			lstrTxt+="\n";
			lstrTxt+="button ${strRetryFull}, full restart everything possible in dev mode:\n"
			lstrTxt+="\t`SECFUNCparamsToEval "${lastrRestart[@]}"` #lastrRestart[@]\n";
			lstrTxt+="\n";
			lstrTxt+="SequentialHelper:\n"
			lstrTxt+="\tsecDelayedExecSequential.sh --filter \"${astrRunParams[0]}\"\n";
			lstrTxt+="\n";
			lstrTxt+="At: `SECFUNCdtFmt --pretty`\n";
			lstrTxt+="\n";
			lstrTxt+="LogInfoDbgCmd(try '$strDumpRetryBtnTxt' button):\n";
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
			
			echo ">>>$LINENO"
			if $bYad;then 
        bEnableSECWarnMessages=true #the 1st time a problem happens, set to true to help on retries debugging
        bCleanSECenv=false #the 1st time a problem happens, set to false to help on retries debugging
				local lbEvalCode=false
				sedClearArrayIndexes="s@\[[[:digit:]]*\]=\"@\"@g"
				strCodeToEval=":;"
				strCodeToEval+="`declare -p astrRunParams |sed -r "$sedClearArrayIndexes"`;"
				# annoying: --on-top
				# the first button will be the default when hitting Enter...
				astrYadFields=(
					bXterm #0
					strCodeToEval #1
          bEnableSECWarnMessages #2
          bCleanSECenv #3
				);declare -p astrYadFields
        astrYadExecParams=(
          "${astrYadBasicOpts[@]}"
          
          --button="Retry:4" # ATTENTION!!! exit VALUES are NOT in order!!!!!
          --button="Retry-DEV:2"
          --button="${strRetryFull}:5"
          --button="${strDumpRetryBtnTxt}:3" 
          --button="gtk-close:1" 
          
          --form 
          --field "[${astrYadFields[0]}] Use Xterm:chk" 
          --field "[${astrYadFields[1]}] b4 run" 
          --field "[${astrYadFields[2]}] :chk" 
          --field "[${astrYadFields[3]}] disabled helps with SEC scripts:chk" 
          --field "info:TXT" # the editable text field is MUCH better than the --text label, it has scroll bar, fixed width in pixels to the window size, 3 click selectable line, everything is better for big texts!
          "${!astrYadFields[0]}" # redirected values
          "${!astrYadFields[1]}" 
          "${!astrYadFields[2]}" 
          "${!astrYadFields[3]}" 
          "$lstrTxt" # options to be captured put above info text dummy (changes are ignored) field
        )
        declare -p astrYadExecParams
        strYadOutput="`SECFUNCexecA -ce yad "${astrYadExecParams[@]}"`"&&:;nRet=$? #astrYadFields entries values will be used to set the default of the yad fields (like the checkbox, the text field etc) !!! :D
	#						--field "[${astrYadFields[1]}] (use '\x7C' instead of '|')" 
	#			IFS=$'\n' read -d '|' -r -a astrYadReturnValues < <(echo "$strYadOutput")&&:
				IFS=$'\n' read -d '' -r -a astrYadReturnValues < <(echo "$strYadOutput")&&:
				declare -p astrYadReturnValues
				if((`SECFUNCarraySize astrYadReturnValues`>0));then
					if [[ "${astrYadReturnValues[0]}" == "TRUE" ]];then bXterm=true;else bXterm=false;fi
					strCodeToEval="${astrYadReturnValues[1]}"
					if [[ "${astrYadReturnValues[2]}" == "TRUE" ]];then bEnableSECWarnMessages=true;else bEnableSECWarnMessages=false;fi 
					if [[ "${astrYadReturnValues[3]}" == "TRUE" ]];then bCleanSECenv=true;else bCleanSECenv=false;fi 
					#bCleanSECenv="`echo ${astrYadReturnValues[3]} |tr "[:upper:]" "[:lower:]"`"
	#					strCodeToEval="`echo "$strCodeToEval" |sed -r 's"[\]x7[Cc]"|"g'`"
				fi
        echoc --info "nRet='$nRet'"
				case $nRet in 
					1)break;; #do not retry, end. The close button.
					2)lbDevMode=true;; #retry in development mode (path)
					3)xterm -maximized -e "secMaintenanceDaemon.sh --dump $$;SECFUNCdrawLine;echo 'astrRunParams: ${astrRunParams[@]}';SECFUNCdrawLine;bash";;
					4)lbDevMode=false;; #normal retry
					5)lbRestartSelfFullDev=true;break;; #retry in development mode (path)
					252)break;; #do not retry, end. Closed using the "window close" title button.
          *)
            SECFUNCechoErrA "unsupported yad return value nRet='$nRet'"
            _SECFUNCcriticalForceExit
            ;;
	#					3)lbDevMode=true;lbEvalCode=true;; #retry in development mode (path)
	#					4)lbDevMode=false;lbEvalCode=true;; #normal retry
				esac
				
	#				if $lbEvalCode;then
	#					local lstrCodeToEval="`yad --entry \
	#						--title "$SECstrScriptSelfName[$$]" \
	#						--text "type code to eval b4 retry:\n$(SECFUNCparamsToEval "${astrRunParams[@]}")"`"&&:
	#					echo "eval: $lstrCodeToEval" >&2
	#					eval "$lstrCodeToEval"
	#				fi
				#~ if [[ -n "$strCodeToEval" ]];then
					#~ eval "$strCodeToEval"
				#~ fi
				eval "$strCodeToEval" # empty eval causes no trouble, TODO may help with some commands if outside 'if' block?
			else
				lstrTxt+="Obs.: Developer options if you install \`yad\`.\n";
				lstrTxt+="\n";
				if ! yad --question --title "$SECstrScriptSelfName[$$]" --text "$lstrTxt";then
					break;
				fi
			fi
		else
			break;
		fi
	done
  
  if $lbRestartSelfFullDev;then
    SECFUNCexecA -ce "${lastrRestart[@]}"
  fi
	
	return $lnRet
};export -f FUNCrun

#if $bXterm;then
#	strTitle="${astrRunParams[@]}"
#	strTitle="`SECFUNCfixIdA -f -- "$strTitle"`"
#	SECFUNCarraysExport;SECFUNCexecA -ce xterm -title "$strTitle" -e 'bash -c "source <(secinit):;FUNCrun"' >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
#else
#	SECFUNCexecA -ce FUNCrun
#fi
#SECFUNCexecA -ce FUNCrun #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
if ! SECFUNCexecA -ce FUNCrun;then
	SECFUNCechoErrA "exited with error..."
fi
#nohup SECFUNCexecA -ce FUNCrun </dev/null >/dev/null 2>&1 & # completely detached from terminal 
#sleep 10

