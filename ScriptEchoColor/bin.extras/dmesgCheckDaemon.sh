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

renice -n 19 $$

trap 'echo "(ctrl+c hit)" >/dev/stderr;bAskExit=true' INT

fileCfg="$HOME/.`basename $0`.cfg"
bAskExit=false
strDmesgTail="(test)"
clr_eol=`tput el` # terminfo clr_eol, constant to clear the line b4 echo

echo "Add checks to $fileCfg"
grep "#help" `which $0` |grep -v "#skip" |sed 's"function \([[:alnum:]]*\).*#help\(.*\)"\t\1\t\2"'

function FUNCdmesg() {
	# dmesg doesnt show everything.. #dmesg -l warn,err,crit,alert,emerg "$@"
	cat /var/log/messages
}

function FUNCupdateLastIdLine {
	#echo "lastId=$lastId" >/dev/stderr
	lastIdLine=""
	if [[ -n "$lastId" ]];then
	  lastIdLine=`FUNCdmesg |grep "$lastId" -n |cut -d ':' -f1 |head -n 1`
	fi
}

function FUNCupdateLastId {
  # updates with the last log entry data
  
  #lastId=`FUNCdmesg |tail -n 1 |cut -d ' ' -f2 |cut -d ']' -f1`
  #lastId=`FUNCdmesg |tail -n 1 |grep "[0-9]*\.[0-9]*" -o |head -n 1`
  lastId=`FUNCdmesg |tail -n 1 |grep -o "[[][[:digit:]]*[.][[:digit:]]*[]]" |grep -o "[[:digit:]]*[.][[:digit:]]*" |head -n 1`
  
  FUNCupdateLastIdLine
}

function FUNCproblem {
  local strDiagnostic=$1
  local strTitle=$2
  if [[ -z "$strTitle" ]]; then strTitle="PROBLEM(ERROR)"; fi
  zenity --info --title="$strTitle" --no-wrap --text="$strDiagnostic\n"\
    "\n"\
    "$strDmesgTail"
}

function FUNCcheck { #help <regexToMatch> <problemReportMessage> [customTitle]
  if echo "$strDmesgTail" |grep "$1"; then
    FUNCproblem "$2" "$3"
  fi
}

bFirstLoop=true
FUNCupdateLastId
while true; do
  totLines=`FUNCdmesg |wc -l`
  
  FUNCupdateLastIdLine #dmesg size may have changed...
  tailCount=$((totLines-lastIdLine))
  
  # collects the new log entries to display
  export strDmesgTail=`FUNCdmesg -T \
    |tail -n $tailCount \
    |grep -v "type=1505 audit.*operation=\"profile_replace\".*name=\"/usr/sbin/mysqld\"" \
    |grep -v "Unknown OutputIN= OUT=vmnet. SRC=" \
    |grep -v "Inbound IN=eth0 OUT= MAC="` # grep excludes at end...
  
  if $bLog; then
    echo -n -e "$clr_eol >>--LOG--> lastId=$lastId, lastIdLine=$lastIdLine, totLines=$totLines, tailCount=$tailCount.\r"
    if [[ -n "$strDmesgTail" ]]; then
      echo #newline to /r log above
      echo "$strDmesgTail"
      #echo " <--LOG--<< "
    fi
  fi
  
  FUNCupdateLastId  # updates as soon as possible, after vars have been used on log above and b4 dialogs...
  
  if [[ ! -f "$fileCfg" ]]; then
  	cat >"$fileCfg" <<EOF
# some useful checks, you can remove them...
FUNCcheck "usb .*: not running at top speed; connect to a high speed hub" \
	"Reconnect USB device (pendrive?), it is running at low speed..."
FUNCcheck "hub .* unable to enumerate USB device on port" \
  "Reconnect USB device (pendrive?)..."
FUNCcheck "device .* entered promiscuous mode" \
  "Who is doing that?! try: cat /var/log/messages |grep 'promiscuous mode'"
EOF
  fi
	source "$fileCfg"
	
	#if $bFirstLoop; then
	#	echo "Current checks:"
	#	cat "$fileCfg"
	#fi
	
  # this is good that prevents mouse scroll outputting messy characters... no problem if you press ENTER for any reason..
	bFirstLoop=false
  read -s -t 10 -p "" #sleep 5
  
  if $bAskExit;then
		if echoc -q "exit";then
			exit
		fi
  	bAskExit=false
  fi
done

