#!/bin/bash
# Copyright (C) 2004-2018 by Henrique Abdalla
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

source <(secinit)

: ${CFGbFakeRun:=false};export CFGbFakeRun
: ${CFGbIsAFunction:=false};export CFGbIsAFunction

function GAMEFUNCchkWinePrefix() {
	if ${WINEPREFIX+false};then
		echoc --alert "missing WINEPREFIX"
		echoc -w "hit ctrl+c to stop" #TODO use the critical force exit func?
	fi
}

function GAMEFUNCcheckIfGameIsRunning() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	pgrep -f "$lstrFileExecutable" 2>&1 >/dev/null
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

function GAMEFUNCwaitGameExit() { #help <lstrFileExecutable>
	local lstrFileExecutable="$1"
	while true;do
		echoc --info "waiting lstrFileExecutable='$lstrFileExecutable' stop running..."
		sleep 3
		if ! GAMEFUNCcheckIfGameIsRunning "$lstrFileExecutable";then
			break
		fi
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

function GAMEFUNCuniquelyRunThisSubScript() {
	GAMEFUNCcheckIfThisScriptCmdIsRunning --nodeprecationwarn "$@"
}
function GAMEFUNCcheckIfThisScriptCmdIsRunning() { #help <"$@"> (all params that were passed to the script) (useful to help on avoiding dup instances)
	local lbWait=true
	local lbDeprecationWarn=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--nowait" || "$1" == "-n" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help will not wait other exit, will just check for it
			lbWait=false
		elif [[ "$1" == "--nodeprecationwarn" ]];then #not an user option.
			lbDeprecationWarn=false
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
	
	if $lbDeprecationWarn;then
		SECFUNCechoWarnA "use instead 'GAMEFUNCuniquelyRunThisSubScript'"
	fi
	
	local lstrDaemonId="$SECstrScriptSelfName $@"
	lstrDaemonId="`SECFUNCfixIdA --justfix -- "$lstrDaemonId"`"
	
	if $lbWait;then
		SECFUNCuniqueLock --id "$lstrDaemonId" --waitbecomedaemon
	else
		if SECFUNCuniqueLock --id "$lstrDaemonId" --isdaemonrunning;then
			return 0
		else
			return 1
		fi
	fi
	
	return 0
}

#function _GAMEFUNCcheckIfThisScriptCmdIsRunning_old() { #help <"$@"> (all params that were passed to the script) (useful to help on avoiding dup instances)
#	#TODO use instead of this work, the SECFUNCuniqueLock daemon mode... silly me..
#	local lbWait=true
#	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
#		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
#		if [[ "$1" == "--help" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help show this help
#			SECFUNCshowHelp $FUNCNAME
#			return 0
#		elif [[ "$1" == "--nowait" || "$1" == "-n" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help will not wait other exit, will just check for it
#			lbWait=false
#		elif [[ "$1" == "--" ]];then #GAMEFUNCcheckIfThisScriptCmdIsRunning_help params after this are ignored as being these options
#			shift
#			break
#		else
#			SECFUNCechoErrA "invalid option '$1'"
#			SECFUNCshowHelp $FUNCNAME
#			return 1
##		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
##			SECFUNCechoErrA "invalid option '$1'"
##			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
#		fi
#		shift
#	done
#	
#	# check if there is other pids than self tree
#	SECFUNCdelay $FUNCNAME --init
#	
#	strParams=""
#	if [[ -n "${1-}" ]];then
#		strParams="$@"
#	fi
#	echoc --info "checking dup for this '$SECstrScriptSelfName${strParams}' pid=$$"
#	ps --no-headers -o cmd -p $$
#	
#	while true;do
#		echoc --info "check if this script is already running for `SECFUNCdelay $FUNCNAME --getpretty`"
#		
#		anPidList=(`pgrep -f "$SECstrScriptSelfName${strParams}"`) #all pids with this script command, including self
#		SECFUNCexecA -ce declare -p anPidList
#		
#		anPidSkipList=(`SECFUNCppidList --addself --child --pid $$`)
#		anPidSkipList+=(`SECFUNCppidList --pid $$`)
#		SECFUNCexecA -ce declare -p anPidSkipList
#		
#		#TODO wont work with secXtermDetached.sh
#		SECFUNCexecA -ce ps --forest --no-headers -o pid,ppid,cmd -p "${anPidList[@]}" "${anPidSkipList[@]}"
#		
#		for((i1=${#anPidList[@]}-1;i1>=0;i1--));do
#			nPid="${anPidList[i1]}"
#			for((i2=0;i2<${#anPidSkipList[@]};i2++));do
#				nPidSkip="${anPidSkipList[i2]}"
#				if((nPid==nPidSkip));then
#					unset anPidList[i1] # unset only works from last to first
#				fi
#			done
#		done
#		SECFUNCexecA -ce declare -p anPidList
#		
##		if [[ -n "${anPidList[@]}" ]];then
#		if((${#anPidList[@]}>0));then
#			if ps --forest --no-headers -o pid,ppid,cmd -p "${anPidList[@]}";then
#				if $lbWait;then
#					echoc -pw -t 10 "script '$SECstrScriptSelfName${strParams}' already running, waiting other exit"
#				else
#					return 0
#				fi
#				# DO NOT EXIT HERE TO NOT MESS USER SCRIPT! #exit 1 
#			else
#				if $lbWait;then
#					return 1
#				fi
#			fi
#		else
#			break;
#		fi
#		
#		#sleep 60
#	done
#	
#	return 1 #because it was not running and reached here
#}

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

function GAMEFUNClookForDupFiles(){ #help <lstrGamePath>
	local lstrGamePath="$1"
	( #to avoid changing the path outside here
		echoc --info "$FUNCNAME: looking for duplicate files"
		SECFUNCdelay --init $FUNCNAME
		cd "$lstrGamePath"
		local lstrFoundDups="`find |sort -f |uniq -Ddi`"
		if [[ -n "$lstrFoundDups" ]];then
			echoc -p "fix required, there are DUPLICATED files (with case insensitive matching names)"
			echo "$lstrFoundDups"
			echoc -p "fix required, there are DUPLICATED files (with case insensitive matching names)"
			exit 1
		fi
		echoc --info "$FUNCNAME: delay `SECFUNCdelay --getpretty $FUNCNAME`"
	)
};export -f GAMEFUNClookForDupFiles
function FUNClookForDupFiles(){ #help <lstrGamePath>
	GAMEFUNClookForDupFiles "$1"
};export -f FUNClookForDupFiles

function FUNCwait() {
	# all loops that happen the whole game must use this wait mode that is faster than echoc
	#echoc -t $1 --info "$2" #uses much cpu
	#echo -n "$2";read -s -t "$1" -p "";echo
	echo -ne "$2(${SECONDS}s)\r";read -t "$1"&&:
	return 0
};export -f FUNCwait

function FUNCaskSleep() { # <msg> <waitTime>
	# echoc -q #is weighty
	echo -n "${1}?(y/...)"
	if [[ "`read -t $2 -n 1 resp;echo $resp`" == "y" ]];then
		return 0
	fi
	return 1
};export -f FUNCaskSleep

function FUNCvarValue {
  eval "echo -n \"\$1=\$$1\""
};export -f FUNCvarValue

function FUNCisGameRunning() {
	if $CFGbFakeRun;then return 0;fi
	
	SECFUNCvarWaitValue --report --not WINEnGamePid ""
	SECFUNCvarShow WINEnGamePid
	if ! ps -p $WINEnGamePid -o pid,pcpu,stat,state,command >/dev/null; then
		echo "game stopped running"
		return 1
	fi
	return 0
};export -f FUNCisGameRunning

function FUNCwaitGameStartRunning() {
	if $CFGbFakeRun;then return 0;fi
	while true;do
		if FUNCcheckIfGameIsRunning;then
			break
		fi
		echo "waiting game start running..."
		sleep 3
	done
};export -f FUNCwaitGameStartRunning

SECFUNCdelay FUNCexitIfGameExits --init
function FUNCexitIfGameExits() {
	echo -en "check if game is running for `SECFUNCdelay $FUNCNAME --getpretty`\r"
	if ! FUNCcheckIfGameIsRunning;then
		echoc --info "game exited..."
		exit 0
	fi
};export -f FUNCexitIfGameExits

function FUNCexitWhenGameExitsLoop() {
	while ! FUNCcheckIfGameIsRunning;do
		if echoc -q -t 3 "waiting strFileExecutable='$strFileExecutable' start, exit?";then
			exit 0
		fi
	done
	
	while true;do
		FUNCexitIfGameExits
		WINEFUNCstopContGame $WINEnGamePid
	done
};export -f FUNCexitWhenGameExitsLoop

function FUNCdaemonize(){ #obrigatory params: "$@"; makes the script command a daemon based on params
	FUNCcheckIfThisScriptCmdIsRunning "$@"
};export -f FUNCdaemonize

function FUNCcheckIfThisScriptCmdIsRunning() { #~DEPRECATED (function name only)
	local lstrId="`basename ${0}` ${@}"
	while SECFUNCuniqueLock --id "$lstrId" --isdaemonrunning;do
		echoc -pw -t 60 "script '$lstrId' already running, waiting other exit"
	done
	
	SECFUNCuniqueLock --id "$lstrId" --waitbecomedaemon
	SECFUNCuniqueLock --id "$lstrId" --getuniquefile
#	if ! FUNCcheckIfGameIsRunning;then exit 0;fi
};export -f FUNCcheckIfThisScriptCmdIsRunning

function WINEFUNCchkSelfScript() {
	: ${WINEBASE:="$HOME/Wine/"}
	if [[ ! -L "${WINEBASE}/`basename "$0"`" ]];then 
		echoc -p "$0 must be stored at '$WINEPREFIX' and only symlinked at main wine folder."; 
#		echo
#		echoc --alert "remember also to auto create the quickrun symlink by running 'bin/runWINEREDIRECT.sh'"
		echo
		echoc --alert "run these commands:"
		echo "cd '${WINEBASE}';pwd;"
		echo "mkdir -vp '${WINEPREFIX}/';"
		echo "mv -v '$SECstrScriptSelfName' '${WINEPREFIX}/';"
		echo "ln -vs '${WINEPREFIX}/$SECstrScriptSelfName' '$SECstrScriptSelfName';"
		echo "${WINEBASE}/bin/runWINEREDIRECT.sh; #to create the quickrun symlink"
		echo
		exit 1;
	fi
};export -f WINEFUNCchkSelfScript

function GAMEFUNCtimestampLoadOrder(){ #help <check|recreateCfgFromInstallation|fix> #TODO make it work
#GAMEFUNCtimestampLoadOrder_help \t\t<check> [strPluginNameFilter] just shows plugins names with timestamps
#GAMEFUNCtimestampLoadOrder_help \t\t<recreateCfgFromInstallation> will update the loadorder file with the currently setup files timestamps (has safety warning)
#GAMEFUNCtimestampLoadOrder_help \t\t<fix> will use the loadorder file to update the plugins files timestamps.
#GAMEFUNCtimestampLoadOrder_help \t\tPS.: load order file allows commented lines beggining with '#' and empty lines
	
	if ! cd "$strPathInstalled/Data";then
		echoc -p "path not found!"
		exit 1
	fi
	
	bIsMultiLayer=false;if secOverrideMultiLayerMountPoint.sh --is "`pwd`";then bIsMultiLayer=true;fi
	#TODO filter out files not at CFGstrPluginsFile
	
	if $bIsMultiLayer;then echoc --info "multilayer mountpoint mode";fi
	
	strLoadOrderFile="`dirname "$CFGstrPluginsFile"`/.loadorder.sec.UpdateThisToUpdatePlugins.cfg"
	if [[ ! -f "$strLoadOrderFile" ]];then
		echoc -p "strLoadOrderFile='$strLoadOrderFile' missing"
		exit 1
	fi
	
	strLastLoadOrderBkp="`ls -1tr "${strLoadOrderFile}."*".bkp" |tail -n 1`"
	if [[ -f "$strLastLoadOrderBkp" ]];then
		if ! SECFUNCexecA -ce cmp "$strLoadOrderFile" "$strLastLoadOrderBkp";then
			SECFUNCexecA -ce cp -vf "$strLoadOrderFile" "${strLoadOrderFile}.`SECFUNCdtFmt --filename`.bkp"
			echoc --info "backup made!"
		fi
	fi
	
	function _GAMEFUNCtimestampLoadOrder_FUNCclearEndLineComment(){
		echo "$1" |sed -r 's"([^#]*[.]es[mp])[[:blank:]]*#.*"\1"'
	}
	
	function _GAMEFUNCtimestampLoadOrder_FUNCchk(){
		bQuiet=false;if [[ "${1-}" == "--no-verbose" ]];then bQuiet=true;shift;fi
		
		strPluginNameFilter="${1-}"
		if ! $bQuiet;then
			SECFUNCexecA -c --echo ls --full-time -tr "${astrPluginFileList[@]}"
			SECFUNCexecA -c --echo ls -l --time-style "+%s" -tr "${astrPluginFileList[@]}"
		fi
		
		if ! $bQuiet;then
			echoc --info "order indexes"
		fi
		nIndex=0 #why -1?
		strOutput=""
		for strLoadOrderEntry in "${astrLoadOrderEntryList[@]}";do 
			strOutput+="`printf "%02X $strLoadOrderEntry" $nIndex`\n"
			((nIndex++))&&:
		done
		if ! $bQuiet;then
			if [[ -n "$strPluginNameFilter" ]];then
				echo -e "$strOutput" |grep "$strPluginNameFilter"
			else
				echo -e "$strOutput"
			fi
		fi
				
		strLoadorderBatHelpFile="$strPathInstalled/batHelpModsLoadOrder"
		echoc --info "updating strLoadorderBatHelpFile='$strLoadorderBatHelpFile'"
		echo -e "$strOutput" |sed 's".*";&\r"' >"$strLoadorderBatHelpFile"
		SECFUNCexecA ls -l "$strLoadorderBatHelpFile"
		if ! $bQuiet;then
			SECFUNCexecA cat "$strLoadorderBatHelpFile"
		fi
	}
	
	#ls -l "$CFGstrPluginsFile"
	IFS=$'\n' read -d '' -r -a astrPluginFileList < <(cat "$CFGstrPluginsFile" |tr -d '\r')&&:
	if [[ -z "${astrPluginFileList[@]-}" ]];then echoc -p "empty plugins list";exit 1;fi
	
	IFS=$'\n' read -d '' -r -a astrLoadOrderEntryList < <(cat "$strLoadOrderFile" |egrep -v "^[[:blank:]]*#|^[[:blank:]]*$" |tr -d '\r')&&:
	if [[ -z "${astrLoadOrderEntryList[@]-}" ]];then echoc -p "empty load order list";exit 1;fi
#	declare -p astrLoadOrderEntryList
	for((i=0;i<${#astrLoadOrderEntryList[@]};i++));do 
		astrLoadOrderEntryList[i]="`_GAMEFUNCtimestampLoadOrder_FUNCclearEndLineComment "${astrLoadOrderEntryList[i]}"`"
	done
#	declare -p astrLoadOrderEntryList;exit 1
	
	echoc --info "strLoadOrderFile='$strLoadOrderFile'"
	
	if [[ "${1-}" == "check" ]];then
		_GAMEFUNCtimestampLoadOrder_FUNCchk
	elif [[ "${1-}" == "fix" ]];then
		echoc --alert "ATTENTION!!!"
		echoc --info "this will also update the plugins file"
		if echoc -q "this will update all plugins time based on the loadorder file, continue?";then
			nTimeBegin=1199152920 #this value is FIXED based on the main data file as set by mod managers
			for strLoadOrderEntry in "${astrLoadOrderEntryList[@]}";do 
#				strLoadOrderEntry="`echo "$strLoadOrderEntry" |sed -r 's"([^#]*[.]es[mp])[[:blank:]]*#.*"\1"'`"  # remove line ending comments
#				strLoadOrderEntry="`_GAMEFUNCtimestampLoadOrder_FUNCclearEndLineComment "$strLoadOrderEntry"`"
			
				echo
#				echoc --info "working with strLoadOrderEntry='$strLoadOrderEntry'"
				echo "INFO: working with strLoadOrderEntry='$strLoadOrderEntry'"
				#SECFUNCexecA -ce grep -o "$strLoadOrderEntry" "$CFGstrPluginsFile" #making sure it is present at plugins.txt
				ls -l --time-style "+%s" "$strLoadOrderEntry";
				
				astrFileList=()
				if ! $bIsMultiLayer;then
					astrFileList+=("$strLoadOrderEntry")
				else
#					if ! IFS=$'\n' read -d '' -r -a astrFileList < <(find "../" -iname "$strLoadOrderEntry");then :;fi
#					IFS=$'\n' read -d '' -r -a astrFileList < <(str="`find "../" -iname "$strLoadOrderEntry"`"&&:;echo "$str")&&:
#					IFS=$'\n' read -d '' -r -a astrFileList < <(find "../" -iname "$strLoadOrderEntry"&&:;exit 0)
#					IFS=$'\n' read -d '' -r -a astrFileList < <(find "../" -type f -iname "$strLoadOrderEntry"&&:)&&:
					IFS=$'\n' read -d '' -r -a astrFileList < <(find "../" -type d ! -perm -a+r -prune -o -type f -iname "$strLoadOrderEntry" -print&&:)&&:
#					find "../" -type d ! -perm -a+r -prune -o -type f -iname "$strLoadOrderEntry" -print&&:
#					declare -p astrFileList
#					exit 1
				fi
				declare -p astrFileList
				pwd
				
				for strFile in "${astrFileList[@]}";do
					if $bIsMultiLayer;then 
#						readlink -e "$strFile"
#						readlink -e "$strLoadOrderEntry"
						if [[ "`readlink -e "$strFile"`" == "`readlink -e "$strLoadOrderEntry"`" ]];then
							continue; #will skip the file at the main Data folder to work only on the ones at layers
						fi
					fi
					
					# the ones at layers MUST be writable!!!
					SECFUNCexecA -ce touch --date="@${nTimeBegin}" "$strFile"
#					SECFUNCexecA -ce touch --date="@${nTimeBegin}" "$strLoadOrderEntry"
				done
				
				ls -l --time-style "+%s" "$strLoadOrderEntry";
				((nTimeBegin+=60))&&:
			done
			
			# if all went well, update plugins.txt
			echo
			echoc --info "recreating plugins.txt"
			ls -l "$CFGstrPluginsFile"
			SECFUNCexecA -ce mv -vf "$CFGstrPluginsFile" "$CFGstrPluginsFile.`SECFUNCdtFmt --filename`.bkp.txt"
			for strLoadOrderEntry in "${astrLoadOrderEntryList[@]}";do 
				echo -en "$strLoadOrderEntry\r\n" >>"$CFGstrPluginsFile"
			done
			ls -l "$CFGstrPluginsFile"
			
			_GAMEFUNCtimestampLoadOrder_FUNCchk --no-verbose #generates the bat with loadorder
			
			sync #to grant cached writes is properly stored
		fi
	elif [[ "${1-}" == "recreateCfgFromInstallation" ]];then
		echoc --alert "is overkill! will lose all comments!!!"
		echoc --info "better just edit the loadorder file directly and use 'fix' option here..."
		if echoc -q "this will update the loadorder file based on current plugins, continue?";then
			SECFUNCexecA -ce cp -vf "$strLoadOrderFile" "${strLoadOrderFile}.`SECFUNCdtFmt --filename`.bkp"
			ls -tr "${astrPluginFileList[@]}" >"$strLoadOrderFile"
			SECFUNCexecA -ce cat "$strLoadOrderFile"
		fi
	else
		echoc -p "invalid option '${1-}'"
		$SECstrScriptSelfName --help
		exit 1
	fi
};export -f GAMEFUNCtimestampLoadOrder

function WINEFUNCcommonOptions {
	echoc --info "$FUNCNAME $@"
  declare -p SECstrRunLogFile
	
	if [[ "${1-}" == "autoStopContOnScreenLock" ]]; then #help
		FUNCcheckIfThisScriptCmdIsRunning "$@"
		FUNCwaitGameStartRunning
		openNewX.sh --script autoStopContOnScreenLock "`pgrep -x $strFileExecutable`"
	elif [[ "${1-}" == "cdInst" ]];then #help
		shift
		cd "$strPathInstalled"
		SECFUNCcheckActivateRunLog --restoredefaultoutputs #or bash interactive wont work..
		$cmdWine bash
	elif [[ "${1-}" == "cmd" ]];then #help prompt command line
		cd "$strPathInstalled"
		SECFUNCcheckActivateRunLog --restoredefaultoutputs #or cmd interactive wont work..
		$cmdWine cmd
	elif [[ "${1-}" == "dropcaches" ]]; then #help try to dethermine what happens when game freezes
				# clears the RAM cache to prevent crashes!
				echoc -x "sync" #echoc -x "sudo sync"
				echoc -x "echo 3 |sudo -k tee /proc/sys/vm/drop_caches"
	elif [[ "${1-}" == "instGecko" ]];then #help instal mono (like dotnet)
		shift
		strFileWMVers="/tmp/wineGeckoVersions.tmp.html"
		SECFUNCexecA -ce wget -O "$strFileWMVers" http://dl.winehq.org/wine/wine-gecko/&&:
		if [[ -f "$strFileWMVers" ]];then
			echoc --info "latest version:"
			SECFUNCexecA -ce html2text "$strFileWMVers" |grep DIR |tail -n 1 |tr -d "[]/" |awk '{a=$2;print a}'
		fi
		SECFUNCexecA -ce locate -r "wine_gecko.*[.]msi"
		
		strFileInst="`echoc -S "install which?"`"
		WINEFUNCcommonOptions msiInstall "$strFileInst"
	elif [[ "${1-}" == "instMono" ]];then #help instal mono (like dotnet)
		shift
		strFileWMVers="/tmp/wineMonoVersions.tmp.html"
		SECFUNCexecA -ce wget -O "$strFileWMVers" http://dl.winehq.org/wine/wine-mono/&&:
		if [[ -f "$strFileWMVers" ]];then
			echoc --info "latest version:"
			SECFUNCexecA -ce html2text "$strFileWMVers" |grep DIR |tail -n 1 |tr -d "[]/" |awk '{a=$2;print a}'
		fi
		SECFUNCexecA -ce locate -r "wine-mono.*[.]msi"
		
		strFileInst="`echoc -S "install which?"`"
		WINEFUNCcommonOptions msiInstall "$strFileInst"
	elif [[ "${1-}" == "kill" ]];then #help
		kill -SIGKILL `pgrep $strFileExecutable`&&:
		$cmdWine wineserver -k&&: #this does not work (bug?)
		if pgrep wineserver;then
			astr=(wineserver services.exe winedevice.exe plugplay.exe explorer.exe);
			for str in "${astr[@]}";do SECFUNCexec --echo -c pkill -x "$str";done	
		fi
	elif [[ "${1-}" == "msiInstall" ]];then #help to install a .msi file
		shift
		SECFUNCcheckActivateRunLog --restoredefaultoutputs #or cmd interactive wont work..
		$cmdWine msiexec /i "$@"
	elif [[ "${1-}" == "minimize" ]];then #help 
		SECFUNCcfgReadDB
		#echo "bWindowMinimized='$bWindowMinimized'"
		#echo "SECcfgFileName='$SECcfgFileName'"
		#SECFUNCexecA -ce cat "$SECcfgFileName"
		
		# if empty or invalid, will be "false"
		if [[ "$bWindowMinimized" != "true" ]];then bWindowMinimized=false;fi
		
		nWindowId="`xdotool search "$strWindowFullName"`"
		if $bWindowMinimized;then
			SECFUNCexecA -ce wmctrl -i -r $nWindowId -b remove,hidden
			#SECFUNCexecA -ce xdotool windowactivate $nWindowId
			bWindowMinimized=false;
		else
			SECFUNCexecA -ce wmctrl -i -r $nWindowId -b add,hidden
			#SECFUNCexecA -ce xdotool windowminimize $nWindowId
			bWindowMinimized=true;
		fi
		
		SECFUNCcfgWriteVar bWindowMinimized
		#echo "bWindowMinimized='$bWindowMinimized'"
		#SECFUNCexecA -ce cat "$SECcfgFileName"
	elif [[ "${1-}" == "fixkeyproblem" ]]; then #help stops X auto repeating keys
		SECFUNCexecA -ce xset r off
	elif [[ "${1-}" == "restoreKeysAutoRepeat" ]]; then #help restore X auto repeating keys
		SECFUNCexecA -ce xset -r r on
	elif [[ "${1-}" == "screenshot" ]];then #help 
		secScreenShotOnMouseStop.sh -t 0 -k -h
	elif [[ "${1-}" == "runAtom" ]]; then #help [gameRunParams]... run just the target executable alone
		shift
		
		cd "$strPathInstalled"
		
		#SECFUNCcleanEnvironment to prevent from crashing with this error: "The environment block used to start a process cannot be longer than 65535 bytes.  Your environment block is 152614 bytes long.  Remove some environment variables and try again."
		if $WINECFGbFixPTrace;then $cmdWine --ptrace;fi #redundant but ok
	#	$cmdWine "${strRelativeExecutablePath}/${strLoader}" "$@" 2>&1 |tee -a "$SECstrRunLogFile"& #env vars cleaning migrated to wine caller script
		$cmdWine "${strRelativeExecutablePath}/${strLoader}" "$@" 
		FUNCwaitGamePid
	elif [[ "${1-}" == "runNewSimultInstance" ]];then #help <strNewWinePrefix> [strLogFileHint|""] [nMaxMemKB|0] [nWaitSeconds|0]... run a simultaneous (initially stopped) new instance for quick restart after crashes/exit, strLogFileHint is when initialization have completted based on log file contents, nMaxMemKB is a guess based on memory being filled up
		#~ shift;strNewWinePrefix="$1" #required
		#~ shift&&:;strLogFileHint="${1-}"
		#~ shift&&:;nMaxMemKB="${1-}";if [[ -z "$nMaxMemKB" ]];then nMaxMemKB=0;fi #will wait til this amount in KB is reached b4 continuing
    #~ shift&&:;nWaitSeconds="${1-}";if [[ -z "$nWaitSeconds" ]];then nWaitSeconds=1;fi #will wait at least 1s
		#~ shift&&:
		#shift;nBlindWaitAfterInit="$1"
    : ${strNewWinePrefix:=};if [[ -z "$strNewWinePrefix" ]];then echoc -p "strNewWinePrefix must be set!";exit 1;fi
		: ${strLogFileHint:=};
		: ${nMaxMemKB:=0} #will wait til this amount in KB is reached b4 continuing
    : ${nWaitSeconds:=1} #will wait at least 1s
    shift&&:;astrAppParams=("$@")
		
	#	export WINEPREFIX="$WINEPREFIX/.WinePrefix.win64.NewInstanceForQuickRestart/"
		export WINEPREFIX="$strNewWinePrefix"
		cd "$WINEPREFIX/$strPathInstRelat"
		
		strPids=""
		nInstanceCount=0
		function FUNClstInsts() {
			strPids="`ps --no-headers -o pid,start_time --sort start_time -p $(pgrep ${strFileExecutable})`"&&:
			declare -p strPids&&:
			if [[ -n "$strPids" ]];then
				nInstanceCount=`echo "$strPids" |wc -l`
			fi
      return 0
		}
		#~ function FUNCinstsCount() {
			#~ echo "$strPids" |wc -l
		#~ }
		
		SECFUNCuniqueLock --id runNewSimultInstanceGrabAppPid --waitbecomedaemon #b4 running the app
    
		FUNClstInsts
		nInstCountB4=$nInstanceCount
		declare -p nInstCountB4&&:
		#$cmdWine "$strLoader" #
		$cmdWine "${strRelativeExecutablePath}/${strLoader}" "${astrAppParams[@]-}"
    
		while true;do
			# list all pids matching the executable name, the last one is the newest
			FUNClstInsts
			declare -p nInstanceCount&&:
			#~ strPids="`FUNClstInsts`"&&:
			#~ echo "$strPids"
			#~ nInstanceCount=`FUNCinstsCount`
			if((nInstCountB4==0)) && ((nInstanceCount==1));then 
				# there was nothing running, so the new is the only one
				break;
			else
				# there was one running already, so the new is the last one
				if((nInstanceCount>nInstCountB4));then 
					break;
				fi
			fi
			sleep 1
		done
		
		# the newest pid is the last one
		nPidNI="`echo "$strPids" |tail -n 1 |awk '{print $1}'`" #awk to trim the line
		declare -p nPidNI&&:
    
    SECFUNCuniqueLock --id runNewSimultInstanceGrabAppPid --release #after getting the pid
		
		astrCmdPs=(ps --no-headers -o ppid,pid,pcpu,pmem,etime,stat,status,state,rss,cmd -p $nPidNI)
		
		# wait hint
		if [[ -n "$strLogFileHint" ]];then
			SECFUNCdelay waitInit --init
			while ! grep "$strLogFileHint" "$SECstrRunLogFile";do
				"${astrCmdPs[@]}"
				echoc -w -t 3 "waiting initialization for `SECFUNCdelay waitInit --getsec`s ..."
			done
		fi
		
		# wait mem fill
		if [[ -n "$nMaxMemKB" ]];then
			iSleep=3
			# blind wait
			#~ iTot=$(($nBlindWaitAfterInit/iSleep))&&:
			#~ for((i=0;i<iTot;i++));do
				#~ ps -o ppid,pid,pcpu,pmem,etime,stat,status,state,rss,cmd -p $nPidNI&&:
				#~ sleep $iSleep
			#~ done
			while true;do
				"${astrCmdPs[@]}" #ps -o ppid,pid,pcpu,pmem,etime,stat,status,state,rss,cmd -p $nPidNI&&:
				nMemCurrentKB="`ps --no-headers -o rss -p $nPidNI`"
				if((nMemCurrentKB>=nMaxMemKB));then break;fi
				sleep $iSleep
			done
		fi
		
    echoc -w -t $nWaitSeconds "waiting specified delay before stopping the app"
    
		kill -SIGSTOP $nPidNI
		
		WINEFUNCcommonOptions hookOnPidStopCont $nPidNI
	elif [[ "${1-}" == "hookOnPidStopCont" ]];then #help <nPid> hook on pid to monitor it and  stop/continue
		shift
		nPid=$1;shift #TODO	WINEnGamePid is saved to a file, better not mess with it?
		
		while true;do
			if ! ps -p "$nPid";then exit 0;fi
			WINEFUNCstopContGame $nPid
		done
	elif [[ "${1-}" == "delOldSaves" ]];then #help <strSavesPath> <iKeepCount> <astrFilesExtensionsAndMask[]> #astrFilesExtensionsAndMask ex.: "*.sav" "*.bla", every entry means a iKeepCount multiplier (as they must be related to the same savegame), so in this ex. it would be 2
		shift
		strSavesPath="$1";shift
		iKeepCount="$1";shift
		astrFilesExtensionsAndMask=("$@")
		
		cd "$strSavesPath";pwd
		IFS=$'\n' read -d '' -r -a astrFileList < <(ls ${astrFilesExtensionsAndMask[@]} -1tr)&&:; #oldest first
		#declare -p astrFileList
		iSub=$((iKeepCount*${#astrFilesExtensionsAndMask[@]}))&&:
		iDelCount=$((${#astrFileList[@]}-iSub))&&:
		if((iDelCount>0));then
			trash -v "${astrFileList[@]:0:$iDelCount}"
		fi
		echoc --info "kept"
		ls ${astrFilesExtensionsAndMask[@]} -lt
	elif $CFGbIsAFunction || [[ "${1-}" == "custom" ]];then #help [cmd and params...] runs a custom command with the WINEPREFIX etc all setup
		if [[ "${1-}" == "custom" ]];then
			shift
		fi
		
		if [[ -d "$strPathInstalled" ]];then cd "$strPathInstalled";fi
		pwd
		
		if $CFGbIsAFunction;then
			"$@"
		else
			$cmdWine "$@"
			FUNCwaitGamePid
		fi
	elif [[ "${1-}" == "winetricks" ]];then #help [params...]
		shift
		$cmdWine winetricks "$@"
		# sound can be fixed with: winetricks sound=alsa #but may cause weird problems like missing sound effects; only pulseaudio works 100%
	else
		echoc -p "invalid option '${1-}'"
		if echoc -q "try as custom?";then
			$0 custom "$@"
		fi
	fi
};export -f WINEFUNCcommonOptions

function FUNCcheckIfGameIsRunning() {
	if $CFGbFakeRun;then return 0;fi
	
	#if pgrep "$strFileExecutable" 2>&1 >/dev/null;then return 0;fi
	#if pgrep -f "^${strRelativeExecutablePath-}[/]*$strFileExecutable" 2>&1 >/dev/null;then return 0;fi
	if [[ -n "${WINEnGamePid-}" ]] && ps -p "$WINEnGamePid";then return 0;fi
	
	return 1;
};export -f FUNCcheckIfGameIsRunning

function FUNCelse() {
	local lstrType="`type -t ${1-}`"
	case "$lstrType" in
		alias|file|function) (SECFUNCcheckActivateRunLog --restoredefaultoutputs;SECFUNCexecA "$@");;
		*) echoc -p "invalid option ($lstrType) '${1-}'";_SECFUNCcriticalForceExit;;
	esac
};export -f FUNCelse

function FUNClimitSaveGames() {
		########### CFG ############
    local lnLimitAmount=200
		local lstrPathSaves=""
		local lstrPathSavesBkp=""
    local lstrExt=""
    local lstrExt2=""
    local lsedStripLocation="" #strip the part of the save name that does not changes between saves depending on location
    local lsedStripIndex=""
    local nMinutes=15
    local lnDelayMaxSec=$((nMinutes*60)) #in seconds
    local lbSpeak=false
    local lbSpeakEachNewSaveDetected=false
    local lbUseTrash=false
		while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
			if [[ "$1" == "--help" ]];then #FUNClimitSaveGames_help
				SECFUNCshowHelp --file "$strSelfFileCommonScripts" $FUNCNAME
				return 0
			elif [[ "$1" == "--lnLimitAmount" || "$1" == "-l" ]];then #FUNClimitSaveGames_help <lnLimitAmount>
				shift
				lnLimitAmount="${1-}"
			elif [[ "$1" == "--lstrPathSaves" ]];then #FUNClimitSaveGames_help <lstrPathSaves>
				shift
				lstrPathSaves="${1-}"
			elif [[ "$1" == "--lstrPathSavesBkp" ]];then #FUNClimitSaveGames_help <lstrPathSavesBkp>
				shift
				lstrPathSavesBkp="${1-}"
			elif [[ "$1" == "--lstrExt" ]];then #FUNClimitSaveGames_help <lstrExt>
				shift
				lstrExt="${1-}"
			elif [[ "$1" == "--lstrExt2" ]];then #FUNClimitSaveGames_help <lstrExt2>
				shift
				lstrExt2="${1-}"
			elif [[ "$1" == "--lnDelayMaxSec" ]];then #FUNClimitSaveGames_help <lnDelayMaxSec> after this delay a backup will always happen
				shift
				lnDelayMaxSec="${1-}"
			elif [[ "$1" == "--lbSpeak" ]];then #FUNClimitSaveGames_help speak the location when a backup happens
				lbSpeak=true
			elif [[ "$1" == "--lbSpeakEachNewSaveDetected" ]];then #FUNClimitSaveGames_help speak whenever a new save is detected, good to make it sure the save happened.
				lbSpeakEachNewSaveDetected=true
			elif [[ "$1" == "--lsedStripLocation" ]];then #FUNClimitSaveGames_help <lsedStripLocation> from filename, must preferably output the location only, something that can be identical between save names; if not set, the location will be ignored and will backup only based on delay
				shift
				lsedStripLocation="${1-}"
			elif [[ "$1" == "--lsedStripIndex" ]];then #FUNClimitSaveGames_help <lsedStripIndex> from filename
				shift
				lsedStripIndex="${1-}"
			elif [[ "$1" == "--lbUseTrash" ]];then #FUNClimitSaveGames_help old files will be trashed instead of rm, beware this may empty your HD free space.
				lbUseTrash=true
			elif [[ "$1" == "--" ]];then #FUNClimitSaveGames_help params after this are ignored as being these options
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
		
		######### validations ##############
		if [[ -n "${1-}" ]];then
			echoc -p "no params expected but found this one: '$1'"
			return 1
		fi
		
		if [[ ! -d "$lstrPathSaves" ]];then
			echoc -p "invalid lstrPathSaves='$lstrPathSaves'"
			return 1
		fi
		if [[ ! -d "$lstrPathSavesBkp" ]];then
			echoc -p "invalid lstrPathSavesBkp='$lstrPathSavesBkp'"
			return 1
		fi
		if [[ -z "$lstrExt" ]];then
			echoc -p "invalid lstrExt='$lstrExt'"
			return 1
		fi
#		if [[ -z "$lsedStripLocation" ]];then
#			echoc -p "invalid lsedStripLocation='$lsedStripLocation'"
#			return 1
#		fi
		
		########### CODE ############
		#SECFUNCshowHelp --file "$strSelfFileCommonScripts" $FUNCNAME;return
		#echoc --alert "needs fixing? (seems to delete some saves it shouldnt?)..."
		
    cd "$lstrPathSaves"
    
    local nSleepMax=10
		local nSleep=$nSleepMax
    local strLocationPrevious=""
    local strLocation=""
    local lastBkpTime=0
    local lsedModifyExtension=""
    local lstrFilePreviousSave=""
    if [[ -n "$lstrExt2" ]];then
	    lsedModifyExtension='s"\(.*\)\.'$lstrExt'$"\1.'$lstrExt2'"'
	  fi
	  local lbExiting=false
    while true; do
#    	FUNCifGameStoppedThenExit
    	if ! FUNCisGameRunning;then
    		echoc --info "exiting..."
    		lbExiting=true
    	fi
#	    SECFUNCvarGet gamePid
#			if ! ps -p $gamePid 2>&1 >/dev/null; then
#				echo "stopped running"
#				break
#			fi
    	
      #lnTotalFiles=`ls |wc -l`
      #dirCount=`ls -l |grep ^d |wc -l`
      local lnTotalFiles="`ls *.$lstrExt |wc -l`"
      if((lnTotalFiles==0));then
      	echoc --info "no saves yet for lstrExt='$lstrExt'..."
      	sleep $nSleep;
      	continue;
      fi
      
      local lstrFileNewestSave="`ls -t *.$lstrExt |head -n 1`"
      local lnNewestIndex=-1
      
      if [[ -n "$lsedStripIndex" ]];then
      	lnNewestIndex="`echo "$lstrFileNewestSave" |sed -r "$lsedStripIndex"`"
      fi
      
      if [[ "$lstrFileNewestSave" != "$lstrFilePreviousSave" ]];then
      	local lstrNewestIndex=""
      	if((lnNewestIndex!=-1));then
      		lstrNewestIndex=$lnNewestIndex;
      	fi
      	echoc --info --say "saved $lstrNewestIndex"
      fi
      
      # when a new location is reached, creates a backup save, also when you are too long on a same place (lnDelayMaxSec)
      if [[ -n "$lsedStripLocation" ]];then
	      strLocation="`echo "$lstrFileNewestSave" |sed -r "$lsedStripLocation"`"
	      
		    if [[ -z "$strLocation" ]];then
		    	echoc -p --say "with limit saves"
		    	echoc -p "lstrFileNewestSave='$lstrFileNewestSave'"
		    	sleep $nSleep
		    	continue
		    fi
	    fi
      
      if [[ "$strLocation" != "$strLocationPrevious" ]] || ((SECONDS-lastBkpTime > lnDelayMaxSec)) || $lbExiting; then
        echo "new location reached: $strLocation (or max delay bkp)"
        cp -uv "$lstrFileNewestSave" "$lstrPathSavesBkp"
        if $lbSpeak;then
	        echoc --info --say "Backup at: $strLocation"
	      fi
        if [[ -n "$lsedModifyExtension" ]];then
		      local lstrFileNewestSave2=`echo "$lstrFileNewestSave" |sed -e "$lsedModifyExtension"`
		      cp -uv "$lstrFileNewestSave2" "$lstrPathSavesBkp"
		    fi
        lastBkpTime=$SECONDS
      fi
      strLocationPrevious="$strLocation"
      
      function FUNClimitSaveGames_trash(){
      	if $lbUseTrash;then
      		trash-put -v "$@"
      	else
      		rm -v "$@"
      	fi
      }
      local toTrash=$((lnTotalFiles-lnLimitAmount))
      if((toTrash>1));then nSleep=0.1;else nSleep=$nSleepMax;fi
      #if echoc -q -t $nSleep "`FUNCvarValue lnTotalFiles`,`FUNCvarValue lnLimitAmount`,`FUNCvarValue toTrash`,$lstrFileNewestSave; Stop Running"; then #slow
      if FUNCaskSleep "`FUNCvarValue lnTotalFiles`,`FUNCvarValue lnLimitAmount`,`FUNCvarValue toTrash`,$lstrFileNewestSave; Stop Running" $nSleep;then
      	break
      fi
      echo # newline for the question
      if((toTrash>0));then
        echo "Trashing:"
        
        local trashFile="`ls -t *.$lstrExt |tail -n 1`"
        ls -tl "$trashFile"
        FUNClimitSaveGames_trash "$trashFile"
        
        if [[ -n "$lsedModifyExtension" ]];then
		      local trashFile2="`echo "$trashFile" |sed -e "$lsedModifyExtension"`"
		      if [[ -f "$trashFile2" ]]; then
				    ls -tl "$trashFile2"
				    FUNClimitSaveGames_trash "$trashFile2"
				  fi
				fi
      fi
      
      lstrFilePreviousSave="$lstrFileNewestSave"
      
      if $lbExiting;then
      	break;
      fi
    done
    
    return 0
};export -f FUNClimitSaveGames

function GAMEFUNCautoStop() { #help OVERRIDE this one to let it auto stop for any reason you want like screensaver enabled!
  return 1;
}
function GAMEFUNCstopContGame() { #help <lnPid>
	#local lnPid="`pgrep -f "$strFileExecutable"`" #TODO may come more than one?
	local lnPid="$1"
	declare -p lnPid
	declare -p WINEPREFIX #to know which instance it is!
	
	ps --no-headers -o pid,stat,state,status,pcpu,rss,cmd -p $lnPid &&:
	
	local lnSleep=10
	
	local lstrPidState="`ps --no-headers -o state -p $lnPid`"
	
  if [[ "$lstrPidState" == "T" ]];then
    if echoc -t $lnSleep -q "continue running?";then
      SECFUNCexecA -ce kill -SIGCONT $lnPid
      
      # raise window
      anWindowIDs=()
      while true;do
        IFS=$'\n' read -d '' -r -a anWindowIDs < <(xdotool search "$strFileExecutable" |sort -u)&&:; 
        if [[ -n "${anWindowIDs[@]-}" ]];then break;fi
        if ! echoc -t 3 -q "unable to find windows for '$strFileExecutable', retry?@Dy";then
          break;
        fi
      done
      if [[ -n "${anWindowIDs[@]-}" ]];then
        for nWID in "${anWindowIDs[@]}";do 
          nWPID="`xdotool getwindowpid $nWID`"&&:
          ps --no-headers -o pid,stat,cmd -p $nWPID&&:
          if((nWPID==lnPid));then
            xdotool windowfocus $nWID
            break;
          fi
        done
      fi
    fi
  else
    local lbStopNow=false
    if ! $lbStopNow && GAMEFUNCautoStop;then lbStopNow=true;fi
    if ! $lbStopNow && echoc -t $lnSleep -q "suspend stop?";then lbStopNow=true;fi
    
    if $lbStopNow;then
      SECFUNCexecA -ce kill -SIGSTOP $lnPid
    fi
  fi
};export -f GAMEFUNCstopContGame
function WINEFUNCstopContGame() { #help DEPRECATED use GAMEFUNCstopContGame instead (kept for compatibility for now)
  GAMEFUNCstopContGame "$@"
};export -f WINEFUNCstopContGame

function GAMEFUNCwaitGamePid() { #help
 	SECFUNCvarSet WINEnGamePid=""
	SECONDS=0
	while ! ps -p $WINEnGamePid >/dev/null 2>&1; do
		SECFUNCvarReadDB
		if [[ "$strLoader" == "$strFileExecutable" ]];then 
			# the direct pid wont die 
			if SECFUNCvarIsSet WINEnDirectGamePid;then
				if ps -p $WINEnDirectGamePid;then
					WINEnGamePid=$WINEnDirectGamePid
				fi
			fi
		fi
		
		# indirect game pid
		if [[ -z "$WINEnGamePid" ]];then
			local lanPid=(`pgrep -f "$strFileExecutable"`)
			
			local nPid
			for nPid in "${lanPid[@]-}";do
        local strExe="$(basename $(readlink "/proc/$nPid/exe"))"&&:
				
				if [[ -n "$strExe" ]] && [[ "${strExe:0:4}" == "wine" ]];then
					# When it is a loader, the loader will die, and a new pid will have the executable name.
					# Only the newest/fresh pid with the executable name must be considered, in case of multiple instances,
					# by ignoring the old instance TODO improve this BAD WILD GUESS WORK.
					strETime="`ps --no-headers -o etime -p $nPid |awk '{tmp=$1;print tmp}'`";
					if [[ "$strETime" =~ ^00:..$ ]];then 
						nETime=${strETime:3:2};
						if((nETime<=20));then # loaders should die fast
							declare -p nETime
							WINEnGamePid=$nPid
							break
						fi
					fi
				fi
			done
		fi
		
		if [[ -n "$WINEnGamePid" ]];then break;fi
		FUNCwait 1 "waiting for game to start..." #echoc -w -t 1 "waiting for game to start"
	done
	SECFUNCvarSet --show WINEnGamePid=$WINEnGamePid
};export -f GAMEFUNCwaitGamePid
function FUNCwaitGamePid() { #help DEPRECATED kept for compat
  GAMEFUNCwaitGamePid "$@"
};export -f FUNCwaitGamePid

function FUNCtrashSymlinksToRoot() {
	( # subshell to not change the caller path
		SECFUNCexecA -ce cd "$WINEPREFIX/"
		pwd
		find -type l -xtype d -lname "/" 2>/dev/null |while read strFolder;do trash -v "$strFolder";done
	)
}

function FUNCchkInitPrefix() {
  #if [[ ! -d "$WINEPREFIX/" ]];then SECFUNCexecA -ce "$cmdWine" wineboot;fi #mkdir -v "$WINEPREFIX/";fi
	if [[ ! -f "$WINEPREFIX/system.reg" ]];then SECFUNCexecA -ce $cmdWine wineboot;fi #mkdir -v "$WINEPREFIX/";fi
	FUNCtrashSymlinksToRoot
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
else
  GAMEFUNCchkWinePrefix
fi

