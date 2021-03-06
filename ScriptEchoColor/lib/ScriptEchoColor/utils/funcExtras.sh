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
function SECFUNCCwindowCmd() { #help [options] <lstrMatchRegex> this will run a child process in loop til the window is found and commands are issued towards it
	local lnDelay=3
	local lstrStopMatchRegex=""
	local lbMaximize=false
	local lbUnMaximize=false
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
	local lnTimeout=60
  local lbWaitExit=false;
  local lbCheck=false
  local lstrXdotoolSearchBy="--name"
  local lbIsWindowID=false
  local lbSticky=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		SECFUNCsingleLetterOptionsA;
		if [[ "$1" == "--help" ]];then #SECFUNCCwindowCmd_help
			#SECFUNCshowHelp --colorize "a child process will wait to issue the action towards <lstrMatchRegex> "
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--wid" ]];then #SECFUNCCwindowCmd_help lstrMatchRegex will be considered as simple windowId (TODO for now using this will break some functionalities, test prior to code)
			lbIsWindowID=true
		elif [[ "$1" == "--class" || "$1" == "--classname" ]];then #SECFUNCCwindowCmd_help search window by (see `xdotool search` for details), default is --name
			lstrXdotoolSearchBy="$1"
		elif [[ "$1" == "--ontop" ]];then #SECFUNCCwindowCmd_help set window on top
			lbOnTop=true
		elif [[ "$1" == "--sticky" ]];then #SECFUNCCwindowCmd_help show on all workspaces
			lbSticky=true
		elif [[ "$1" == "--focus" ]];then #SECFUNCCwindowCmd_help focus window
			lbFocus=true
		elif [[ "$1" == "--maximize" || "$1" == "-x" ]];then #SECFUNCCwindowCmd_help maximize window
			lbMaximize=true
		elif [[ "$1" == "--unmaximize" || "$1" == "-X" ]];then #SECFUNCCwindowCmd_help unmaximize window
			lbUnMaximize=true
		elif [[ "$1" == "--minimize" || "$1" == "-i" ]];then #SECFUNCCwindowCmd_help minimize window
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
		elif [[ "$1" == "--timeout" || "$1" == "-o" ]];then #SECFUNCCwindowCmd_help <lnTimeout> after this timeout, will stop looking for window to match
			shift 
			lnTimeout="${1-}"
		elif [[ "$1" == "--stop" || "$1" == "-s" ]];then #SECFUNCCwindowCmd_help <lstrMatchRegex> will look for this function running instances related to specified window title and stop them. Implies --nochild.
			shift
			lstrStopMatchRegex="${1-}" #TODO pointless..
			
			lbChild=false
		elif [[ "$1" == "--wait" || "$1" == "-w" ]];then #SECFUNCCwindowCmd_help just wait regex match a window and return 0
			lbWait=true
		elif [[ "$1" == "--waitexit" ]];then #SECFUNCCwindowCmd_help wait until specified regex window closes
			lbWaitExit=true
		elif [[ "$1" == "--check" ]];then #SECFUNCCwindowCmd_help check if some window matches the regex and exit 0 if any does or 1 otherwise
			lbCheck=true
		elif [[ "$1" == "--nochild" || "$1" == "-n" ]];then #SECFUNCCwindowCmd_help do not run as child. Useful after a previous line using --wait option.
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
	
	if [[ -n "$lstrStopMatchRegex" ]];then #lbChild no child is actually just implied
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
	
	if ! SECFUNCisNumber -dn $lnTimeout;then
		SECFUNCechoErrA "invalid lnTimeout='$lnTimeout'"
		return 1
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
	
	local lstrMatchRegex="${1-}"
	if [[ -z "$lstrMatchRegex" ]];then
		SECFUNCechoErrA "lstrMatchRegex='$lstrMatchRegex' missing"
		return 1
	fi
	export lstrMatchRegex
	
  local lnWindowId=-1
  if $lbIsWindowID;then
    if [[ "${lstrMatchRegex:0:2}" == "0x" ]];then
      lnWindowId="`printf %d ${lstrMatchRegex}`"
    else
      lnWindowId=$lstrMatchRegex
    fi
  fi
  declare -p lnWindowId >&2

	local lstrWarnMsg="still no window found matching `SECFUNCternary $lbIsWindowID ? echo windowId : echo regex` '$lstrMatchRegex'"
	if $lbWait && ! $lbIsWindowID;then
		while ! xdotool search $lstrXdotoolSearchBy "$lstrMatchRegex";do
			SEC_WARN=true SECFUNCechoWarnA "$lstrWarnMsg"
			sleep $lnDelay;
      
			if SECFUNCdelay lnTimeout --checkorinit $lnTimeout;then
				SECFUNCechoErr "$lstrWarnMsg (TIMEOUT)"
				break;
			fi
		done
		return 0
	fi
  
	if $lbWaitExit;then
		while true;do
      if $lbIsWindowID;then
        if ! xdotool getwindowname $lnWindowId;then break;fi
      else
        if ! xdotool search $lstrXdotoolSearchBy "$lstrMatchRegex";then break;fi
      fi
      
			sleep $lnDelay;
      
			if SECFUNCdelay lnTimeout --checkorinit $lnTimeout;then
				SECFUNCechoErr "while waiting window exit: (TIMEOUT)"
				break;
			fi
		done
		return 0
	fi
  
	if $lbCheck;then
    if $lbIsWindowID;then
      if xdotool getwindowname $lnWindowId;then return 0;fi
    else
      if xdotool search $lstrXdotoolSearchBy "$lstrMatchRegex";then return 0;fi
    fi
		return 1
	fi
	
	function SECFUNCCwindowCmd_ChildLoop() {
		SECFUNCrestoreAliases; # required as aliases are not applied on child processes like ()&
#child process
		local lbStop=false
		trap 'lbStop=true;' USR1
		declare -p lbOnTop lbFocus lbMaximize lbUnMaximize lbMinimize lbMoveGeom >&2
		while true;do
			if $lbStop;then
				break
			fi
			
      export lstrMatchRegex
			
      declare -p lnWindowId >&2
      if((lnWindowId==-1));then
        if ! lnWindowId="`xdotool search $lstrXdotoolSearchBy "$lstrMatchRegex"`";then
          lnWindowId=-1
        fi
      fi
      
			if SECFUNCisNumber -nd "$lnWindowId";then
				##################
				# each option will be issued one time, so must be disabled 
				##################
				if $lbOnTop && SECFUNCexecA -ce wmctrl -i -a $lnWindowId -b add,above;then
					lbOnTop=false;
				fi
				if $lbSticky && SECFUNCexecA -ce wmctrl -i -a $lnWindowId -b add,sticky;then
					lbSticky=false;
				fi
				if $lbFocus && SECFUNCexecA -ce xdotool windowactivate $lnWindowId && SECFUNCexecA -ce xdotool windowfocus $lnWindowId && SECFUNCexecA -ce wmctrl -i -r $lnWindowId -b remove,below;then # if minimized, must be activated before focus!
					lbFocus=false
				fi
				if $lbMaximize || $lbUnMaximize;then
					local lstrMaxMode="add"
					if $lbUnMaximize;then lstrMaxMode="remove";fi
					if SECFUNCexecA -ce wmctrl -i -r $lnWindowId -b ${lstrMaxMode},maximized_vert,maximized_horz;then
						lbMaximize=false;
						lbUnMaximize=false;
					fi
				fi
#				if $lbMinimize && wmctrl -i -r $lnWindowId -b add,hidden;then
				if $lbMinimize && SECFUNCexecA -ce xdotool windowminimize $lnWindowId && SECFUNCexecA -ce wmctrl -i -r $lnWindowId -b add,below;then # "below" is a trick in case "window" cant be minimized properly
					lbMinimize=false;
				fi
				if $lbMoveGeom && SECFUNCexecA -ce wmctrl -i -r $lnWindowId -e 0,$lnPosX,$lnPosY,$lnWidth,$lnHeight;then #TODO xdotool doesnt work well for this? because of top systray panel?
					lbMoveGeom=false;
				fi
				#############
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# ATTENTION  <-----<< !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# only end when all is done
				#############
				declare -p lbOnTop lbFocus lbMaximize lbUnMaximize lbMinimize lbMoveGeom >&2
				if	! $lbOnTop && 
						! $lbFocus && 
						! $lbMaximize && 
						! $lbUnMaximize &&
						! $lbMinimize &&
						! $lbMoveGeom && 
            true;
        then
					break;
				fi
			fi
			SEC_WARN=true SECFUNCechoWarn "$lstrWarnMsg (to stop this, execute \`kill $BASHPID\`)" #TODO why other aliases work while the alias SECFUNCechoWarnA fails while running secOpenNewX.sh?
			sleep $lnDelay;
			
			if SECFUNCdelay lnTimeout --checkorinit $lnTimeout;then
				SECFUNCechoErr "$lstrWarnMsg (TIMEOUT)"
				break;
			fi
		done	
	};export -f SECFUNCCwindowCmd_ChildLoop
	(SECFUNCCwindowCmd_ChildLoop)&lnChildPid=$!;if ! $lbChild;then wait;fi
	
	SECastrSECFUNCCwindowCmd_ChildRegex[lnChildPid]="$lstrMatchRegex"
	#echo "$lnChildPid"
	
	return 0
}

function SECFUNCCwindowOnTop() { #help
	SECFUNCCwindowCmd --ontop "$@"
}


###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcExtras.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowHelp --onlyvars
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibExtras=$$

