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
eval `secinit`

declare -A astrDeviceList=()
strDeviceIdLastChosen=""
bUseLastChosenDevice=false

######################### FUNCTIONS

function FUNCrescan() {
	astrDeviceList=()
	
	echoc --alert "wait, bluetooth devices being scanned..."
	if ! strDevices="`hcitool scan |tail -n +2`";then #skips 1st "scanning..." line
		echoc -p "unable to scan for bluetooth devices"
		exit 1
	fi

	bkpIFS="$IFS";IFS=$'\n';readarray astrDevices < <(echo "$strDevices");IFS="$bkpIFS";
	for strDevice in "${astrDevices[@]}";do 
		astrDeviceList["`echo "$strDevice" |cut -f2`"]="`echo "$strDevice" |cut -f3`"
	done

	SECFUNCcfgWriteVar astrDeviceList

	echoc -x "cat \"$SECcfgFileName\""&&:
}

####################### MAIN
SECFUNCcfgReadDB

echoc -x "cat \"$SECcfgFileName\""&&:

if [[ -n "$strDeviceIdLastChosen" ]];then
	if zenity --title "$SECstrScriptSelfName" --question --text="Use the last chosen device?\n\tstrDeviceIdLastChosen='$strDeviceIdLastChosen'\n\tDevice Name='${astrDeviceList[$strDeviceIdLastChosen]}'";then
		bUseLastChosenDevice=true
	fi
fi

if ! $bUseLastChosenDevice;then
	bRescan=false
	if ! $bRescan && [[ -z "${astrDeviceList[@]-}" ]];then
		bRescan=true
	fi
	if ! $bRescan && echoc -q "re-scan bluetooth devices?";then
		bRescan=true
	fi

	if $bRescan;then
		FUNCrescan
	fi

	astrZenityValues=()
	nIndex=0
	for strDeviceId in "${!astrDeviceList[@]}";do
		astrZenityValues+=("$((nIndex++))")
		astrZenityValues+=("$strDeviceId")
		astrZenityValues+=("${astrDeviceList[$strDeviceId]}")
	done
	strDeviceId=$(zenity --title "$SECstrScriptSelfName" --list --radiolist \
		--text="Select one Bluetooth device." \
		--column="Index" --column="ID" --column="Name" \
		"${astrZenityValues[@]}")

	if [[ -n "$strDeviceId" ]];then
		SECFUNCcfgWriteVar strDeviceIdLastChosen="$strDeviceId"
	fi
fi

echoc --info "strDeviceIdLastChosen='$strDeviceIdLastChosen' Device Name='${astrDeviceList[$strDeviceIdLastChosen]}'"








