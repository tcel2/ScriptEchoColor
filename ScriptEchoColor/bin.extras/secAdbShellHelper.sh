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

eval `secinit`

bAddRule=false
strDeviceFilter=""
#bAdbServer=false
bReversedUsbTethering=false
strUsbInterface="usb0"
bRestart=false
strDesktopIp="10.42.0.1"
strSmtphoneIp="10.42.0.2"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "helper for android shell"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--addrule" || "$1" == "-a" ]];then #help <strDeviceFilter> at lsusb, use this filter to generate the permission rule data required by adb server
		shift
		strDeviceFilter="${1-}"
		
		bAddRule=true
	elif [[ "$1" == "--restart" || "$1" == "-r" ]];then #help restart adb server
		bRestart=true
	elif [[ "$1" == "--rut" ]];then #help reversed usb tethering tip and commands
		bReversedUsbTethering=true
	elif [[ "$1" == "--rutInterface" ]];then #help <strUsbInterface> the usb network tethered interface
		strUsbInterface="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift
done

if $bAddRule;then
	strRulesFile="/etc/udev/rules.d/51-android-rules"
	
	strDeviceUsbData="`lsusb |grep "$strDeviceFilter"`"&&:
	if [[ -z "$strDeviceUsbData" ]] || ((`echo "$strDeviceUsbData" |wc -l`!=1));then
		echoc -p "invalid strDeviceFilter='$strDeviceFilter'"
		lsusb
		exit 1
	fi
	
	strRule="`lsusb \
		|grep "$strDeviceFilter" \
		|sed -r 's@.*ID ([^ ]{4}):([^ ]{4}).*@SUBSYSTEM=="usb", ATTR{idVendor}=="\1", ATTR{idProduct}=="\2", MODE="0600", OWNER="'$USER'"@'`"
	bMissingRule=false
	if [[ ! -f "$strRulesFile" ]];then 
		bMissingRule=true;
	elif ! grep -q "$strRule" "$strRulesFile";then 
		SECFUNCexecA -c --echo cat "$strRulesFile"
		bMissingRule=true;
	fi
	
	if $bMissingRule;then
		echoc --info "add and activate the missing rule with this command:"
		echo "echo '$strRule' |sudo tee -a '$strRulesFile';sudo udevadm control --reload;sudo -k;"
	else
		echoc --info "rule already set."
	fi
	
	exit 0
fi

function FUNCadbServerPid(){
	nPid="`pgrep -fx "adb -P .* fork-server server"`"&&:
	if [[ -n "$nPid" ]];then
		ps --no-headers -o pid,user,cmd -p "$nPid" >>/dev/stderr
		echo "$nPid"
	fi
}

strAbdServerUser=""
nAdbServerPid="`FUNCadbServerPid`"
echo "nAdbServerPid='$nAdbServerPid'"
if [[ -n "$nAdbServerPid" ]];then
	strAbdServerUser="`ps --no-headers -o user -p $nAdbServerPid`"
fi
echo "strAbdServerUser='$strAbdServerUser'"

if $bRestart || [[ "$strAbdServerUser" != "root" ]];then
	echoc --alert "properly restarting adb server"
	SECFUNCexecA -c --echo sudo adb kill-server # `sudo` is to make it sure stopping it will work
	SECFUNCexecA -c --echo sudo adb start-server # only the server needs to be run as root
	#sudo adb logcat
	SECFUNCexecA -c --echo sudo -k
	FUNCadbServerPid
fi

SECFUNCdrawLine BasicTips
echoc --info "now, run the shell with:"
echo "adb shell"
echoc --info "or some 'su' command like:"
echo "adb shell su -c 'svc wifi enable'"

if $bReversedUsbTethering;then
	SECFUNCdrawLine ReversedUsbTethering
	echoc --info "based on instructions from: http://forum.xda-developers.com/showthread.php?t=2287494"
	
	strDevicesList="`adb devices |grep -v "List of devices attached"`"
	if [[ -z "$strDevicesList" ]];then
		echoc -p "no device connected!"
		exit 1
	fi
	
	while ! SECFUNCexecA -ce ifconfig "$strUsbInterface";do
		echoc -w "enable usb tethering at your smartphone"
	done
	
	while ! ifconfig "$strUsbInterface" |grep "inet addr:$strDesktopIp";do
		if ! echoc -q "will you edit your $strUsbInterface network interface IPV4/Method to 'Shared to other computers'?@Dy";then
			SECFUNCexecA -ce sudo ifconfig "$strUsbInterface" "$strDesktopIp" netmask 255.255.255.0
		fi
	done
	
	# this will be made by the network manager, just make it sure it was done
	if [[ "`cat /proc/sys/net/ipv4/ip_forward`" == "0" ]];then
		echo 1 |SECFUNCexecA -ce sudo tee /proc/sys/net/ipv4/ip_forward
	fi
	
	# this will be made by the network manager, just make it sure it was done
	if echoc -q "update iptables?";then
		SECFUNCexecA -ce sudo iptables -t nat --list
		#TODO is this step safe/essential?: SECFUNCexecA -ce sudo iptables -t nat -F
		
		SECFUNCexecA -ce sudo iptables -t nat --list
		
		#TODO add a check before this step, it may not be necessary
		SECFUNCexecA -ce sudo iptables -t nat -A POSTROUTING -j MASQUERADE #can be removed by using -D instead of -A
		SECFUNCexecA -ce sudo iptables -t nat --list
	fi
	
	SECFUNCexecA -ce sudo -k
	
	# now work at android
	SECFUNCexecA -ce adb shell su -c "ifconfig rndis0 $strSmtphoneIp netmask 255.255.255.0"
	SECFUNCexecA -ce adb shell su -c "route add default gw $strDesktopIp dev rndis0"
	
	echoc --info "your computer IP address thru   $strUsbInterface: $strDesktopIp"
	echoc --info "your smartphone IP address thru $strUsbInterface: $strSmtphoneIp"
fi

SECFUNCexecA -c --echo adb devices

#cd "$HOME/Installed/AndroidSDK - adt-bundle-linux-x86-20130219/sdk/platform-tools"

#logfile="$HOME/temp/`basename $0`.`date +"%Y%m%d-%H%M%S"`.log"
#ln -sf "$logfile" "$HOME/temp/`basename $0`.LastOne.log"

#adb devices |tee "$logfile"

#if [[ -n "$1" ]]; then
#	adb "$@" |tee -a "$logfile"
#else
#	echoc -x "adb shell" |tee -a "$logfile"
#fi

