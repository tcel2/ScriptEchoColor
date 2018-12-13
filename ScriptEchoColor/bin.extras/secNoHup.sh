#!/bin/bash
# Copyright (C) 2018 by Henrique Abdalla
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

echoc -c

# initializations and functions

#TODO how to make this script use overall a single bash pid?
echoc --alert "TODO: @-n This should use as little rss mem as possible see: ps -o ppid,pid,rss,cmd --forest -p \`pgrep -f secNoHup\`"

strFCN=""
if secEnvDev.sh --isdevmode;then
  strFCN="_DEV"
fi

strDaemonId="`SECFUNCfixId --justfix "$(basename "$0")"`"
strDaemonId+="$strFCN"

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bDaemon=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
astrCmdToRun=()
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t[astrCmdToRun] with params if required"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	#~ elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		#~ shift
		#~ strExample="${1-}"
	elif [[ "$1" == "--daemon" ]];then #help ~single
		bDaemon=true
	elif [[ "$1" == "--stopdaemon" ]];then #help ~single mainly for debug, all child pids may also stop running
    SECFUNCexecA -ce kill -SIGUSR2 `SECFUNCuniqueLock --id $strDaemonId --getdaemonpid`
    $0 : #this will the `cat` return and let the loop continue running once
    exit 0
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
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
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code ###################################################
SEC_WARN=true

declare -p SECstrRunLogFile
echoc --info "This Pid = $$"

astrCmdToRun=("$@")
#~ declare -p astrCmdToRun
#~ if((`SECFUNCarraySize astrRemainingParams`>0));then
  #~ astrCmdToRun=("${astrRemainingParams[@]}") #astrCmdToRun=("$@") TODO could fill with empty?
#~ fi

strScId="$(SECFUNCscriptNameAsId)"

strFifoFl="`SECFUNCcreateFIFO $strFCN`"

if $bDaemon;then
  declare -p bDaemon
  if SECFUNCexecA -ce SECFUNCuniqueLock --id $strDaemonId --isdaemonrunning;then
    SECFUNCechoWarnA "daemon already running pid = `SECFUNCuniqueLock --id $strDaemonId --getdaemonpid`"
    exit 0
  else
    : ${SECNoHupDaemonDetach:=false}
    declare -p SECNoHupDaemonDetach
    if ! $SECNoHupDaemonDetach;then
      ( export SECNoHupDaemonDetach=true; SECFUNCexecA -ce secTerm.sh -- -title "Daemon${strFCN}:${strScId}" -e $0 --daemon & disown ) #TODO remove secTerm.sh when this is working well...
      exit 0
    fi
  fi
  
  SECFUNCexecA -ce SECFUNCuniqueLock --id $strDaemonId --waitbecomedaemon
  
  echoc --info "starting $0 daemon pid $$"
  
  strTrap="" #TODO why ctrl+c wont fall on the SIGINT trap????
  trap 'strTrap="SIGINT"'  SIGINT
  trap 'strTrap="SIGHUP"'  SIGHUP
  trap 'strTrap="SIGQUIT"' SIGQUIT
  trap 'strTrap="SIGABRT"' SIGABRT #TODO this works?
  trap 'strTrap="SIGKILL"' SIGKILL #TODO didnt work, why?
  trap 'strTrap="SIGTERM"' SIGTERM
  trap 'strTrap="SIGSTOP"' SIGSTOP # prevent suspending new requests TODO why?
  trap 'strTrap="SIGUSR1"' SIGUSR1 # may be useful
  trap 'strTrap="SIGUSR2"' SIGUSR2 # may be useful
  #TODO anything else?
  
  #declare -a astrCmdRequest
  #astrCmdRequest=()
  #astrCmdRqList=()
  while true;do
    if [[ -n "$strTrap" ]];then
      if [[ "$strTrap" == "SIGUSR1" ]];then
        SECFUNCechoWarnA "$strTrap: #TODO something useful"
        strTrap=""
      fi
      if [[ "$strTrap" == "SIGUSR2" ]];then
        SECFUNCechoWarnA "$strTrap: force quitting, mainly to help on restarting a development version"
        exit 0
      fi
    
      if [[ -n "$strTrap" ]];then
        SECFUNCechoWarnA "$strTrap: won't quit or some pseudo-child pid may exit..." # pseudo-child as despite the pid is already ofphaned it may still have some relation with this pid in some way TODO how? what way it keeps that relation?
      fi
      strTrap=""
    fi
    
    #(sleep 10;while true;do ps --ppid $$ |egrep "cat.*${strFifoFl}";sleep 1;done)&
    #IFS=$'\n' read -d '' -r -a astrCmdRequest <"$strFifoFl" &&:
    strSrcExecAll="`cat <"$strFifoFl"`" # this will WAIT until somthing is written to the PIPE!!!
    if [[ -n "$strSrcExecAll" ]];then
      echo "$strSrcExecAll" |while read strSrcExec;do
      #if((`SECFUNCarraySize astrCmdRequest`>0));then
        #TODO to control this daemon, special comments can become commands here ex.: "#SECNoHup:speakCmds"
        #astrCmdRqList+=("$strCmdRequest")
        #strLog="EXEC@`SECFUNCdtFmt --logmessages`: `declare -p astrCmdRequest`"
        strLog="EXEC@`SECFUNCdtFmt --logmessages`: `declare -p strSrcExec`"
        echo "$strLog"
        echo "$strLog" >>"$SECstrRunLogFile"
  #      echo "$strLog" |tee -a "$SECstrRunLogFile"
        #( "${astrCmdRequest[@]}" & ) # will reparent to init or the like
#        ( eval "$strSrcExec"; "${astrCmdToRun[@]}"& )&&: # this trick will reparent to init or the like
        ( eval "$strSrcExec"; "${astrCmdToRun[@]}" & disown )&disown &&: # this trick will reparent to init or the like and grant disown!
      done
    fi
  done
  SECFUNCechoErrA "should not have reached here!"
  exit 1
fi

if ! SECFUNCuniqueLock --id $strDaemonId --isdaemonrunning;then
  #(SECFUNCexecA -ce $0 --daemon & disown)
  SECFUNCexecA -ce $0 --daemon
  while true;do
    if((`SECFUNCuniqueLock --id $strDaemonId --getdaemonpid&&:`!=0));then
      break;
    else
      echoc -w -t 3 "waiting daemon start"
    fi
  done
fi

if((`SECFUNCarraySize astrCmdToRun`==0));then
#~ if [[ -z "${astrCmdToRun[@]-}" ]];then
  SECFUNCechoErrA "command required."
  exit 1
fi

nDPid="`SECFUNCuniqueLock --id $strDaemonId --getdaemonpid`"&&:
declare -p nDPid&&:
echoc --info "daemon pid = $nDPid, file '`SECFUNCuniqueLock --id $strDaemonId --getuniquefile`'"

#echo "${astrCmdToRun[@]}" >>"$strFifoFl"
echo "SENDINGCOMMAND: `declare -p astrCmdToRun`"
declare -p astrCmdToRun >>"$strFifoFl" # will only return after it is read!
echo "SENT."
#echoc -w -t 60

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
