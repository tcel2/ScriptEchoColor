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

source <(secinit)

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Supported screensavers: gnome."
		SECFUNCshowHelp --colorize "Calculate how much time your screensaver has been active."
		#TODO calc how much time it was inactive and sum for a day, also check for mouse/keyboard activity, and statistics too for cpu/gpu usage, temperatures and music players (too much?)"
		SECFUNCshowHelp
		exit
#	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help MISSING DESCRIPTION
#		echo "#your code goes here"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

logFile="."`basename $0`".log"

nGlobalDelay=0
function FUNClog {
  strTime=`gnome-screensaver-command --time`
  
  strCheck="The screensaver has been active for "
  if [[ ${strTime:0:${#strCheck}} == "$strCheck" ]]; then
    nDelay=`echo $strTime |cut -d' ' -f7`
    if ((nDelay>0)); then
      nDelayAdj=$((10800+nDelay)) #10800 is to adjust epoch time that is 21h to 00h
      nDays=$((`date -d @$nDelayAdj +"%j"` - 1))
      strDelay=$nDays"d"`date -d @$nDelayAdj +"%Hh%Mm%Ss"` 
      
      # global delay cant be here... but its pointless anyway...
      #nGlobalDelay=$((nGlobalDelay+nDelay))
      #nGlobalDelayAdj=$((10800+nGlobalDelay)) #10800 is to adjust epoch time that is 21h to 00h
      #strGlobalDelay=`date -d @$nGlobalDelayAdj +"%H:%M:%S"` 
      
      #strTime="$strTime Delay of $strDelay/$strGlobalDelay."
      strTime="$strTime ($strDelay)."
    fi
  fi
  
  strDate=`date +"%Y%m%d-%H%M%S"`
  strLog="$strDate ($1) $strTime"
}

function FUNCwriteLog {
  echo $strLog >>$HOME/$logFile
  echo $strLog
}

active=false
firstTime=true

# restores last log entry in case of a system crash
strLog=`cat "/tmp/$logFile.tmp"`
FUNCwriteLog
echo "" >"/tmp/$logFile.tmp"
if [[ -n "$strLog" ]]; then #if has something, it was active when the system crashed
  active=true
fi

cat $HOME/$logFile
echo "__________________ Past Above ____________________"

SECFUNCuniqueLock --waitbecomedaemon

while true; do 
  if gnome-screensaver-command --query |grep -q "The screensaver is active"; then
    if ! $active; then
      # restore the saved tmp log
      strLog=`cat "/tmp/$logFile.tmp"`
      FUNCwriteLog
      
      # update log (can be off when this line is reached? once it seem to happen...)
      FUNClog BEGIN
      FUNCwriteLog #logs the begin time
      
      active=true
    else
      FUNClog ON #stores the ammount of time the screensaver has been ON
      echo $strLog >"/tmp/$logFile.tmp"
    fi
  else
    if $active; then
      FUNCwriteLog #saves the ammount of time the screensaver has been ON
      
      FUNClog OFF
      FUNCwriteLog
      echo "" >"/tmp/$logFile.tmp"
      
      active=false
    fi
  fi 
  
  sleep 1
done

