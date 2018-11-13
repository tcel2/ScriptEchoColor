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

#ls -l --color=always "/proc/$$/fd" >&2

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
bRunAll=false
#SECFUNCfdReport;SECFUNCrestoreDefaultOutputs;SECFUNCfdReport;strLogFile="`secDelayedExec.sh --getgloballogfile`";SECFUNCfdReport;declare -p strLogFile;exit 0
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
	elif [[ "$1" == "-r" || "$1" == "--runall" ]];then #help use on startup
    bRunAll=true
	elif [[ "$1" == "-f" || "$1" == "--filter" ]];then #help <strFilter> do the work only if entry matches regex filter
    shift
		strFilter="${1-}"
    declare -p strFilter
	elif [[ "$1" == "-l" || "$1" == "--listonly" ]];then #help cmds
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
if $bRunAll || $bListOnly || [[ -n "$strFilter" ]];then
  :
else
  exit 0
fi

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

cd $HOME/.config/autostart/

########## autostart cfg files
IFS=$'\n' read -d '' -r -a astrFileList < <(grep "enabled=true" * |cut -d: -f1)&&:

echo
echo "Enabled FILES at: '`pwd`'"
for strFile in "${astrFileList[@]}";do  
  echo -e " $strFile     #`egrep -h "Exec=.* --SequentialCfg " "${strFile}" |sed 's"^Exec=""'`"
done
#ls -1 "${astrFileList[@]}" |sed "s@.*@`pwd`/&@"
#find "`pwd`/" -iname "*.desktop" |sort

########## autostart commands
IFS=$'\n' read -d '' -r -a astrCmdList < <(egrep -h "Exec=.* --SequentialCfg " "${astrFileList[@]}" |sed 's"^Exec=""' |sort)&&:
#declare -p astrCmdList |tr '[' '\n'

########## prepare list to be ordered
sedGetSleepTime="s'.*-s[ ]*([[:digit:]]*) .*'\1'"
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
echo
echo "Sequential CMDs:"
declare -p astrCmdListOrdered |tr '[' '\n'

if $bListOnly;then exit 0;fi

strLogFile="`secDelayedExec.sh --getgloballogfile`"; #declare -p strLogFile;exit 0
echo -n >>"$strLogFile" #grant it is created
chmod go-rw "$strLogFile"

########## run the commands
if [[ -n "$strFilter" ]];then
  nFilterMatchCount=0
  for strCmd in "${astrCmdListOrdered[@]}";do
    if [[ "$strCmd" =~ $strFilter ]];then 
      echo "MATCH: $strCmd"
      ((nFilterMatchCount++))&&:
    fi
  done
  
  if((nFilterMatchCount>1));then
    echoc -p "filter matched more than once"
    exit 1
  fi
  
  if((nFilterMatchCount==0));then
    echoc --info "filter matches nothing..."
    exit 0
  fi
fi

if $bRunAll || [[ -n "$strFilter" ]];then
  SECFUNCuniqueLock --waitbecomedaemon
  
  echoc --info "running commands sequentially as the system allows it if not encumbered"
  #SECbExecJustEcho=false
  export SECCFGbOverrideRunThisNow=true
  iCount=0
  SECFUNCdelay totalTime --init
  for strCmd in "${astrCmdListOrdered[@]}";do
    SECFUNCdrawLine #--left "$strCmd"
    
    ((iCount++))&&:
    
    #~ declare -p strCmd
    #SECFUNCexecA -cj $strCmd & echo pid=$!
    echo "Cmd${iCount}/${#astrCmdListOrdered[@]}: $strCmd"
    if [[ -n "$strFilter" ]] && ! [[ "$strCmd" =~ $strFilter ]];then echo skip;continue;fi
    
    while ! FUNCchkCanRunNext;do
      echoc -w -t 1 "wait cpu free up a bit"
    done # check cpu
    
    if ! strDtTm="`SECFUNCdtFmt --filename`";then #TODO can this problem actually ever happen if the OS and hardware are all OK?
      strDtTm="_BUG_CANT_GET_DATETIME_"
    fi
    
    strLogFileFull="${strLogFile}.$$.$strDtTm.`SECFUNCfixId --trunc 100 --justfix -- "$strCmd"`"
    
    strLogTxt=" Seq -> $strDtTm;0s;pid=?;$strCmd ; # Sequential run"
    echo "$strLogTxt" >>"$strLogFile"
    echo "$strLogTxt" >>"$strLogFileFull"
    
    echo "RUNNING: $strCmd"
    #TODO disown is not preventing some applications from closing/hangup when this terminal closes...
    #env -i bash -c "${strCmd}&disown" >>"$strLogFileFull" 2>&1 
    ( 
      #TODO right? SECFUNCcleanEnvironment # this is good to grant no lucky run is happening, also `env -i` was too much preventing being run at all, right?
      bash -c "SECbDelayExecIgnoreSleep=true SECbDelayExecIgnoreWaitChkPoint=true ${strCmd}&disown" >>"$strLogFileFull" 2>&1 
    )
    #(${strCmd} >>"$strLogFileFull" 2>&1 & disown) & disown
    
    ps -A --forest -o ppid,pid,cmd |egrep --color=always "${strCmd}$" -B 2&&: |tee -a "$strLogFileFull" # strCmd will (expectedly) not end with '$" -B 2' :)
    
    chmod go-rw "$strLogFileFull"
    
    echoc -w -t 0.35 #to let the app kick in blindly
  done
  SECFUNCdelay totalTime --getpretty
fi

#echoc -w -t 60
#while true;do echo "$$ $SECstrScriptSelfName loop sleep 1h";sleep 3600;done
exit 0 # important to have this default exit value in case some non problematic command fails before exiting
