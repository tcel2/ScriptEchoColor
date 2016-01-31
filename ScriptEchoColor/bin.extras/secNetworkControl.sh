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

eval `secinit --extras`

# initializations and functions

bValidateOnly=false
bCheckInternet=false
bListNetworkFiles=false
bToggle=false
nCoolDownDelay=15
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "This script helps on ex.:"
		SECFUNCshowHelp --colorize "\tThunderbird will stop asking for password on startup."
		SECFUNCshowHelp --colorize "\tLower cpu load on system startup for internet related applications like browsers with pre-opened tabs!"
		SECFUNCshowHelp --colorize "Accepted commands executable in sequence:"
		SECFUNCshowHelp --colorize "\t'enable' the internet using nmcli"
		SECFUNCshowHelp --colorize "\t'disable' the internet using nmcli"
		SECFUNCshowHelp --colorize "\tDelayInSeconds - delay between executing each param"
		SECFUNCshowHelp --colorize "This example will disable on startup, wait 120s and enable again:"
		echoc --info "\t$SECstrScriptSelfName disable 120 enable"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--checkinternet" || "$1" == "-c" ]];then #help check if internet is active return 0, or inactive return 1
		bCheckInternet=true
	elif [[ "$1" == "--validateonly" || "$1" == "-v" ]];then #help just validate the params and exit without executing them.
		bValidateOnly=true
	elif [[ "$1" == "--listnetworkfiles" || "$1" == "-l" ]];then #help lsof -i
		bListNetworkFiles=true
	elif [[ "$1" == "--cooldown" || "$1" == "-d" ]];then #help <nCoolDownDelay> a hardware cooldown delay time to wait before changing network state. Some hardware may stop working and require a computer reboot if its state is changed too fast.
		shift
		nCoolDownDelay="${1-}"
	elif [[ "$1" == "--toggle" || "$1" == "-t" ]];then #help toggle network on/off
		bToggle=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

function FUNCcheckInternet() {
  if ip route ls |grep --color=always "192.168.0." >/dev/null;then
  	return 0
  fi
  return 1
}

if $bCheckInternet;then
	if FUNCcheckInternet;then
		echoc --info "Internet is ON"
		exit 0
	fi
	echoc --info "Internet is OFF"
	exit 1
elif $bListNetworkFiles;then
	lsof -i
	exit 0
fi

# required before toggling too
SECFUNCuniqueLock --daemonwait

function FUNCsetEnable(){
	SECFUNCcfgReadDB
	if SECFUNCisNumber -dn "${CFGnLastStateRequestTime-}";then
#		while true;do
			local lnCurrentTime="`SECFUNCdtFmt --nonano`"
			local lnElapsed=$(($lnCurrentTime-$CFGnLastStateRequestTime))&&:
			local lnRemaining=$(($nCoolDownDelay-$lnElapsed))
#			if(($lnElapsed<$nCoolDownDelay));then
			if((lnRemaining>0));then
				local lstrTitle="$SECstrScriptSelfName: cooldown"
				
				local lstrText="lnRemaining='$lnRemaining', waiting cooldown before changing state..."
				echoc --info "$lstrTitle: $lstrText"
				
				SECFUNCCwindowOnTop -d 1 "^$lstrTitle$"
				#SECFUNCexecA -ce zenity --timeout $lnRemaining --info --title "$lstrTitle" --text "$lstrText"
				( for((iProgress=0;iProgress<lnRemaining;iProgress++));do echo $((iProgress*100/lnRemaining));sleep 1;done) \
					| SECFUNCexecA -ce zenity --progress --percentage=0 --auto-close --no-cancel --title "$lstrTitle" --text "$lstrText"
#				continue
			fi
#			break;
#		done
	else
		SECFUNCechoWarnA "invalid CFGnLastStateRequestTime='${CFGnLastStateRequestTime-}', will be fixed..."
	fi
	
	strRet="`nmcli nm enable $1 2>&1`"
	strErr="Not authorized to enable/disable networking"
	if echo "$strRet" |grep -q "$strErr";then
		echoc --say "$strErr"
		return 1
	fi
	SECFUNCcfgWriteVar CFGnLastStateRequestTime="`SECFUNCdtFmt --nonano`"
	return 0
}

function FUNCisInternetOn(){
	[[ "`nmcli -f STATE -t nm`" == "connected" ]]
}

function FUNCwaitConnectDialog(){
	local lbEnable="$1"
	shift
	local lstrTitle="$1"
	shift
	local lstrText="$1"
	shift
	local lstrTextEnd="$1"
	
	for((i=0;i<100;i++));do
		if((i<98));then
			local lbEnd=false
			if $lbEnable;then
				if FUNCisInternetOn;then
					lbEnd=true;
				fi
			else
				if ! FUNCisInternetOn;then
					lbEnd=true;
				fi
			fi
			
			if $lbEnd;then
				i=98 #just to stay for more 2 seconds
			fi
		fi;
		echo $i;
		sleep 1;
	done |zenity --progress --auto-close --title "$lstrTitle" --text "$lstrText"
	echoc --say --info "$lstrTextEnd"
}

if $bToggle;then
	bEnable=true
	strText="Internet going ON"
	strTextEnd="Internet ON"
#	if nmcli nm |tail -n 1 |grep -q connected;then 
	if FUNCisInternetOn;then
		bEnable=false
		strText="Internet going OFF"
		strTextEnd="Internet OFF"
	fi
	
	if FUNCsetEnable $bEnable;then
		strTitle="$SECstrScriptSelfName: Info Internet Status"
		SECFUNCCwindowOnTop -d 1 "^$strTitle$"
		echoc --say --info "$strText"
#		if $bEnable;then
			FUNCwaitConnectDialog $bEnable "$strTitle" "$strText" "$strTextEnd"
#		else
#			SECFUNCexecA -ce zenity --timeout 3 --info --title "$strTitle" --text "$strText"&
#		fi
	fi
	
#	if nmcli nm |tail -n 1 |grep -q connected;then 
#		if FUNCsetEnable false;then
#			strText="Internet OFF"
#			SECFUNCCwindowOnTop -d 1 "$SECstrScriptSelfName"
#			zenity --timeout 3 --info --title "$SECstrScriptSelfName" --text "$strText"&
#			echoc --say --info "$strText"
#		fi
#	else 
#		if FUNCsetEnable true;then
#			strText="Internet ON"
#			SECFUNCCwindowOnTop -d 1 "$SECstrScriptSelfName"
#			zenity --timeout 3 --info --title "$SECstrScriptSelfName" --text "$strText"&
#			echoc --say --info "$strText"
#		fi
#	fi
	exit $?
fi

# Main code
#SECFUNCuniqueLock --daemonwait

function FUNCexecParam() {
	local lbValidateOnly=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #help
#			SECFUNCshowHelp --colorize "#TODO help text here, accepts \t \n"
			SECFUNCshowHelp --nosort $FUNCNAME
			return
		elif [[ "$1" == "--validateonly" ]];then #FUNCexecParam_help
			lbValidateOnly=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			_SECFUNCcriticalForceExit
		fi
		shift
	done
	
	local lstrParam="${1-}"
	
	if [[ "$lstrParam" == "enable" ]];then
		if $lbValidateOnly;then echo "ok '$lstrParam'"; return;fi
		if FUNCcheckInternet;then
			echo "internet already enabled."
		else
			echoc -x "nmcli nm enable true"
		fi
	elif [[ "$lstrParam" == "disable" ]];then
		if $lbValidateOnly;then echo "ok '$lstrParam'"; return;fi
		if FUNCcheckInternet;then
			echoc -x "nmcli nm enable false"
		else
			echo "internet already disabled."
		fi
	elif SECFUNCisNumber -dn "$lstrParam";then
		if $lbValidateOnly;then echo "ok '$lstrParam'"; return;fi
		if [[ "`tty`" != "not a tty" ]];then
			echoc -w -t $lstrParam "If a key is pressed, next param will be executed now"
		else
			sleep $lstrParam
		fi
	else
		echoc -p "invalid param '$lstrParam'"
		return 1
	fi
}

astrParams=("$@")

# validate to not make user loose time
for strParam in "${astrParams[@]}";do
	if [[ "${strParam:0:1}" == "-" ]];then
		echoc -p "param commands cannot begin with '-'"
		exit 1
	fi
	if ! FUNCexecParam --validateonly "$strParam";then
		exit 1
	fi
done
if $bValidateOnly;then
	echoc --info "all param commands are OK!"
	exit
fi

# run it!
for strParam in "${astrParams[@]}";do
	if ! FUNCexecParam	"$strParam";then
		exit 1
	fi
done

