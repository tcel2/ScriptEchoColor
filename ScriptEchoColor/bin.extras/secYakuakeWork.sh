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

source <(secinit)

function echoerr {
  echo "$@" >&2
}

function FUNCaddSession {
  local l_newestSession=-1

  if qdbus org.kde.yakuake /yakuake/sessions addSession >&2; then
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
  local l_strTitle="${2-}"
  
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

    if((l_newestSession==-1)) || $bNewSessionAlways;then
      l_newestSession=`FUNCaddSession`
    fi
    
    if((l_newestSession>=0));then
      qdbus org.kde.yakuake /yakuake/tabs setTabTitle $l_newestSession "$l_strTitle" >&2

      FUNCevenTermId $l_newestSession;local l_termToSplit=$FUNCevenTermId
      
      #being a new session has only one terminal with same session id
      if((iCmd>1)); then
        qdbus org.kde.yakuake /yakuake/sessions splitTerminalTopBottom $l_termToSplit
      fi
			echoerr "terms: ${evenTerms[*]}"
      
      local execCmdAtTerm=`FUNClastTermId $l_newestSession`
      if((execCmdAtTerm>=0));then
        echoerr "new term: cmd=$l_cmd,title=$l_strTitle,session=$l_newestSession,termId=$execCmdAtTerm."
				sleep $nSleep
        qdbus org.kde.yakuake /yakuake/sessions runCommandInTerminal $execCmdAtTerm "$l_cmd" >&2
      else
        echoerr "ERROR: invalid terminal..."
      fi
    fi
  done
}

function FUNCactiveYakuakeTermId() {
	#if [[ -z "${PS1-}" ]];then return 0;fi #only for interactive shells
	astrPPid=(`SECFUNCppidList`);
	if SECFUNCarrayContains astrPPid `pgrep yakuake`;then 
		nYakActiveTermId=`qdbus org.kde.yakuake /yakuake/sessions activeTerminalId`;
	fi
	
	return 0
}

#wait for yakuake to start
#: ${SECbAllowYakTermTitleChange:=true}
nYakActiveTermId=-1
nSleep=0
bNewSessionAlways=false
nAddSessions=0
strCurrentSTitle=""
bTitleAsCommandBeingRun=false
FUNCactiveYakuakeTermId # initial setup
bDoRun=true
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
	  #grep "\"--" $0 |grep -v grep
		SECFUNCshowHelp --colorize "Uses qdbus to open new sessions and terminals at Yakuake."
		echoc -p "TODO: fixing, not fully functional!"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--checkAndRun" || "$1" == "-c" ]]; then #help check if yakuake is running before running the command at it
		while ! qdbus org.kde.yakuake 2>&1 >/dev/null; do
		  sleep 1
		done
#		sleep 3
#		qdbus org.kde.yakuake /yakuake/sessions runCommand $0 >&2
#		exit 0
	elif [[ "$1" == "--sleep" || "$1" == "-s" ]];then #help nSleep (seconds) before running
		shift
		nSleep="${1-}"
	elif [[ "$1" == "--newsession" || "$1" == "-n" ]];then #help always open a new session
		bNewSessionAlways=true;
	elif [[ "$1" == "--justaddsessions" || "$1" == "-a" ]];then #help just add <nAddSessions> and exit
		shift
		nAddSessions="${1-}"
	elif [[ "$1" == "-t" ]];then #help <strCurrentSTitle> set current session tab title
		shift
		strCurrentSTitle="${1-}"
	elif [[ "$1" == "-r" ]];then #help set current session tab title as the command for the run arguments
		bTitleAsCommandBeingRun=true
	elif [[ "$1" == "--tr" ]];then #help set current session tab title as the command for the run arguments (but do not run it)
		bTitleAsCommandBeingRun=true
		bDoRun=false
	elif [[ "$1" == "--is" ]];then #help if is running at yakuake return 0 (true). and will output the yakuake terminal id.
		if((nYakActiveTermId>=0));then
			echo "$nYakActiveTermId"
			exit 0
		fi
		exit 1
#		SECbAllowYakTermTitleChange=false
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if ! SECFUNCisNumber -dn $nAddSessions;then
	echoc -p invalid "nAddSessions='$nAddSessions'"
	exit 1
fi

if((nAddSessions>0));then
	#this is important to have yakuake initially opened to detect current session
	bHadToOpenYak=false
	if [[ `"qdbus" "org.kde.yakuake" /yakuake/MainWindow_1 org.qtproject.Qt.QWidget.visible` == false ]];then 
		bHadToOpenYak=true
		yakuake;
		sleep 1
	fi
	
	astrSessions=(`qdbus org.kde.yakuake |grep /Windows/`);
	nSID=-1
	nSIDFirst=-1
	for strSession in "${astrSessions[@]}";do 
		echo $strSession;
		nSID="`qdbus org.kde.yakuake $strSession org.kde.konsole.Window.currentSession`";
		
		if((nSIDFirst==-1));then
			nSIDFirst="${strSession#/Windows/}"; #the id is actually at the end of the session name -1
			((nSIDFirst--))&&:
		fi
		
		echo $nSID;
		if((nSID>-1));then 
			break;
		fi;
	done
	if((nSID!=-1));then
		nSID=$((nSID-1))&&:
	else
		SECFUNCechoWarnA "unable to detect current yakuake terminal session, restoring focus to 1st one"
		nSID=$nSIDFirst;
	fi
	
	if $bHadToOpenYak;then yakuake;fi #but it can be closed just after...
	
	for((i=0;i<nAddSessions;i++));do 
		SECFUNCexecA -ce qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.addSession;
	done
	
	if((nSID!=-1));then
		sleep 1
		SECFUNCexecA -ce qdbus org.kde.yakuake /yakuake/sessions org.kde.yakuake.raiseSession $nSID
	fi
	
	exit 0
fi

#echoc -p "$0, further functionalities needs fixing, is currently broken..";exit 1;

if ! SECFUNCisNumber -dn $nSleep;then
	echoc -p invalid "nSleep='$nSleep'"
	exit 1
fi

astrRunCmd=("$@")

if $bTitleAsCommandBeingRun;then
	for strPart in "${astrRunCmd[@]}";do
		if [[ "${strPart:0:1}" == "-" ]];then continue;fi
		if [[ "$strPart" == "sudo" ]];then continue;fi
		strCurrentSTitle="$strPart"
		break;
	done
fi

if ((nYakActiveTermId>=0)) && [[ -n "$strCurrentSTitle" ]];then
	qdbus org.kde.yakuake /yakuake/tabs setTabTitle $nYakActiveTermId "$strCurrentSTitle";
fi

if $bDoRun;then
	if [[ -n "${astrRunCmd[@]-}" ]]; then
		#FUNCtask "${astrRunCmd[@]}"
		SECFUNCexecA -ce "${astrRunCmd[@]}"
	fi
fi

exit 0 ################### review code below?
	
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
    #strLine=`echo -n $strLine` #trim spaces
    strLine="`echo -n "$strLine" |tr -s " "`" #trim spaces
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

