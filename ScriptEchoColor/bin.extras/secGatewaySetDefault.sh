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

source <(secinit)

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
CFGstrInterface=""
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help useful when you enable smartphone usb tethering and is unable to navigate using the other connected internet interface
		SECFUNCshowHelp --colorize "\t[CFGstrInterface]"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
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

SECFUNCexecA -ce route -n

SECFUNCexecA -ce ip -4 route list 0/0

#aWifi=(`route |egrep -o "wlan." |uniq`)

echoc --info "chose interface:"
strIface="`echoc -S "@D$CFGstrInterface"`"

function FUNCgwGuess(){
	strDest="`route -n |egrep -v "^0[.]0[.]0[.]0" |grep "$strIface" |gawk '{print $1;}'`"
	if [[ -z "$strDest" ]];then
		echoc -p "invalid strIface='$strIface'"
		exit 1
	fi

	aDest=(`echo "$strDest" |tr "." " "`)
	aDest[3]=1 #TODO is this value the default to be guessed???

	echo "${aDest[@]}" |tr " " "."
}

strGW="`ip -4 route list 0/0 |grep "$strIface" |cut -d' ' -f 3`"
if [[ -z "$strGW" ]];then
	strGW="`FUNCgwGuess`"
#	if [[ -z "$strGW" ]];then
#		echoc -p "invalid strGW='$strGW'"
#		exit 1
#	fi
fi

if echoc -q "remove all b4 setting the right one?";then
	astrGW=(`ip -4 route list 0/0 |cut -d ' ' -f3,5`)
	for((i=0;i<${#astrGW[@]};i+=2));do
		SECFUNCexecA -ce sudo route del default gw ${astrGW[i]} ${astrGW[i+1]}&&:
	done
	SECFUNCexecA -ce ip -4 route list 0/0
fi

SECFUNCexecA -ce sudo route add default gw "$strGW" "$strIface"&&:
SECFUNCexecA -ce ip -4 route list 0/0

SECFUNCexecA -ce sudo -k

SECFUNCexecA -ce route -n

