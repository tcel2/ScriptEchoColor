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

# THIS FILE must contain everything that can be used everywhere without any problems if possible

# TOP CODE
if ${SECinstallPath+false};then export SECinstallPath="`secGetInstallPath.sh`";fi; #to be faster
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcBase.sh") #no need for the array to be previously set empty
source "$SECinstallPath/lib/ScriptEchoColor/utils/funcCore.sh";
###############################################################################

# MAIN CODE

########################## FUNCTIONS
function SECFUNCexecOnSubShell(){ #help runs one parameter with `bash -c "$1"`, and grants arrays are exported
	SECFUNCdbgFuncInA
	
	SECFUNCarraysExport
	
	#local lstrToExec="`SECFUNCparamsToEval "$@"`"
	#SECFUNCechoDbgA "lstrToExec=\"$lstrToExec\""
	
	#bash -c "$lstrToExec"
	bash -c "$1"
	
	SECFUNCdbgFuncOutA
}

function SECFUNCrealFile(){ #help 
	local lfile="${1-}"
	if [[ ! -f "$lfile" ]];then
		SECFUNCechoErrA "lfile='$lfile' not found."
		echo "$lfile"
		return 1
	fi
	
	lfile="`type -P "$lfile"`"
	lfile="`readlink -f "$lfile"`" #canonical name
	
	echo "$lfile"
}

function SECFUNCarraysExport() { #help export all arrays
	SECFUNCdbgFuncInA;
	
	# var init here
	local lbVerbose=false
	local lastrRemainingParams=()
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #SECFUNCarraysExport_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--verbose" || "$1" == "-v" ]];then #SECFUNCarraysExport_help show everything being done
			lbVerbose=true
		elif [[ "$1" == "--" ]];then #SECFUNCarraysExport_help params after this are ignored as being these options, and stored at lastrRemainingParams
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	
	local lsedArraysIds='s"^([[:alnum:]_]*)=\(.*"\1";tfound;d;:found' #this avoids using grep as it will show only matching lines labeled 'found' with 't'
	# this is a list of arrays that are set by the system or bash, not by SEC
	local lastrArraysToSkip=(`env -i bash -i -c declare 2>/dev/null |sed -r "$lsedArraysIds"`)
	local lastrArrays=(`declare |sed -r "$lsedArraysIds"`)
	if $lbVerbose;then declare -p lastrArrays >>/dev/stderr;fi
	lastrArraysToSkip+=(
		BASH_REMATCH 
		FUNCNAME 
		lastrArraysToSkip 
		lastrArrays
		SECastrFunctionStack #TODO explain why this must be skipped...
	) #TODO how to automatically list all arrays to be skipped? 'BASH_REMATCH' and 'FUNCNAME', I had to put by hand, at least now it only exports arrays already marked to be exported what may suffice...
	export SECcmdExportedAssociativeArrays=""
	for lstrArrayName in ${lastrArrays[@]};do
#		local lbSkip=false
		for lstrArrayNameToSkip in ${lastrArraysToSkip[@]};do
			if [[ "$lstrArrayName" == "$lstrArrayNameToSkip" ]];then
#				lbSkip=true
				if $lbVerbose;then echo "SKIP: $lstrArrayName" >>/dev/stderr;fi
				continue 2; #continues outer loop
#				break; # breaks this inner loop
			fi
		done
#		if $lbSkip;then
#			continue;
#		fi
		
		# only export already exported arrays...
		if ! declare -p "$lstrArrayName" |grep -q "^declare -.x";then
			if $lbVerbose;then echo "SKIP: $lstrArrayName" >>/dev/stderr;fi
			continue
		fi
		
		# associative arrays MUST BE DECLARED like: declare -A arrayVarName; previously to having its values attributted, or it will break the code...
		if declare -p "$lstrArrayName" |grep -q "^declare -A";then
			if [[ -z "$SECcmdExportedAssociativeArrays" ]];then
				SECcmdExportedAssociativeArrays="declare -Ag "
			fi
			#export "${SECstrExportedArrayPrefix}_ASSOCIATIVE_${lstrArrayName}=true"
			SECcmdExportedAssociativeArrays+="${lstrArrayName} "
		fi
		
		# creates the variable to be restored on a child shell
		local lstrToExport="export `declare -p $lstrArrayName |sed -r 's"declare -[[:alpha:]]* (.*)"'${SECstrExportedArrayPrefix}'\1"'`"
		if $lbVerbose;then echo "$lstrToExport" >>/dev/stderr;fi
		eval "$lstrToExport"
		
		export SECbHasExportedArrays=true
	done
	
	if $lbVerbose;then
		declare -p SECcmdExportedAssociativeArrays >>/dev/stderr
		declare -p SECbHasExportedArrays >>/dev/stderr
	fi
	
	SECFUNCdbgFuncOutA;
}

function SECFUNCdtFmt() { #help [lfTime] in seconds (or with nano) since epoch; otherwise current (now) is used
	#SECFUNCdtFmt_help If no format option is selected, the default simplest format seconds.nano (%s.%N), will be used, mainly to be reused at param lfTime with --delay.

	#local lastrParams=("$@") #backup before consuming with shift
	local lfTime=""
	local lbPretty=false
	local lbFilename=false
	local lbLogMessages=false
	local lbShowDate=true
	local lstrFmtCustom=""
	local lbDelayMode=false
	local lbShowZeros=true;
	local lbAlternative=false;
	local lbShowNano=true
	local lbShowFormat=false
#	local lbGetSimple=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCdtFmt_help show this help
			SECFUNCshowHelp --nosort ${FUNCNAME}
			return
		elif [[ "$1" == "--pretty" ]];then #SECFUNCdtFmt_help to show as user message
			lbPretty=true
		elif [[ "$1" == "--alt" ]];then #SECFUNCdtFmt_help alternative mode
			lbAlternative=true
		elif [[ "$1" == "--filename" ]];then #SECFUNCdtFmt_help to be used on filename
			lbFilename=true
		elif [[ "$1" == "--logmessages" ]];then #SECFUNCdtFmt_help compact for log messages
			lbLogMessages=true
		elif [[ "$1" == "--nodate" ]];then #SECFUNCdtFmt_help show only time, not the date
			lbShowDate=false
		elif [[ "$1" == "--delay" ]];then #SECFUNCdtFmt_help show as a delay, so days are counted and time starts at '0 00:00:0.0'; only works if param lfTime is specified. The value used at param lfTime must be a delay time, not a date, ex.: if it is 3600 with --pretty, will show as one hour.
			lbDelayMode=true
		elif [[ "$1" == "--nozero" ]];then #SECFUNCdtFmt_help only show date, hour, minute and nano if it is not zero (or has not only zeros to the left, except nano), only works with --delay 
			lbShowZeros=false
		elif [[ "$1" == "--nonano" ]];then #SECFUNCdtFmt_help do not show nano for seconds
			lbShowNano=false
#		elif [[ "$1" == "--get" ]];then #SECFUNCdtFmt_help the simplest format seconds.nano (%s.%N), mainly to be reused at param lfTime with --delay 
#			lbGetSimple=true
		elif [[ "$1" == "--fmt" ]];then #SECFUNCdtFmt_help <format> specify a custom format
			shift
			lstrFmtCustom="${1-}"
		elif [[ "$1" == "--showfmt" ]];then #SECFUNCdtFmt_help show the resulting format used with `date`
			lbShowFormat=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	local lstrFormatSimplest="%s.%N"
	if ! $lbShowNano;then
		lstrFormatSimplest="%s"
	fi
	
	lfTime="${1-}"
	if [[ -z "$lfTime" ]];then
		lfTime="`date +"$lstrFormatSimplest"`" #now
		if $lbDelayMode;then
			SECFUNCechoWarnA "lbDelayMode='$lbDelayMode' requires 'lfTime' to be set, disabling option.."
			lbDelayMode=false
		fi
	else
		if [[ ! "$lfTime" =~ "." ]];then #dot not found
			lfTime+=".0" #fix to be float
		fi
	fi
	
	if ! SECFUNCisNumber -n "$lfTime";then
		SECFUNCechoErrA "invalid lfTime='$lfTime'"
		return 1
	fi
	
	local lnDays=0
	if $lbDelayMode;then
		local lnOneDayInSeconds="$((3600*24))"
		#((lfTime+=$SECnFixDate))
#		echo "SECDBG: $FUNCNAME using SECFUNCbcPrettyCalcA" >>/dev/stderr
		local lnDays="`SECFUNCbcPrettyCalcA --trunc --scale 0 "$lfTime/$lnOneDayInSeconds"`"
		lfTime="`SECFUNCbcPrettyCalcA --scale 9 "$lfTime+$SECnFixDate"`"
		
		#local lstrDays="(`SECFUNCbcPrettyCalcA --scale 9 "($lfTime-$SECnFixDate)/$lnOneDayInSeconds"` days) "
#		local lnDays="`SECFUNCbcPrettyCalcA --scale 0 "($lfTime-$SECnFixDate)/$lnOneDayInSeconds"`"
	fi
	local lnTimeSeconds="${lfTime%.*}" #removed nanos
	local lnTimeNano="${lfTime#*.}" #only nanos
	
	local lstrFormat
	if [[ -n "$lstrFmtCustom" ]];then
		lstrFormat="$lstrFmtCustom"
	else
		function SECFUNCdtFmt_set_lstrFormat() {
			local lstrDaysText="$1"
			local lstrDateFmt="$2"
			local lstrTimeSeparator="$3"
			local lstrNanoSeparator="$4"
			
			if $lbShowDate;then	
				if $lbDelayMode;then 
					if $lbShowZeros || ((lnDays>0));then
						lstrFormat+="$lstrDaysText";
					fi
				else 
					lstrFormat+="$lstrDateFmt";
				fi;
			fi
			
			#SECFUNCechoDbgA --callerfunc "SECFUNCdtFmt" --vars lnTimeSeconds lnTimeNano lfTime
			#SECFUNCechoDbgA --vars lnTimeSeconds lnTimeNano lfTime
			
			# below must be separate to hour and minutes
			if $lbShowZeros || ((lnDays>0)) || (( lnTimeSeconds>=(3600+$SECnFixDate) ));then #3600 = 1h
				lstrFormat+="%H"
				if $lbAlternative;then lstrFormat+="h";fi
				lstrFormat+="${lstrTimeSeparator}"
			fi
			
			if $lbShowZeros || ((lnDays>0)) || (( lnTimeSeconds>=(60+$SECnFixDate) ));then
				lstrFormat+="%M"
				if $lbAlternative;then lstrFormat+="m";fi
				lstrFormat+="${lstrTimeSeparator}"
			fi
			
			lstrFormat+="%S" #always show seconds
			if $lbShowNano;then
				if $lbShowZeros || ((10#$lnTimeNano>0));then
					lstrFormat+="${lstrNanoSeparator}%N"
				fi
			fi
			if $lbAlternative;then lstrFormat+="s";fi
		}
		if $lbPretty;then
			SECFUNCdtFmt_set_lstrFormat "${lnDays} days, " "%d/%m/%Y " ":" "."
		elif $lbFilename;then
			SECFUNCdtFmt_set_lstrFormat "${lnDays}-" "%Y_%m_%d-" "_" "_"
		elif $lbLogMessages;then
			SECFUNCdtFmt_set_lstrFormat "${lnDays}+" "%Y%m%d+" "" "."
		elif $lbAlternative;then
			SECFUNCdtFmt_set_lstrFormat "${lnDays}d" "%Yy%mm%dd+" "" "."
		else
			#SECFUNCdtFmt_set_lstrFormat "" "" "" "."
			lstrFormat="$lstrFormatSimplest"
			if $lbDelayMode;then
				lfTime="`SECFUNCbcPrettyCalcA --scale 9 "$lfTime-$SECnFixDate"`" #undo the fix to show properly
			fi
		fi
	fi
	
	if $lbShowFormat;then
		echo "$FUNCNAME:lstrFormat='$lstrFormat'" #user can easily capture this
	fi
	if ! date -d "@$lfTime" "+${lstrFormat}";then
		SECFUNCechoErrA "invalid lstrFormat='$lstrFormat'" #lfTime already checked
		return 1
	fi
}

#deprecated these functions...
function SECFUNCdtNow() { #
	#date +"%s.%N"; 
	SECFUNCechoErrA "use instead: SECFUNCdtFmt"
	_SECFUNCcriticalForceExit 
}
function SECFUNCdtTimeNow() { #
	SECFUNCechoErrA "use instead: SECFUNCdtFmt"
	_SECFUNCcriticalForceExit 
}
function SECFUNCtimePretty() { #
	#date -d "@`bc <<< "${_SECbugFixDate}+${1}"`" +"%H:%M:%S.%N"
	#date -d "@${1}" +"%H:%M:%S.%N"
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --nodate --pretty ${1-}"
	_SECFUNCcriticalForceExit 
}
function SECFUNCtimePrettyNow() { #
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --nodate --pretty"
	_SECFUNCcriticalForceExit 
}
function SECFUNCdtTimePretty() { #
	#date -d "@${1}" +"%d/%m/%Y %H:%M:%S.%N"
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --pretty ${1-}"
	_SECFUNCcriticalForceExit 
}
function SECFUNCdtTimePrettyNow() { #
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --pretty"
	_SECFUNCcriticalForceExit 
}
function SECFUNCdtTimeToFileName() { #
	#date -d "@${1}" +"%Y_%m_%d-%H_%M_%S_%N"
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --filename ${1-}"
	_SECFUNCcriticalForceExit 
}
function SECFUNCdtTimeToFileNameNow() { #
	SECFUNCechoErrA "use instead: SECFUNCdtFmt --filename"
	_SECFUNCcriticalForceExit 
}

function SECFUNCprc() { #help use (the alias) as `SECFUNCprcA <otherFunction> [params]`, "prevent recursive call" (prc) over 'otherFunction'; requires a variable 'SEClstrFuncCaller' to be set as being the caller of the function that is calling this one\nWARNING this will fail if called from a subfunction of a function...
	local lstrCaller=""
	local lstrFuncCallerOfCaller=""
	local lbCalledWithAlias=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCprc_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCprc_help is the name of the function calling this one
			shift
			lstrCaller="${1-}"
		elif [[ "$1" == "--callerOfCallerFunc" ]];then #SECFUNCprc_help <FUNCNAME> is the name of the function that called the function that called this one
			shift
			lstrFuncCallerOfCaller="${1-}" #will be enforced to be filled below
		elif [[ "$1" == "--calledWithAlias" ]];then #DO NOT DOCUMENT THIS ONE! :P
			lbCalledWithAlias=true
		else
			echo "$FUNCNAME:ERROR:invalid option '$1'" >>/dev/stderr; #DO NOT USE SECFUNCechoErrA here as it calls this function and will cause recursiveness
			_SECFUNCcriticalForceExit
		fi
		shift
	done
	
	if [[ -z "$lstrCaller" ]];then
			echo "SECERROR:$lstrCaller.$FUNCNAME: Must be called from other functions lstrCaller='$lstrCaller'." >>/dev/stderr; #DO NOT USE SECFUNCechoErrA here as it calls this function and will cause recursiveness
			_SECFUNCcriticalForceExit
	fi
	#if [[ -z "$lstrFuncCallerOfCaller" ]];then
	if ! $lbCalledWithAlias;then
			echo "SECERROR:$lstrCaller.$FUNCNAME: Use the alias 'SECFUNCprcA', and set this variable at caller function (current value is): SEClstrFuncCaller='${SEClstrFuncCaller-}'" >>/dev/stderr; #DO NOT USE SECFUNCechoErrA here as it calls this function and will cause recursiveness
			_SECFUNCcriticalForceExit
	fi
	
	# no log or message on fail, as it is an execution preventer
	if [[ "$lstrFuncCallerOfCaller" != "$1" ]];then
#		echo "DIFF: lstrFuncCallerOfCaller='$lstrFuncCallerOfCaller' lstrCaller='$lstrCaller' FUNCNAME='$FUNCNAME' SEClstrFuncCaller='$SEClstrFuncCaller'" >>/dev/stderr
		"$@"
	fi
}

#if [[ "$SEC_DEBUG" == "true" ]];then
#	SECFUNCechoErrA "test error message"
#	SECFUNCechoErr --caller "lstrCaller=funcMisc.sh" "test error message"
#fi

function SECFUNCpidChecks() { #help pid checks #TODO remove deprecated code
	local lbCheckOnly=false
	local lbCmpPid=false
	local lbWritePid=false
	local lbHasOtherPidsPidSkip=false
	local lbMustBeActive=false
	local lbCheckPid=false
	#!!! local lnPid= #do not set it!!! unbound will work
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCpidChecks_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
#		elif [[ "$1" == "--hasotherpids" ]];then #SECFUNCpidChecks_help <skipPid> return true if there are other requests other than the skipPid (usually $$ of lstrCaller script)
#			shift
#			lnPid="${1-0}"
#			
#			lbHasOtherPidsPidSkip=true
#			lbCheckPid=true
		elif [[ "$1" == "--cmp" ]];then #SECFUNCpidChecks_help <pid>
			shift
			lnPid="${1-0}"
			
			lbCmpPid=true
			lbCheckPid=true
#		elif [[ "$1" == "--write" || "$1" == "--allow" ]];then #SECFUNCpidChecks_help <pid>
#			shift
#			lnPid="${1-0}"
#			
#			lbWritePid=true
#			lbCheckPid=true
		elif [[ "$1" == "--active" ]];then #SECFUNCpidChecks_help the pid of other options must be active or it will return false
			lbMustBeActive=true
		elif [[ "$1" == "--check" ]];then #SECFUNCpidChecks_help <pid>
			shift
			lnPid="${1-0}"
			
			lbCheckOnly=true
			lbCheckPid=true
		else
			SECFUNCechoErrA "invalid option $1"
			return 1
		fi
		shift
	done
	
	if $lbHasOtherPidsPidSkip && $lbMustBeActive;then
		SECFUNCechoWarnA "the option '--hasotherpids' ignores '--active'"
		lbMustBeActive=false
	fi
	
	function SECFUNCpidChecks_check(){ 
		local lnPid="${1-}"
		
		if [[ -z "$lnPid" ]];then
			SECFUNCechoErrA "lnPid='$lnPid' empty"
			return 1
		fi
		if [[ -n "`echo "$lnPid" |tr -d "[:digit:]"`" ]];then
			SECFUNCechoErrA "lnPid='$lnPid' is not a pid"
			return 1
		fi
		if(($1<1));then
			SECFUNCechoErrA "lnPid='$lnPid' < 1"
			return 1
		fi
		if(($1>SECnPidMax));then
			SECFUNCechoErrA "lnPid='$lnPid' > $SECnPidMax"
			return 1
		fi
		return 0
	}
	
	# pid check only
	if $lbCheckPid;then
		if ! SECFUNCpidChecks_check "$lnPid";then
			if $lbHasOtherPidsPidSkip;then
				# if pid is invalid all other pids available are valid to return 0
				lnPid=-1
			else
				return 1
			fi
		fi
		if [[ ! -d "/proc/$lnPid" ]];then
			if $lbMustBeActive;then
				return 1
			fi
			SECFUNCechoWarnA "pid '$lnPid' not found"
		fi
		if $lbCheckOnly;then
			return 0
		fi
	fi
			
	# other functionalities
	
	if $lbHasOtherPidsPidSkip;then
		# empty arrays create one empty line prevented with "^$"
		local lnCount="`cat "$SECstrLockFileRequests" "$SECstrLockFileAceptedRequests" 2>/dev/null |grep -wv "$lnPid" |grep -v "^$" |wc -l`"
		#echo "lnCount=$lnCount, `cat "$SECstrLockFileRequests" "$SECstrLockFileAceptedRequests"`" >>/dev/stderr
		if((lnCount>0));then
			return 0
		else
			return 1
		fi
	fi
	
	if $lbWritePid;then
		if [[ -f "$SECstrLockFileAllowedPid" ]];then
			SECFUNCechoWarnA "file SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid' exists, overwritting"
		fi
		if [[ ! -d "/proc/$lnPid" ]];then
			SECFUNCechoErrA "there is no such lnPid='$lnPid' running..."
			return 1
		fi
		echo -n "$lnPid" >"$SECstrLockFileAllowedPid"
		return 0
	fi

	local lnAllowedPid="-1"
	local lbAllowedIsValid=false
	if [[ -f "$SECstrLockFileAllowedPid" ]];then
		lnAllowedPid="`cat "$SECstrLockFileAllowedPid" 2>/dev/null`"
		if SECFUNCpidChecks_check $lnAllowedPid;then
			lbAllowedIsValid=true
		fi
	else
		SECFUNCechoWarnA "file not available SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid'"
	fi
		
	if $lbCmpPid;then
		if ! $lbAllowedIsValid;then
			return 1
		fi
		
		if((lnAllowedPid==lnPid));then
			return 0
		else
			return 1
		fi
	fi
	
	if $lbAllowedIsValid;then
		echo -n "$lnAllowedPid"
		return 0
	else
		echo -n "-1"
		return 1
	fi
	
	return 1
}

#function SECFUNCfixParams() {
#	local lstrToExec=""
#	for lstrParam in "$@";do
#		lstrParam="`echo "${lstrParam}" \
#			|sed -r 's; ;\\\\ ;g' \
#			|sed -r 's;";\\\\";g'`"
#		lstrToExec+="${lstrParam} "
#	done
#	
#  echo "$lstrToExec"
#}

function SECFUNCparamsToEval() { #help 
	local lbNoQuotes=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCparamsToEval_help
			SECFUNCshowHelp --nosort $FUNCNAME
			return
		elif [[ "$1" == "--noquotes" ]];then #SECFUNCparamsToEval_help escape spaces and use no quotes
			lbNoQuotes=true
		else
			SECFUNCechoErrA "invalid option '$1' lstrCaller='$lstrCaller'"
			return 1
		fi
		shift
	done

	local lstrToExec=""
	for lstrParam in "$@";do
		if $lbNoQuotes;then
			lstrToExec+="`sed -r 's; ;\\\\ ;g' <<< "${lstrParam}"` "
		else
			#lstrToExec+="'${lstrParam}' "
			#lstrToExec+="\"`echo "${lstrParam}" |sed -r 's;";\\\\";g'`\" "
			lstrToExec+="\"`sed -r 's;";\\\\";g' <<< "${lstrParam}"`\" "
		fi
	done
	
  echo "$lstrToExec"
}

function SECFUNCsingleLetterOptions() { #help Add this at beggining of your options loop: SECFUNCsingleLetterOptionsA;\n\tIt will expand joined single letter options to separated ones like in -abc to -a -b -c;\n\tOf course will only work with options that does not require parameters, unless the parameter is for the last option...\n\tThis way code maintenance is made easier by not having to update more than one place with the single letter option.
	local lstrCaller=""
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do # "--" this is a specific case where only "--" options are allowed, because this function thakes care of splitting "-" options, to not bugout...
		if [[ "$1" == "--help" ]];then #SECFUNCsingleLetterOptions_help
			SECFUNCshowHelp --nosort $FUNCNAME
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCsingleLetterOptions_help is the name of the function calling this one
			shift
			lstrCaller="${1-}"
		elif [[ "$1" == "--" ]];then #SECFUNCsingleLetterOptions_help params after this are ignored as being options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1' lstrCaller='$lstrCaller'"
			return 1
		fi
		shift
	done
	
	# $1 will be bound
	local lstrOptions=""
	local lnOptSingleLetterIndex
	for((lnOptSingleLetterIndex=1; lnOptSingleLetterIndex < ${#1}; lnOptSingleLetterIndex++));do
		lstrOptions+="-${1:lnOptSingleLetterIndex:1} "
	done
	
	echo "$lstrOptions"
}

: ${SECbExecJustEcho:=true}
#: ${SECbExecDefaultOptions:=""}
function SECFUNCexec() { #help prefer using SECFUNCexecA\n\t[command] [command params] if there is no command and params, and --log is used, it will just initialize the automatic logging for all calls to this function
	local lbOmitOutput=false
	local bShowElapsed=false
	local bWaitKey=false
	local bExecEcho=false
	local bJustEcho=false
	local bJustEchoNoQuotes=false
	local lbLog=false;
	local lbLogTmp=false;
	local lbLogCustom=false;
	export SEClstrLogFileSECFUNCexec #NOT local, so it can be reused by other calls
	export SEClstrFuncExecLastChildRef #NOT local, so it can be reused by other calls
	local lstrLogFileNew="" #actually is temporary variable
	local lbChild=false
	local lbChildClean=false
	local lbDetach=false;
	export SEClnLogQuotaSECFUNCexec #NOT local, so it can be reused by other calls
	local lnLogQuota=0; #0 means no limit
	local lbDoLog=true
	local lstrCaller=""
	local SEClstrFuncCaller=""
	local lbShowLog=false
	local lbDetachedList=false
	local lbStopLog=false
	local lbColorize=false
	local lbEnvVar=false
	local lbDateTimeShow=true;
	local lbFunctionInfoShow=true;
	local lstrChildReference=""
	local lstrReadStatus=""
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		SECFUNCsingleLetterOptionsA;
		if [[ "$1" == "--help" ]];then #SECFUNCexec_help show this help
			SECFUNCshowHelp --nosort ${FUNCNAME}
			return
		elif [[ "$1" == "--caller" ]];then #SECFUNCexec_help is the name of the function calling this one
			shift
#			lstrCaller="${1}: "
			lstrCaller="${1}"
		elif [[ "$1" == "--callerfunc" ]];then #SECFUNCexec_help <FUNCNAME>
			shift
			SEClstrFuncCaller="${1}"
		elif [[ "$1" == "--colorize" || "$1" == "-c" ]];then #SECFUNCexec_help output colored
			lbColorize=true
		elif [[ "$1" == "--quiet" || "$1" == "-q" ]];then #SECFUNCexec_help ommit command output to stdout and stderr (logging overrides this)
			lbOmitOutput=true
		elif [[ "$1" == "--quietoutput" ]];then #deprecated
			SECFUNCechoErrA "deprecated '$1', use --quiet instead"
			_SECFUNCcriticalForceExit
		elif [[ "$1" == "--waitkey" ]];then #SECFUNCexec_help wait a key before executing the command
			bWaitKey=true
		elif [[ "$1" == "--elapsed" ]];then #SECFUNCexec_help quiet, ommit command output to stdout and
			bShowElapsed=true;
		elif [[ "$1" == "--echo" || "$1" == "-e" ]];then #SECFUNCexec_help echo the command that will be executed, output goes to /dev/stderr
			bExecEcho=true;
		elif [[ "$1" == "--justecho" || "$1" == "-j" ]];then #SECFUNCexec_help if global SECbExecJustEcho is false (default is true), command will be run normally, not just echoed. Basically: wont execute, will just echo what would be executed without any format to be easily reused as command anywhere; this output goes to /dev/stdout
			bJustEcho=true;
		elif [[ "$1" == "--justechonoquotes" ]];then #SECFUNCexec_help like --justecho but will not use quotes
			bJustEchoNoQuotes=true;
		elif [[ "$1" == "--log" ]];then #SECFUNCexec_help create a log file (prevent interactivity)
			lbLog=true;
		elif [[ "$1" == "--logtmp" ]];then #SECFUNCexec_help create a temporary log file that is erased on reboot (prevent interactivity)
			lbLog=true;
			lbLogTmp=true;
		elif [[ "$1" == "--logset" ]];then #SECFUNCexec_help <logFile> set your logFile, implies --log (prevent interactivity)
			lbLog=true;
			shift
			lstrLogFileNew="${1-}"
		elif [[ "$1" == "--logshow" ]];then #SECFUNCexec_help show log filename and contents and return
			lbShowLog=true
		elif [[ "$1" == "--logstop" ]];then #SECFUNCexec_help next calls to this function will not be logged after this option happens once (current execution can still be logged unless --nolog is used)
			lbStopLog=true;
		elif [[ "$1" == "--nolog" ]];then #SECFUNCexec_help after log is set once, it will automatically log with other calls to this function, so this prevent a specific exec being logged at SEClstrLogFileSECFUNCexec
			lbDoLog=false;
		elif [[ "$1" == "--nodt" || "$1" == "-D" ]];then #SECFUNCexec_help removes the default datetime
			lbDateTimeShow=false;
		elif [[ "$1" == "--nofunc" || "$1" == "-F"  ]];then #SECFUNCexec_help removes the default function info
			lbFunctionInfoShow=false;
		elif [[ "$1" == "--logquota" ]];then #SECFUNCexec_help <nMaxLines> limit logfile size by nMaxLines, implies --log
			shift
			lnLogQuota=${1-};
			lbLog=true
		elif [[ "$1" == "--child" ]];then #SECFUNCexec_help will run as a child process. It's temp status file goes to SEClstrFuncExecLastChildRef, to not interfere with default outputs.
			lbChild=true;
		elif [[ "$1" == "--readchild" ]];then #SECFUNCexec_help <lstrChildReference> <lstrReadStatus> use SEClstrFuncExecLastChildRef as reference. Each line has a status, like 'exit', use it to retrieve its value. If status is 'all', will dump the full file data. If status is prefixed with 'chk:' like 'chk:exit', will return true if that status was written to the temp file, and false otherwise.
			shift
			lstrChildReference="${1-}"
			shift
			lstrReadStatus="${1-}"
		elif [[ "$1" == "--detach" ]];then #SECFUNCexec_help like --child but creates a detached child process that will continue running without this parent process, implies --log (only really works if outputs are redirected) unless another log type is set; overrides --child
			lbDetach=true;
		elif [[ "$1" == "--detachedlist" ]];then #SECFUNCexec_help show list of detached pids at log
			lbDetachedList=true;
#		elif [[ "$1" == "--childclean" ]];then #SECFUNCexec_help <pid,pid...> clean temp child files 
#			lbChildClean=true; #TODO should validate if is child of this parent?
		elif [[ "$1" == "--envvarset" || "$1" == "-v" ]];then #SECFUNCexec_help will basically prepend the command with `declare -g`
			lbEnvVar=true;
		else
			SECFUNCechoErrA "lstrCaller=${lstrCaller}: invalid option $1"
			return 1
		fi
		shift
	done
	
	if [[ -n "$lstrChildReference" ]];then
#		local lnRefPid="` echo "$lstrChildReference" |cut -f1`"
#		local lnRefFile="`echo "$lstrChildReference" |cut -f2`"
		local lnRefFile="$lstrChildReference"
		if [[ ! -f "$lnRefFile" ]];then
			SECFUNCechoErrA "invalid lnRefFile='$lnRefFile'"
			return 1
		fi
		
		local bChkOnly=false
		if [[ "$lstrReadStatus" =~ ^chk: ]];then
			bChkOnly=true
			lstrReadStatus="${lstrReadStatus:4}"
		fi
		
		local lstrRefPrefix="$lstrReadStatus${SECcharTab}"
		local lstrRefFound
		if [[ "$lstrReadStatus" == "all" ]];then
			lstrRefFound="`cat "$lnRefFile"`"
		else
			lstrRefFound="`egrep "^$lstrRefPrefix" "$lnRefFile"`"&&:
		fi
		
		if [[ -z "$lstrRefFound" ]];then
			if $bChkOnly;then
				return 1
			fi
			SECFUNCechoErrA "invalid lstrReadStatus='$lstrReadStatus'"
			return 1
		else
			if $bChkOnly;then
				return 0
			fi
		fi
		
		if [[ "$lstrReadStatus" == "all" ]];then
			echo "$lstrRefFound"
		else
			echo "$lstrRefFound" |sed -r "s@^$lstrRefPrefix(.*)@\1@"
		fi
		
		return 0
	fi
	
	if $lbDetachedList;then
		if [[ -f "${SEClstrLogFileSECFUNCexec-}" ]];then
			grep "$FUNCNAME;lnPidDetached=" "$SEClstrLogFileSECFUNCexec"&&:
			return 0
		else
			SECFUNCechoErrA "log file SEClstrLogFileSECFUNCexec='${SEClstrLogFileSECFUNCexec-}' not found."
			return 1
		fi
	fi
	
	# fix options
	if [[ "$SEC_DEBUG" == "true" ]];then
		lbOmitOutput=false
	fi
	
	if $lbDetach;then
		lbLog=true;
		lbDoLog=true
		lbChild=true;
	fi
	
	if $lbChild;then
		bShowElapsed=false;
	fi
	
	# main code
	
	if $lbLog;then
		local lbCreateLogFile=false
		if [[ -n "$lstrLogFileNew" ]];then
			lbCreateLogFile=true
		else
			if [[ ! -f "${SEClstrLogFileSECFUNCexec-}" ]];then
				# automatic log filename
				local lstrLogId="$(SECFUNCfixId --justfix $(basename $0))"
				lstrLogFileNew="log/SEC.$lstrLogId.$$.log"
				if $lbLogTmp;then
					lstrLogFileNew="$SECstrTmpFolderUserName/$lstrLogFileNew" #tmp log
#				elif $lbLog;then #as lbLog is default, it comes last here
				else #as lbLog is default, it comes last here
					lstrLogFileNew="$SECstrUserHomeConfigPath/$lstrLogFileNew" #persistent log
				fi

				lbCreateLogFile=true
			fi
		fi

		if $lbCreateLogFile;then
			if ! mkdir -p "`dirname "$lstrLogFileNew"`";then
				SECFUNCechoErrA "unable to create log path for file '$lstrLogFileNew'"
				return 1
			fi
			#if [[ ! -f "$lstrLogFileNew" ]];then 
				if ! echo -n >>"$lstrLogFileNew";then #create file
					SECFUNCechoErrA "unable to create log file '$lstrLogFileNew'"
					return 1
				fi
			#fi
			
			#now lstrLogFileNew exist!
			
			if [[ -f "${SEClstrLogFileSECFUNCexec-}" ]];then
				if [[ "${SEClstrLogFileSECFUNCexec}" != "$lstrLogFileNew" ]];then
					# append old log to new
					cat "${SEClstrLogFileSECFUNCexec}" >>"$lstrLogFileNew"
					#rm "$SEClstrLogFileSECFUNCexec" #TODO more log is better than less?
				fi
			fi
			
			SEClstrLogFileSECFUNCexec="$lstrLogFileNew"
		fi
	fi
	
	###### main code
	if $lbShowLog;then
		if [[ -f "${SEClstrLogFileSECFUNCexec}" ]];then
			echo "SEClnLogQuotaSECFUNCexec=$SEClnLogQuotaSECFUNCexec"
			echo "SEClstrLogFileSECFUNCexec='${SEClstrLogFileSECFUNCexec}'"
			SECFUNCdrawLine " Contents " " <> "
			cat "${SEClstrLogFileSECFUNCexec}"
		else
			echo "no log."
		fi
		return
	fi
	
	local lastrParamsToExec=("$@")
	if $lbEnvVar;then
		lastrParamsToExec=("declare" "-g" "${lastrParamsToExec[@]}")
	fi
	
  local lstrExec="`SECFUNCparamsToEval "${lastrParamsToExec[@]}"`"
	SECFUNCechoDbgA "lstrCaller=${lstrCaller}: $lstrExec"
	
	if $bExecEcho; then
		local lstrColorPrefix=""
		local lstrColorSuffix=""
		if $lbColorize;then
#			lstrColorPrefix="\E[0m\E[37m\E[46m\E[1m"
			lstrColorPrefix="${SECcolorCancel}${SECcolorWhite}\E[46m\E[1m"
			lstrColorSuffix="${SECcolorCancel}"
		fi
		
		local lstrDateTime="";
		if $lbDateTimeShow;then
			lstrDateTime="[`SECFUNCdtTimeForLogMessages`] "
		fi
		
		local lstrFunctionInfo=""
		if $lbFunctionInfoShow;then
			lstrFunctionInfo="$FUNCNAME: lstrCaller=${lstrCaller}: "
		fi
		
		local lstrChildIndicator=""
		if $lbChild;then
			lstrChildIndicator=" # as "
			if $lbDetach;then
				lstrChildIndicator+="DETACHED "
			fi
			lstrChildIndicator+="CHILD process (see var SEClstrFuncExecLastChildRef)"
		fi
		
		echo -e "${lstrColorPrefix}${lstrDateTime}${lstrFunctionInfo}${lstrExec}${lstrChildIndicator}${lstrColorSuffix}" >>/dev/stderr
	fi
	
	if $bWaitKey;then
		echo -n "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME: lstrCaller=${lstrCaller}: press a key to exec..." >>/dev/stderr;read -n 1;
	fi
	
	if $SECbExecJustEcho;then
		if $bJustEcho;then
			echo "$lstrExec" #TODO this is to go to stdout, but... wouldnt be better to go to stderr?
			return 0
		fi
		if $bJustEchoNoQuotes;then
			echo "`SECFUNCparamsToEval --noquotes "${lastrParamsToExec[@]}"`" #TODO this is to go to stdout, but... wouldnt be better to go to stderr?
			return 0
		fi
	fi
	
	local lnSECFUNCexecReturnValue=0
	if $bShowElapsed;then local lnDelayInitTime=`SECFUNCdtFmt`;fi
  #eval "$lstrExec" $omitOutput;lnSECFUNCexecReturnValue=$?
  #"${lastrParamsToExec[@]}" $omitOutput;lnSECFUNCexecReturnValue=$?
  if [[ ! -f "${SEClstrLogFileSECFUNCexec-}" ]];then
  	lbDoLog=false
  fi
  
	export lstrFileRetVal=$(mktemp)
	function SECFUNCexec_runAtom(){ #help <BASHPID> (useless?)
		#trap >>/dev/stderr
		local lnBPid="$1"
		
		local lnPPid="$$"
		
		local lnPidChild
		local lnDelayInitTimeChild=`SECFUNCdtFmt`
		
		if $lbChild;then
			echo "cmd${SECcharTab}${lastrParamsToExec[@]}" >>"$lstrFileRetVal"
		fi
		
		if $lbDoLog;then
			echo "logfile${SECcharTab}$SEClstrLogFileSECFUNCexec" >>"$lstrFileRetVal"
			if $lbChild;then
			  echo "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME;lnPidDetached='$lnPidDetached';${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec"
				"${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec" 2>&1 &	lnPidChild=$!
			else
				echo "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME;${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec"
				"${lastrParamsToExec[@]}" &&: >>"$SEClstrLogFileSECFUNCexec" 2>&1;lnSECFUNCexecReturnValue=$?
			fi
		else
			if $lbOmitOutput;then
				if $lbChild;then # detach always require log, above
					"${lastrParamsToExec[@]}" >/dev/null 2>&1 &	lnPidChild=$!
				else
					"${lastrParamsToExec[@]}" &&: >/dev/null 2>&1;lnSECFUNCexecReturnValue=$?
				fi
			else
				if $lbChild;then # detach always require log, above
					"${lastrParamsToExec[@]}" &	lnPidChild=$!
				else
					"${lastrParamsToExec[@]}" &&: ;lnSECFUNCexecReturnValue=$?
				fi
			fi
		fi
		
#		if [[ -n "$lnPidChild" ]];then # detach is also child
		if $lbChild;then # detach is also child
			echo "pid${SECcharTab}$lnPidChild" >>"$lstrFileRetVal"
			
#			if ! $lbDetach;then	trap "kill -SIGABRT $lnPidChild" exit SIGHUP SIGINT SIGQUIT SIGILL SIGABRT SIGFPE SIGKILL SIGSEGV SIGPIPE SIGTERM; fi
			#trap >>/dev/stderr
			function SECFUNCexec_atomKill(){ #help trapping exit signals didnt work...
				# to test this: FUNCtst(){ trap 'echo oi' KILL;trap 'echo oi' TERM;sleep 1000; };SECFUNCexecA -ce --child FUNCtst;echo $SEClstrFuncExecLastChildRef
				while [[ -d "/proc/$1" ]];do sleep 1;done;
				if [[ -d "/proc/$lnPidChild" ]];then kill -SIGTERM $lnPidChild;fi;sleep 1;
				if [[ -d "/proc/$lnPidChild" ]];then kill -SIGKILL $lnPidChild;fi;sleep 1;
				if [[ -d "/proc/$lnPidChild" ]];then kill -SIGABRT $lnPidChild;fi;sleep 1;
			};SECFUNCexec_atomKill $lnPPid >/dev/null 2>&1 & #echo "lnPPid='$lnPPid'" >>/dev/stderr
			
			wait $lnPidChild&&:;lnRet=$?;echo "exit${SECcharTab}${lnRet}" >>"$lstrFileRetVal";
			echo "exitSignalInfo${SECcharTab}`SECFUNCerrCodeExplained ${lnRet}`" >>"$lstrFileRetVal";
		fi
				
#		local lnRet
#		if $lbDetach || ( $lbDoLog && $lbChild );then
#			echo "logfile${SECcharTab}$SEClstrLogFileSECFUNCexec" >>"$lstrFileRetVal"
#			"${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec" 2>&1 &	lnPidChild=$!
#		elif $lbChild;then
#			"${lastrParamsToExec[@]}" &	lnPidChild=$!
#		elif $lbDoLog;then
#		  echo "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME;${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec"
#		  "${lastrParamsToExec[@]}" &&: >>"$SEClstrLogFileSECFUNCexec" 2>&1;lnSECFUNCexecReturnValue=$?
#		else
#			"${lastrParamsToExec[@]}" &&: ; lnRet=$?
#		fi
		
#		if [[ -z "$lnRet" ]];then
#		if $lbChild;then # detach is also child
#			wait $lnPidChild;lnRet=$?;echo "ret${SECcharTab}${lnRet}" >>"$lstrFileRetVal";
#		fi
		
		local lnDelayEndTimeChild=`SECFUNCdtFmt`
		
#		trap >>/dev/stderr
#		echo "asdf`SECFUNCbcPrettyCalcA --help`" >>/dev/stderr
#		echo "elapsed${SECcharTab}`SECFUNCbcPrettyCalcA "$lnDelayEndTimeChild-$lnDelayInitTimeChild"`" >>/dev/stderr
#		echo ">>>SECDBG: $FUNCNAME using SECFUNCbcPrettyCalcA" >>/dev/stderr			
#		alias SECFUNCbcPrettyCalcA >>/dev/stderr
#		echo "AAA`alias SECFUNCbcPrettyCalcA`" >>/dev/stderr
#		echo "AAA`SECFUNCbcPrettyCalcA 1+2`" >>/dev/stderr
#		echo "elapsed${SECcharTab}`SECFUNCbcPrettyCalcA "$lnDelayEndTimeChild-$lnDelayInitTimeChild"`" >>/dev/stderr
#		set -x
		local lnElapsed="`SECFUNCbcPrettyCalcA "$lnDelayEndTimeChild-$lnDelayInitTimeChild"`"
		echo "elapsed${SECcharTab}${lnElapsed}" >>"$lstrFileRetVal";
#		set +x
		
		return 0
	}
	
	if $lbDetach;then # overrides simple child option
		SECFUNCexec_runAtom "$BASHPID" >>"$SEClstrLogFileSECFUNCexec" 2>&1 & disown #if this process ends, the child will continue running
	elif $lbChild;then
		if $lbDoLog;then
			SECFUNCexec_runAtom "$BASHPID" >>"$SEClstrLogFileSECFUNCexec" 2>&1 & disown #if this process ends, the child will continue running
		else
			#SECFUNCechoWarnA "without log, the function SECFUNCexec_runAtom error output will be discarded..." #TODO find a workaround...
#			SECFUNCexec_runAtom "$BASHPID" >/dev/null 2>&1 &
			SECFUNCexec_runAtom "$BASHPID" & # do not touch default outputs!
		fi
	else
		SECFUNCexec_runAtom "$BASHPID"
	fi
	
	if $lbChild;then # detach is also child
		sleep 0.1 # to help on avoiding the warn msg
		while lnPidChild="`egrep "^pid${SECcharTab}" "$lstrFileRetVal" |cut -f2`"; [[ -z "$lnPidChild" ]];do
			SECFUNCechoWarnA "waiting for pid of child cmd: ${lastrParamsToExec[@]}"
			sleep 0.1 #TODO is it safe not use this delay? such loop may clog cpu?
		done
#		echo -e "$lnPidChild\t$lstrFileRetVal" #so user can capture it
#		echo "$lstrFileRetVal" #so user can capture it
		SEClstrFuncExecLastChildRef="$lstrFileRetVal"
	else
		rm "$lstrFileRetVal"
	fi
	
#  if $lbDoLog || $lbDetach || $lbChild;then
#  	if $lbDetach || $lbChild;then
##			if $lbDetach;then #overrides simple child option
##				SECFUNCexec_runAtom >>"$SEClstrLogFileSECFUNCexec" 2>&1 & disown #if this process ends, the child will continue running
##			elif $lbChild;then
##				SECFUNCexec_runAtom &
##			else
##				SECFUNCexec_runAtom
##			fi
#			
##			if $lbDetach || $lbChild;then
##				sleep 0.1 # to help on avoiding the warn msg
##				while lnPidChild="`egrep "^pid${SECcharTab}" "$lstrFileRetVal" |cut -f2`"; [[ -z "$lnPidChild" ]];do
##					SECFUNCechoWarnA "waiting for pid of child cmd: ${lastrParamsToExec[@]}"
##					sleep 0.1 #TODO is it safe not use this delay? such loop may clog cpu?
##				done
##				echo -e "$lnPidChild\t$lstrFileRetVal" #so user can capture it
##			fi

##		  "${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec" 2>&1 & disown
##		  local lnPidDetached=$!
##		  echo "$lnPidDetached" #so user can capture it
#		  echo "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME;lnPidDetached='$lnPidDetached';${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec"
#		else
#		  echo "[`SECFUNCdtTimeForLogMessages`]$FUNCNAME;${lastrParamsToExec[@]}" >>"$SEClstrLogFileSECFUNCexec"
#		  "${lastrParamsToExec[@]}" &&: >>"$SEClstrLogFileSECFUNCexec" 2>&1;lnSECFUNCexecReturnValue=$?
#		  #"${lastrParamsToExec[@]}" 2>&1 |tee -a "$SEClstrLogFileSECFUNCexec";lnSECFUNCexecReturnValue=$? #tee prevent return value
#		fi
#  else
#  	if $lbOmitOutput;then
#		  #"${lastrParamsToExec[@]}" 2>/dev/null 1>/dev/null;lnSECFUNCexecReturnValue=$?
#		  "${lastrParamsToExec[@]}" &&: >/dev/null 2>&1;lnSECFUNCexecReturnValue=$?
#  	else
#  		"${lastrParamsToExec[@]}" &&: ; lnSECFUNCexecReturnValue=$?
#  	fi
#  fi
  
	if $bShowElapsed;then local lnDelayEndTime=`SECFUNCdtFmt`;fi
	
	if [[ -f "${SEClstrLogFileSECFUNCexec-}" ]];then
		if((lnLogQuota>0)) || ((${SEClnLogQuotaSECFUNCexec-0}>0));then
			if((lnLogQuota>0));then
				SEClnLogQuotaSECFUNCexec="$lnLogQuota"
			fi
			local lnLineCount=$(wc -l "$SEClstrLogFileSECFUNCexec" |cut -d" " -f 1)
			local lnLimitOfLines=$(( SEClnLogQuotaSECFUNCexec+(SEClnLogQuotaSECFUNCexec*5/100) ))
			if((lnLineCount>lnLimitOfLines));then #5% margin to avoid doing it all the time
				local lnDiffOfLinesCount=$((lnLineCount-SEClnLogQuotaSECFUNCexec))
				sed -i "1,${lnDiffOfLinesCount}d" "$SEClstrLogFileSECFUNCexec"
			fi
		fi
	fi
	
	if $lbStopLog;then
		SEClstrLogFileSECFUNCexec=""
	fi
	
	local lstrReturned=""
	#if((lnSECFUNCexecReturnValue>=0));then
	if $lbDetach;then
		lstrReturned="(DetachedChild): "
	else
		lstrReturned="RETURN=$lnSECFUNCexecReturnValue: "
	fi
  SECFUNCechoDbgA "lstrCaller=${lstrCaller}: ${lstrReturned}$lstrExec"
  
	if $bShowElapsed;then
		echo "[`SECFUNCdtTimeForLogMessages`]SECFUNCexec: lstrCaller=${lstrCaller}: ELAPSED=`SECFUNCbcPrettyCalcA "$lnDelayEndTime-$lnDelayInitTime"`s"
	fi
	
	if((lnSECFUNCexecReturnValue!=0));then
#		strSECFUNCtrapErrCustomMsg="ExecutedCmd: ${lastrParamsToExec[@]}; CallerInfo: $lstrCaller" # do NOT append if it is set, will stack with all other calls to this function...
		strSECFUNCtrapErrCustomMsg="Cmd: ${lstrExec}; CallerInfo: $lstrCaller" # do NOT append if it is set, will stack with all other calls to this function...
#		if [[ -z "${strSECFUNCtrapErrCustomMsg-}" ]];then
#			strSECFUNCtrapErrCustomMsg="ExecutedCmd: ${lastrParamsToExec[@]}"
#		else
#			strSECFUNCtrapErrCustomMsg="ExecutedCmd: ${lastrParamsToExec[@]} ($strSECFUNCtrapErrCustomMsg)"
#		fi
	fi
	
  return $lnSECFUNCexecReturnValue
}

function SECFUNCexecShowElapsed() { #help 
	SECFUNCexec --elapsed "$@"
}

function _SECFUNChelpExit() { #help #TODO this should help on exiting cleanly on ctrl+c, develop it?
    #echo "usage: options runCommand"
    
    # this sed only cleans lines that have extended options with "--" prefixed
    sedCleanHelpLine='s".*\"\(.*\)\".*#opt"\t\1\t"' #helpskip
    grep "#opt" $0 |grep -v "#helpskip" |sed "$sedCleanHelpLine" #helpskip is to skip this very line too!
    
    exit 0 #whatchout this will exit the script not only this function!!!
}

function SECFUNCppidListToGrep() { #help 
  # output ex.: "^[ |]*30973\|^[ |]*3861\|^[ |]*1 "

  #echo `SECFUNCppidList "|"` |sed 's"|"\\|"g'
  local ppidList=`SECFUNCppidList "$@" --separator ","`
  local separator='\\|'
  local grepMatch="^[ |]*" # to match none or more blank spaces at begin of line
  ppidList=`echo "$ppidList" |sed "s','$separator$grepMatch'g"`
  echo "$grepMatch$ppidList "
}

function SECFUNCbcPrettyCalc() { #help prefer using SECFUNCbcPrettyCalcA
	#TODO try to convert to wcalc?
	local bCmpMode=false
	local bCmpQuiet=false
	local lnScale=2
	local lbRound=true
	local lstrCaller=""
	local lbCalcLog=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCbcPrettyCalc_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return 0
		elif [[ "$1" == "--caller" ]];then #SECFUNCsingleLetterOptions_help is the name of the function calling this one
			shift
			lstrCaller="${1-}"
		elif [[ "$1" == "--cmp" ]];then #SECFUNCbcPrettyCalc_help output comparison result as "true" or "false"
			bCmpMode=true
		elif [[ "$1" == "--cmpquiet" ]];then #SECFUNCbcPrettyCalc_help return comparison as execution value for $? where 0=true 3=false (if it returns 1, means some error happened...)
			bCmpMode=true
			bCmpQuiet=true
		elif [[ "$1" == "--scale" ]];then #SECFUNCbcPrettyCalc_help scale is the decimal places shown to the right of the dot
			shift
			lnScale=$1
		elif [[ "$1" == "--trunc" ]];then #SECFUNCbcPrettyCalc_help default is to round the decimal value
			lbRound=false
		elif [[ "$1" == "--debug" ]];then #SECFUNCbcPrettyCalc_help shows calc debug info at stderr
			lbCalcLog=true
		else
			SECFUNCechoErrA "lstrCaller='$lstrCaller' invalid option '$1'"
			return 1
		fi
		shift
	done
	local lstrOutput="$1"
	local lstrOutputInitial="$lstrOutput"
	
	function SECFUNCbcPrettyCalc_bc() {
		local lstrCalcTmp="$1"
		if $lbCalcLog;then
			echo "SECFUNCbcPrettyCalc_bc:CalcLog: '$lstrCalcTmp'" >>/dev/stderr;
		fi
		bc <<< "$lstrCalcTmp"
	}
	
	if $lbRound;then
		# NOTICE: bc does not exit with error on syntax error, but an empty output means there is error.
#		lstrCalcTmp="scale=$((lnScale+1));$lstrOutput"
#		if $lbCalcLog;then echo "$lstrCalcTmp" >>/dev/stderr;fi
#		lstrOutput="`bc <<< "$lstrCalcTmp"`"
		lstrOutput="`SECFUNCbcPrettyCalc_bc \
			"scale=$((lnScale+1));$lstrOutput"`"
		if [[ -z "$lstrOutput" ]];then
		  SECFUNCechoErrA "lstrCaller='$lstrCaller' lstrOutput='$lstrOutput' syntax error at round(1) lstrOutputInitial='$lstrOutputInitial'"
		  return 1
		fi
		
		local lstrSignal="+"
		if [[ "${lstrOutput:0:1}" == "-" ]];then
			lstrSignal="-"
		fi
		lstrOutput="`SECFUNCbcPrettyCalc_bc \
			"scale=${lnScale};((${lstrOutput}*(10^${lnScale})) ${lstrSignal}0.5) / (10^${lnScale})"`"
		if [[ -z "$lstrOutput" ]];then
		  SECFUNCechoErrA "lstrCaller='$lstrCaller' lstrOutput='$lstrOutput' syntax error at round(2) lstrOutputInitial='$lstrOutputInitial'"
		  return 1
		fi
			
#		local lstrLcNumericBkp="$LC_NUMERIC"
#		export LC_NUMERIC="en_US.UTF-8" #force "." as decimal separator to make printf work...
#		lstrOutput="`printf "%0.${lnScale}f" "${lstrOutput}"`"
#		export LC_NUMERIC="$lstrLcNumericBkp"
#	else
#		lstrOutput="`SECFUNCbcPrettyCalc_bc "scale=$lnScale;($lstrOutput)/1.0;"`"
	fi
	
	local lstrZeroDotZeroes="0"
	if((lnScale>0));then
		lstrZeroDotZeroes="0.`eval "printf '0%.0s' {1..$lnScale}"`"
	fi
	
	# if it is less than 1.0 prints leading "0" like "0.123" instead of ".123"
#	lstrOutput="`SECFUNCbcPrettyCalc_bc \
#		"scale=$lnScale;x=($lstrOutput)/1; if(x==0) print \"$lstrZeroDotZeroes\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x"`"
#	echo "scale=$lnScale;x=($lstrOutput)/1; if(x==0) print \"$lstrZeroDotZeroes\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x" >>/dev/stderr
#	lstrOutput="`SECFUNCbcPrettyCalc_bc	"scale=$lnScale;x=($lstrOutput)/1; if(x==0) print \"$lstrZeroDotZeroes\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \"-0\",-x else print x"`"
	lstrOutput="`SECFUNCbcPrettyCalc_bc "scale=$lnScale;x=($lstrOutput)/1; if(x==0) print \"$lstrZeroDotZeroes\" else if(x>0 && x<1) print 0,x else if(x>-1 && x<0) print \\\"-\\\",0,-x else print x"`"
	if [[ -z "$lstrOutput" ]];then
	  SECFUNCechoErrA "lstrCaller='$lstrCaller' lstrOutput='$lstrOutput' syntax error at adding left zero lstrOutputInitial='$lstrOutputInitial'"
	  return 1
	fi
	
	
	if $bCmpMode;then
		if [[ "${lstrOutput:0:1}" == "1" ]];then
			if $bCmpQuiet;then
				return 0
			else
				echo -n "true"
			fi
		elif [[ "${lstrOutput:0:1}" == "0" ]];then
			if $bCmpQuiet;then
				return 3
			else
				echo -n "false"
			fi
		else
		  SECFUNCechoErrA "lstrCaller='$lstrCaller' invalid result for comparison lstrOutput='$lstrOutput'"
		  return 1
		fi
	else
		echo -n "$lstrOutput"
	fi
	
	return 0
}

function SECFUNCdrawLine() { #help [wordsAlignedDefaultMiddle] [lineFillChars]
	SECFUNCdbgFuncInA;
	local lstrAlign="middle"
	local lbStay=false
	local lbTrunc=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdrawLine_help show help
			SECFUNCshowHelp ${FUNCNAME}
			SECFUNCdbgFuncOutA;return
		elif [[ "$1" == "--left" || "$1" == "-0" ]];then #SECFUNCdrawLine_help align words at left
			lstrAlign="left"
		elif [[ "$1" == "--middle" || "$1" == "-1" ]];then #SECFUNCdrawLine_help align words at middle
			lstrAlign="middle"
		elif [[ "$1" == "--right" || "$1" == "-2" ]];then #SECFUNCdrawLine_help align words at right
			lstrAlign="right"
		elif [[ "$1" == "--stay" ]];then #SECFUNCdrawLine_help no newline at end, and appends \r
			lbStay=true
		elif [[ "$1" == "--notrunc" ]];then #SECFUNCdrawLine_help do not trunc line to fit columns
			lbTrunc=false
		else
			SECFUNCechoErrA "invalid option '$1'"
			SECFUNCdbgFuncOutA;return 1
		fi
		shift
	done
	
	local lstrWords="${1-}";
	shift
	local lstrFill="${1-}"

	local sedRemoveFormatChars='s"[\]E[[][[:digit:]]*m""g'
	local sedRemoveFormatCharsBin='s"'`printf '\033'`'[[][[:digit:]]*m""g'
	local lstrWordsNoFmt="`echo "$lstrWords" |sed -r -e "$sedRemoveFormatChars" -e "$sedRemoveFormatCharsBin"`"
	SECFUNCechoDbgA "lstrWordsNoFmt='$lstrWordsNoFmt' size ${#lstrWordsNoFmt}"
	local lnWordsFmtDiffSize=$((${#lstrWords}-${#lstrWordsNoFmt}))
	
	if [[ -z "$lstrFill" ]];then
		lstrFill="="
	fi
	
	#local lnTerminalWidth="`tput cols 2>/dev/null`" #tput fails if 2 is redirected :P
	local lnTerminalWidth="`stty size 2>/dev/null |cut -d" " -f2`"
	#local lnTerminalWidth="`stty -a 2>/dev/null |grep "columns [[:digit:]]*" -o |cut -d" " -f2`"
	if [[ -z "$lnTerminalWidth" ]];then
#		if [[ "${SECbWarnEnvValNotSetTERM-}" != true ]];then
#			SECFUNCechoErrA "environment variable 'TERM' is not set causing 'tput' to fail, using default of 80 cols instead" #could be a warning, but with err it will be logged!
#		fi
#		SECbWarnEnvValNotSetTERM=true
		lnTerminalWidth=80 #uses a default generic value...
	fi
	
	local lnTotalFillChars=$((lnTerminalWidth-${#lstrWordsNoFmt}))
	local lnFillCharsLeft=$((lnTotalFillChars/2))
	local lnFillCharsRight=$((lnTotalFillChars/2))

	SECFUNCechoDbgA "#lstrWordsNoFmt=${#lstrWordsNoFmt}, lnTotalFillChars=$lnTotalFillChars, lnFillCharsLeft=$lnFillCharsLeft, lnFillCharsRight=$lnFillCharsRight, lnWordsFmtDiffSize=$lnWordsFmtDiffSize"
	
	# if odd width, add one char
	if(( (lnTotalFillChars%2) == 1 ));then 
		((lnFillCharsRight++))
	fi
	
	# at least one complete fill must happen at beggining and ending, what may cause more than one line to be printed
	if((lnFillCharsLeft<${#lstrFill}));then
		lnFillCharsLeft=${#lstrFill}
	fi
	if((lnFillCharsRight<${#lstrFill}));then
		lnFillCharsRight=${#lstrFill}
	fi
	
	local lstrFill=`eval "printf \"%.0s${lstrFill}\" {1..${lnTerminalWidth}}"`
	
	case $lstrAlign in
		left)   local lstrWordsLeft=$lstrWords;;
		middle) local lstrWordsMiddle=$lstrWords;;
		right)  local lstrWordsRight=$lstrWords;;
	esac
	
	local lstrOutput="${lstrWordsLeft-}${lstrFill:0:lnFillCharsLeft}${lstrWordsMiddle-}${lstrFill:${#lstrFill}-lnFillCharsRight}${lstrWordsRight-}"
	
	local loptNewLine=""
	local loptCarryageReturn=""
	if $lbStay;then
		loptNewLine="-n"
		loptCarryageReturn="\r"
	fi
	
	#trunc
	if $lbTrunc;then
		if(( (${#lstrOutput}-lnWordsFmtDiffSize) > lnTerminalWidth ));then
			# +lnWordsFmtDiffSize as the formatting characters will be interpreted and removed on the output so it will fit!
			lstrOutput="${lstrOutput:0:$((lnTerminalWidth+lnWordsFmtDiffSize))}" 
		fi
	fi
	
	SECFUNCechoDbgA "#lstrWordsNoFmt=${#lstrWordsNoFmt}, lnTotalFillChars=$lnTotalFillChars, lnFillCharsLeft=$lnFillCharsLeft, lnFillCharsRight=$lnFillCharsRight"
	
#	echo "$lstrOutput$loptCarryageReturn" >>/dev/stderr
	echo -e $loptNewLine "$lstrOutput$loptCarryageReturn"
	
	SECFUNCdbgFuncOutA;
}

function SECFUNCfixCorruptFile() { #help usually after a blackout?
	local lstrDataFile="${1-}"
	
	if [[ ! -f "$lstrDataFile" ]];then
		SECFUNCechoErrA "invalid file lstrDataFile='$lstrDataFile'"
		return 1
	fi
	
	# deal only with real files and not symlinks..
	lstrDataFile="`readlink -f "${lstrDataFile}"`"
	
	local lstrMsgCriticalCorruptDataFile="\E[0m\E[93m\E[41m\E[5m Critical: Corrupt data-file! \E[0m"
	echo -e "$lstrMsgCriticalCorruptDataFile backuping..." >>/dev/stderr
	cp -v "$lstrDataFile" "${lstrDataFile}.`SECFUNCdtFmt --filename`" >>/dev/stderr
	echo " >>---[Possible lines with problem]--->" >>/dev/stderr
	cat "$lstrDataFile" |cat -n |sed "/^[[:blank:]]*[[:digit:]]*[[:blank:]]*[[:alnum:]_]*=.*/d" >>/dev/stderr
	if [[ "`read -n 1 -p "\`echo -e "$lstrMsgCriticalCorruptDataFile"\` This can happen after a blackout. It is advised to manually fix the data file. Removing it may cause script malfunction. Remove it anyway (y/...)? (any other key to manually fix it)" strResp;echo "$strResp"`" == "y" ]];then
		echo >>/dev/stderr
		rm -v "$lstrDataFile" >>/dev/stderr
		
		# recreate the datafile so symlinks dont get broken avoiding creating new files and disconnecting sec pids...
		echo -n "" >"$lstrDataFile"
		while true;do
			if [[ "`read -n 1 -p "\`echo -e "$lstrMsgCriticalCorruptDataFile"\` As you removed the file, it is adviseable to stop the script now with 'Ctrl+c', or you wish to continue running it at your own risk (y)?" strResp;echo "$strResp"`" == "y" ]];then
				echo >>/dev/stderr
				break;
			fi
			echo >>/dev/stderr
		done
	else
		echo >>/dev/stderr
		while [[ "`read -n 1 -p "\`echo -e "$lstrMsgCriticalCorruptDataFile"\` (waiting manual fix) ready to continue (y/...)?" strResp;echo "$strResp"`" != "y" ]];do
			echo >>/dev/stderr
		done
		echo >>/dev/stderr
	fi
}

function SECFUNCcleanEnvironment() { #help clean environment from everything related to ScriptEchoColor
	local lbJustList=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]]; then #SECFUNCcleanEnvironment_help
			SECFUNCshowHelp "$FUNCNAME"
			return
		elif [[ "${1-}" == "--list" ]]; then #SECFUNCcleanEnvironment_help just list all commands that will be run without cleaning
			lbJustList=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	#TODO This should instead have a list of what was set and clean based on that. User may create something beggining with SEC
	local lstrCmdUnset="`set |egrep "^_?SEC" |sed -r 's"^([[:alnum:]_]*)[ =].*"unset \1"'`"
	local lstrCmdUnalias="`alias |egrep "^alias _?SEC" |sed -r 's"^alias (_?SEC[[:alnum:]_]*)=.*"\1"' |tr "\n" " "`"
	if [[ -n "$lstrCmdUnalias" ]];then
		lstrCmdUnalias="unalias $lstrCmdUnalias"
	fi
	if $lbJustList;then
		(echo "$lstrCmdUnset" && echo "$lstrCmdUnalias") |sort
	else
		$lstrCmdUnset
		if [[ -n "$lstrCmdUnalias" ]];then
			$lstrCmdUnalias
		fi
	fi
}

function SECFUNCsplitInWords() { #help
	SECFUNCseparateInWords "$@"
}
function SECFUNCseparateInWords() { #help <string> ex.: 'abcDefHgi_jkl' becomes 'abc def hgi jkl', good to use with variables and options, also to be spoken
	lbShowType=true
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "${1-}" == "--help" ]]; then #SECFUNCseparateInWords_help
			SECFUNCshowHelp "$FUNCNAME"
			return
		elif [[ "${1-}" == "--notype" ]]; then #SECFUNCseparateInWords_help remove the beggining word mainly for variables
			lbShowType=false
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	lsedLowerFirstChar="s'^[A-Z]'\L&'";
	lsedSeparateInWords="s'([a-z]*)([A-Z])'\1 \2'g";
	local lstrOutput="`echo "$1" |sed -r -e "$lsedLowerFirstChar" -e "$lsedSeparateInWords" |tr "[:upper:]_" "[:lower:] "`"
	if $lbShowType;then
		echo "$lstrOutput"
	else
		echo "$lstrOutput" |cut -d" " -f2-
	fi
}

function SECFUNCdelay() { #help The first parameter can optionally be a string identifying a custom delay:\n\tSECFUNCdelay [delayId] --init;\n\tex.:\n\tSECFUNCdelay main --init;\n\tSECFUNCdelay test --init;\n\tSECFUNCdelay $FUNCNAME --init;
	declare -g -A _dtSECFUNCdelayArray
	
	local bIndexSetByUser=false
	local indexId="$FUNCNAME"
	# if is not an "--" option, it is the indexId
	if [[ -n "${1-}" ]] && [[ "${1:0:2}" != "--" ]];then
		bIndexSetByUser=true
		indexId="`SECFUNCfixIdA "$1"`"
		shift
	fi
	
	function SECFUNCdelay_ValidateIndexIdForOption() { # validates if indexId has been set in the environment to use all other options other than --init
		local lbSimpleCheck=false
		if [[ "${1-}" == "--simplecheck" ]];then
			lbSimpleCheck=true
			shift
		fi
		if [[ -z "${_dtSECFUNCdelayArray[$indexId]-}" ]];then
			# programmer must have coded it somewhere to make that code clear
			#echo "--init [indexId=$indexId] needed before calling $1" >&2
			if ! $lbSimpleCheck;then
				SECFUNCechoErrA "the --init option is required before using option '$1' with [indexId=$indexId]"
				_SECFUNCcriticalForceExit
			fi
			return 1
		fi
	}
	
	local lbInit=false
	local lbGet=false
	local lbGetSec=false
	local	lbGetPretty=false
#	local lbNow=false
	local lbCheckOrInit=false
	local l_b1stIsTrueOnCheckOrInit=false
	local lbGetPrettyFull=false
	local lbShowId=false
	local lnCheckDelayAt=0
	#TODO create an automatic init option that works with ex --getpretty, so a function can be called by a loop and still retain control over its initialization inside of it.
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
		if [[ "$1" == "--help" ]];then #SECFUNCdelay_help --help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--1stistrue" ]];then #SECFUNCdelay_help to use with --checkorinit that makes 1st run return true
			l_b1stIsTrueOnCheckOrInit=true
		elif [[ "$1" == "--checkorinit" ]];then #SECFUNCdelay_help <lnCheckDelayAt> will check if delay (in seconds, can be float) is above or equal specified at lnCheckDelayAt;\n\t\twill then return true and re-init the delay variable;\n\t\totherwise return false
			shift
			lnCheckDelayAt=${1-}
			
			lbCheckOrInit=true
		elif [[ "$1" == "--checkorinit1" ]];then #SECFUNCdelay_help <lnCheckDelayAt> like --1stistrue  --checkorinit 
			shift
			lnCheckDelayAt=${1-}
			
			lbCheckOrInit=true
			l_b1stIsTrueOnCheckOrInit=true
		elif [[ "$1" == "--init" ]];then #SECFUNCdelay_help set temp date storage to now
			lbInit=true
		elif [[ "$1" == "--get" ]];then #SECFUNCdelay_help get delay from init (is the default if no option parameters are set)
			if ! SECFUNCdelay_ValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
		elif [[ "$1" == "--getsec" ]];then #SECFUNCdelay_help get (only seconds without nanoseconds) from init
			if ! SECFUNCdelay_ValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
			lbGetSec=true
		elif [[ "$1" == "--getpretty" ]];then #SECFUNCdelay_help pretty format
			if ! SECFUNCdelay_ValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
			lbGetPretty=true
		elif [[ "$1" == "--getprettyfull" ]];then #SECFUNCdelay_help pretty format but does not skip left zeroes
			if ! SECFUNCdelay_ValidateIndexIdForOption "$1";then return 1;fi
			lbGet=true
			lbGetPrettyFull=true
		elif [[ "$1" == "--showid" ]];then #SECFUNCdelay_help outputs the current delay id if used with --getpretty or --getprettyfull
			lbShowId=true
		elif [[ "$1" == "--now" ]];then #deprecated
#			lbNow=true
			SECFUNCechoErrA "'$1' has deprecated, use 'SECFUNCdtFmt' instead"
			_SECFUNCcriticalForceExit
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
		fi
		shift
	done
	
	#if $lbCheckOrInit && ( $lbInit || $lbGet || $lbGetSec || $lbGetPretty || $lbNow );then
	if $lbCheckOrInit;then
#		if $lbInit || $lbGet || $lbGetSec || $lbGetPretty || $lbNow;then
		if $lbInit || $lbGet || $lbGetSec || $lbGetPretty || $lbGetPrettyFull || $lbShowId;then
			SECFUNCechoErrA "--checkorinit must be used without other options"
			SECFUNCdelay --help |grep "\-\-checkorinit"
			_SECFUNCcriticalForceExit
		fi
	else
		if ! $lbInit;then
			if ! SECFUNCdelay_ValidateIndexIdForOption "";then return 1;fi
		fi
	fi
	
	function SECFUNCdelay_init(){
		_dtSECFUNCdelayArray[$indexId]="`SECFUNCdtFmt`"
	}
	
	function SECFUNCdelay_get(){
		local lfNow="`SECFUNCdtFmt`"
#		echo ">>>SECDBG: $FUNCNAME using SECFUNCbcPrettyCalcA" >>/dev/stderr			
		local lfDelayToOutput="`SECFUNCbcPrettyCalcA --scale 9 "${lfNow} - ${_dtSECFUNCdelayArray[$indexId]}"`"
		local lstrShowId=""
		if $lbShowId;then
			lstrShowId="$indexId, "
		fi
		if $lbGetSec;then
			echo "$lfDelayToOutput" |sed -r 's"^([[:digit:]]*)[.][[:digit:]]*$"\1"' #seconds only
		elif $lbGetPretty;then
			#local lfDelay="`SECFUNCdelay $indexId --get`"
			#SECFUNCtimePretty "$lfDelay"
			#SECFUNCtimePretty "`SECFUNCbcPrettyCalcA "$lfDelay+$SECnFixDate"`"
			#SECFUNCdtFmt --delay --nodate --pretty "$lfDelay"
			#echo "lfDelayToOutput='$lfDelayToOutput'" >>/dev/stderr
			#SECFUNCdtFmt --delay --nodate --pretty "$lfDelayToOutput"
			echo -n "$lstrShowId";SECFUNCdtFmt --delay --nozero --pretty "$lfDelayToOutput"
		elif $lbGetPrettyFull;then
			echo -n "$lstrShowId";SECFUNCdtFmt --delay --pretty "$lfDelayToOutput"
		else
			echo "$lfDelayToOutput"
		fi
	}
	
	if $lbInit;then
		SECFUNCdelay_init
	elif $lbGet;then
		SECFUNCdelay_get
#	elif $lbNow;then
#		SECFUNCdtFmt
  elif $lbCheckOrInit;then
#		if [[ -z "$lnCheckDelayAt" ]] || [[ -n "`echo "$lnCheckDelayAt" |tr -d '[:digit:].'`" ]];then
#		if [[ -n "`echo "$lnCheckDelayAt" |tr -d '[:digit:].'`" ]];then
  	if ! SECFUNCisNumber -n "$lnCheckDelayAt";then
			SECFUNCechoErrA "required valid <delayLimit>, can be float"
			SECFUNCdelay --help |grep "\-\-checkorinit"
			_SECFUNCcriticalForceExit
		fi
		
		if ! SECFUNCdelay_ValidateIndexIdForOption --simplecheck "--checkorinit";then
			SECFUNCdelay_init
			if $l_b1stIsTrueOnCheckOrInit;then
				return 0
			fi
		fi
		
		local delay=`SECFUNCdelay_get`
#		echo ">>>SECDBG: $FUNCNAME using SECFUNCbcPrettyCalcA" >>/dev/stderr			
		if SECFUNCbcPrettyCalcA --cmpquiet "$delay>=$lnCheckDelayAt";then
			SECFUNCdelay_init
			return 0
		else
			return 1
		fi
	else
		SECFUNCdelay_get #default
	fi
}

###############################################################################
# LAST THINGS CODE
if [[ `basename "$0"` == "funcBase.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowHelp --onlyvars
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibBase=$$

