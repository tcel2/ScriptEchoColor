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

function GAMEFUNCcheckIfGameIsRunning() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	pgrep "$lstrFileExecutable" 2>&1 >/dev/null
}

function GAMEFUNCwaitGameStartRunning() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	while true;do
		if GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";then
			break
		fi
		echoc --info "waiting lstrFileExecutable='$lstrFileExecutable' start running..."
		sleep 3
	done
}

SECFUNCdelay GAMEFUNCexitIfGameExits --init
function GAMEFUNCexitIfGameExits() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	echo -en "check if game is running for `SECFUNCdelay $FUNCNAME --getpretty`\r"
	if ! GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";then
		echoc --info "game exited..."
		exit 0
	fi
}

function GAMEFUNCwaitAndExitWhenGameExits() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	while ! GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";do
		if echoc -q -t 3 "waiting lstrFileExecutable='$lstrFileExecutable' start, exit?";then
			exit 0
		fi
	done
	while true;do
		GAMEFUNCexitIfGameExits "$lstrFileExecutable"
		sleep 10
	done
}

function GAMEFUNCcheckIfThisScriptCmdIsRunning() { #help <"$@"> (all params that were passed to the script) (useful to help on avoiding dup instances)
	local lbWait=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--nowait" || "$1" == "-n" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help will not wait other exit, will just check for it
			lbWait=false
		elif [[ "$1" == "--" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help params after this are ignored as being these options
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
	
	# check if there is other pids than self tree
	SECFUNCdelay $FUNCNAME --init
	
	strParams=""
	if [[ -n "${1-}" ]];then
		strParams="$@"
	fi
	echoc --info "checking dup for this '$SECstrScriptSelfName${strParams}' pid=$$"
	ps --no-headers -o cmd -p $$
	
	while true;do
		echoc --info "check if this script is already running for `SECFUNCdelay $FUNCNAME --getpretty`"
		
		anPidList=(`pgrep -f "$SECstrScriptSelfName${strParams}"`) #all pids with this script command, including self
		SECFUNCexecA -ce declare -p anPidList
		
		anPidSkipList=(`SECFUNCppidList --addself --child --pid $$`)
		anPidSkipList+=(`SECFUNCppidList --pid $$`)
		SECFUNCexecA -ce declare -p anPidSkipList
		
		#TODO wont work with secXtermDetached.sh
		SECFUNCexecA -ce ps --forest --no-headers -o pid,ppid,cmd -p "${anPidList[@]}" "${anPidSkipList[@]}"
		
		for((i1=${#anPidList[@]}-1;i1>=0;i1--));do
			nPid="${anPidList[i1]}"
			for((i2=0;i2<${#anPidSkipList[@]};i2++));do
				nPidSkip="${anPidSkipList[i2]}"
				if((nPid==nPidSkip));then
					unset anPidList[i1] # unset only works from last to first
				fi
			done
		done
		SECFUNCexecA -ce declare -p anPidList
		
#		if [[ -n "${anPidList[@]}" ]];then
		if((${#anPidList[@]}>0));then
			if ps --forest --no-headers -o pid,ppid,cmd -p "${anPidList[@]}";then
				if $lbWait;then
					echoc -pw -t 10 "script '$SECstrScriptSelfName${strParams}' already running, waiting other exit"
				else
					return 0
				fi
				# DO NOT EXIT HERE TO NOT MESS USER SCRIPT! #exit 1 
			else
				if $lbWait;then
					return 1
				fi
			fi
		else
			break;
		fi
		
		#sleep 60
	done
	
	return 1 #because it was not running and reached here
}

#function GAMEFUNCquickSaveAutoBkp() { #help <lstrPathSavegames> <lstrQuickSaveNameAndExt>
function GAMEFUNCquickSaveAutoBkp() { #help <lstrQuickSaveFullPathNameAndExt>
	local lnKeepSaveInterval=100
	local lnSaveLimit=50
	local lbRunOnce=false
	local lnSleepDelay=10
	local lnLeftZeros=10
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #GAMEFUNCquickSaveAutoBkp_help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--keepsaveinterval" || "$1" == "-k" ]];then #GAMEFUNCquickSaveAutoBkp_help <lnKeepSaveInterval> how many saves must happen before one save is kept (not auto trashed)
			shift
			lnKeepSaveInterval="${1-}"
		elif [[ "$1" == "--savelimit" || "$1" == "-l" ]];then #GAMEFUNCquickSaveAutoBkp_help <lnSaveLimit> older saves will be trashed
			shift
			lnSaveLimit="${1-}"
		elif [[ "$1" == "--once" ]];then #GAMEFUNCquickSaveAutoBkp_help run once, no loop
			lbRunOnce=true
		elif [[ "$1" == "--sleepdelay" || "$1" == "-s" ]];then #GAMEFUNCquickSaveAutoBkp_help delay between savegame checks (in seconds) when in loop (default) mode
			shift
			lnSleepDelay="${1-}"
		elif [[ "$1" == "--leftzeros" || "$1" == "-z" ]];then #GAMEFUNCquickSaveAutoBkp_help how many zeros to the left will be placed in the savegame filename
			shift
			lnLeftZeros="${1-}"
		elif [[ "$1" == "--" ]];then #GAMEFUNCquickSaveAutoBkp_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	local lstrQuickSaveFullPathNameAndExt="${1-}"
	
	local lstrPathSavegames="`dirname "$lstrQuickSaveFullPathNameAndExt"`"
	local lstrQuickSaveNameAndExt="`basename "$lstrQuickSaveFullPathNameAndExt"`"
#	echo "lstrQuickSaveFullPathNameAndExt='$lstrQuickSaveFullPathNameAndExt'"
#	echo "lstrPathSavegames='$lstrPathSavegames'"
#	echo "lstrQuickSaveNameAndExt='$lstrQuickSaveNameAndExt'"
	
	if ! SECFUNCisNumber -dn "$lnKeepSaveInterval";then
		SECFUNCechoErrA "invalid lnKeepSaveInterval='$lnKeepSaveInterval'"
		return 1
	fi
	if ! SECFUNCisNumber -dn "$lnSaveLimit";then
		SECFUNCechoErrA "invalid lnSaveLimit='$lnSaveLimit'"
		return 1
	fi
	if ! SECFUNCisNumber -dn "$lnSleepDelay";then
		SECFUNCechoErrA "invalid lnSleepDelay='$lnSleepDelay'"
		return 1
	fi
	if [[ "${lstrPathSavegames:0:1}" != "/" ]];then
		SECFUNCechoErrA "invalid lstrPathSavegames='$lstrPathSavegames', must be absolute"
		return 1
	fi
	if [[ ! -d "$lstrPathSavegames" ]];then
		SECFUNCechoErrA "invalid lstrPathSavegames='$lstrPathSavegames', inexistant"
		return 1
	fi
	if ! SECFUNCisNumber -dn "$lnLeftZeros";then
		SECFUNCechoErrA "invalid lnLeftZeros='$lnLeftZeros'"
		return 1
	fi
	
	#cd "`readlink -f "$lstrPathSavegames"`"
	strPathPwdBkp="`pwd`"
	cd "$lstrPathSavegames"
	echoc --info "PWD='`pwd`'"

	local lstrQuickSaveName="`echo "$lstrQuickSaveNameAndExt" |sed -r 's"(.*)[.][^.]*$"\1"'`"
	local lstrQuickSaveExt="`echo "$lstrQuickSaveNameAndExt" |sed -r 's".*[.]([^.]*)$"\1"'`"
#	echoc --info "lnSaveLimit='$lnSaveLimit'"
#	echoc --info "lnLeftZeros='$lnLeftZeros'"
	
	strLeftZeros="`  eval printf "0%.0s" {1..$lnLeftZeros}`"
	strLeftMatches="`eval printf "?%.0s" {1..$lnLeftZeros}`"
	
	SECFUNCdelay "$FUNCNAME" --init
	while true;do
		GAMEFUNCexitIfGameExits "$strFileExecutable"
		
		local lstrSaveList="`ls -1 $strLeftMatches.$lstrQuickSaveExt |sort -nr`"
		local lnSaveTotal="`echo "$lstrSaveList" |wc -l`"
		local lstrFileNewestSave="`echo "$lstrSaveList" |head -n 1`"
		local lstrFileOldestSave="`echo "$lstrSaveList" |tail -n 1`"
		
		if((lnSaveTotal>lnSaveLimit));then
			trash -v "${lstrFileOldestSave%.$lstrQuickSaveExt}."*
		fi
		
		local lastrExtensionList=(`ls -1 "$lstrQuickSaveName."* |sed -r "s'$lstrQuickSaveName[.]''"`)
		if [[ -z "${lastrExtensionList[@]-}" ]];then
			echoc -p "unable to gather filename extensions for lstrQuickSaveName='$lstrQuickSaveName', at PWD='$PWD'"
			echoc -x "ls -l '${lstrQuickSaveName}.'*"
			echoc -w
			return 1
		fi
		if [[ -n "$lstrFileNewestSave" ]];then
			local lstrIndex="${lstrFileNewestSave%.$lstrQuickSaveExt}"
			if ! SECFUNCisNumber -dn "$lstrIndex";then
				echoc --say -p "invalid save lstrIndex='$lstrIndex'"
			else
				if [[ -f "$lstrQuickSaveNameAndExt" ]];then
					if ! cmp "$lstrQuickSaveNameAndExt" "${lstrIndex}.$lstrQuickSaveExt";then
						# create new
						nIndex="$((10#$lstrIndex))" #prevents octal error
						((nIndex++))&&:
					
						local lstrIndexNew="`printf %0${lnLeftZeros}d $nIndex`"
						
						for strExtension in "${lastrExtensionList[@]}";do
							cp -v "$lstrQuickSaveName.$strExtension" "${lstrIndexNew}.$strExtension"
						done
						if (( (nIndex % lnKeepSaveInterval) == 0 ));then
							for strExtension in "${lastrExtensionList[@]}";do
								cp -v "${lstrIndexNew}.$strExtension" "keep_${lstrIndexNew}.$strExtension"
							done
							echoc --say "keep save $nIndex"
						else
							echoc --say "save $nIndex"
						fi
					
						SECFUNCdelay "$FUNCNAME" --init
					else
						echo -en "waiting new $lstrQuickSaveNameAndExt='$lstrQuickSaveNameAndExt' for `SECFUNCdelay "$FUNCNAME" --getpretty`s\r"
					fi
				else
					echo "waiting $lstrQuickSaveNameAndExt='$lstrQuickSaveNameAndExt' be created..."
				fi
			fi
		else
			pwd
			for strExtension in "${lastrExtensionList[@]}";do
				cp -v "$lstrQuickSaveName.$strExtension" "$strLeftZeros.$strExtension"
				echoc --say "save 0"
			done
		fi
		
		if $lbRunOnce;then
			break
		fi
		
		sleep $lnSleepDelay
	done
	
	cd "$strPathPwdBkp"
	return 0
}

if [[ "$0" == */secGameHelper.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #help
			SECFUNCshowHelp --colorize "use this script as source at other scripts"
			SECFUNCshowHelp
			SECFUNCshowFunctionsHelp
			exit 0
#		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help MISSING DESCRIPTION
#			echo "#your code goes here"
		elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
			shift
			break
		else
			echoc -p "invalid option '$1'"
			exit 1
		fi
		shift
	done
fi

