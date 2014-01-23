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

strSelfName="`basename "$0"`"

eval `secinit`

SECFUNCcfgRead
if [[ -z "$bHoldScripts" ]];then
	SECFUNCcfgWriteVar bHoldScripts=false
fi

while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--checkhold" ]];then #help the script executing this will hold/wait
		
		if $bHoldScripts;then
			echoc --info "$strSelfName: script on hold..."
			
			SECONDS=0
			while $bHoldScripts;do
				echo -ne "${SECONDS}s (hit 'y' to run once)\r"
				
				#sleep 5
				read -n 1 -t 5 strResp
				if [[ "$strResp" == "y" ]];then
					break
				fi
				
				SECFUNCcfgRead
			done
		
			echo
			echoc --info "$strSelfName: script continues..."
		fi
		
		exit
	elif [[ "$1" == "--hold" ]];then #help will request scripts to hold execution
		echoc --info "scripts will hold execution"
		SECFUNCcfgWriteVar bHoldScripts=true
		exit
	elif [[ "$1" == "--continue" ]];then #help will request scripts to continue execution
		echoc --info "scripts will continue execution"
		SECFUNCcfgWriteVar bHoldScripts=false
		exit
	elif [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	
	shift
done

