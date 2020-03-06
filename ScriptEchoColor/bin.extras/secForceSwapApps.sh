#!/bin/bash
# Copyright (C) 2020 by Henrique Abdalla
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

echo "[strPgrepSigStop] this optional param is a regex"
echo "# HELP: fill memory fastly to make apps swap out preventing memory exaustion ( mainly by dxvk ) and prevent also a few apps from crashing/freeze/etc"

SECFUNCcfgReadDB
declare -p SECcfgFileName
if [[ -f "$SECcfgFileName" ]];then cat "$SECcfgFileName";fi

egrep "[#]help" "$0"

strPgrepSigStop="${1-}";shift&&:
if [[ -n "$strPgrepSigStop" ]];then
  CFGstrPgrepSigStop="$strPgrepSigStop"
  SECFUNCcfgAutoWriteAllVars
fi

nTotMemMB="`free --mega |grep Mem |awk '{print $2}'`"

anPidAlreadyStopped=()
function FUNCsig() { # <SIGNAL>
  local lstrSig="$1"
  if [[ -n "$CFGstrPgrepSigStop" ]];then
    if pgrep -fa "$CFGstrPgrepSigStop";then
      if [[ "${lstrSig}" == "STOP" ]];then
        declare -ag anPidAlreadyStopped
        local lanPid=(`pgrep -f "$CFGstrPgrepSigStop"`)
        for lnPid in "${lanPid[@]}";do
          if grep "State.*stopped" /proc/$lnPid/status;then
            anPidAlreadyStopped+=($lnPid)
          fi
        done
        declare -p anPidAlreadyStopped
      fi
      
      SECFUNCexecA -ce pkill -SIG${lstrSig} -fe "$CFGstrPgrepSigStop"
      
      if [[ "${lstrSig}" == "CONT" ]];then # messy undoer
        declare -p anPidAlreadyStopped
        echo "SECFUNCarraySize anPidAlreadyStopped $(SECFUNCarraySize anPidAlreadyStopped)"
        if((`SECFUNCarraySize anPidAlreadyStopped`>0));then
          for lnPid in "${anPidAlreadyStopped[@]}";do
            ps -o pid,cmd -p $lnPid
            SECFUNCexecA -m "keep stopped as was already" -ce kill -SIGSTOP $lnPid
          done
          anPidAlreadyStopped=() # cleanup to refill on next stop
        fi
      fi
    fi
  fi
}

: ${nUsedLimitMB:=500} #help
: ${nUseMBDefault:=2000} #help
nUseMB=$nUseMBDefault
bBigOnce=false
SECFUNCuniqueLock --waitbecomedaemon
while true;do 
#  nFreeMemMB="`free --mega |grep Mem |awk '{print $4}'`";
  nAvailMemMB="`free --mega |grep Mem |awk '{print $7}'`"; # available memory ignores buff/cache memory!
  declare -p nAvailMemMB nTotMemMB nUseMBDefault nUseMB;
  if $bBigOnce || ((nAvailMemMB<nUsedLimitMB));then 
    SEC_SAYVOL=25 echoc --waitsay "swapping"
    echoc -w -t 3 "let user take some fast action"
    FUNCsig STOP
    #if [[ -n "$CFGstrPgrepSigStop" ]];then
      #if pgrep -fa "$CFGstrPgrepSigStop";then
        #SECFUNCexecA -ce pkill -SIGSTOP -fe "$CFGstrPgrepSigStop"
      #fi
    #fi
    
    SECFUNCexecA -ce stress-ng --vm-bytes ${nUseMB}M --timeout 15 --vm-keep --vm 1 --verbose;
    SEC_SAYVOL=25 echoc --say "swapping done"
    
    FUNCsig CONT
    #if [[ -n "$CFGstrPgrepSigStop" ]];then
      #if pgrep -fa "$CFGstrPgrepSigStop";then
        #SECFUNCexecA -ce pkill -SIGCONT -fe "$CFGstrPgrepSigStop"
      #fi
    #fi
    bBigOnce=false
    nUseMB=$nUseMBDefault
  fi;
  if echoc -q -t 15 "fill memory a lot once?";then
    bBigOnce=true
    nUseMB=$((nTotMemMB-1000))
  fi
done 
