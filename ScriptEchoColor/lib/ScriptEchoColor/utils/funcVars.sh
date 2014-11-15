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
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh") #no need for the array to be previously set empty
source "$SECinstallPath/lib/ScriptEchoColor/utils/funcMisc.sh";
###############################################################################

# MAIN CODE

#shopt -s expand_aliases #at funcMisc

#trap 'SECFUNCvarReadDB;SECFUNCvarWriteDBwithLock;exit 2;' INT

#trap 'SEC_DEBUG=false;SECFUNCvarReadDB;SECFUNCvarWriteDBwithLock;kill -SIGINT $$;' INT #TODO THIS TRAP IS BUGGING NORMAL EXECUTION, IMPROVE IT! to simulate the problem, uncomment it and: eval `secinit`; while true; do echoc -w -t 10; done #now try to hit ctrl+c ...

# Fix in case it is empty or something else, make it sure it is true or false.
# The comparison must be inverse to default value!
# This way, it can be inherited from parent!
#if [[ "$SEC_DEBUG" != "true" ]]; then
#	export SEC_DEBUG=false # of course, np if already "false"
#fi
: ${SEC_DEBUG_WAIT:=false}
if [[ "$SEC_DEBUG_WAIT" != "true" ]]; then
	export SEC_DEBUG_WAIT=false # of course, np if already "false"
fi

: ${SEC_DEBUG_SHOWDB:=false}
if [[ "$SEC_DEBUG_SHOWDB" != "true" ]]; then
	export SEC_DEBUG_SHOWDB=false
fi

: ${SECvarOptWriteAlways:=true}
if [[ "$SECvarOptWriteAlways" != "false" ]]; then
	export SECvarOptWriteAlways=true
fi

: ${SECvarShortFuncsAliases:=true}
if [[ "$SECvarShortFuncsAliases" != "false" ]]; then
	export SECvarShortFuncsAliases=true
fi

# other important initializers
#: ${SECvars=}
if ${SECvars:+false};then
	export SECvars=()
fi
#if [[ -z "${SECvars+dummyValue}" ]];then 
#	export SECvars=()
#fi

if ${SECvarsUserAllowed:+false};then
	export SECvarsUserAllowed=()
fi

#: ${SECmultiThreadEvenPids:=}
if ${SECmultiThreadEvenPids:+false};then
	export SECmultiThreadEvenPids=()
fi
#if [[ -z "${SECmultiThreadEvenPids+dummyValue}" ]];then 
#	export SECmultiThreadEvenPids=()
#fi

# This is not an array, is just a string representin an array..
: ${SECexportedArraysList=}
#if ${SECexportedArraysList:+false};then
#	export SECexportedArraysList=();
#fi

: ${SECvarFile=}

# function aliases for easy coding
: ${SECvarPrefix:=var} #this prefix can be setup by the user
if $SECvarShortFuncsAliases; then 
	#TODO validate if such aliases or executables exist before setting it here and warn about it
	alias "$SECvarPrefix"get='SECFUNCvarGet';
	alias "$SECvarPrefix"readdb='SECFUNCvarReadDB';
	alias "$SECvarPrefix"set='SECFUNCvarSet';
	alias "$SECvarPrefix"setdb='SECFUNCvarSetDB';
	alias "$SECvarPrefix"syncwrdb='SECFUNCvarSyncWriteReadDB';
	alias "$SECvarPrefix"writedb='SECFUNCvarWriteDB';
fi

#if [[ "$SECvarOptWriteDBUseFullEnv" != "false" ]]; then
#	export SECvarOptWriteDBUseFullEnv=true # EXPERIMENTAL!!!!
#fi
#@@@R if [[ "$SECvarInitialized" != "true" ]]; then
#@@@R 	export SECvarInitialized=false #initialized at SECFUNCvarInit
#@@@R fi
### !!!!!!!!! UPDATE l_allVars at SECFUNCvarWriteDB !!!!!!!!!!!!!

function SECFUNCvarClearTmpFiles() { #help remove tmp files that have no related pid
	SECFUNCdbgFuncInA;
	
	local lnDelayToBeOld=600 #in seconds
	local lbForce=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--force" ]]; then #SECFUNCvarClearTmpFiles_help will force clean now
			lbForce=true
		elif [[ "$1" == "--help" ]]; then #SECFUNCvarClearTmpFiles_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		else
			echo "SECERROR(`basename "$0"`:$FUNCNAME): invalid option $1" >>/dev/stderr
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	#local ltmpDateIn=`date +"%Y/%m/%d-%H:%M:%S.%N"`;echo -e "\nIN[$ltmpDateIn]: SECFUNCvarClearTmpFiles\n" >>/dev/stderr
	
	# a control file to clean once only after a delay
	lstrClearControlFile="$SEC_TmpFolder/.SEC.ClearTmpFiles.LastDateTimeStamp"
	if [[ ! -a "$lstrClearControlFile" ]];then
		echo -n >"$lstrClearControlFile"
	fi
	if $lbForce || ((`SECFUNCfileSleepDelay "$lstrClearControlFile"`>60));then #one minute delay
		touch "$lstrClearControlFile"
	else
		SECFUNCdbgFuncOutA;return
	fi

	function SECFUNCvarClearTmpFiles_removeFilesForDeadPids() { 
		SECFUNCdbgFuncInA;
		local lfile="$1";
		
		# the file must exist
		if [[ ! -f "$lfile" ]] && [[ ! -L "$lfile" ]];then
			SECFUNCdbgFuncOutA;return
		fi
		
		if [[ -L "$lfile" ]] && [[ ! -a "$lfile" ]];then
			SECFUNCechoWarnA "the symlink '$lfile -> `readlink "$lfile"`' is broken..."
		fi
		
		# the pid must be written properly
		local lsedPidFromFile='s".*[.]([[:digit:]]*)[.]vars[.]tmp$"\1"';
		local lnPid=`echo "$lfile" |sed -r "$lsedPidFromFile"`;
		# bad filename
		if [[ -z "$lnPid" ]] || [[ -n "`echo "$lnPid" |tr -d "[:digit:]"`" ]];then
			SECFUNCechoErrA "invalid pid '$lnPid' from filename '$lfile'"
			SECFUNCdbgFuncOutA;return 1
		fi
		
		# the pid must NOT be running
		#if ps -p $lnPid >/dev/null 2>&1; then 
		if [[ -d "/proc/$lnPid" ]]; then 
			# skip files that have active pid
			SECFUNCdbgFuncOutA;return
		fi
		
		# the file must NOT have symlinks pointing to it
		#local lnSymlinkToFileCount="`find "$SEC_TmpFolder/" -ignore_readdir_race -maxdepth 1 -lname "$lfile" |wc -l`" #-ignore_readdir_race is not working...
		local lnSymlinkToFileCount="`ls -l "$SEC_TmpFolder/SEC."*".vars.tmp" |egrep " -> $lfile$" |wc -l`"
		if((lnSymlinkToFileCount>=1));then
			SECFUNCechoDbgA "HAS $lnSymlinkToFileCount SYMLINK(s): $lfile"
			SECFUNCdbgFuncOutA;return
		fi
		
		# now only old files will be on the list! this is not needed..
		# skip files the were last active (modified or touch) for less than 10 minutes #TODO this is a hack, a child process should fastly link to parent file but "sometimes it seems to not happen"? would require confirmation...; can this cause a problem that a new pid may be the same of an old pid and so try to use the same file?
#		if((`SECFUNCfileSleepDelay "$lfile"`<lnDelayToBeOld));then
#			SECFUNCdbgFuncOutA;return
#		fi
		
		if ! SECFUNCexecA rm -f "$lfile";then
			SECFUNCechoErrA "rm failed for: $lfile"
		fi
		SECFUNCdbgFuncOutA;
	};export -f SECFUNCvarClearTmpFiles_removeFilesForDeadPids;
	
	# Remove symlinks for dead pids
	#find $SEC_TmpFolder -ignore_readdir_race -maxdepth 1 -name "SEC.*.vars.tmp" -exec bash -c "SECFUNCvarClearTmpFiles_removeFilesForDeadPids \"{}\"" \; #-ignore_readdir_race is not working...
	#set -x
	#find "$SEC_TmpFolder/" -maxdepth 1 -name "SEC.*.vars.tmp" 2>/dev/null |while read lstrFoundFile 2>/dev/null; do SECFUNCvarClearTmpFiles_removeFilesForDeadPids "$lstrFoundFile";done
	#set +x
	#local lfilesList="`find "$SEC_TmpFolder/" -ignore_readdir_race -maxdepth 1 -name "SEC.*.vars.tmp" 2>/dev/null`"
	#local lfilesList="`ls "$SEC_TmpFolder/SEC."*".vars.tmp" 2>/dev/null`"
	#echo "$lfilesList" |while read lstrFoundFile 2>/dev/null; do SECFUNCvarClearTmpFiles_removeFilesForDeadPids "$lstrFoundFile";done
	#ls "$SEC_TmpFolder/SEC."*".vars.tmp" 2>/dev/null |while read lstrFoundFile; do SECFUNCvarClearTmpFiles_removeFilesForDeadPids "$lstrFoundFile";done
	
	# creates a file to use as reference of time that when `ls` by time its position is the delimiter; so files older than it will be after it!
	local lnTimeLimitReference="`date +"%s"`"
	lnTimeLimitReference=$((lnTimeLimitReference-lnDelayToBeOld))
	lstrTimeLimitFile="$SEC_TmpFolder/.SEC.ClearTmpFiles.TimeLimit"
	if [[ ! -f "$lstrTimeLimitFile" ]];then
		echo -n >"$lstrTimeLimitFile"
	fi
	touch --date="@${lnTimeLimitReference}" "$lstrTimeLimitFile"
	local lnLimitOfFilesToWorkWith="`ls "$SEC_TmpFolder/SEC."*".vars.tmp" |wc -l`"
	ls "$SEC_TmpFolder/.SEC.ClearTmpFiles.TimeLimit" "$SEC_TmpFolder/SEC."*".vars.tmp" -t \
		|grep "$SEC_TmpFolder/.SEC.ClearTmpFiles.TimeLimit" -A $lnLimitOfFilesToWorkWith \
		|tail -n +2 2>/dev/null \
		|while read lstrFoundFile; do SECFUNCvarClearTmpFiles_removeFilesForDeadPids "$lstrFoundFile";done
	
	#echo -e "OUT[$ltmpDateIn]: SECFUNCvarClearTmpFiles" >>/dev/stderr
	
	touch "$lstrClearControlFile" #be the last thing after the main work so the delay without cpu usage is granted
	SECFUNCdbgFuncOutA
}

function SECFUNCvarInit() { #help generic vars initializer
	SECFUNCdbgFuncInA
	
	local lbVarChildDb=true
	if [[ "${1-}" == "--nochild" ]];then
		lbVarChildDb=false
	fi
	
	if $lbVarChildDb;then
		SECFUNCvarSetDB #SECFUNCvarReadDB #important to update vars on parent shell when using eval `secinit` #TODO are you sure?
	else
		SECFUNCvarSetDB --forcerealfile
	fi
	
	SECFUNCechoDbgA "SECvarCheckScriptSelfNameParentChange=$SECvarCheckScriptSelfNameParentChange"
	#ls -l "$SECvarFile"
	#if SECbScriptSelfNameChanged;then
	if ! SECFUNCscriptSelfNameCheckAndSet;then # must come after DB is set, better set again as `secinit --vars` may be called later
		if [[ -L "$SECvarFile" ]];then
			if $SECvarCheckScriptSelfNameParentChange;then
				SECFUNCechoBugtrackA "parent script '$SECstrScriptSelfNameParent' differs from current script '$SECstrScriptSelfName' but they have the same DB file where '$SECvarFile' is a symlink. To disable this message: export SECvarCheckScriptSelfNameParentChange=false;";
			fi
		fi
	fi
	
	SECFUNCdbgFuncOutA
}
function SECFUNCvarEnd() { #help generic vars finalizer
	SECFUNCvarEraseDB
}
function SECFUNCvarIsArray() { #help 
	#local l_strTmp=`declare |grep "^$1=("`; #declare is a bit slower than export
	eval "export $1"
	local l_strTmp=`export |grep "^declare -[Aa]x $1='("`;
	
 	#if(($?==0));then
 	if [[ -n "$l_strTmp" ]]; then
 		return 0;
 	fi;
 	return 1;
#  local l_arrayCount=`eval 'echo ${#'$1'[*]}'`
#  if((l_arrayCount>1));then
#  	return 0;
# 	fi
# 	return 1
}

function SECFUNCvarGet() { #help <varname> [arrayIndex] if var is an array, you can use a 2nd param as index in the array (none to return the full array)
  if `SECFUNCvarIsArray $1`;then
  	if [[ -n "${2-}" ]]; then
  		eval 'echo "${'$1'['$2']}"'
  	else
	  	#declare |grep "^$1=(" |sed 's"^'$1'=""'
	  	local l_sedRemoveDeclare="s;^declare -[^ ]* $1=;;"
	  	local l_sedRemovePliqs="s;^'(.*)'$;\1;"
	  	declare -p $1 |sed -r -e "$l_sedRemoveDeclare" -e "$l_sedRemovePliqs"
#			local l_value=""
#			#for val in `eval 'echo "${'$1'[@]}"'`; do
#			local l_tot=`eval 'echo "${#'$1'[*]}"'`
#			for((i=0;i<l_tot;i++)); do
#				local l_separator=`if((i==0));then echo "";else echo " ";fi`
#				#l_value="$l_value '$val'"
#				local l_val=`eval 'echo "${'$1'['$i']}"'`
#				l_val="`SECFUNCfixPliq "$l_val"`"
#				l_value="$l_value$l_separator\"$l_val\""
#			done
#			l_value="($l_value)"
#			echo "$l_value";
  	fi
  else
		#@@@R local varWithCurrencySign=`echo '$'$1`
		#@@@R eval 'echo "'$varWithCurrencySign'"'
		eval 'echo "${'$1'-}"'
	fi
}
function SECFUNCfixPliq() { #help 
		#echo "$1"
  	#echo "$1" |sed -e 's/"/\\"/g' -e 's"\"\\"g'
  	echo "$1" |sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}
function SECFUNCvarShowSimple() { #help (see SECFUNCvarShow)
  SECFUNCvarShow "$1"
}
function SECFUNCvarShow() { #help show var
	local l_prefix="" #"export "
	local lbVarWords=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]]; then #SECFUNCvarShow_help
			SECFUNCshowHelp "$FUNCNAME"
			return
		elif [[ "${1-}" == "--towritedb" ]]; then #SECFUNCvarShow_help
			#l_prefix="SECFUNCvarSet --nowrite " # --nowrite because it will be used at read db
			l_prefix="export "
		elif [[ "${1-}" == "--varwords" ]]; then #SECFUNCvarShow_help
			lbVarWords=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	local lstrVarId="${1-}"
	
	if [[ -z "$lstrVarId" ]] || ! declare -p "$lstrVarId" >/dev/null 2>&1;then
		SECFUNCechoErrA "invalid var '$lstrVarId'"
		return 1
	fi

	if `SECFUNCvarIsArray "$lstrVarId"`;then
  	#TODO support to "'"?
		#TODO (what about declare -g global option?) IMPORTANT: arrays set inside functions cannot have export or they will be ignored!
		echo "$lstrVarId=`SECFUNCvarGet $lstrVarId`;";
	else
		local l_value="`SECFUNCvarGet $lstrVarId`"
		l_value=`SECFUNCfixPliq "$l_value"`
		if $lbVarWords;then
			echo "`SECFUNCseparateInWords $lstrVarId` = \"$l_value\""
		else
			echo "${l_prefix}$lstrVarId=\"$l_value\";";
		fi
	fi
	
}
function SECFUNCvarShowDbg() { #help only show var and value if SEC_DEBUG is set true
  if $SEC_DEBUG; then
    SECFUNCvarShow "$@"
  fi
}

function SECFUNCvarToggle() { #help <varId> only works with variable that has "boolean" value\n\tWill also write the changed variable to BD.
	local lbShow=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]]; then #SECFUNCvarToggle_help
			SECFUNCshowHelp "$FUNCNAME"
			return
		elif [[ "${1-}" == "--show" ]]; then #SECFUNCvarToggle_help
			lbShow=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	local lstrOptShow=""
	if $lbShow;then
		lstrOptShow="--show"
	fi
	
	local lstrVarId="${1-}"
	if [[ -z "$lstrVarId" ]];then
		SECFUNCechoErrA "invalid var '$lstrVarId'"
		return 1
	fi
	
	local lstrValue="`SECFUNCvarGet "$lstrVarId"`"
	local lstrNewValue=""
	if [[ "$lstrValue" == "true" ]];then
		lstrNewValue="false"
	elif [[ "$lstrValue" == "false" ]];then
		lstrNewValue="true"
	else
		SECFUNCechoErrA "var '$lstrVarId' has not boolean value '$lstrValue'"
		return 1
	fi
	
	SECFUNCvarSet $lstrOptShow $lstrVarId="$lstrNewValue"
}

function SECFUNCvarUnset() { #help <var> unregister the variable so it will not be saved to BD next time
	pSECFUNCvarRegister --unregister $1
}

function SECFUNCvarSet() { #help [options] <<var> <value>|<var>=<value>>\n\tImportant: Once a variable is set with this function, always set it with this function, because the DB is read before each set and a previously set value may overwrite the current one, if it was not set with this function. Problem ex.: varset A=10;A=20;varset B=1;echo $A
	SECFUNCdbgFuncInA;
	#SECFUNCvarReadDB
	
	local l_bShow=false
	local l_bShowDbg=false
	#local l_bWrite=false
	local l_bWrite=$SECvarOptWriteAlways
	local l_bDefault=false
	local lbArray=false
	local lbAllowUserToSet=false
	local lbCheckIfUserCanSet=false
	local lbStopParams=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--help" ]]; then #SECFUNCvarSet_help show this help
			SECFUNCshowHelp --nosort ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--show" ]]; then #SECFUNCvarSet_help will show always var and value
			l_bShow=true
		elif [[ "$1" == "--showdbg" ]]; then #SECFUNCvarSet_help will show only if SEC_DEBUG is set
			l_bShowDbg=true
		elif [[ "$1" == "--write" ]]; then #SECFUNCvarSet_help (this is the default now) will also write value promptly to DB
			l_bWrite=true
		elif [[ "$1" == "--array" ]]; then #SECFUNCvarSet_help (auto detection) arrays must be set outside here, this param is just to indicate that the array must be registered, but it cannot (yet?) be set thru this function...
			lbArray=true
		elif [[ "$1" == "--allowuser" ]]; then #SECFUNCvarSet_help user is allowed to easily modify the variable with --checkuser
			lbAllowUserToSet=true
		elif [[ "$1" == "--checkuser" ]]; then #SECFUNCvarSet_help check if user is allowed to easily modify the variable value
			lbCheckIfUserCanSet=true
		elif [[ "$1" == "--nowrite" ]]; then #SECFUNCvarSet_help prevent promptly writing value to DB
			l_bWrite=false
		elif [[ "$1" == "--default" ]]; then #SECFUNCvarSet_help will only set if variable is not set yet (like being initialized only ONCE)
			l_bDefault=true
		elif [[ "$1" == "--" ]];then #SECFUNCvarSet_help remaining params after this are considered as not being options
			lbStopParams=true;
		else
			#echo "SECERROR(`basename "$0"`:$FUNCNAME): invalid option $1" >>/dev/stderr
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
		if $lbStopParams;then
			break;
		fi
	done
	
	local l_varPlDoUsThVaNaPl="$1" #PleaseDontUseThisVarNamePlease
	local l_value="${2-}" #no need to be set as $1 can be var=value

	#if [[ -z "$l_value" ]]; then
	# if begins with valid variable name and also has value set
	if echo "$l_varPlDoUsThVaNaPl" |grep -q "^[[:alnum:]_]*="; then
		#sedVar='s"\(.*\)=.*"\1"'
		sedVar='s"\([[:alnum:]_]*\)=.*"\1"'
		sedValue='s"[[:alnum:]_]*=\(.*\)"\1"'
		l_varPlDoUsThVaNaPl=`echo "$1" |sed "$sedVar"`
		l_value=`echo "$1" |sed "$sedValue"`
	fi
	
	# check if variable id is valid
	if [[ -n "`tr -d "[:alnum:]_" <<< "$l_varPlDoUsThVaNaPl"`" ]] || # if has chars not being: alphanumeric or _
	   [[ -z "`tr -d "[:digit:]" <<< "${l_varPlDoUsThVaNaPl:0:1}"`" ]]; # if 1st char is a number
	then
		SECFUNCechoErrA "invalid variable id l_varPlDoUsThVaNaPl='$l_varPlDoUsThVaNaPl', may only contain alphanumerics and underscores (1st char must not be number)."
		SECFUNCdbgFuncOutA;return 1
	fi
	
	if `SECFUNCvarIsArray $l_varPlDoUsThVaNaPl`; then
		lbArray=true
		l_value=""
	fi
	
	# check if value is compatible
	if ! $lbArray;then
		# boolean check
		if [[ "${!l_varPlDoUsThVaNaPl-}" == "true" || "${!l_varPlDoUsThVaNaPl-}" == "false" ]];then
			if ! [[ "${l_value}" == "true" || "${l_value}" == "false" ]];then
				SECFUNCechoErrA "variable '$l_varPlDoUsThVaNaPl' is considered as being a boolean. l_value='$l_value' but expected value is 'true' or 'false'"
				return 1
			fi
		fi
	fi
	
	SECFUNCvarReadDB --skip $l_varPlDoUsThVaNaPl #TODO test: to read DB is useful to keep current environment updated with changes made by other threads? 
	#TODO may be reading the DB should also be made uniquely (one thread per time)? may be not required, as to set the variable is already uniquely done and it reads the DB;
	#TODO this fails (A=20 is overwritten by A=10): varset A=10;A=20;varset B=1; #find a workaround or not?
	
	local lbUserAllowed=false
	if $lbCheckIfUserCanSet;then
		local lvarCheck
		for lvarCheck in ${SECvarsUserAllowed[@]};do
			if [[ "$l_varPlDoUsThVaNaPl" == "$lvarCheck" ]];then
				lbUserAllowed=true
				break
			fi
		done
		
		if ! $lbUserAllowed;then
			SECFUNCechoErrA "user not allowed to easily set var '$l_varPlDoUsThVaNaPl'"
			SECFUNCdbgFuncOutA;return 1
		fi
	fi
	
	pSECFUNCvarRegister $l_varPlDoUsThVaNaPl #must register before writing
	
	if ! ${lbArray:?}; then
		local l_bSetVarValue=false
		if ${l_bDefault:?}; then
			########################################################
			## TODO improve this info...
			## VALUE can be empty ex. ${VAR+} ${VAR:-}
			## ':' basically means 'empty test'
			## ${VAR+VALUE} # if VAR is unset result is empty '', if VAR is empty or with data, result is 'VALUE'
			## ${VAR:+VALUE} # if VAR is unset OR empty result is empty '', if VAR is with data, result is 'VALUE'
			## ${VAR-VALUE} # if VAR is unset result is 'VALUE', if VAR is set result is $VAR
			## ${VAR:-VALUE} # if VAR is unset or empty result is 'VALUE', if var is with data result is $VAR
			## ${VAR=VALUE} # if VAR is unset, set VAR to 'VALUE' and result is $VAR (that is 'VALUE' now), if VAR is empty or has data result is $VAR
			## ${VAR:=VALUE} # if VAR is unset or empty, set VAR to 'VALUE' and result is $VAR (that is 'VALUE' now), if VAR has data result is $VAR
			## ${VAR?ERRORMESSAGE} #if VAR is unset, terminate shell script with ERRORMESSAGE (that can be empty)
			## ${VAR:?ERRORMESSAGE} #if VAR is unset or empty, terminate shell script with ERRORMESSAGE (that can be empty)
			########################################################
		
			# set default value if variable is not set yet
			if ! eval "[[ -n \${$l_varPlDoUsThVaNaPl+dummyValue} ]]"; then 
				l_bSetVarValue=true
			fi
		else
			l_bSetVarValue=true
		fi
		if $l_bSetVarValue; then
			#eval "export $l_varPlDoUsThVaNaPl=\"$l_value\""
			eval "export $l_varPlDoUsThVaNaPl=\"`SECFUNCfixPliq "$l_value"`\""
		fi
  fi
	
	# add var to user allowed array
	if $lbAllowUserToSet;then
		if ! echo "${SECvarsUserAllowed[@]-}" |grep -qw "$l_varPlDoUsThVaNaPl";then
			SECvarsUserAllowed+=($l_varPlDoUsThVaNaPl)
		fi
	fi
	
	if $lbArray || $l_bSetVarValue; then
		pSECFUNCvarPrepareArraysToExport $l_varPlDoUsThVaNaPl
		if $l_bWrite; then
			if [[ "`SECFUNCfileLock --islocked "$SECvarFile"`" == "$$" ]];then
				#the lock may happen before this function so it must be unlocked only there...
				SECFUNCvarWriteDB --skiplock $l_varPlDoUsThVaNaPl
				if $lbAllowUserToSet;then
					SECFUNCvarWriteDB --skiplock SECvarsUserAllowed
				fi
			else
				SECFUNCvarWriteDB $l_varPlDoUsThVaNaPl
				if $lbAllowUserToSet;then
					SECFUNCvarWriteDB SECvarsUserAllowed
				fi
			fi
		fi
	fi

  if $l_bShow; then # priority over show only in debug mode
	  SECFUNCvarShow $l_varPlDoUsThVaNaPl
  elif $l_bShowDbg; then
	  SECFUNCvarShowDbg $l_varPlDoUsThVaNaPl
	fi
	
	SECFUNCdbgFuncOutA;
}
function SECFUNCvarIsRegistered() { #help check if var is registered
	#echo "${SECvars[*]}" |grep -q $1
	local l_var
	for l_var in ${SECvars[*]-}; do
		if [[ "$1" == "$l_var" ]]; then
			return 0  # found = 0 = true
		fi
	done
	return 1
}
function SECFUNCvarIsSet() { #help equal to: SECFUNCvarIsRegistered
	SECFUNCvarIsRegistered $1
	return $?
}
#function SECFUNCdebugMsg() {
#	echo "SEC_DEBUG(`basename "$0"`): $@" >>/dev/stderr
#}
#function SECFUNCdebugMsgWaitAkey() {
#	if $SEC_DEBUG_WAIT;then
#		SECFUNCechoDbgA "$@, press a key to continue..."
#		read -n 1
#	fi
#}
function SECFUNCvarWaitValue() { #help [OPTIONS] <var> <value> [delay]: wait until var has specified value. Also get the var.
	local l_bNot=false
	local l_bProgress=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--not" ]]; then #SECFUNCvarWaitValue_help true if the value differs from specified.
			l_bNot=true
		elif [[ "$1" == "--report" ]]; then #SECFUNCvarWaitValue_help report what is happening while it waits
			l_bProgress=true
		elif [[ "$1" == "--help" ]]; then #SECFUNCvarWaitValue_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		else
			SECFUNCechoErr "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	local l_var=${1-}
	local l_valueCheck="${2-}"
	local l_delay=${3-}
	if [[ -z "$l_delay" ]]; then
		l_delay=1
	fi
	
	SECONDS=0
	while true; do
		SECFUNCvarReadDB $l_var
		local l_value=`SECFUNCvarGet $l_var`;
		local l_bOk=false;
		
		if $l_bNot; then
			if [[ "$l_value" != "$l_valueCheck" ]]; then
				l_bOk=true;
			fi
		else
			if [[ "$l_value" == "$l_valueCheck" ]]; then
				l_bOk=true;
			fi
		fi
		if $l_bOk; then
			SECFUNCvarGet $l_var #this is to also create the variable on caller
			break;
		fi
		if ! sleep $l_delay; then kill -SIGINT $$; fi
		#read -t $l_delay #bash will crash!
		if $l_bProgress;then
			local lstrNot=""
			if $l_bNot;then
				lstrNot="NOT "
			fi
			echo -ne "waiting $l_var='$l_value' ${lstrNot}be '$l_valueCheck' for ${SECONDS}s...\r" >>/dev/stderr
		fi
	done
}
function SECFUNCvarWaitRegister() { #help <var> [l_delay]: wait var be stored. Loop check delay can be float. Also get the var.
	local l_delay=${2-}
	if [[ -z "$l_delay" ]]; then
		l_delay=1
	fi
	
	while true; do
		SECFUNCvarReadDB $1
		if $SEC_DEBUG;then local l_value=`SECFUNCvarGet $1`;SECFUNCechoDbgA "$1=$l_value";fi
		if SECFUNCvarIsSet $1; then
			SECFUNCvarGet $1 #this is to also create the variable on caller
			break;
		fi
		if ! sleep $l_delay; then kill -SIGINT $$; fi
		#read -t $l_delay #bash will crash!
	done
}
function pSECFUNCvarPrepare_SECvars_ArrayToExport() { #private: 
	if ${SECvars+false};then 
		# was not set
		export SECvars=()
	else 
		# just prepare to be shown with `declare` below
		export SECvars
	fi
#	if((${#SECvars[*]}==0));then
#		export SECvars=()
#	else
#		# just prepare to be shown with `declare` below
#		export SECvars
#	fi
	# collect exportable array in string mode
	local l_export=`declare -p SECvars |sed 's"^declare -ax SECvars"export SECvarsTmp"'`
	# creates SECvarsTmp to be restored as array at pSECFUNCvarRestore_SECvars_Array (on a child shell)
	eval "$l_export"
}
function pSECFUNCvarRestore_SECvars_Array() { #private: IMPORTANT: SECFUNCvarReadDB makes this function useless, just keep it for awhile...
	# if SECvarsTmp is set, recover its value to array on child shell
	if [[ -n "${SECvarsTmp-}" ]]; then
		eval 'SECvars='$SECvarsTmp #do not put export here! this is just to transform the string back into a valid array. Arrays cant currently be exported by bash.
	fi
}
function pSECFUNCvarPrepareArraysToExport() { #private:
	local l_list="$1" #optional for single array variable export
	
	if [[ -z "$1" ]];then
		l_list="${SECvars[*]-}"
	fi
	
	local l_varPlDoUsThVaNaPl #PleaseDontUseThisVarNamePlease
	#export SECexportedArraysList="" #would break in case of single array var export...
	for l_varPlDoUsThVaNaPl in $l_list; do
		if `SECFUNCvarIsArray $l_varPlDoUsThVaNaPl`;then
			# just prepare to be shown with `declare` below
			eval "export $l_varPlDoUsThVaNaPl"
			# collect exportable array in string mode
			local l_export=`declare -p $l_varPlDoUsThVaNaPl |sed "s'^declare -ax $l_varPlDoUsThVaNaPl'export exportedArray_${l_varPlDoUsThVaNaPl}'"`
			if $SEC_DEBUG;then SECFUNCechoDbgA "l_export=$l_export";fi
			
			# creates temp string var representing the array to be restored as array at SECFUNCvarRestoreArray (on a child shell)
			eval "$l_export"
			
			if ! echo "${SECexportedArraysList}" |grep -w "$l_varPlDoUsThVaNaPl" >/dev/null 2>&1; then
				if [[ -n "${SECexportedArraysList}" ]];then #append space
				#if((${#SECexportedArraysList[*]}>0));then #append space
				#if((`SECFUNCarraySize SECexportedArraysList`>0));then #append space
					export SECexportedArraysList="$SECexportedArraysList "
				fi
				export SECexportedArraysList="${SECexportedArraysList}""exportedArray_${l_varPlDoUsThVaNaPl}"
			fi
		fi
	done
}
function pSECFUNCvarRestoreArrays() { #private: 
	# if SECexportedArraysList is set, work with it to recover arrays on child shell
	if [[ -n "${SECexportedArraysList-}" ]]; then
		eval `declare -p $SECexportedArraysList |sed -r 's/^declare -x exportedArray_([[:alnum:]_]*)=(.*)/eval \1=\`echo \2\`;/'`
	fi
}
#function SECFUNCvarRestoreArray() { #private: 
#	# recover temp string value to a real array
#	eval "$1=\$exportedArray_$1" #do not put export here! this is just to transform the string back into a valid array. Arrays cant currently be exported by bash.
#}

function pSECFUNCvarRegister() { #private: 
	local l_bRegister=true
	if [[ "${1-}" == "--unregister" ]];then
		l_bRegister=false
		shift
	fi
	
	if	(   $l_bRegister && ! SECFUNCvarIsRegistered $1 ) ||
			( ! $l_bRegister &&   SECFUNCvarIsRegistered $1 )    ;
	then
		local l_wasLockedHere=false #the lock may happen outside here so it must be unlocked only outside here...
		if [[ "`SECFUNCfileLock --islocked "$SECvarFile"`" != "$$" ]];then
			SECFUNCfileLock "$SECvarFile"
			l_wasLockedHere=true
		fi
		
		SECFUNCvarReadDB SECvars
		#pSECFUNCvarLoadMissingVars
		#SECFUNCvarReadDB
		
		if $l_bRegister;then
			SECvars+=($1) # useless to use like 'export SECvars' here, because bash cant export arrays...
		else
			local l_nSECvarTmpIndex=0
			for l_strSECvarTmp in ${SECvars[@]-}; do
				if [[ "$l_strSECvarTmp" == "$1" ]];then
					unset SECvars[$l_nSECvarTmpIndex]
					SECvars=(${SECvars[@]-}) #to fix index, the removed var will be empty/null
					break
				fi
				((l_nSECvarTmpIndex++))
			done
		fi
		
		pSECFUNCvarPrepare_SECvars_ArrayToExport # so SECvars is always ready when pSECFUNCvarRestore_SECvars_Array is used at child shell
		pSECFUNCvarPrepareArraysToExport $1
	
		SECFUNCvarWriteDB --skiplock SECvars
		
		if $l_wasLockedHere;then
			SECFUNCfileLock --unlock "$SECvarFile" #IMPORTANT: MUST REACH THIS CODE LINE!
		fi
	fi
}

function pSECFUNCvarLoadMissingVars() { #private: 
	# load new vars list
	SECFUNCvarReadDB SECvars;
	
	# load only variables that are missing, to prevent overwritting old variables values
	local l_varsMissing=()
	for l_varNew in ${SECvars[@]-};do
		if ! declare -p $l_varNew >/dev/null 2>&1;then
			SECFUNCvarReadDB $l_varNew;
			l_varsMissing+=($l_varNew)
		fi
	done
#	echo "SECvars=${SECvars[@]-}" >>/dev/stderr
#	echo "MisVars=${l_varsMissing[@]}" >>/dev/stderr
#	cat $SECvarFile |grep varTst |grep -v SECvars >>/dev/stderr
}

function pSECFUNCvarMultiThreadEvenPidsAllowThis() { #private
	# the array SECmultiThreadEvenPids will be indexed by pid ID, and each value is the counter of executions; if a pid is executing above the average of all pids, it will wait (but wont stop completely) so other pids can do their processing...
	SECFUNCdbgFuncInA
	local l_bForceAllow=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--force" ]];then
			l_bForceAllow=true
		else
			SECFUNCechoErrA "invalid option: $1"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
#	local l_pid=-1
#	local l_maxPidId=`cat /proc/sys/kernel/pid_max`
#	for((l_pid=0;l_pid<l_maxPidId;l_pid++));do
#		if [[ -n "${SECmultiThreadEvenPids[l_pid]}" ]];then
#			SECmultiThreadEvenPidsOLD[l_pid]=${SECmultiThreadEvenPids[l_pid]}
#		fi
#	done
	local l_thisPidCounter=0
	if [[ -n "${SECmultiThreadEvenPids[$$]+dummyValue}" ]];then
		# if exists (is set, not unset), backup the value before reading DB
		l_thisPidCounter=${SECmultiThreadEvenPids[$$]}
	fi
	#echo "TEST (`SECFUNCvarShow SECmultiThreadEvenPids`) "`declare -p SECmultiThreadEvenPids` >>/dev/stderr
	SECFUNCvarReadDB SECmultiThreadEvenPids #readonly read the full array (that will also bring the pids in the indexes!), just to know what other pids are doing; the stored SECmultiThreadEvenPids on the DB, is just an old value that was set by the last pid that write to the DB, not the real current value in the memory of that pid.
	#echo "TEST (`SECFUNCvarShow SECmultiThreadEvenPids`) "`declare -p SECmultiThreadEvenPids` >>/dev/stderr
	#restore the backuped value, or set default if none
	SECmultiThreadEvenPids[$$]=$l_thisPidCounter
	#echo "TEST (`SECFUNCvarShow SECmultiThreadEvenPids`) "`declare -p SECmultiThreadEvenPids` >>/dev/stderr
	
	#maintenance, remove dead pids from the list
	if $l_bForceAllow;then 
		local l_pid=-1 #TODO read: info kill, about negative and 0 pid...
#		local l_maxPidId=`cat /proc/sys/kernel/pid_max`
#		for((l_pid=0;l_pid<l_maxPidId;l_pid++));do
#			if [[ -n "${SECmultiThreadEvenPids[l_pid]}" ]];then
#				if ! ps -p $l_pid >/dev/null 2>&1;then
#					unset SECmultiThreadEvenPids[l_pid]
#				fi
#			fi
#		done
#		local sedSelectArrayValue="s;declare -a[x]* SECmultiThreadEvenPids='\(([^)]*)\)';\1;"
#		local sedColledPidsOnly='s;\[([[:digit:]]*)\]="[^"]*";\1;g'
#		local aPidList=(`declare -p SECmultiThreadEvenPids |sed -r -e "$sedSelectArrayValue" -e "$sedColledPidsOnly"`)
#		for l_pid in ${aPidList[@]};do
		for l_pid in ${!SECmultiThreadEvenPids[@]};do
			#if [[ -n "${SECmultiThreadEvenPids[l_pid]}" ]];then
				#if ! ps -p $l_pid >/dev/null 2>&1;then
				if [[ ! -d "/proc/$l_pid" ]];then
					unset SECmultiThreadEvenPids[l_pid]
				fi
			#fi
		done
	fi
	
	# local vars
#	if [[ -z "${SECmultiThreadEvenPids[$$]+dummyValue}" ]];then
#		SECmultiThreadEvenPids[$$]=0
#	fi
#	local l_thisPidCounter=${SECmultiThreadEvenPids[$$]}
	local l_totPids="${#SECmultiThreadEvenPids[@]}"
	local l_sumCounters=`echo "${SECmultiThreadEvenPids[@]}" |tr ' ' '+'`;l_sumCounters=`bc <<< "$l_sumCounters"`
	local l_average=`bc <<< "$l_sumCounters/$l_totPids"`
	
	SECFUNCechoDbgA "l_average=$l_average, l_thisPidCounter=$l_thisPidCounter, l_totPids=$l_totPids, SECmultiThreadEvenPids=(${SECmultiThreadEvenPids[@]}), \$\$=$$, BASHPID=$BASHPID, BASH_SUBSHELL=$BASH_SUBSHELL"
	
	if $l_bForceAllow || ((l_thisPidCounter<=l_average));then
		((++l_thisPidCounter)) #((++SECmultiThreadEvenPids[$$]))
		SECmultiThreadEvenPids[$$]=$l_thisPidCounter
		# SECFUNCvarSet SECmultiThreadEvenPids #do not do this! breaks the synchronised DB access..
		SECFUNCdbgFuncOutA;return 0
	else
		SECFUNCdbgFuncOutA;return 1
	fi
	SECFUNCdbgFuncOutA
}

function SECFUNCvarSyncWriteReadDB() { #help this function should come in the beggining of a loop
	SECFUNCdbgFuncInA
	local l_lockPid
	#grep $$ $SEC_TmpFolder/.SEC.FileLock.*.lock.pid >>/dev/stderr #@@@R
	if l_lockPid=`SECFUNCfileLock --islocked "$SECvarFile"`;then
		#echo "$$,l_lockPid=$l_lockPid,SECFUNCvarWriteDB" >>/dev/stderr
		if [[ "$l_lockPid" == "$$" ]];then
			#pSECFUNCvarRegister SECmultiThreadEvenPids
			SECFUNCvarWriteDB --skiplock #the lock was created in the end of this function
			SECFUNCfileLock --unlock "$SECvarFile" #releases the reading lock
		fi
	fi
	
	SECFUNCdelay pSECFUNCvarMultiThreadEvenPidsAllowThis --init
	while ! pSECFUNCvarMultiThreadEvenPidsAllowThis;do
		sleep 0.1 #waits so other processes have a change to work with the BD
		#echo "delay=`SECFUNCdelay pSECFUNCvarMultiThreadEvenPidsAllowThis --getsec`" >>/dev/stderr
		if((`SECFUNCdelay pSECFUNCvarMultiThreadEvenPidsAllowThis --getsec`>1));then #limit to allow other pids to process
			pSECFUNCvarMultiThreadEvenPidsAllowThis --force
			break;
		fi
	done
	#echo "TEST (`SECFUNCvarShow SECmultiThreadEvenPids`) "`declare -p SECmultiThreadEvenPids` >>/dev/stderr
	
	SECFUNCfileLock "$SECvarFile" # wait until able to get a lock for reading
	#grep $$ $SEC_TmpFolder/.SEC.FileLock.*.lock.pid >>/dev/stderr #@@@R
	SECFUNCvarSet SECmultiThreadEvenPids #SECFUNCvarWriteDB --skiplock SECmultiThreadEvenPids
	SECFUNCvarReadDB #will read the changes of other scripts and force them wait for this caller script to end its proccessing
	
	# exits so the caller script can work with variables on it #TODO verify what happens at SECFUNCvarSet
	SECFUNCdbgFuncOutA
}

function SECFUNCvarWriteDB() { #help 
	SECFUNCdbgFuncInA
	
	local l_bSkipLock=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--skiplock" ]];then
			l_bSkipLock=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local l_fileExist=false
	if [[ -f "$SECvarFile" ]];then
		l_fileExist=true
	fi
	
	if $l_fileExist;then
		if ! $l_bSkipLock;then
			SECFUNCfileLock "$SECvarFile"
		fi
	fi
	
	SECFUNCechoDbgA "'$SECvarFile'"
	
	local l_filter=${1-}; #l_filter="" #@@@TODO FIX FILTER FUNCTIONALITY THAT IS STILL BUGGED!
	local l_allVars=()
	
#  if $SECvarOptWriteDBUseFullEnv;then
  	#declare >"$SECvarFile" #I believe was not too safe
  	
	local lstrDeclareAssociativeArray=""
	if [[ -n "$l_filter" ]];then
		# this way (without cleaning the DB file), it will just append one variable to it; so in the DB file there will have 2 instances of such variable but, of course, only the last one will be valid; is this messy? #TODO update the specific variable with sed -i
		if declare -p "$l_filter" |grep -q "^declare -A";then
			lstrDeclareAssociativeArray="declare -Ag $l_filter;"
		fi
		
		l_allVars=($l_filter)
		#TODO for some reason this sed is breaking the db file data; without it the new var value will be appended and the next db read will ensure the last var value be the right one (what a mess..)
		#sed -i "/^$l_filter=/d" "$SECvarFile" #remove the line with the var
	else
		# do not save these (to prevent them being changed at read db):
		#SEC_DEBUG
		#SEC_DEBUG_SHOWDB
		#SECvarFile
		# this seems safe!  	
		l_allVars=(
			SECvars
			SECvarOptWriteAlways
		)
		l_allVars+=(${SECvars[@]-})
		SECFUNCechoDbgA "l_allVars=(${l_allVars[@]})"
		#declare |grep "^`echo ${l_allVars[@]} |sed 's" "=\\\|^"g'`" >"$SECvarFile"
		#if((${#SECvars[*]}==0));then SECvars=();fi
		echo -n >"$SECvarFile" #clean db file
	fi
	
	local l_sedRemoveArrayPliqs="s;(^.*=)'(\(.*)'$;\1\2;"
	if [[ -n "$lstrDeclareAssociativeArray" ]];then
		echo "$lstrDeclareAssociativeArray" >>"$SECvarFile"
	fi
	declare -p ${l_allVars[@]} 2>/dev/null |sed -r -e 's"^declare -[^ ]* ""' -e "$l_sedRemoveArrayPliqs" >>"$SECvarFile"
#  else
#	  echo >"$SECvarFile" #clean
#	  
#		# register vars to speed up read db
#		echo "export SECvars=(${SECvars[@]});" >>"$SECvarFile"
#		 
#		local l_var
#		for l_var in ${SECvars[*]}; do
#		  SECFUNCvarShow --towritedb $l_var >>"$SECvarFile"
#		done
#  fi
  
	if $SEC_DEBUG && $SEC_DEBUG_SHOWDB; then 
		SECFUNCechoDbgA "Show DB $SECvarFile"
		cat "$SECvarFile" >>/dev/stderr
		if $SEC_DEBUG_WAIT;then
			SECFUNCechoDbgA "press a key to continue..."
			read -n 1
		fi
	fi
	
	if $l_fileExist;then
		if ! $l_bSkipLock;then
			SECFUNCfileLock --unlock "$SECvarFile" #IMPORTANT: MUST REACH THIS CODE LINE!
		fi
	fi
	
	SECFUNCdbgFuncOutA
}

function SECFUNCvarReadDB() { #help [varName] filter to load only one variable value
	SECFUNCdbgFuncInA
	
	l_bSkip=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCvarReadDB_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return 0
		elif [[ "$1" == "--skip" ]];then #SECFUNCvarReadDB_help to skip reading only the optionally specified variable 'varName'
			l_bSkip=true
		else
			echo "SECERROR(`basename "$0"`:$FUNCNAME): invalid option $1" >>/dev/stderr
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	local l_filter="${1-}"
	
	if $SEC_DEBUG; then 
		SECFUNCechoDbgA "'$SECvarFile'"; 
		if $SEC_DEBUG_SHOWDB;then
			cat "$SECvarFile" >>/dev/stderr
		fi
	fi
	
	if [[ -n "$l_filter" ]];then
		#eval "`cat "$SECvarFile" |grep "^${l_filter}="`" >/dev/null 2>&1
		#eval "`grep "^${l_filter}=" "$SECvarFile"`" >/dev/null 2>&1
		local l_paramInvert=""
		if $l_bSkip;then
			l_paramInvert="-v"
		fi
		# can retrieve more than one line with same variable, what is ok as the last set will override all previous ones
		while true;do
			eval "`grep $l_paramInvert "^${l_filter}=" "$SECvarFile"`" >/dev/null 2>&1
			local lnRetFromEval=$?
			if((lnRetFromEval!=0));then
				SECFUNCechoErrA "at config file SECvarFile='$SECvarFile'"
				SECFUNCfixCorruptFile "$SECvarFile"
			else
				break
			fi
		done
	else
		while true;do
			eval "`cat "$SECvarFile"`" >/dev/null 2>&1
			local lnRetFromEval=$?
			if((lnRetFromEval!=0));then
				SECFUNCechoErrA "at config file SECvarFile='$SECvarFile'"
				SECFUNCfixCorruptFile "$SECvarFile"
			else
				break
			fi
		done
	fi
	pSECFUNCvarPrepare_SECvars_ArrayToExport #TODO: (GAMBIARRA) makes SECvars work again, understand why and fix.
	#pSECFUNCvarPrepareArraysToExport
	#pSECFUNCvarRestoreArrays
	
	SECFUNCdbgFuncOutA
}
function SECFUNCvarEraseDB() { #help 
  rm "$SECvarFile"
}
function SECFUNCvarGetMainNameOfFileDB() { #help <pid> returns the main executable name at variables filename
	local l_pid=$1;
	local l_fileFound=`find $SEC_TmpFolder -maxdepth 1 -name "SEC.*.$l_pid.vars.tmp"`
	if [[ -n "$l_fileFound" ]];then 
		echo $l_fileFound |sed -r "s;^$SEC_TmpFolder/SEC[.](.*)[.]$l_pid[.]vars[.]tmp$;\1;"
	else
		return 1
	fi
	
	return 0
}
function SECFUNCvarGetPidOfFileDB() { #help <$SECvarFile> full DB filename
#	if [[ -z "$1" ]];then
#		SECFUNCechoErrA "missing SECvarFile filename to extract pid from..."
#		return 1
#	fi
	
	local l_output=`echo "${1-}" |sed -r 's".*[.]([[:digit:]]*)[.]vars[.]tmp$"\1"'`
	if [[ -z "$l_output" ]];then
		SECFUNCechoErrA "invalid SECvarFile '${1-}' filename..."
		return 1
	fi
	
	echo "$l_output"
}

function SECFUNCvarSetDB() { #help [pid] the variables file is automatically set, but if pid is specified it allows this process to intercomunicate with that pid process thru its vars DB file.
	SECFUNCdbgFuncInA
	
	local l_bForceRealFile=false
	local lbReadDB=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]]; then #SECFUNCvarSetDB_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--forcerealfile" || "$1" == "-f" ]];then #SECFUNCvarSetDB_help it wont create a symlink to a parent DB file and so will create a real top DB file that other childs may link to.
			l_bForceRealFile=true
		elif [[ "$1" == "--skipreaddb" ]];then #SECFUNCvarSetDB_help by default it will read the db at the end of this function, so skip doing this.
			lbReadDB=false
		else
			SECFUNCechoErrA "invalid option $1"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	# params
	local l_pid="${1-}"
	#local l_basename="$2"
	
	# config
	local l_prefix="SEC"
	local l_sufix="vars.tmp"
	local lstrCanonicalFileName="`readlink -f "$0"`"
	local lstrId="`basename "$lstrCanonicalFileName"`"
	lstrId="`SECFUNCfixIdA --justfix "$lstrId"`"
	local l_varFileAutomatic="$SEC_TmpFolder/$l_prefix.$lstrId.$$.$l_sufix"
	local l_basename=""
	
	# BEGIN WORK 
	SECFUNCechoDbgA "SECvarFile=$SECvarFile, l_varFileAutomatic=$l_varFileAutomatic, l_bForceRealFile=$l_bForceRealFile"
	#SECFUNCechoDbgA "ls of l_varFileAutomatic: `ls -l $l_varFileAutomatic >/dev/null 2>&1`"
	
	if $l_bForceRealFile;then
		if [[ -L "$l_varFileAutomatic" ]];then
			rm "$l_varFileAutomatic"
			unset SECvarFile
		elif [[ -f "$l_varFileAutomatic" ]];then
			# if parent pid dies before the symlink be created, a real file will have already been created
			if [[ "$SECvarFile" == "$l_varFileAutomatic" ]];then
				SECFUNCechoDbgA "no need to force as real file has already been created because the parent pid died before the symlink be created..."
				SECFUNCdbgFuncOutA;return 0
			fi
		elif [[ ! -a "$l_varFileAutomatic" ]];then
			# if not exist the automatic will be used below!
			unset SECvarFile
		fi
	fi
	
	#if [[ -z "$l_basename" ]];then
		if [[ -n "$l_pid" ]];then
			l_basename=`SECFUNCvarGetMainNameOfFileDB $l_pid`
			if [[ -z "$l_basename" ]];then
				SECFUNCechoWarnA "not expected: variables file does not exist for asked pid $l_pid..."
			fi
		else
			l_basename=`basename "$0"`
		fi
	#fi
	
	local l_varFileSymlinkToOther=""
	if [[ -n "$l_pid" ]];then
		local l_varFileSymlinkToOther="$SEC_TmpFolder/$l_prefix.$l_basename.$l_pid.$l_sufix"
	fi
	
	local bSymlinkToOther=true
	if [[ -z "$l_pid" ]];then
		bSymlinkToOther=false
	#elif ! ps -p $l_pid >/dev/null 2>&1;then
	elif [[ ! -d "/proc/$l_pid" ]];then
		bSymlinkToOther=false
		SECFUNCechoWarnA "asked pid $l_pid is not running"
	#elif [[ ! -n `find $SEC_TmpFolder -maxdepth 1 -name "SEC.*.$l_pid.vars.tmp"` ]];then #DO NOT TRY TO GUESS THINGS UP, IT IS MESSY...
	elif [[ ! -f "$l_varFileSymlinkToOther" ]];then
		bSymlinkToOther=false
		SECFUNCechoWarnA "SECvarFile '$l_varFileSymlinkToOther' for asked other pid $l_pid does not exist"
	fi
	SECFUNCechoDbgA "bSymlinkToOther=$bSymlinkToOther"
	
	if [[ -n "${SECvarFile-}" ]]; then #SECvarFile is set and not empty
		if [[ ! -f "$SECvarFile" ]];then #check if file was removed
			local l_pidParent=`SECFUNCvarGetPidOfFileDB $SECvarFile`
			#if ps -p $l_pidParent >/dev/null 2>&1;then
			if [[ -n "$l_pidParent" ]] && [[ -d "/proc/$l_pidParent" ]];then
				SECFUNCechoWarnA "SECvarFile '$SECvarFile' should exist..."
			fi
			unset SECvarFile # parent pid died and file was already removed; this allows the creation of a new file below. This can be a problem on a situation where a parent spawns several childs that should intercommunicate and the parent dies before the first symlink to its DB file be created... is it a real/practical problem??
		fi
	fi
	
	if [[ -n "${SECvarFile-}" ]]; then #SECvarFile is set and not empty
		SECFUNCechoDbgA "SECvarFile is already set to $SECvarFile"
		if $bSymlinkToOther;then
			if [[ "$SECvarFile" == "$l_varFileAutomatic" ]];then
				# This function is being called a second time with parameters set. This process variables file will now symlink to a file of another process.
				# no need to first remove the old existing SECvarFile as it will be overwritten
				if [[ ! -f "$SECvarFile" ]];then
					SECFUNCechoWarnA "not expected: SECvarFile '$SECvarFile' should exist..."
				fi
				ln -sf "$l_varFileSymlinkToOther" "$SECvarFile"
			else
				# this will only happen if a child first call to this function has parameters, what is unexpected...
				SECFUNCechoWarnA "not expected: a child first call to this function has parameters that point to another pid/proccess (SECvarFile '$SECvarFile' != l_varFileAutomatic '$l_varFileAutomatic')..."
			fi
		else #not symlink to other
			if [[ "$SECvarFile" != "$l_varFileAutomatic" ]];then
				# THOUGH a child process will DO automatically symlink to parent SECvarFile! #TODO test if is really child is unnecessary?
				local SECvarFileParent="$SECvarFile"
				SECFUNCexecA ln -sf "$SECvarFileParent" "$l_varFileAutomatic"
				export SECvarFile="$l_varFileAutomatic" #IMPORTANT use 'export' to set it properly because read and write DB are on child proccess
			else
				# equal means this function is being called again for this same pid/process, what is unexpected/redundant
				SECFUNCechoWarnA "not expected: redundant call to this function, automatic file '$l_varFileAutomatic' already setup..."
			fi
		fi
	else #SECvarFile is not set (unset)
		# if SECvarFile is not set, it does not exist, will be the first file and the real file (not symlink); happens on parentest initialization
		if [[ -L "$l_varFileAutomatic" ]] || [[ -f "$l_varFileAutomatic" ]];then 
			#SECFUNCechoDbgA "TEST '$l_varFileAutomatic' TMP `ls -l "$l_varFileAutomatic"`"
			SECFUNCechoWarnA "not expected: automatic SECvarFile '$l_varFileAutomatic' should not exist..."
		fi
		
		export SECvarFile="$l_varFileAutomatic" #IMPORTANT use export to set it because read and write DB are on child proccess
		if $bSymlinkToOther;then
			ln -sf "$l_varFileSymlinkToOther" "$SECvarFile"
		else
			SECFUNCvarWriteDB #create the file
		fi
	fi
	
	if $lbReadDB;then
		SECFUNCvarReadDB
	fi
	
	SECFUNCdbgFuncOutA
}
function SECFUNCvarUnitTest() { #help 
	echo "Test to set and get values:"
	local l_values=(
		"123"
		"a b c" 
		"a'b" 
		"a' b" 
		"a'b'" 
		"a '  b' c" 
		"1.2.3" 
		"123.4" 
		"a\"b" 
		"a\"b\"c" 
		"a\"b \"c" 
		"a\"b\" c"
		"a\\//\\\"b\" c"
	)
	for((i=0;i<${#l_values[@]};i++));do
		local l_var
		SECFUNCvarSet l_var="${l_values[i]}"
		if [[ "`SECFUNCvarGet l_var`" != "${l_values[i]}" ]]; then
			echo "FAIL to: ${l_values[i]}"
		else
			echo "OK to: ${l_values[i]}"
		fi
	done
	#SECFUNCvarSet --array l_values
	SECFUNCvarSet l_values
	SECFUNCvarShow l_values
}

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcVars.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibVars=$$

