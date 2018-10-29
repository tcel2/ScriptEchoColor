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

source <(secinit --extras)

echo "SelfPid=$$"

function FUNCCHILDaddIgnorePid() { #<lnPid>
  local lnPid="$1"
  (
    echo "SENDING PID TO IGNORE: $lnPid"
    SECFUNCexecA -ce kill -SIGUSR1 $$ # will make it wait pipe be filled up
    echo "$lnPid" >>"$strFifoFl" # will only return after it is read!
    echo "SENT."
  )&
}

astrRegexIgnorePgrep=(Xorg compiz metacity xfwm4 kwin mutter)
strFifoFl="`SECFUNCcreateFIFO`"
: ${nMemLimKB:=500000} #help
anPidIgnore=() #TODO use cmd regex later at default config file to auto ignore pids
#TODO revalidate pids to check if they are still alive
#anPidManaged=()
: ${nLimPids:=100} #help
bReadFIFO=false
trap 'bReadFIFO=true' SIGUSR1
while true;do
  nMaxCols=`tput cols` #;declare -p nMaxCols
#  declare -p anPidIgnore
  
  IFS=$'\n' read -d '' -r -a astrList < <(
    ps --no-headers -A -o rss,pid,state,cmd --sort -rss \
          |head -n $nLimPids \
          |sed -r 's@([[:digit:]]*) *([[:digit:]]*) *([[:alnum:]]) *(.*)@nResKB=\1;nPid=\2;strState="\3";strCmd="\4";@'  
  )&&:
  
  for strRegexIgnore in "${astrRegexIgnorePgrep[@]}";do
    if nPidRegexIgnore=`pgrep $strRegexIgnore`;then
      if ! SECFUNCarrayContains anPidIgnore $nPidRegexIgnore;then
        anPidIgnore+=($nPidRegexIgnore)
      fi
    fi
  done
  
  bShowHeader=true
  for strLine in "${astrList[@]}";do 
    eval "$strLine";
    
    if $bReadFIFO;then
      strFIFOdata="`cat <"$strFifoFl"`" # this will WAIT until somthing is written to the PIPE!!!
      if [[ -n "$strFIFOdata" ]];then
        if ps -p $strFIFOdata;then
          nPidIgnore=$strFIFOdata
          SECFUNCexecA -ce kill -SIGCONT $nPidIgnore
          anPidIgnore+=($nPidIgnore)
        fi
        #~ declare -p anPidIgnore
        #~ echo "EVAL: $strFIFOdata"
        #~ eval "$strFIFOdata"
        #~ echo "$strFIFOdata" |while read strSrcExec;do
          #~ echo "EVAL: $strSrcExec"
          #~ eval "$strSrcExec"
        #~ done
        #~ declare -p anPidIgnore
      fi
      bReadFIFO=false
    fi
    
    if [[ "$strState" == "T" ]];then 
      if $bShowHeader;then
        SECFUNCdrawLine --left " nPid nResKB strState strCmd "
        bShowHeader=false
      fi
      echo $nPid $nResKB $strState $strCmd |sed -r "s@(.{$nMaxCols}).*@\1@"
      #~ if ! SECFUNCarrayContains anPidManaged $nPid;then
        #~ anPidManaged+=($nPid)
      #~ fi
      continue;
    fi
    
    if((nResKB>nMemLimKB));then
      if ! SECFUNCarrayContains anPidIgnore $nPid;then
        SECFUNCexecA -ce kill -SIGSTOP $nPid
        (
          astrText=(
            '!!! IGNORE AND CONTINUE RUNNING THIS PID ? !!!\n'
            "\n"
            "This memory hungry app was stopped:\n"
            "Pid=$nPid\n"
            "ResKB=$nResKB\n"
            "strCmd=$strCmd\n"
          )
          strText="${astrText[*]}"
          if yad --title="$SECstrScriptSelfName" --info \
            --button="gtk-ok:0" --button="gtk-close:1" \
            --text="${strText:0:1000}";
          then
            FUNCCHILDaddIgnorePid $nPid
#            echo "SENDING PID TO IGNORE: $nPid"
            #~ SEC_WARN=true
 #           SECFUNCexecA -ce kill -SIGUSR1 $$ # will make it wait pipe be filled up
  #          echo "$nPid" >>"$strFifoFl" # will only return after it is read!
            #~ echo "anPidIgnore+=($nPid);" >>"$strFifoFl" # will only return after it is read!
            #~ SECFUNCexecA -ce kill -SIGCONT $nPid
            #~ while ! echo "anPidIgnore+=($nPid)" >>"$strFifoFl";do
              #~ ls -l "$strFifoFl" &&:
              #~ SECFUNCechoWarnA "Failed SENDING PID TO IGNORE, retrying."
              #~ sleep 1
            #~ done
   #         echo "SENT."
          fi
        )&
      fi
      
      #~ if yad --title="$SECstrScriptSelfName" --button="gtk-ok:0" --button="gtk-close:1" --text "Memory hungry app:\nPID=$nPid\nIGNORE IT?";then
        #~ SECFUNCexecA -ce kill -SIGCONT $nPid
      #~ fi
    fi
  done
  
  #~ ps --no-headers -A -o rss,pid,state,cmd --sort -rss |egrep "^ *[[:digit:]]* *[[:digit:]]* T "
  #~ if echoc -q -t 10 "show stopped pids list?";then
    #~ yad --title="$SECstrScriptSelfName" \
      #~ --list --checklist --text="select what pids to IGNORE" \
      #~ --column="" --column="PID" --column="ResKB" --column="CMD" \
      #~ 0 123 321 asdf 1 124 322 asdfg
  #~ fi
  ScriptEchoColor -t 10 -Q "question@O_add one PID to ignore list/_list ignored pids"&&:; nRet=$?; case "`secascii $nRet`" in 
    a)
      nPidIgnore=`echoc -S "what PID"`;
      if [[ -n "$nPidIgnore" ]];then
        FUNCCHILDaddIgnorePid $nPidIgnore
      fi
      ;; 
    l)
      echoc --info "Ignored PIDs"
      SECFUNCexecA -ce ps -o rss,pid,state,cmd --sort -rss -p "${anPidIgnore[@]}" |sed -r "s@(.{$nMaxCols}).*@\1@" &&:
      ;;
    *)if((nRet==1));then SECFUNCechoErrA "err=$nRet";exit 1;fi;; 
  esac
  
#  if echoc -t 10 -q "add one PID to ignore list?";then
    #nPidIgnore=`echoc -S "what PID"`;
    #if [[ -n "$nPidIgnore" ]];then
     # FUNCCHILDaddIgnorePid $nPidIgnore
      #~ anPidIgnore+=($nPidIgnore)
      #~ declare -p anPidIgnore
      #~ SECFUNCexecA -ce kill -SIGCONT $nPidIgnore
    #fi
  #fi
done
