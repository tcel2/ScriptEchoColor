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

function echoerr {
  echo "$@" >/dev/stderr
}

function FUNCaddSession {
  local l_newestSession=-1

  if qdbus org.kde.yakuake /yakuake/sessions addSession >/dev/stderr; then
    local l_anSessions=(`qdbus org.kde.yakuake /yakuake/sessions sessionIdList |tr ',' ' '`)
    #echoerr ${l_anSessions[*]}
    
    for((i=0;i<${#l_anSessions[*]};i++));do
      l_session=${l_anSessions[i]}
      if((l_session>l_newestSession));then
        l_newestSession=$l_session
      fi
    done
    
    echo $l_newestSession
  else
    echoerr "ERROR: cant add session..."
  fi
}

function FUCNfirstTermId {
  local l_newestSession=$1
  local l_idTermList=`qdbus org.kde.yakuake /yakuake/sessions terminalIdsForSessionId $l_newestSession`
	sedFirtNumPeriodSeparated='s"\([0-9]*\),.*"\1"'
	#sed2ndNumPeriodSeparated='s"[0-9]*,\([0-9]*\),.*"\1"'
  local l_idTerm=`echo "$l_idTermList" |sed "$sedFirtNumPeriodSeparated"`
  echo $l_idTerm
}
function FUNClastTermId {
  local l_newestSession=$1
  local l_idTermList=`qdbus org.kde.yakuake /yakuake/sessions terminalIdsForSessionId $l_newestSession`
  local l_idTerm=`echo "$l_idTermList" |tr ',' '\n' |tail -n 1`
  echo $l_idTerm
}
evenTerms=()
currentTerm=-1
refresh=true
FUNCevenTermId=-1 #used to store return value!
function FUNCevenTermId {
  local l_newestSession=$1
  local l_idTerm=-1
  
  if $refresh; then
		local l_idTermList=`qdbus org.kde.yakuake /yakuake/sessions terminalIdsForSessionId $l_newestSession`
		evenTerms=(`echo "$l_idTermList" |sed 's"," "g'`)
		currentTerm=-1
		refresh=false
	fi
	
	((currentTerm++))
	l_idTerm=${evenTerms[currentTerm]}
	if(( currentTerm == (${#evenTerms[*]}-1) )); then
		refresh=true
	fi
	
  #echo $l_idTerm
  FUNCevenTermId=$l_idTerm
}
function FUNCtermId {
	#FUCNfirstTermId "$@"
	#FUNClastTermId "$@"
	FUNCevenTermId "$@"
}

function FUNCtask {
  local l_cmdList="$1"
  local l_strTitle="$2"
  
  local l_newestSession=-1
  local l_cmdCount=`echo "$l_cmdList" |tr ',' '\n' |wc -l`
  
  # to let split with better height size 
  #@@@ missing a check to see if it is visible (not isVisible option o.O)
  #qdbus org.kde.yakuake /yakuake/MainWindow_1 com.trolltech.Qt.QWidget.show
  # this way it expects yakuake to be shrinked... :/
  #qdbus org.kde.yakuake /yakuake/window org.kde.yakuake.toggleWindowState
  #echo "wait..."
  #sleep 3
  #@@@ NAO PRECISA MAIS!
  
  for((iCmd=1;iCmd<=l_cmdCount;iCmd++));do
    local l_cmd=`echo "$l_cmdList" |tr ',' '\n' |head -n $iCmd |tail -n 1`
    
    if [[ -z "$l_strTitle" ]]; then
      l_strTitle="${l_cmd:0:20}"
    fi

    if((l_newestSession==-1));then
      l_newestSession=`FUNCaddSession`
    fi
    
    if((l_newestSession>=0));then
      qdbus org.kde.yakuake /yakuake/tabs setTabTitle $l_newestSession "$l_strTitle" >/dev/stderr

      FUNCevenTermId $l_newestSession;local l_termToSplit=$FUNCevenTermId
      
      #being a new session has only one terminal with same session id
      if((iCmd>1)); then
        qdbus org.kde.yakuake /yakuake/sessions splitTerminalTopBottom $l_termToSplit
      fi
			echoerr "terms: ${evenTerms[*]}"
      
      local execCmdAtTerm=`FUNClastTermId $l_newestSession`
      if((execCmdAtTerm>=0));then
        echoerr "new term: cmd=$l_cmd,title=$l_strTitle,session=$l_newestSession,termId=$execCmdAtTerm."
        qdbus org.kde.yakuake /yakuake/sessions runCommandInTerminal $execCmdAtTerm "$l_cmd" >/dev/stderr
      else
        echoerr "ERROR: invalid terminal..."
      fi
    fi
  done
}

params="$@"

#wait for yakuake to start
if [[ "$1" == "--help" ]]; then
  grep "\"--" $0 |grep -v grep
  exit 0
elif [[ "$1" == "--checkAndRun" ]]; then
  while ! qdbus org.kde.yakuake 2>&1 >/dev/null; do
    sleep 1
  done
  sleep 3
  qdbus org.kde.yakuake /yakuake/sessions runCommand $0 >/dev/stderr
  exit 0
#elif [[ -n "$1" ]]; then
#  if [[ "${1:0:1}" == "-" ]]; then
elif [[ -n "$params" ]]; then
  if [[ "${params:0:1}" == "-" ]]; then
    echo "ERROR: invalid option $1..."
    read -n 1
    exit 1
  else
    #FUNCtask "$1"
    FUNCtask "$params"
    exit 0
    #strExec=`which "$1"`
    #if [[ -x "$strExec" ]]; then
    #  FUNCtask `basename "$strExec"`
    #  exit 0
    #fi
  fi
fi


echoerr "Running at Yakuake!"

cfgFile="$HOME/.`basename $0`.cfg"
if [[ ! -f "$cfgFile" ]]; then
  echo "# put one application/script per line to be run on a new yakuake session/terminal." >>$cfgFile
  echo "# it must be a command without parameters and comments for now..." >>$cfgFile
  echo "# ex. uncomment to run htop" >>$cfgFile
  echo "#htop" >>$cfgFile
  echoerr "INFO: edit $cfgFile with applications to be run at yakuake!"
  exit 0
else
  countCmds=0
  #for((i=0;i<`wc -l $cfgFile |cut -d' ' -f1`;i++));do 
    #strLine=`cat $cfgFile |head -n $i |tail -n 1`
  #done 
  while read strLine; do 
    strLine=`echo -n $strLine` #trim spaces
    #echo "($strLine)"
    
    if [[ "${strLine:0:1}" == "#" ]]; then continue; fi
    if [[ -z "$strLine"           ]]; then continue; fi
    
    FUNCtask "$strLine"
    ((countCmds++))
  done <$cfgFile
  
  if((countCmds==0));then
    echoerr "INFO: no commands found at $cfgFile"
  fi
fi
