#!/bin/bash

# Copyright (C) 2012,2015 by Henrique Abdalla
#
# This file is part of HighPriorityToFocusedWindow.
#
# HighPriorityToFocusedWindow is a way to your games or desktop feel cooler IMO...
#
# HighPriorityToFocusedWindow is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# HighPriorityToFocusedWindow is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with HighPriorityToFocusedWindow. If not, see <http://www.gnu.org/licenses/>.
#
#
# Homepage: http://scriptechocolor.sourceforge.net/
# Project Homepage: https://sourceforge.net/projects/scriptechocolor/
# Project Email: teike@users.sourceforge.net

eval `secinit`

#sudo -k moved from here.. #trap 'echo "Interrupted by user (Ctrl+c)" >/dev/stderr; bCleanExit=true; sudo -k; ' INT
trap 'echo "Interrupted by user (Ctrl+c)" >/dev/stderr; bCleanExit=true; ' INT
SECFUNCcheckActivateRunLog --restoredefaultoutputs # to make it sure it will work with ctrl+c

################# INTERNAL CFG
nVersion=0.3
version="$nVersion alpha"

################# FUNCTIONS 
function FUNCpidExist {
  if ps -p ${1-} >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

function FUNCcheckNumOnly {
  local l_tmp=`echo "$1" |tr -d '\-\+\.[:digit:]'`
  if [[ -n $l_tmp ]]; then
    FUNCmsgErrQuit "invalid value: '$l_tmp'"
  fi
  echo $1
}

function FUNCaskQuit {
  if ! echoc -q "$@"; then
    exit 0
  fi
}

#function FUNCask {
#    echo -n "$@"" (y/...)?"; read -n 1 strResp; echo
#    if [[ $strResp == "y" ]]; then
#      return 0
#    fi
#    return 1
#}

function FUNCmsgErrQuit {
  FUNCmsgErr "$@"
  exit 1
}

function FUNCmsgErr {
  echo "PROBLEM: $@" >/dev/stderr
}

#function FUNCcmpFloat {
#  local l_ret=`echo "$1 $2 $3" |bc`
#  
#  if((l_ret==0));then return 1; fi #c++ 0 is false, shell return non zero is error
#  if((l_ret==1));then return 0; fi #c++ 1 is true, shell return 0 is ok
#  
#  FUNCmsgErrQuit "..."
#}

function FUNCgetNice {
    local l_pid=$1
    
    local l_str=`ps -o nice -p $l_pid |tail -n 1`
    
    echo $l_str
}

function FUNCrenice {
    local l_windowId=${1-}
    local l_nice=${2-}
    local l_pid=${3-}
    
    local l_strInfo=`xdotool getwindowname $l_windowId`
    
    #local l_niceOld=`FUNCgetNice $l_pid`
    echo "$l_strInfo"
    
    SECFUNCexecA -c --echo sudo renice -n $l_nice -p $l_pid
    # no problem if this fails, the window may have been closed...
    #if ! sudo renice -n $l_nice -p $l_pid; then # the magic is here!
    #  FUNCmsgErrQuit "renice fail..."
    #fi
    
    echo
    #local l_niceNew=`FUNCgetNice $l_pid`
    ps -A --sort=-pcpu -o pcpu,pid,stat,state,nice,comm |head -n 4
    ps -p $l_pid       -o pcpu,pid,stat,state,nice,comm |tail -n 1
    echo
    
    #echo "[pid=$l_pid] [nice=$l_niceOld] [nice=$l_niceNew] $l_strInfo"
}

#function FUNCsetOpt {
#  eval "$1=$2"
#  aIdOpts[$((nIndexOpt++))]="$1"
#}

################# SET OPTIONS
nOptNiceHigh=-10
nOptDelay=1.5
bOptYesToAll=false

#nIndexOpt=0
#aIdOpts=() #fill below

bHelp=false
#while [[ -n "${1-}" ]]; do
#  strOpt="--help"
#  if [[ "$1" == "$strOpt" ]]; then
#    bHelp=true
#    
#    echo "HighPriorityToFocusedWindow version $version"
#    echo "$strOpt show this help"
#  fi
#  
#  ### >>--options--> ###
#  ######################
#  strOpt="--yestoall";default=$bOptYesToAll
#  if $bHelp; then
#    # help
#    echo "$strOpt assume 'y' to all FOLLOWING params questions (default=$default)"
#  elif [[ "$1" == "$strOpt" ]]; then
#    #shift  # to collect value

#    # set option
#    bOptYesToAll=true
#    #FUNCsetOpt bOptYesToAll true
#    
#    # validations
#    
#    shift;continue  # to prepare for next param
#  fi
#  
#  ######################
#  strOpt="--nice";default=$nOptNiceHigh
#  if $bHelp; then
#    # help
#    echo "$strOpt set the high priority value (default=$default)"
#  elif [[ "$1" == "$strOpt" ]]; then
#    shift  # to collect value
#    
#    # set option
#    nOptNiceHigh=`FUNCcheckNumOnly "$1"`
#    
#    # validations
#    if ! $bOptYesToAll && FUNCcmpFloat "$nOptNiceHigh" ">=" "0";then
#      FUNCaskQuit "$strOpt should be < 0, continue"
#    fi
#    if ! $bOptYesToAll && FUNCcmpFloat "$nOptNiceHigh" "<" "-15";then
#      FUNCaskQuit "$strOpt too high priority ($nOptNiceHigh < -15), continue"
#    fi
#    
#    shift;continue  # to prepare for next param
#  fi
#  
#  ######################
#  strOpt="--delay";default=$nOptDelay
#  if $bHelp; then
#    # help
#    echo "$strOpt check for focused window delay (default=$default)"
#  elif [[ "$1" == "$strOpt" ]]; then
#    shift  # to collect value
#    
#    # set option
#    nOptDelay=`FUNCcheckNumOnly "$1"`
#    
#    # validations
#    if ! $bOptYesToAll && FUNCcmpFloat "$nOptDelay" ">" "3.0";then
#      FUNCaskQuit "$strOpt is too high > 3, continue"
#    fi
#    if FUNCcmpFloat "$nOptDelay" "<=" "0";then #do not use bOptYesToAll here!
#      FUNCmsgErrQuit "delay must be > 0.0"
#    fi
#    
#    shift;continue  # to prepare for next param
#  fi
#  ### <--options--<< ###
#  
#  if $bHelp; then 
#    exit 0; 
#  fi
#  
#  FUNCmsgErrQuit "invalid param: $1, try --help"
#done

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "High Priority to Focused Window, version $version"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--yestoall" || "$1" == "-y" ]];then #help assume 'y' to all FOLLOWING params questions {bOptYesToAll}
		bOptYesToAll=true
	elif [[ "$1" == "--delay" || "$1" == "-d" ]];then #help <nOptDelay> check for focused window delay
		shift
		nOptDelay="${1-}"
		
		if ! SECFUNCisNumber -n "$nOptDelay";then
      echoc -p "invalid nOptDelay='$nOptDelay', should be positive, can be float"
      exit 1
		fi
    if ! $bOptYesToAll && SECFUNCbcPrettyCalc --cmpquiet "$nOptDelay>3.0";then
      FUNCaskQuit "nOptDelay='$nOptDelay' is too high > 3, continue"
    fi
	elif [[ "$1" == "--nice" || "$1" == "-n" ]];then #help <nOptNiceHigh> set the high priority value
		shift
		nOptNiceHigh="${1-}"
		
    # validations
    strInvalid="invalid nOptNiceHigh='$nOptNiceHigh'"
		if ! SECFUNCisNumber -d "$nOptNiceHigh";then
      echoc -p "$strInvalid, should be decimal"
      exit 1
		fi
    if ! $bOptYesToAll && ((nOptNiceHigh>=0));then
      FUNCaskQuit "$strInvalid, should be < 0, continue"
    fi
    if ! $bOptYesToAll && ((nOptNiceHigh<-15));then
      FUNCaskQuit "$strInvalid, too high priority ($nOptNiceHigh < -15), continue"
    fi
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done


# report options
#echo "nOptNiceHigh=$nOptNiceHigh" >/dev/stderr
#echo "nOptDelay=$nOptDelay" >/dev/stderr
#for((i=0;i<${#aIdOpts[*]};i++));do
#  echo "${aIdOpts[i]}=`eval "\$${aIdOpts[i]}"`" >/dev/stderr
#done

#################### WORKing #####################
bkpNice="none"
bFirstTime=true
bCleanExit=false
windowId=
pid=

while true; do
  windowIdNew=`xdotool getwindowfocus`&&:
  
  if((windowIdNew!=windowId)) || $bCleanExit;then
    #if ps -p $pid >/dev/null 2>&1; then
    if FUNCpidExist $pid; then
      # restores old pid nice
      if((bkpNice < 0)) && ((bkpNice == nOptNiceHigh));then #this means that such window was probably a child of another that had high priority...
        bkpNice=0
      fi
      FUNCrenice $windowId $bkpNice $pid
    fi
    
    # after cleanup (restore nice) above
    if $bCleanExit; then
    	echoc --info "clean exit requested"
      SECFUNCexecA -c --echo sudo -k
      exit 2 #SIGINT
    fi
    
    windowId=$windowIdNew
    pid=`xdotool getwindowpid $windowId`&&:
    if FUNCpidExist $pid; then
      bkpNice=`FUNCgetNice $pid`
      #bkpNice=`ps -o nice -p $pid |tail -n 1`
      #bkpNice=`echo $bkpNice`
      
      FUNCrenice $windowId $nOptNiceHigh $pid
    fi
  fi  
  
  #sudoed sleep to prevent loss of rights in case too much time without changing windows
  SECFUNCexecA -c --echo sudo sleep $nOptDelay&&: #do not protect here cuz of ctrl+c... if ! sudo sleep $nOptDelay; then FUNCmsgErrQuit "sleep fail..."; fi
done

