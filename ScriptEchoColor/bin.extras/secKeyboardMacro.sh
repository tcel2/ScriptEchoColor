#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

eval `secinit --extras`

#: ${strEnvVarUserCanModify:="test"}
#export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
#export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
strWindowNameRegex=""
astrKeySequenceList=()

: ${CFGfDelayBetweenMacroPlays:=0.5};
export CFGfDelayBetweenMacroPlays #help 

: ${CFGfDelayBetweenKeyStrokes:=0.5};
export CFGfDelayBetweenKeyStrokes #help 

strDesc="temp";

: ${CFGbSpeakEnabled:=true};
export CFGbSpeakEnabled #help 

: ${CFGbSpeakDisabled:=true};
export CFGbSpeakDisabled #help 

strText=""

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\tUpper left screen corner (x,y<50,50) is a cursor hotspot to activate the macro."
		SECFUNCshowHelp --colorize "\tUses: xdotool key; to perform key strokes"
		SECFUNCshowHelp --colorize "\t<strWindowNameRegex> <astrKeySequenceList...>"
#		SECFUNCexecA -DFce SECFUNCcfgFileName --get
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--description" || "$1" == "-d" ]];then #help <strDesc> is an explanation informing what the macro is for.
		shift
		strDesc="${1-}"
	elif [[ "$1" == "--copy" || "$1" == "-c" ]];then #help <strText> put this text (can be formatted like tabs etc) on the clipboard (will disable clipboard show loop)
		shift
		strText="${1-}"
#	elif [[ "$1" == "--shutupall" || "$1" == "-s" ]];then #help do not speak anything
#		bSpeakEnabled=false
#		bSpeakDisabled=false
#	elif [[ "$1" == "--shutupdis" || "$1" == "-i" ]];then #help do not speak disable text
#		bSpeakDisabled=false
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

strWindowNameRegex="${1-}"
shift&&:
astrKeySequenceList=("${@-}")

if [[ -z "$strWindowNameRegex" ]];then
	echoc -p "invalid strWindowNameRegex='$strWindowNameRegex'"
	exit 1
fi
if [[ -z "${astrKeySequenceList[@]-}" ]];then
	echoc -p "invalid astrKeySequenceList '`declare -p astrKeySequenceList`'"
	exit 1
fi

eval `xdotool getdisplaygeometry |sed -r "s'(.*) (.*)'nScreenW=\1;nScreenH=\2;'"`
echo "nScreenW='$nScreenW'"
echo "nScreenH='$nScreenH'"

function FUNCudpateCursorPos(){
	eval `xdotool getmouselocation |tr ": " "=;"`
	nCursorX=$x
	nCursorY=$y
}
FUNCudpateCursorPos #initialize

bUsingPaste=false
if echo "${astrKeySequenceList[@]}" |grep "ctrl+v" -iw;then
	bUsingPaste=true
fi

nWindowId="`xdotool search "$strWindowNameRegex"`"
if [[ -n "$nWindowId" ]];then
	echoc --info "Running macro: '$strDesc'"
	
	if $bUsingPaste;then
		if [[ -z "$strText" ]];then
			while true; do
				strText="`xclip -selection clipboard -o`"
				echo "strText='$strText'"
				if echoc -q "clipboard contents above, proceed?";then break;fi
			done
		fi
	fi
	
	bSayOnce=true
	bSayDisabledOnce=true
	while true;do
		FUNCudpateCursorPos
		
		if((nCursorX<50 && nCursorY<50));then #activation area check
			if $bSayOnce;then	
				if $CFGbSpeakEnabled;then echoc --say "macro activated";fi
				bSayOnce=false;
			fi
			
			if $bUsingPaste;then
				strClipboard="`xclip -selection clipboard -o`"
				if [[ "$strClipboard" != "$strText" ]];then
					SECFUNCechoWarnA "updating clipboard, was strClipboard='$strClipboard'"
					echo -ne "$strText" |xclip -selection clipboard
				fi
			fi
		
			SECFUNCexecA -ce xdotool windowactivate $nWindowId
			
			# key --delay does not work well, ex.: ctrl+v will paste and add "v" ...
			for strKey in "${astrKeySequenceList[@]}";do
				SECFUNCexecA -ce xdotool key "${strKey}"
				sleep $CFGfDelayBetweenKeyStrokes
			done
			
			bSayDisabledOnce=true
			
			sleep $CFGfDelayBetweenMacroPlays
		else
			if $bSayDisabledOnce;then
				if $CFGbSpeakDisabled;then echoc --say "macro disabled, move cursor to upper left screen corner to enable it";fi
				bSayDisabledOnce=false;
			fi
			
			bSayOnce=true
		fi
	done
fi

