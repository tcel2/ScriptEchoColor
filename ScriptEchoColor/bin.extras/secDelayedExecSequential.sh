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

: ${CFGnTstCmdRepeatCount:=8000}
export CFGnTstCmdRepeatCount; #help

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script

: ${bChkSimpleTest:=false}
export bChkSimpleTest #help

: ${bChkCpuLoad:=false}
export bChkCpuLoad #help

export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
nFreeCpuPercToAllow=25
strFilter=""
bListOnly=false
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
	elif [[ "$1" == "-f" || "$1" == "--filter" ]];then #help <strFilter> do the work only if entry matches regex filter
    shift
		strFilter="${1-}"
    declare -p strFilter
	elif [[ "$1" == "-l" || "$1" == "--listonly" ]];then #help do the work only if entry matches regex filter
		bListOnly=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help MISSING DESCRIPTION
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

# Main code
nCores="`grep "core id" /proc/cpuinfo |wc -l`"
#nMax=$((nCores==1?1:nCores-1));

function FUNCchkCanRunNext() {
  SECFUNCdelay testSpeed --init;
  
  echo "Simple test" #TODO is useful?
#  for((i=0;i<CFGnTstCmdRepeatCount;i++));do echo -ne "testSpeed\r";done;
  for((i=0;i<CFGnTstCmdRepeatCount;i++));do echo -ne "testSpeed" >/dev/null;done;
  if SECFUNCdelay testSpeed --checkorinit 1;then return 1;fi  # if the speed test is executed in less than 1 second, there is system resources available to execute next command
  echo ok
  
  #~ strPercCpuAllCores="`ps --no-headers -o pcpu -A |tr '\n' + |tr -d ' ' |awk '{print $1 0}' |bc`"
  #~ echo "CPU usage: $strPercCpuAllCores"
  #~ if((nCores>1)) && SECFUNCbcPrettyCalc --cmpquiet "$strPercCpuAllCores>$((100*(nCores-1)))";then return 1;fi
  #~ if((nCores==1)) && SECFUNCbcPrettyCalc --cmpquiet "$strPercCpuAllCores>50";then return 1;fi # 50%
  #~ echo ok
  
  ######## this test may be enough as it is based on lack of cpu iddleness! :D
  nPercCpuTimeSpendIddle="`vmstat 1 2|tail -n 1|awk '{print $15}'`"; # this will spend 2 seconds!!!
  nAllCoresCpuUsage=$((100-$nPercCpuTimeSpendIddle));
  echo "CPU usage: $nAllCoresCpuUsage"
  if((nAllCoresCpuUsage>(100-nFreeCpuPercToAllow)));then return 1;fi
  echo ok
  
  if $bChkCpuLoad;then
    strRecentLoadAvg="`cat /proc/loadavg |awk '{print $1}'`"
    echo "CPU loadavg: $strRecentLoadAvg"
    if SECFUNCbcPrettyCalc --cmpquiet "$strRecentLoadAvg>$((nCores))";then return 1;fi
    echo ok
  fi
  
  return 0
}

#strDEG="`secDelayedExec.sh --getgloballogfile`"
cd $HOME/.config/autostart/

########## autostart cfg files
IFS=$'\n' read -d '' -r -a astrFileList < <(grep enabled=true * |cut -d: -f1)&&:

########## autostart commands
IFS=$'\n' read -d '' -r -a astrCmdList < <(grep "Exec=" -h "${astrFileList[@]}" -h |sed 's"^Exec=""' |sort)&&:
#declare -p astrCmdList |tr '[' '\n'

########## prepare list to be ordered
sedGetSleepTime="s'.*-s ([[:digit:]]*) .*'\1'"
astrCmdListToSort=()
for strCmd in "${astrCmdList[@]}";do
  nIndex=$((10#`echo "$strCmd" |sed -r "$sedGetSleepTime"`));
  astrCmdListToSort+=("$nIndex $strCmd")
done
#declare -p astrCmdListToSort |tr '[' '\n'
 
########## order the list
sedRmOrderDigits='s"^[[:digit:]]* ""'
sedRmSeqCfgOpt='s" --SequentialCfg " "'
astrCmdListOrdered=()
IFS=$'\n' read -d '' -r -a astrCmdListOrdered < <(for strSCmd in "${astrCmdListToSort[@]}";do echo "$strSCmd";done |sort -n |sed -r -e "$sedRmOrderDigits" -e "$sedRmSeqCfgOpt")&&:
declare -p astrCmdListOrdered |tr '[' '\n'

if $bListOnly;then exit 0;fi

########## run the commands
echoc --info "running commands sequentially as the system allows it if not encumbered"
#SECbExecJustEcho=false
export SECCFGbOverrideRunThisNow=true
iCount=0
for strCmd in "${astrCmdListOrdered[@]}";do
  SECFUNCdrawLine #--left "$strCmd"
  
  echo "Cmd: $strCmd"
  if [[ -n "$strFilter" ]] && ! [[ "$strCmd" =~ $strFilter ]];then echo skip;continue;fi
  
  while ! FUNCchkCanRunNext;do
    echoc -w -t 5 "wait cpu free up a bit"
#    if echoc -q -t 5 "wait cpu free up a bit or run it now?";then
    #~ if echoc -q -t 5 "ignore cpu load?";then
      #~ bChkCpuLoad=false
      #~ break;
    #~ fi
  done # check cpu
  
  #SECFUNCexecA -cj $strCmd & echo pid=$!
  echo "Cmd$((iCount++))/${#astrCmdListOrdered[@]}: $strCmd"
  
  #~ export strCmd
  #~ function FUNCrun() {
    #~ #eval "nohup $strCmd" & disown
    #~ eval "$strCmd" & disown
    #~ echo "cmdPid=$! #$strCmd"
    #~ echoc -w -t 5 "do not close too fast"
    #~ return 0
  #~ };export -f FUNCrun
  #~ secXtermDetached.sh --nohup FUNCrun&&:
  
  ######
  ### strCmd needs eval TODO find other way?
  ######
#  (
#    exec >>/dev/stderr 2>&1
#    eval $strCmd >>/dev/stderr 2>&1 & disown # stdout must be redirected or the terminal wont let it be disowned, >&2 will NOT work either, must be to /dev/stderr


#AlmostOK#   eval $strCmd >/dev/null 2>&1 & disown # /dev/null prevents messing this log

#~ #    ps -o ppid,pid,cmd -p $$
    #~ (eval $strCmd >/dev/null 2>&1 & disown)&disown;nSubShellPid=$! # /dev/null prevents messing this log
#~ #    ps -o ppid,pid,cmd -p $nSubShellPid
    #~ SECFUNCexecA -ce ps -A --forest -o ppid,pid,cmd |grep --color=always "${nSubShellPid}" -C 10&&:
    #~ eval "strCmdDbgTmp='$strCmd'"
    #~ SECFUNCexecA -ce ps -A --forest -o ppid,pid,cmd |grep --color=always "$strCmd" -C 10&&:
    #~ SECFUNCexecA -ce ps -A --forest -o ppid,pid,cmd |grep --color=always "$strCmdDbgTmp" -C 10&&:
#~ #    SECFUNCexecA -ce kill $nSubShellPid
    
#    bash -c "$strCmd&" # >/dev/null 2>&1 & disown
    bash -c "$strCmd&" >/dev/null 2>&1
    SECFUNCexecA -ce ps -A --forest -o ppid,pid,cmd |egrep --color=always "${strCmd}$" -C 10&&: # strCmd will (expectedly) not end with '$" -C 10' :)
    
#  )
  
  ### strCmd being secDelayedExec.sh will not need input, therefore --nohup.
  #eval secXtermDetached.sh $strCmd
#  eval secXtermDetached.sh --nohup $strCmd
#  eval secXtermDetached.sh --logonly $strCmd
  #eval secXtermDetached.sh $strCmd >>/dev/stderr & disown # strCmd needs eval TODO find other way?
  #eval secDelayedExec.sh -x $strCmd 
  
  #secDelayedExec.sh -x FUNCrun&&:
  #xterm -e "$strCmd"&disown
  #echo "Eval: $strCmd"
  #eval "$strCmd" 1>/dev/null 2>&1 & disown
  #echo "cmdPid=$! #$strCmd"
  
  echoc -w -t 1 #to let the app kick in
done

#echoc -w -t 60
#while true;do echo "$$ $SECstrScriptSelfName loop sleep 1h";sleep 3600;done
exit 0 # important to have this default exit value in case some non problematic command fails before exiting
