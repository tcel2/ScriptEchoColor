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

# this is actually just a simple/single way to use a chosen terminal in the whole project

source <(secinit)

#~ SECFUNCshowHelp --colorize "\tRun this like you would xterm or mrxvt, so to exec something requires -e param."
#~ SECFUNCshowHelp --colorize ""
#~ SECFUNCshowHelp --colorize "\tIf first option is --getcmd it will just output the full command and exit."
#~ SECFUNCshowHelp --colorize "\t\tCan be used as \`source <(secTerm.sh --getcmd)\`"
#~ SECFUNCshowHelp --colorize "\t\t\`declare -p SECastrFullTermCmd\`"

: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
bJustOutput=false
bDisown=false
: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
bRaise=false
bOnTop=false
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help overriding term option
		SECFUNCshowHelp --colorize "\tRun this like you would xterm or mrxvt, so to exec something requires -e param."
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
  elif [[ "$1" == "--getcmd" ]];then #help if used as first option it will just output the full command and exit. Can be used as ex.:\n\t\tsource <(secTerm.sh --getcmd -- -e sleep 10).\n\t\tdeclare -p SECastrFullTermCmd.\n\t\t"${SECastrFullTermCmd[@]}"
    bJustOutput=true
  elif [[ "$1" == "--ontop" ]];then #help 
    bOnTop=true
  elif [[ "$1" == "--focus" ]];then #help activate/focus/raise
    bRaise=true
  elif [[ "$1" == "--disown" ]];then #help 
    bDisown=true
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
	elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #help MISSING DESCRIPTION
		bExample=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams, and further passed to the X term
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

# Main code
astrXTermParms=( "${astrRemainingParams[@]}" )
#~ if((`SECFUNCarraySize astrXTermParms`==0));then
  #~ astrXTermParms+=(bash)
#~ fi

SECastrFullTermCmd=()

#~ function FUNCrun238746478() {
  #~ source <(secinit)
  
  #~ declare -p SECastrFullTermCmd
  #~ echo "SECTERMrun: ${astrXTermParms[@]}"
  
  #~ "${astrXTermParms[@]}";nRet=$?

  #~ if((nRet!=0));then
    #~ declare -p nRet
    #~ if SECFUNCisShellInteractive;then
      #~ echoc -p -t 60 "exit error $nRet"
    #~ fi
  #~ fi
#~ };export -f FUNCrun238746478

strConcatParms="${astrXTermParms[@]-}"
strTitle="SECTerm_`SECFUNCfixId --justfix -- "$strConcatParms"`"
if which mrxvt >/dev/null 2>&1;then
  # mrxvt chosen because of: 
  #  low memory usage; 
  #  `xdotool getwindowpid` works on it;
  #  TODO rxvt does not kill some child proccesses when it is closed, if so, which ones?
  #  anyway none will kill(or hup) if the child was started with sudo!
  SECastrFullTermCmd+=(mrxvt -hold 0 -sl 1000 -aht +showmenu) #max -sl is 65535
  if [[ -n "$strConcatParms" ]];then
    SECastrFullTermCmd+=(-title "$strTitle" "${astrXTermParms[@]}")
  fi
  #SECastrFullTermCmd+=(mrxvt -aht +showmenu -title "`SECFUNCfixId --justfix -- "$strConcatParms"`" bash -c "FUNCrun238746478")
else
  #SECastrFullTermCmd+=(xterm -e bash -c "FUNCrun238746478") # fallback
  SECastrFullTermCmd+=(xterm "${astrXTermParms[@]}-") # fallback
fi

declare -p SECastrFullTermCmd # to be reused must be evaluated outside here or imported as source code

if $bJustOutput;then exit 0;fi

########### RUNS BELOW HERE ###########

SECFUNCarraysExport #important for exported arrays before calling/reaching this script
if $bOnTop;then SECFUNCCwindowOnTop "$strTitle";fi
if $bRaise;then SECFUNCCwindowCmd --focus "$strTitle";fi
if $bDisown;then
  ( "${SECastrFullTermCmd[@]}"&disown )&disown &&:
else
  "${SECastrFullTermCmd[@]}";nRet=$?
   
  if((nRet!=0));then
    declare -p nRet
    source <(secinit)
    if SECFUNCisShellInteractive;then
      echoc -p -t 60 "exit error $nRet"
    fi
  fi
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
