#!/bin/bash
# Copyright (C) 2019 by Henrique Abdalla
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

source <(secinit) # this causes a small delay but is actually good  :)

: ${bAllowDbgMode:=false} #help
bDbg=false
if $bAllowDbgMode;then
  if [[ "$1" != "--dbg" ]];then  #DBG
    xterm -e $0 --dbg "$@"
    exit 0
  else
    bDbg=true
    shift
  fi
fi

# initializations and functions

: ${bWriteCfgVars:=false} #help false to speedup if writing them is unnecessary
: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bExample=false
bShowLastLog=false
CFGstrTest="Test"
astrRemainingParams=()
strComment="edge action"
nRelativeMoveX=0
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t[nRelativeMoveX] create edge actions on your window managers to let mouse be moved furter, commands example:"
    echo "$0 -m 'Left Edge Action' -- -10"
    echo "$0 -m 'Right Edge Action' -- 10"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-m" || "$1" == "--comment" ]];then #help <strComment>
		shift;strComment="${1-}"
	elif [[ "$1" == "-l" || "$1" == "--showlastactionlog" ]];then #help ~single
		bShowLastLog=true
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

if $bShowLastLog;then
  declare -p SECstrRunLogFile
  strFlLastLog="`ls "$SECstrTmpFolderLog/$SECstrScriptSelfName."*".log" -t |grep -v "$SECstrRunLogFile" |head -n 1`"
  if [[ -f "$strFlLastLog" ]];then
    ls -l "$strFlLastLog"
    SECFUNCexecA -ce -m "last action's log" cat "$strFlLastLog"
  else
    echoc -p "no previous log found"
  fi
  exit 0
fi

function FUNCexit() {
  if $bDbg;then echoc -w -t 60;fi
  exit $1
}

# Main code

date >&2

# collect params
if SECFUNCarrayCheck -n astrRemainingParams;then # this may happen if the first value (x) is a negative decimal, therefore only accepted after '--' param
  nRelativeMoveX="${astrRemainingParams[0]}"
else
  nRelativeMoveX="$1";shift
  #nRelativeMoveY=$1;shift
fi
declare -p nRelativeMoveX >&2

#SECFUNCuniqueLock --waitbecomedaemon # if a daemon or to prevent simultaneously running it

strXRandrInfo="`xrandr`"
nMinSH=$(echo "$strXRandrInfo" |grep connected -w |egrep "[[:digit:]]+x[[:digit:]]+" -o |tr x ' ' |awk '{print $2}' |sort -n |head -n 1)
nSW=$(echo "$strXRandrInfo" |grep Screen |egrep -o 'current [[:digit:]]*' |tr -d '[[:alpha:]] ')
declare -p nSW nMinSH >&2

strXdtInfoToEval="`xdotool getmouselocation|tr ': ' '=;'`"
declare -p strXdtInfoToEval >&2
eval "$strXdtInfoToEval" >&2
declare -p x y screen window; >&2

#####################################
### the user may have changed his/her mind, so double check for the mouse postion being at the edge! (the 1st check is the Window Manager edge action)
: ${nEdgeDist:=3} #help
if((x > nEdgeDist)) && ((x < (nSW-nEdgeDist) ));then FUNCexit 0;fi
if((y < nEdgeDist*3)) || ((y > (nSW-nEdgeDist*3) ));then FUNCexit 0;fi # this one is to protect the corners

##### move it
nNewX=$((x + $nRelativeMoveX))
declare -p nNewX >&2
if((nNewX<0));then ((nNewX+=nSW))&&:;fi
if((nNewX>nSW));then ((nNewX-=nSW))&&:;fi
declare -p nNewX >&2

nNewY=$y
declare -p nNewY >&2
if((nNewY>nMinSH));then nNewY=$((nMinSH-1))&&:;fi # this fix is important in case of multiple monitors with different resolutions!
declare -p nNewY >&2

xdotool getmouselocation >&2
#xdotool mousemove_relative -- $nNewX 0
SECFUNCexecA -ce xdotool mousemove -- $nNewX $nNewY # this fails `xdotool mousemove_relative ...`
xdotool getmouselocation >&2

FUNCexit 0 # important to have this default exit value in case some non problematic command fails before exiting
