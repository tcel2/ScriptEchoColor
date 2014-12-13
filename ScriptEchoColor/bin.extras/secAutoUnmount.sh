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
bStillActiveWarn=true
nKeepAliveDelayInMin=30
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "To let a backup storage go safely sleep, its base id must be supplied (the one that doesnt ends with '-part?'). Also detects unison and keeps devices awake."
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
	elif [[ "$1" == "--keepalive" ]];then #help <nKeepAliveDelayInMin> each delay in minutes, auto mount and unmount; the device may become buggy if unmounted for too long
		shift
		nKeepAliveDelayInMin="${1-}"
		
		bKeepAlive=true
	elif [[ "$1" == "--nostillactivewarn" ]];then #help disable audible warning for backup storage being kept active for too long
		bStillActiveWarn=false
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

if ! SECFUNCisNumber -dn "$nKeepAliveDelayInMin";then
	echoc -p "invalid nKeepAliveDelayInMin='$nKeepAliveDelayInMin'"
	exit 1
fi

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

function FUNCupdateDevList() {
	declare -ag astrDev=()
	
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
	
	for nIndex in ${!astrDev[@]};do
		echoc --info "Init timer for: ${astrDev[nIndex]}"
		SECFUNCdelay "Device${nIndex}" --init
	done
}
FUNCupdateDevList

SECFUNCuniqueLock --daemonwait

varset --allowuser --show nCheckDelay=60
varset --allowuser --show nWaitSecondsToUnmount=300 #5min

#astrDev=(`ls "$strDevBase"?`)

declare -A anPidKeepAwake
declare -A astrMountedPaths
while true;do
	for nIndex in ${!astrDev[@]};do
		strDev="${astrDev[nIndex]}"
		
		function FUNCkillLs(){
			if [[ -d "/proc/${anPidKeepAwake[$strDev]-0}" ]];then
				kill -SIGKILL ${anPidKeepAwake[$strDev]}&&:
				anPidKeepAwake[$strDev]="" #cleanup to prevent access to a reused pid
			fi
		}
		
		if mount |grep -q "^$strDev";then
			bResetTimer=false
			bKeepAwake=false

			strLsCmd="ls -lR"
			strDeviceMountedPath="`mount |grep "$strDev" |sed -r "s'^$strDev on (/.*) type .*'\1'"`"
			astrMountedPaths[$strDev]="$strDeviceMountedPath"
			
			function FUNCkillLostLs () { #mainly useful at developing time where this script is exited several times...
				pgrep -fx "$strLsCmd $strDeviceMountedPath" \
					|while read nLsPid;do 
						nLsPPid="`ps --no-headers -o ppid -p $nLsPid`"&&:
						if((nLsPPid==$$));then
							continue
						fi
						
						strLsStat="`ps --no-headers -o stat -p $nLsPid`"&&:
						if [[ "$strLsStat" == "T" ]];then
							echoc -x "kill -SIGKILL $nLsPid #@{b}killing lost ls pid"
						fi
					done
			}
			FUNCkillLostLs

			if pgrep unison >/dev/null;then
				echoc --info "$strDev timer reset, 'unison' is running (also keep storage active)"
				ps --no-headers -p `pgrep unison`

				# trick to keep awake by quickly using ls, this shall force io status changes
				if [[ ! -d "/proc/${anPidKeepAwake[$strDev]-0}" ]];then
					#ls -lR "$strDeviceMountedPath" >/dev/null 2>&1 &
					$strLsCmd $strDeviceMountedPath >/dev/null 2>&1 &
					anPidKeepAwake["$strDev"]=$!
				fi
				kill -SIGCONT ${anPidKeepAwake[$strDev]}&&:
				sleep 0.01
				kill -SIGSTOP ${anPidKeepAwake[$strDev]}&&:
				ps --no-headers -o pid,tty,time,cmd -p ${anPidKeepAwake[$strDev]}&&:
				
				if $bStillActiveWarn;then
					if SECFUNCdelay --checkorinit $((15*60));then
						echoc --info --say "Backup storage still active."
						echoc --alert "Attention, backup storage may heat up."
					fi
				fi
				
				# do not use bResetTimer=true here, ls work should provide enough status changes to make it work...
				bKeepAwake=true
			else
				FUNCkillLs
#				if [[ -d "/proc/${anPidKeepAwake[$strDev]-0}" ]];then
#					kill -SIGKILL ${anPidKeepAwake[$strDev]}&&:
#					anPidKeepAwake[$strDev]="" #cleanup to prevent access to a reused pid
#				fi
			fi
			
			strStatus[nIndex]=$(iostat -d $strDev |sed "/^$/d" |tail -n 1 |sed -r "s'[[:blank:]]+' 'g" |cut -d" " -f 5,6)
			
			if [[ "${strStatusPrevious[nIndex]-}" != "${strStatus[nIndex]}" ]];then
				bResetTimer=true
			fi
			
			if $bResetTimer;then
				SECFUNCdelay "Device${nIndex}" --init
			fi
			
			nInactiveFor="`SECFUNCdelay "Device${nIndex}" --getsec`"
			if $bKeepAwake && ! $bResetTimer && (( nInactiveFor>(nWaitSecondsToUnmount/2) ));then
				echoc --alert "unable to keep strDev='$strDev' awake..."
			fi
			echo "$strDev inactive for ${nInactiveFor}s, Status '${strStatus[nIndex]}'"
			
			if((`SECFUNCdelay "Device${nIndex}" --getsec`>nWaitSecondsToUnmount));then
				if echoc -x "umount '$strDev'"&&: ;then
					SECFUNCdelay "Device${nIndex}" --init #initialize umounted time
				fi
			fi
		
			strStatusPrevious[nIndex]="${strStatus[nIndex]}"
		else
			FUNCkillLs
#			if [[ -d "/proc/${anPidKeepAwake[$strDev]-0}" ]];then
#				kill -SIGKILL ${anPidKeepAwake[$strDev]}&&:
#				anPidKeepAwake[$strDev]="" #cleanup to prevent access to a reused pid
#			fi
			
			nUnmountedFor="`SECFUNCdelay "Device${nIndex}" --getsec`"
			echoc --info "$strDev unmounted for ${nUnmountedFor}s"
			
			if $bKeepAlive;then
				if(( nUnmountedFor >= (nKeepAliveDelayInMin*60) ));then
					bKeepAliveWorking=true
#					if ! SECFUNCexec --echo -c mount "$strDev";then
#						if ! SECFUNCexec --echo -c mount "${astrMountedPaths[$strDev]-}";then
#							echoc --alert "failed"
#							bKeepAliveWorking=false
#						fi
#					fi
					if ! SECFUNCexec --echo -c udisks --mount "$strDev";then
						echoc --alert "failed"
						bKeepAliveWorking=false
					else
						SECFUNCdelay "Device${nIndex}" --init
					fi
					
					if $bKeepAliveWorking;then
						echoc -w -t 10 "wait a bit"
						SECFUNCexec --echo -c umount "$strDev"&&:
					fi
				fi
			fi
		fi
	done
	
	#echoc -w -t $nCheckDelay
	if echoc -q -t $nCheckDelay "update devices list?";then
		FUNCupdateDevList
	fi
done

