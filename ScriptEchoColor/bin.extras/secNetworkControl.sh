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

source <(secinit --extras)

# initializations and functions

bValidateOnly=false
bCheckInternet=false
bListNetworkFiles=false
bToggle=false
nCoolDownDelay=15
bOn=false
bOff=false
bState=false
bVerbose=false
export CFGbControlWifi;: ${CFGbControlWifi:=true}; #help set to false to ignore wifi
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
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
	elif [[ "$1" == "--validateonly" || "$1" == "-o" ]];then #help just validate the params and exit without executing them.
		bValidateOnly=true
	elif [[ "$1" == "--listnetworkfiles" || "$1" == "-l" ]];then #help lsof -i
		bListNetworkFiles=true
	elif [[ "$1" == "--cooldown" || "$1" == "-d" ]];then #help <nCoolDownDelay> a hardware cooldown delay time to wait before changing network state. Some hardware may stop working and require a computer reboot if its state is changed too fast.
		shift
		nCoolDownDelay="${1-}"
	elif [[ "$1" == "--toggle" || "$1" == "-t" ]];then #help toggle network on/off
		bToggle=true
	elif [[ "$1" == "--on" ]];then #help network on
		bOn=true
	elif [[ "$1" == "--off" ]];then #help network off
		bOff=true
	elif [[ "$1" == "--verbose" || "$1" == "-v" ]];then #help 
		bVerbose=true
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

function FUNCinternetState() {
	nmcli -f STATE -t nm
}

function FUNCinternetConnectivity() {
	ip route ls |grep --color=always "192.168.0."
}

function FUNCcheckInternet() {
	if $bVerbose;then
		echo "state:'`FUNCinternetState`'" >&2
		echo "connectivity:'`FUNCinternetConnectivity`'" >&2
	fi
	
  if FUNCinternetConnectivity >/dev/null;then
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

function FUNCsetEnable(){ #help <true|false>
	local lbEnable="$1"
	
	if $lbEnable && FUNCinternetStateCmp connected connecting;then 
		echoc --info "@ralready on..."
		return 0;
	fi
	
	if ! $lbEnable && FUNCinternetStateCmp disconnected;then 
		echoc --info "@ralready off..."
		return 0;
	fi
	
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
	
	strRet="`nmcli nm enable $lbEnable 2>&1`"
	strErr="Not authorized to enable/disable networking"
	if echo "$strRet" |grep -q "$strErr";then
		echoc --say "$strErr"
		return 1
	fi
	
	if $CFGbControlWifi;then
		echoc -w -t 3 #blind useful delay to help it work
		if $lbEnable;then
			SECFUNCexecA -ce nmcli nm wifi on
		else
			SECFUNCexecA -ce nmcli nm wifi off
		fi
	fi
	
	SECFUNCcfgWriteVar CFGnLastStateRequestTime="`SECFUNCdtFmt --nonano`"
	return 0
}

#function FUNCisInternetOn(){
#	[[ "`nmcli -f STATE -t nm`" == "connected" ]]
#}

function FUNCinternetStateCmp() { #help <lstrCheck>... state(s) to check for
	while ! ${1+false};do
		local lstrCheck="$1"
		case "$lstrCheck" in
			disconnected|connecting|connected);;
			*)SECFUNCechoErrA "invalid lstrCheck='$lstrCheck'"
				_SECFUNCcriticalForceExit
				;;
		esac
	
		if [[ "`FUNCinternetState`" == "$lstrCheck" ]];then
			return 0
		fi
		
		shift&&:
	done
	
	return 1;
}

function FUNCdialogConnStateProgress(){
	local lbEnable="$1"
	shift
	local lstrTitle="$1"
	shift
	local lstrText="$1"
	shift
	local lstrTextEnd="$1"
	
	for((i=0;i<100;i++));do
		if((i>0 && i<98));then # >0 to have time to show it
			local lbEnd=false
			if $lbEnable;then
				if FUNCinternetStateCmp connected;then
					lbEnd=true;
				fi
			else
#				if FUNCinternetStateCmp disconnected;then
					lbEnd=true; # disconnecting always works instantly
#				fi
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

#if $bState;then
#	FUNCinternetState
#	exit 0
if $bOn || $bOff || $bToggle;then
	bEnable=true
	
	if $bOn;then
		bEnable=true
	elif $bOff;then
		bEnable=false
	elif $bToggle;then
		if FUNCinternetStateCmp connected connecting;then
			bEnable=false
		fi
	fi
	
	if $bEnable;then
		strText="Internet going ON"
		strTextEnd="Internet ON"
	else
		strText="Internet going OFF"
		strTextEnd="Internet OFF"
	fi
	
	if FUNCsetEnable $bEnable;then
		strTitle="$SECstrScriptSelfName: Info Internet Status"
		SECFUNCCwindowOnTop -d 1 "^$strTitle$"
		echoc --say --info "$strText"
		FUNCdialogConnStateProgress $bEnable "$strTitle" "$strText" "$strTextEnd"
	fi

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

