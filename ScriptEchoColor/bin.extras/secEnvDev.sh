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

strBN="`basename "$0"`"

strCfg="$HOME/.$strBN.cfg"

strSECDEVPath="`cat "$strCfg"`"
strSECDEVPath="`realpath -e "$strSECDEVPath"`"
declare -p strSECDEVPath
if [[ ! -f "$strSECDEVPath/bin/secinit" ]];then
  echo "dev path not set at '$strCfg'" >&2
  exit 1
fi

bAlreadyDev=false;
if [[ "$(realpath -e "`secGetInstallPath`")" == "$strSECDEVPath" ]];then
  bAlreadyDev=true;
fi

if ! $bAlreadyDev;then
  strDevExec="$strSECDEVPath/bin.extras/$strBN"
  if ! cmp $0 "$strDevExec";then
    echo "'$0' is newer at dev path '$strDevExec', using newer" >&2
    "$strDevExec" "$@"
    exit 0;
  fi
fi

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bCdDevPath=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
bExitAfterCmd=false
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t[commands]"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
	elif [[ "$1" == "-c" || "$1" == "--cd" ]];then #help cd to SEC dev path
		bCdDevPath=true
	elif [[ "$1" == "--exit" ]];then #help exit after running user command
		bExitAfterCmd=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
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
strRCFileTmp="`mktemp`"
ls -l "$strRCFileTmp"
if ! $bAlreadyDev;then
  strPATHtmp=""
  strPATHtmp+="$strSECDEVPath/bin:"
  strPATHtmp+="$strSECDEVPath/bin.extras:"
  strPATHtmp+="$strSECDEVPath/bin.examples:"
  strPATHtmp+="$PATH"

  SECFUNCcleanEnvironment
  cat "$HOME/.bashrc" >>"$strRCFileTmp"
  echo >>"$strRCFileTmp"
  echo "########################################################" >>"$strRCFileTmp"
  echo "#ScriptEchoColor development specifics" >>"$strRCFileTmp"
  echo >>"$strRCFileTmp"
  echo "export PATH='$strPATHtmp';" >>"$strRCFileTmp"
  echo >>"$strRCFileTmp"
  echo "source <(secinit --force --extras);" >>"$strRCFileTmp"
  

  : ${SECDEVbUnboundErr:=false};export SECDEVbUnboundErr
  echo '
  function SECFUNCbeforePromptCommand_CustomUserCommand(){
    :
  }
  function SECFUNCpromptCommand_CustomUserText(){ # function redefined from secFuncPromptCommand.sh
    # Result of: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
    local lstrBanner="\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"
    
    local lstrInternetConn=""
    if nmcli d |egrep -q "ethernet[ ]*connected";then lstrInternetConn+="Ether";fi
    if nmcli d |egrep -q "wifi[ ]*connected";then lstrInternetConn+="Wifi";fi
    if [[ -z "$lstrInternetConn" ]];then lstrInternetConn="OFF";fi

    echo "${lstrBanner}[INET:${lstrInternetConn}]"
  }
  function FUNCcleanTraps(){
    set +E #without this, causes trouble too with bash auto completion
    trap -- ERR #trap ERR must be disabled to avoid problems while typing commands that return false...
    
    # good way to avoid bash completion problem, but why it happens?
    if $SECDEVbUnboundErr;then 
      set -u;
    else 
      set +u;
    fi
  }
  function SECFUNCpromptCommand_CustomUserCommand(){
    FUNCcleanTraps #put here to avoid segfaulting current bash with user commands
  }
  ' >>"$strRCFileTmp"
	#~ cat >>"$strRCFileTmp" \
#~ <<EOF
	#~ function SECFUNCpromptCommand_CustomUserText(){ # function redefined from secFuncPromptCommand.sh
		#~ # Result of: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
		#~ local lstrBanner="\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"
		
		#~ local lstrInternetConn=""
		#~ if nmcli d |egrep -q "ethernet[ ]*connected";then lstrInternetConn+="Ether";fi
		#~ if nmcli d |egrep -q "wifi[ ]*connected";then lstrInternetConn+="Wifi";fi
		#~ if [[ -z "$lstrInternetConn" ]];then lstrInternetConn="OFF";fi

		#~ echo "${lstrBanner}[INET:${lstrInternetConn}]"
	#~ }
#~ EOF
  
fi

if $bCdDevPath;then
  echo >>"$strRCFileTmp"
  echo "cd '$strSECDEVPath';" >>"$strRCFileTmp"
fi

if [[ -n "${@-}" ]];then
  astrSECDEVCmds=("$@")
  echo >>"$strRCFileTmp"
  echo "`declare -p astrSECDEVCmds`;" >>"$strRCFileTmp"
  echo '"${astrSECDEVCmds[@]}";' >>"$strRCFileTmp"
  if $bExitAfterCmd;then
    echo "exit $?;" >>"$strRCFileTmp"
  fi
fi

cat "$strRCFileTmp"
if $bAlreadyDev;then
  source "$strRCFileTmp"
else
  bash --rcfile "$strRCFileTmp"
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
