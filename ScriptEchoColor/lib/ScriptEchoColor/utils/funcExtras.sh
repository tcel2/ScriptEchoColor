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

# TOP CODE
if ${SECinstallPath+false};then export SECinstallPath="`secGetInstallPath.sh`";fi; #to be faster
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcExtras.sh") #no need for the array to be previously set empty
source "$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh";
###############################################################################
### this lib must NOT be used by the core package in any way, it deals with ###
### window manipulations and anything else not related to console apps!     ###
###############################################################################

#TODO this wont work..., find a workaround?: export _SECCstrkillSelfMsg='(to stop this, execute \`kill $BASHPID\`)' #for functions that run as child process SECC

declare -a SECastrSECFUNCCwindowOnTop_ChildRegex=()
function SECFUNCCwindowOnTop() { #help <lstrWindowTitleRegex> this will run a child process in loop til the window is found and put on top
	local lnDelay=3
	local lstrStopMatchRegex=""
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCCwindowOnTop_help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--delay" || "$1" == "-d" ]];then #SECFUNCCwindowOnTop_help <lnDelay> between checks
			shift
			lnDelay="${1-}"
		elif [[ "$1" == "--stop" || "$1" == "-s" ]];then #SECFUNCCwindowOnTop_help <lstrWindowTitleRegex>
			shift
			lstrStopMatchRegex="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCCwindowOnTop_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift
	done
	
	if [[ -n "$lstrStopMatchRegex" ]];then
		for lnPid in "${!SECastrSECFUNCCwindowOnTop_ChildRegex[@]}";do
			if [[ "${SECastrSECFUNCCwindowOnTop_ChildRegex[$lnPid]}" == "$lstrStopMatchRegex" ]];then
				if [[ ! -d "/proc/$lnPid" ]];then
					unset SECastrSECFUNCCwindowOnTop_ChildRegex[$lnPid]
					continue
				fi
				if SECFUNCexecA -c --echo kill -SIGUSR1 $lnPid;then
					unset SECastrSECFUNCCwindowOnTop_ChildRegex[$lnPid]
				fi
				#no break as can have more than one with same regex
			fi
		done
		return 0
	fi
	
	if ! SECFUNCisNumber -dn "$lnDelay";then
		SECFUNCechoErrA "invalid lnDelay='$lnDelay'"
		return 1
	fi
	
	local lstrWindowTitleRegex="${1-}"
	if [[ -z "$lstrWindowTitleRegex" ]];then
		SECFUNCechoErrA "lstrWindowTitleRegex='$lstrWindowTitleRegex' missing"
		return 1
	fi
	
	( #child process
		local lbStop=false
		trap 'lbStop=true;' USR1
		while true;do
			if $lbStop;then
				break
			fi
			local lnWindowId="`xdotool search --name "$lstrWindowTitleRegex"`"
			if SECFUNCisNumber -nd "$lnWindowId";then
				if wmctrl -F -i -a "$lnWindowId" -b add,above;then
					break;
				fi
			fi
			SEC_WARN=true SECFUNCechoWarnA "still no window found with title lstrWindowTitleRegex='$lstrWindowTitleRegex' (to stop this, execute \`kill $BASHPID\`)"
			sleep $lnDelay;
		done
	) & lnChildPid=$!
	
	SECastrSECFUNCCwindowOnTop_ChildRegex[lnChildPid]="$lstrWindowTitleRegex"
	#echo "$lnChildPid"
}

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcExtras.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibExtras=$$

