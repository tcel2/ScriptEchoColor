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

eval `secinit`

SECFUNCuniqueLock --daemonwait
#secDaemonsControl.sh --register

renice -n 19 $$

#trap 'echo "(ctrl+c hit, wait loop timeout...)" >>/dev/stderr;bAskExit=true' INT

bAskExit=false
strDmesgTail="(test)"
clr_eol=`tput el` # terminfo clr_eol, constant to clear the line b4 echo

SECFUNCcfgRead
if [[ ! -f "$SECcfgFileName" ]]; then
	check001=("usb .*: not running at top speed; connect to a high speed hub" "Reconnect USB device (pendrive?), it is running at low speed..." "Some USB could be faster?")
	check002=("hub .* unable to enumerate USB device on port" "Reconnect USB device (pendrive?)..." "USB connection failed")
	check003=("device .* entered promiscuous mode" "Who is doing that?! try: cat /var/log/messages |grep 'promiscuous mode'")
	check004=("Device offlined - not ready after error recovery" "fsck some of your storage devices" "Some storage has errors?")
	
#	SECFUNCcfgWriteVar check001
#	SECFUNCcfgWriteVar check002
#	SECFUNCcfgWriteVar check003
  nCheckId=1
  while true;do
  	strCheckId=$(printf "check%03d" $nCheckId)
  	if ! ${!strCheckId+false};then
			SECFUNCcfgWriteVar $strCheckId
	  else
	  	break
  	fi
	  ((nCheckId++))
  done

fi

echo "Add checks to '$SECcfgFileName'"
grep "#help" `which $0` |grep -v "#skip" |sed 's"function \([[:alnum:]]*\).*#help\(.*\)"\t\1\t\2"'
echo "You can test this way: echo 'dmesg message go here' |sudo -k tee /dev/kmsg"
echoc -x "cat '$SECcfgFileName'"

function FUNCdmesg() {
	#cat /var/log/messages
	#cat /var/log/kern.log
	dmesg -l warn,err,crit,alert,emerg "$@"
}

function FUNCupdateLastIdLine {
	#echo "lastId=$lastId" >>/dev/stderr
	lastIdLine=""
	if [[ -n "$lastId" ]];then
	  lastIdLine=`FUNCdmesg |grep "$lastId" -n |cut -d ':' -f1 |head -n 1`
	fi
}

function FUNCupdateLastId {
  # updates with the last log entry data
  
  #lastId=`FUNCdmesg |tail -n 1 |cut -d ' ' -f2 |cut -d ']' -f1`
  #lastId=`FUNCdmesg |tail -n 1 |grep "[0-9]*\.[0-9]*" -o |head -n 1`
  #lastId=`FUNCdmesg |tail -n 1 |grep -o "[[][[:digit:]]*[.][[:digit:]]*[]]" |grep -o "[[:digit:]]*[.][[:digit:]]*" |head -n 1`
  lastId=`FUNCdmesg |tail -n 1 |sed -r 's".*\[ *([[:digit:]]*[.][[:digit:]]*)\].*"\1"'`
  
  FUNCupdateLastIdLine
}

function FUNCproblem {
  local strDiagnostic=$1
  local strTitle=$2
  
  strTitle="Dmesg check: $strTitle"
  
  zenity --info --title="$strTitle" --no-wrap --text="$strDiagnostic\n\ndmesg:\n$strDmesgTail"
}

function FUNCcheck { #help <regexToMatch> <problemReportMessage> [customTitle]
	#echo "$FUNCNAME: '${1}' '${2}' '${3-}'"
  if echo "$strDmesgTail" |grep "$1"; then
    FUNCproblem "$2" "${3-}"
  fi
}

bFirstLoop=true
bLog=true
echoc --info "begin checkings..."
FUNCupdateLastId
while true; do
  totLines=`FUNCdmesg |wc -l`
  
  FUNCupdateLastIdLine #dmesg size may have changed...
  remainingLinesToCheck=$((totLines-lastIdLine))
  
  # collects the new log entries to display skipping "useless?" ones
  export strDmesgTail=`FUNCdmesg \
    |tail -n $remainingLinesToCheck \
    |grep -v "type=1505 audit.*operation=\"profile_replace\".*name=\"/usr/sbin/mysqld\"" \
    |grep -v "Unknown OutputIN=" \
    |grep -v "Inbound IN="`
  
  if $bLog; then
    echo -n -e "${clr_eol}id:$lastId,ln:$lastIdLine/$totLines,chk:$remainingLinesToCheck\r"
    if [[ -n "$strDmesgTail" ]]; then
      echo #newline to /r log above
      echo "$strDmesgTail"
      #echo " <--LOG--<< "
    fi
  fi
  
  FUNCupdateLastId  # updates as soon as possible, after vars have been used on log above and b4 dialogs...
  
  SECFUNCcfgRead
  
  nCheckId=1
  while true;do
  	strCheckId=$(printf "check%03d" $nCheckId)
  	#echo "strCheckId='$strCheckId'"
  	#if declare -p "$strCheckId" 2>&1 >/dev/null;then
  	if ! ${!strCheckId+false};then
  		strCheckIdAllElements="${strCheckId}[@]"
	  	#echo "strCheckIdAllElements='$strCheckIdAllElements'"
	  	FUNCcheck "${!strCheckIdAllElements}"
	  else
	  	break
  	fi
	  ((nCheckId++))
  done
  
#	cat "$fileCfg" |while read strLine;do
#		#echo FUNCcheck $strLine
#		if [[ "${strLine:0:1}" != "#" ]];then
#			astrParamsToFuncCheck=($strLine)
#			declare -p astrParamsToFuncCheck
#			FUNCcheck "${astrParamsToFuncCheck[@]}"
#		fi
#	done
	
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
  
	if SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
done

