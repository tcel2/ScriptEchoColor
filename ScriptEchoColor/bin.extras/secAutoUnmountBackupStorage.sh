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

SECFUNCshowHelp --colorize "<device> ex.: sde (that must be at '/dev/')"

strDevBase="/dev/$1";
if [[ ! -a "$strDevBase" ]];then
	echoc -p "invalid device '$1'"
	exit 1
fi

SECFUNCuniqueLock --daemonwait

varset --show nCheckDelay=60
varset --show nWaitSecondsToUnmount=300 #5min

astrDev=(`ls "$strDevBase"?`)

for nIndex in ${!astrDev[@]};do
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

