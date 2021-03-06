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

##################### INIT/CFG/FUNCTIONS
source <(secinit)

declare -A astrDeviceList=()
strDeviceIdLastChosen=""
bUseLastChosenDevice=false
astrFileToPushList=()

######################### FUNCTIONS

function FUNCbluetoothChannel () {
	sdptool browse "$1" |egrep "Service Name: (OBEX |)Object Push" -A 20 |grep "Channel: "|head -n 1 |tr -d ' ' |cut -d: -f2
}

function FUNCrescan() {
	# do not empty the list to keep undetected configured! #astrDeviceList=()
	
	echoc --alert "wait, bluetooth devices being scanned..."
	if ! strDevices="`hcitool scan |tail -n +2`";then #skips 1st "scanning..." line
		echoc -p "unable to scan for bluetooth devices"
		return 1
	fi

	#bkpIFS="$IFS";IFS=$'\n';readarray astrDevices < <(echo "$strDevices");IFS="$bkpIFS";
  astrDevices=()
  SECFUNCarrayWork --fill astrDevices echo "$strDevices"
	#IFS=$'\n' read -d '' -r -a astrDevices < <(echo "$strDevices")
  declare -p astrDevices >&2
	#~ echo "astrDevices[@]=(${astrDevices[@]-})" >&2
	if((`SECFUNCarraySize astrDevices`>0));then
		for strDevice in "${astrDevices[@]}";do 
			if [[ -n "$strDevice" ]];then
				echo "strDevice='$strDevice'" >&2
				astrDeviceList["`echo "$strDevice" |cut -f2`"]="`echo "$strDevice" |cut -f3`"
			fi
		done
	fi
	
	if((${#astrDeviceList[@]}==0));then
		echoc -p "no bluetooth devices found..."
		return 1
	fi

	SECFUNCcfgWriteVar astrDeviceList

	echoc -x "cat \"$SECcfgFileName\""&&:
}

####################### MAIN
bNautilusMode=false
bReUseLast=false
bInteractive=true
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "<astrFileToPushList>... Send files thru bluetooth."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--nautilus" ]];then #internal use, no user help..., enables the nautilus mode.
		bNautilusMode=true
	elif [[ "$1" == "--uselast" ]] || [[ "$1" == "-l" ]];then #help re-use the last chosen target bluetooth device
		bReUseLast=true
	elif [[ "$1" == "--noninteractive" ]] || [[ "$1" == "-n" ]];then #help just exit on failures and questions use defaults
		bInteractive=false
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done
astrFileToPushList+=("$@")

declare -p NAUTILUS_SCRIPT_SELECTED_FILE_PATHS&&:
#echo "NAUTILUS_SCRIPT_SELECTED_FILE_PATHS=${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}"
#xterm

if $bNautilusMode;then
#	eval astrNautilusSelectedFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
	#bkpIFS="$IFS";IFS=$'\n';readarray astrNautilusSelectedFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS");IFS="$bkpIFS";
	IFS=$'\n' read -d '' -r -a astrNautilusSelectedFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")&&: #TODO 'returned 1' but worked; is the EOF error?
	#declare -p astrNautilusSelectedFiles
	astrFileToPushList+=("${astrNautilusSelectedFiles[@]}")
	#declare -p astrFileToPushList
else
	# Check for Nautilus Mode
	if [[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}" ]];then
		#eval astrNautilusSelectedFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
		xterm -e "\"$0\" --nautilus" #"${astrNautilusSelectedFiles[@]}"
		exit 0
	fi
fi

echoc --info "Will work with files:"
for strFileToPush in "${astrFileToPushList[@]}";do
	echo "File: '$strFileToPush' type='`stat -c %F "$strFileToPush"`'"
	if [[ ! -f "$strFileToPush" ]];then
		echoc -w -t 60 -p "invalid strFileToPush='$strFileToPush'"
		exit 1
	fi
done

SECFUNCcfgReadDB

echoc -x "cat \"$SECcfgFileName\""&&:

if $bReUseLast;then
	bUseLastChosenDevice=true
else
	if [[ -n "$strDeviceIdLastChosen" ]];then
		if $bInteractive;then
			if yad --title "$SECstrScriptSelfName" --question --text="Use the last chosen device?\n\tstrDeviceIdLastChosen='$strDeviceIdLastChosen'\n\tDevice Name='${astrDeviceList[$strDeviceIdLastChosen]-}'";then
				bUseLastChosenDevice=true
			fi
		fi
	fi
fi

if $bInteractive;then
	if ! $bUseLastChosenDevice;then
		strDeviceId=""
		while [[ -z "$strDeviceId" ]];do
			bRescan=false
			if ! $bRescan && [[ -z "${astrDeviceList[@]-}" ]];then
				bRescan=true
			fi
			if ! $bRescan && echoc -q -t 3 "re-scan bluetooth devices (exit ctrl+c)?";then
				bRescan=true
			fi

			if $bRescan;then
				while true;do
					if FUNCrescan;then
						break;
					fi
				
					if ! echoc -q "no devices found, re-scan bluetooth devices?";then
						exit 0
					fi
				done
			fi

			astrZenityValues=()
			nIndex=0
			for strDeviceId in "${!astrDeviceList[@]}";do
				astrZenityValues+=( "$((nIndex++))" )
				astrZenityValues+=( "$strDeviceId" )
				astrZenityValues+=( "${astrDeviceList[$strDeviceId]}" )
			done
		
			strDeviceId=$(yad --title "$SECstrScriptSelfName" --list --radiolist \
				--text="Select one Bluetooth device." \
        --print-column=2 --separator="" \
				--column="Index" --column="ID" --column="Name" \
				"${astrZenityValues[@]}")&&: # column 2 is the ID

			if [[ -n "$strDeviceId" ]];then
				SECFUNCcfgWriteVar strDeviceIdLastChosen="$strDeviceId"
			fi
		done
	fi
fi

echoc --info "strDeviceIdLastChosen='$strDeviceIdLastChosen' Device Name='${astrDeviceList[$strDeviceIdLastChosen]-}'"

while true;do
	nBluetoothChannel="`FUNCbluetoothChannel "$strDeviceIdLastChosen"`"&&:
	if SECFUNCisNumber -dn "$nBluetoothChannel";then
		break;
	else
		if $bInteractive;then
			if echoc -q -t 3 -p "failed to acquire nBluetoothChannel='$nBluetoothChannel', exit? (if not, will retry)";then
				exit 1
			fi
		else
			exit 1
		fi
	fi
done

#for strFileToPush in "${astrFileToPushList[@]}";do
#	if [[ ! -f "$strFileToPush" ]];then
#		echoc -w -t 60 -p "invalid strFileToPush='$strFileToPush'"
#		exit 1
#	else
#		SECFUNCexec -c --echo \
#			obexftp --nopath --noconn \
#				--uuid none \
#				--bluetooth "$strDeviceIdLastChosen" \
#				--channel "$nBluetoothChannel" \
#				--put "$strFileToPush"
#	fi
#fi
if ! SECFUNCexec -c --echo \
	obexftp --nopath --noconn \
		--uuid none \
		--bluetooth "$strDeviceIdLastChosen" \
		--channel "$nBluetoothChannel" \
		--put "${astrFileToPushList[@]}";then
	echoc --info "TODO: even succeeding, the return status is always as failed. how to be sure it worked?"
fi

if $bInteractive;then
	echoc -w -t 60
fi

