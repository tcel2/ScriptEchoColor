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

declare -a SECastrSECFUNCCwindowCmd_ChildRegex=()
function SECFUNCCwindowCmd() { #help [options] <lstrWindowTitleRegex> this will run a child process in loop til the window is found and commands are issued towards it
	local lnDelay=3
	local lstrStopMatchRegex=""
	local lbMaximize=false
	local lbOnTop=false
	local lnPosX=-1
	local lnPosY=-1
	local lnWidth=-1
	local lnHeight=-1
	local lbMoveGeom=false
	local lbFocus=false
	local lbWait=false
	local lbChild=true
	local lbMinimize=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		SECFUNCsingleLetterOptionsA;
		if [[ "$1" == "--help" ]];then #SECFUNCCwindowCmd_help
			#SECFUNCshowHelp --colorize "a child process will wait to issue the action towards <lstrWindowTitleRegex> "
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--ontop" ]];then #SECFUNCCwindowCmd_help set window on top
			lbOnTop=true
		elif [[ "$1" == "--focus" ]];then #SECFUNCCwindowCmd_help focus window
			lbFocus=true
		elif [[ "$1" == "--maximize" || "$1" == "-x" ]];then #SECFUNCCwindowCmd_help maximize window
			lbMaximize=true
		elif [[ "$1" == "--minimize" || "$1" == "-i" ]];then #SECFUNCCwindowCmd_help maximize window
			lbMinimize=true
		elif [[ "$1" == "--delay" || "$1" == "-d" ]];then #SECFUNCCwindowCmd_help <lnDelay> between checks
			shift
			lnDelay="${1-}"
		elif [[ "$1" == "--move" || "$1" == "-m" ]];then #SECFUNCCwindowCmd_help <lnPosX> <lnPosY> move to
			shift
			lnPosX="${1-}"
			shift
			lnPosY="${1-}"
			
			lbMoveGeom=true;
		elif [[ "$1" == "--geom" || "$1" == "-g" ]];then #SECFUNCCwindowCmd_help <lnWidth> <lnHeight> geometry
			shift
			lnWidth="${1-}"
			shift
			lnHeight="${1-}"
			
			lbMoveGeom=true;
		elif [[ "$1" == "--stop" || "$1" == "-s" ]];then #SECFUNCCwindowCmd_help <lstrWindowTitleRegex> will look for this function running instances related to specified window title and stop them.
			shift
			lstrStopMatchRegex="${1-}" #TODO pointless..
		elif [[ "$1" == "--wait" || "$1" == "-w" ]];then #SECFUNCCwindowCmd_help wait regex match a window and return
			lbWait=true
		elif [[ "$1" == "--nochild" || "$1" == "-n" ]];then #SECFUNCCwindowCmd_help do not run as child, helped by --wait 
			lbChild=false
		elif [[ "$1" == "--" ]];then #SECFUNCCwindowCmd_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCshowHelp $FUNCNAME
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift
	done
	
	if [[ -n "$lstrStopMatchRegex" ]];then
		for lnPid in "${!SECastrSECFUNCCwindowCmd_ChildRegex[@]}";do
			if [[ "${SECastrSECFUNCCwindowCmd_ChildRegex[$lnPid]}" == "$lstrStopMatchRegex" ]];then
				if [[ ! -d "/proc/$lnPid" ]];then
					unset SECastrSECFUNCCwindowCmd_ChildRegex[$lnPid]
					continue
				fi
				if SECFUNCexecA -c --echo kill -SIGUSR1 $lnPid;then
					unset SECastrSECFUNCCwindowCmd_ChildRegex[$lnPid]
				fi
				#no break as can have more than one with same regex
			fi
		done
		return 0
	fi
	
	if ! SECFUNCisNumber -d $lnPosX;then
		SECFUNCechoErrA "invalid lnPosX='$lnPosX'"
		return 1
	fi
	if ! SECFUNCisNumber -d $lnPosY;then
		SECFUNCechoErrA "invalid lnPosY='$lnPosY'"
		return 1
	fi
	if ! SECFUNCisNumber -d $lnWidth;then
		SECFUNCechoErrA "invalid lnWidth='$lnWidth'"
		return 1
	fi
	if ! SECFUNCisNumber -d $lnHeight;then
		SECFUNCechoErrA "invalid lnHeight='$lnHeight'"
		return 1
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
	
	local lstrWarnMsg="still no window found with title lstrWindowTitleRegex='$lstrWindowTitleRegex'"
	if $lbWait;then
		while ! xdotool search --name "$lstrWindowTitleRegex";do
			SEC_WARN=true SECFUNCechoWarnA "$lstrWarnMsg"
			sleep $lnDelay;
		done
		return 0
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
				##################
				# each option will be issued one time, so must be disabled 
				##################
				if $lbOnTop && wmctrl -i -a "$lnWindowId" -b add,above;then
					lbOnTop=false;
				fi
				if $lbFocus && xdotool windowfocus "$lnWindowId" && xdotool windowactivate "$lnWindowId";then
					lbFocus=false
				fi
				if $lbMaximize && wmctrl -i -r $lnWindowId -b add,maximized_vert,maximized_horz;then
					lbMaximize=false;
				fi
#				if $lbMinimize && wmctrl -i -r $lnWindowId -b add,hidden;then
				if $lbMinimize && xdotool windowminimize $lnWindowId;then
					lbMinimize=false;
				fi
				if $lbMoveGeom && wmctrl -i -r $lnWindowId -e 0,$lnPosX,$lnPosY,$lnWidth,$lnHeight;then
					lbMoveGeom=false;
				fi
				#############
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# only end when all is done
				#############
				if	! $lbOnTop && 
						! $lbFocus && 
						! $lbMoveGeom && 
						! $lbMaximize && 
						! $lbMinimize;then
					break;
				fi
			fi
			SEC_WARN=true SECFUNCechoWarnA "$lstrWarnMsg (to stop this, execute \`kill $BASHPID\`)"
			sleep $lnDelay;
		done
	) & lnChildPid=$!;if $lbChild;then wait;fi
	
	SECastrSECFUNCCwindowCmd_ChildRegex[lnChildPid]="$lstrWindowTitleRegex"
	#echo "$lnChildPid"
	
	return 0
}

function SECFUNCCwindowOnTop() {
	SECFUNCCwindowCmd --ontop "$@"
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

