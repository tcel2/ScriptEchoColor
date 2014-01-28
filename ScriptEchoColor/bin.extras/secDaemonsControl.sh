#!/bin/bash

# Copyright (C) 2013-2014 by Henrique Abdalla
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

############################# INIT ###############################
strSelfName="`basename "$0"`"

eval `secinit`

SECFUNCcfgRead
if [[ -z "$bHoldScripts" ]];then
	SECFUNCcfgWriteVar bHoldScripts=false
fi

############################# OPTIONS ###############################
bReleaseAll=false
bHoldAll=false
bCheckHold=false
while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--checkhold" || "$1" == "-c" ]];then #help the script executing this will hold/wait
		bCheckHold=true
	elif [[ "$1" == "--holdall" || "$1" == "-h" ]];then #help will request all scripts to hold execution
		bHoldAll=true
	elif [[ "$1" == "--releaseall" || "$1" == "-r" ]];then #help will request all scripts to continue execution
		bReleaseAll=true
	elif [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	
	shift
done

############################# MAIN ###############################
if $bCheckHold;then
	if $bHoldScripts;then
		echoc --info "$strSelfName: script on hold..."
	
		SECONDS=0
		while $bHoldScripts;do
			echo -ne "${SECONDS}s (hit: 'y' to run once; 'r' to release all)\r"
		
			#sleep 5
			read -n 1 -t 5 strResp
			if [[ "$strResp" == "y" ]];then
				break
			elif [[ "$strResp" == "r" ]];then
				SECFUNCcfgWriteVar bHoldScripts=false
				break
			fi
		
			SECFUNCcfgRead
		done
		
		echo
		echoc --info "$strSelfName: script continues..."
	fi
elif $bReleaseAll;then
	echoc --info "scripts will continue execution"
	SECFUNCcfgWriteVar bHoldScripts=false
elif $bHoldAll;then
	echoc --info "scripts will hold execution"
	SECFUNCcfgWriteVar bHoldScripts=true
fi

