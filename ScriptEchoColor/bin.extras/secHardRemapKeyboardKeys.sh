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

source <(secinit)

declare -p SECstrUserScriptCfgPath
strExample="DefaultValue"
bExample=false
bRecreateKbdCfg=false
bExitAfterConfig=false
bRestoreDefaultCfg=false
bApplyNewConfig=false
bIgnoreNumlock=false
bAcceptWithoutReview=false
CFGstrTest="Test"
CFGstrSomeCfgValue=""
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful

SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above, and BEFORE the skippable ones!!!

: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-c" || "$1" == "--CFGnDevEvtNum" ]];then #help ~single <CFGnDevEvtNum> choose the device event number using `evtest`
		shift;CFGnDevEvtNum="${1-}"
		bExitAfterConfig=true
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift;strExample="${1-}"
	elif [[ "$1" == "-b" || "$1" == "--recreatekbdcfg" ]];then #help ~single recreate the backup config file for the current keyboard default configuration
		bRecreateKbdCfg=true
	elif [[ "$1" == "-i" || "$1" == "--numerickeypad" ]];then #help ~single ignore if numlock is active and always provide a numeric keypad
		bIgnoreNumlock=true
	elif [[ "$1" == "-a" || "$1" == "--alllooksgood" ]];then #help ~single accept changes without review
		bAcceptWithoutReview=true
	elif [[ "$1" == "-n" || "$1" == "--newconfig" ]];then #help ~single create and apply a new config, subsequent params will be stored on the new config file ex.: <KEYBOARD_KEY_700f1=kp0> [[KEYBOARD_KEY_7005c=1] ...]
		bApplyNewConfig=true
	elif [[ "$1" == "-r" || "$1" == "--restoredefaults" ]];then #help ~single restore default keyboard config based on the backup cfg file
		bRestoreDefaultCfg=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams. TODO explain how it will be used
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift&&: #will consume all remaining params
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
if $bWriteCfgVars;then SECFUNCcfgAutoWriteAllVars;fi #this will also show all config vars
if $bExitAfterConfig;then exit 0;fi

### collect required named params
# strParam1="$1";shift
# strParam2="$1";shift

# Main code
if SECFUNCarrayCheck -n astrRemainingParams;then :;fi

SECFUNCuniqueLock --waitbecomedaemon # if a daemon or to prevent simultaneously running it

if ! SECFUNCisNumber -dn "${CFGnDevEvtNum-}";then
  echoc -p "CFGnDevEvtNum needs to be configured, see evtest"
  exit 1
fi

trap 'set -x;sudo -k;set +x;echo "SUDO off"' EXIT

######## COLLECT DEFAULT (CURRENT) KEYBOARD CFG ######

strFlKbdDefCfg="$SECstrUserScriptCfgPath/KeyboardDefault.cfg"
mkdir -vp "`dirname "${strFlKbdDefCfg}"`"
declare -p strFlKbdDefCfg
ls -l "${strFlKbdDefCfg-}" &&:
if $bRecreateKbdCfg || [[ ! -f "${strFlKbdDefCfg-}" ]];then
  echoc --info "creating a required backup of the current (default) keyboard keys configuration"
  
  #### input-kbd
  strInputKbdData="`SECFUNCexecA -ce sudo input-kbd $CFGnDevEvtNum`";declare -p strInputKbdData
  strHexaVendor="` echo "$strInputKbdData" |grep vendor  |grep "0x.*" -o |tr "[:lower:]" "[:upper:]"`";strHexaVendor="`printf "%04X" $strHexaVendor`";declare -p strHexaVendor
  strHexaProduct="`echo "$strInputKbdData" |grep product |grep "0x.*" -o |tr "[:lower:]" "[:upper:]"`";strHexaProduct="`printf "%04X" $strHexaProduct`";declare -p strHexaProduct

  #### evtest
  (sleep 1;sudo pkill -fe -SIGINT "^evtest /dev/input/event${CFGnDevEvtNum}")& strEvtestData="`SECFUNCexecA -ce sudo evtest /dev/input/event${CFGnDevEvtNum}`";declare -p strEvtestData
  if ! echo "$strEvtestData" |egrep "Input device name:.*Keyboard";then
    echoc -p "Not a keyboard?"
    exit 1
  fi
  if echo "$strEvtestData" |egrep "Input device name:.*MOUSE";then
    echoc -p "invalid device, MOUSE may contain the Keyboard word in it's name"
    exit 1
  fi

  strHexaBus="`echo "$strEvtestData" |grep "Input device ID" |egrep "bus 0x[^ ]*" -o |egrep "0x.*" -o`";strHexaBus="`printf "%04X" $strHexaBus`";declare -p strHexaBus

  strEvalCreateArray="$(echo "$strEvtestData" |egrep "KEY_" |sed -r "s'.*Event code ([[:digit:]]*) \(KEY_([^)]*)\)'\1 \2'" |tr "[:upper:]" "[:lower:]" |sed -r "s'([[:digit:]]*) (.*)'anEvtCodeAndName[\1]=\"\2\";'")";declare -p strEvalCreateArray
  eval "$strEvalCreateArray"
  declare -p anEvtCodeAndName |tr "[" "\n"

  strEvalCreateArray2="$(echo "$strInputKbdData" |egrep -v "= 240" |egrep "^0x" |sed -r "s'0x([^ ]*) = *([[:digit:]]*).*'anEvtCodeAndHexaMscScanVal[\2]=\"\1\";'")";declare -p strEvalCreateArray2
  eval "$strEvalCreateArray2"
  declare -p anEvtCodeAndHexaMscScanVal|tr "[" "\n"

  echo "evdev:input:b${strHexaBus}v${strHexaVendor}p${strHexaProduct}*" >"$strFlKbdDefCfg"
  for nEvtCode in "${!anEvtCodeAndName[@]}";do 
    strHexaMsc="${anEvtCodeAndHexaMscScanVal[${nEvtCode}]-}";
    if [[ -z "$strHexaMsc" ]];then continue;fi;
    echo " KEYBOARD_KEY_${strHexaMsc}=${anEvtCodeAndName[${nEvtCode}]}" >>"$strFlKbdDefCfg"
    strToSort="`cat "$strFlKbdDefCfg"`"
    echo "$strToSort" |sort >"$strFlKbdDefCfg"
  done
  SECFUNCexecA -ce cat "$strFlKbdDefCfg"

  #nEventCode
  #strHexaMscScanVal
  exit 0
fi

######## APPLY BELOW HERE!!! 
bApplyOnSystem=false
strSystemCfgFile="/etc/udev/hwdb.d/98-${SECstrScriptSelfName}.hwdb";declare -p strSystemCfgFile

if $bApplyNewConfig;then
  echoc --info "Preparing to apply a new keyboard keys configuration"
  
  if [[ -z "${1-}" ]];then
    echoc -p "at least one key cfg is required"
    exit 1
  fi
  
  head -n 1 "$strFlKbdDefCfg" |SECFUNCexecA -ce sudo tee "$strSystemCfgFile"
  for strKeyCfg in "$@";do
    echo " $strKeyCfg" |sudo tee -a "$strSystemCfgFile"
  done
  SECFUNCexecA -ce cat "$strSystemCfgFile"
  
  SECFUNCexecA -ce ls -l "/etc/udev/hwdb.d/"*".hwdb"
  SECFUNCexecA -ce ls -l /etc/udev/hwdb.bin &&:
  
  if $bAcceptWithoutReview;then
    :
  else
    if ! echoc -q "all looks good?";then
      exit 0
    fi
  fi
  
  bApplyOnSystem=true
fi

if $bRestoreDefaultCfg;then
  echoc --info "Preparing to restore keyboard keys default configuration"
  
  SECFUNCexecA -ce cat "$strFlKbdDefCfg"
  #if echoc -q "use the default cfg backup above?";then
    SECFUNCexecA -ce sudo cp -vf "$strFlKbdDefCfg" "$strSystemCfgFile"
    SECFUNCexecA -ce cat "$strSystemCfgFile"
  #else
    #SECFUNCexecA -ce sudo trash -v "$strSystemCfgFile" &&:
  #fi
  
  SECFUNCexecA -ce ls -l "/etc/udev/hwdb.d/"*".hwdb" &&:
  SECFUNCexecA -ce ls -l /etc/udev/hwdb.bin &&:

  bApplyOnSystem=true
fi

if $bApplyOnSystem;then
  SECFUNCexecA -ce sudo udevadm hwdb --update
  
  SECFUNCexecA -ce ls -l /etc/udev/hwdb.bin
  
  echoc -w -t 5 "wait a bit before trigger"
  SECFUNCexecA -ce sudo udevadm trigger --sysname-match="event*"
  
  echoc -w -t 5 "wait a bit after trigger to query setxkbmap"
  if $bIgnoreNumlock || ! setxkbmap -query |egrep "options:.*numpad:mac";then
    if $bIgnoreNumlock || echoc -q "force ignore numlock key and grant it will always be a numeric keypad?";then
      SECFUNCexecA -ce setxkbmap -option numpad:mac
    fi
  fi
  
  exit 0
fi

SECFUNCexecA -ce sudo -k

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

