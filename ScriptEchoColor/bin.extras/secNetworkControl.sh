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

# initializations and functions

bValidateOnly=false
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
	elif [[ "$1" == "--validateonly" || "$1" == "-v" ]];then #help just validate the params and exit without executing them.
		bValidateOnly=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

# Main code

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
		echoc -x "nmcli nm enable true"
	elif [[ "$lstrParam" == "disable" ]];then
		if $lbValidateOnly;then echo "ok '$lstrParam'"; return;fi
		echoc -x "nmcli nm enable false"
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
