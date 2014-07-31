#!/bin/bash
# Copyright (C) 2004-2014 by Henrique Abdalla
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

eval `secinit`

#SECFUNCshowHelp --colorize "<device> ex.: sde (that must be at '/dev/')"
#strDevBase="${1-}";
#if [[ -z "${strDevBase}" ]];then
#	echoc -p "missing device param"
#	exit 1
#fi
#if [[ "${strDevBase:0:1}" != "/" ]];then
#	strDevBase="/dev/$strDevBase"
#fi
#if [[ ! -a "${strDevBase}" ]];then
#	echoc -p "missing device '$strDevBase'"
#	exit 1
#fi
#strDevBaseTest=$(ls -l "$strDevBase");
#if [[ "${strDevBaseTest:0:1}" != "b" ]];then
#	echoc -p "invalid device '$strDevBaseTest', must be a block device"
#	exit 1
#fi
#echoc --info "working with: $strDevBase"

#bById=false
#bByLabel=false
#bByPath=false
#bByUuid=false
bList=false
bRetry=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "To let a backup storage go safely sleep, its base id must be supplied (the one that doesnt ends with '-part?')."
		SECFUNCshowHelp --colorize "<deviceId1> [deviceId2] ..."
		SECFUNCshowHelp
		exit
#	elif [[ "$1" == "--byid" ]];then #help 
#		bById=true
#	elif [[ "$1" == "--bylabel" ]];then #help 
#		bByLabel=true
#	elif [[ "$1" == "--bypath" ]];then #help 
#		bByPath=true
#	elif [[ "$1" == "--byuuid" ]];then #help 
#		bByUuid=true
	elif [[ "$1" == "--list" ]];then #help list all devices available
		bList=true
	elif [[ "$1" == "--retry" ]];then #help device may not be ready so keep trying
		bRetry=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done
astrDevTemp=("$@")

bExitWithError=false
if ! $bList && [[ -z "${astrDevTemp[@]-}" ]];then
	bList=true
	bExitWithError=true
fi

strDevIdsPath="/dev/disk/by-id"
if $bList;then
	echoc -x "tree $strDevIdsPath -ft"
	if $bExitWithError;then 
		echoc --alert "choose the devices from above"
		exit 1;
	else 
		exit 0;
	fi
fi

astrDev=()
for strDevTemp in "${astrDevTemp[@]-}";do
	# fix path
	if [[ "$strDevTemp" == /* ]];then
		if [[ "`dirname "$strDevTemp"`" != "$strDevIdsPath" ]];then
			echoc -p "invalid '$strDevTemp', must be at '$strDevIdsPath'"
			exit 1
		fi
	else
		strDevTemp="$strDevIdsPath/$strDevTemp"
	fi
	
	if $bRetry;then
		while [[ ! -a "$strDevTemp" ]];do
			echoc -w -t 60 "waiting device '$strDevTemp' become available"
		done
	fi
	
	# add to array
	if [[ -L "$strDevTemp" ]];then
		if [[ "$strDevTemp" == *-part? ]];then
			astrDev+=("`readlink -f "$strDevTemp"`")
		else
			# add partitions to array in case it is base device
			for strDevTemp2 in `ls -1 "${strDevTemp}-part"*`;do
				astrDev+=("`readlink -f "$strDevTemp2"`")
			done
		fi
	else
		echoc -p "invalid device id '$strDevTemp'"
		exit 1
	fi
done

echoc --info "Devices: ${astrDev[@]}"

SECFUNCuniqueLock --daemonwait

varset --allowuser --show nCheckDelay=60
varset --allowuser --show nWaitSecondsToUnmount=300 #5min

#astrDev=(`ls "$strDevBase"?`)

for nIndex in ${!astrDev[@]};do
	echoc --info "Init timer for: ${astrDev[nIndex]}"
	SECFUNCdelay "Device${nIndex}" --init
done

while true;do
	for nIndex in ${!astrDev[@]};do
		strDev="${astrDev[nIndex]}"
		
		if mount |grep -q "^$strDev";then
#			strStatus[nIndex]=$(
#				(iostat -d $strDev \
#					|sed "/^$/d" \
#					|tail -n 1 \
#				 && \
#				 iostat -d $strDev -x \
#				 	|sed "/^$/d" \
#				 	|tail -n 1) \
#				|tr "\n" " " \
#				|sed -r "s'[[:blank:]]+' 'g"
#			)
			strStatus[nIndex]=$(iostat -d $strDev |sed "/^$/d" |tail -n 1 |sed -r "s'[[:blank:]]+' 'g" |cut -d" " -f 5,6)
			
			bResetTimer=false
			if [[ "${strStatusPrevious[nIndex]-}" != "${strStatus[nIndex]}" ]];then
				bResetTimer=true
			fi
			if pgrep unison >/dev/null;then
				echoc --info "$strDev timer reset, 'unison' is running (also keep storage active)"
				ps --no-headers -p `pgrep unison`
				strDeviceMountedPath="`mount |grep "$strDev" |sed -r "s'^$strDev on (.*) type .*'\1'"`"
				ls -l "$strDeviceMountedPath" >/dev/null #TODO does this help keep storage active?
				bResetTimer=true
			fi
			if $bResetTimer;then
				SECFUNCdelay "Device${nIndex}" --init
			fi

			echo "$strDev inactive for `SECFUNCdelay "Device${nIndex}" --getsec`s, Status '${strStatus[nIndex]}'"
			
			if((`SECFUNCdelay "Device${nIndex}" --getsec`>nWaitSecondsToUnmount));then
				echoc -x "umount '$strDev'"
				SECFUNCdelay "Device${nIndex}" --init #initialize umounted time
			fi
		
			strStatusPrevious[nIndex]="${strStatus[nIndex]}"
		else
			echoc --info "$strDev unmounted for `SECFUNCdelay "Device${nIndex}" --getsec`s"
		fi
	done
	
	echoc -w -t $nCheckDelay
done

