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

# THIS FILE SHOULD CONTAIN ONLY THINGS THAT CANNOT BE EXPORTED!!!

# BEFORE EVERYTHING: UNIQUE CHECK, SPECIAL CODE
if((`id -u`==0));then echo -e "\E[0m\E[33m\E[41m\E[1m\E[5m ScriptEchoColor is still beta, do not use as root... \E[0m" >>/dev/stderr;exit 1;fi

shopt -s expand_aliases
set -u #so when unset variables are expanded, gives fatal error
set -E #ERR trap is inherited by shell functions
set -T #DEBUG trap is inherited by shell functions

# environment must have been already initialized on parent
function SECFUNCfastInitCheck() { #help
	if ${SECinstallPath+false};then
		echo "SECERROR: the 'Fast' lib can only work after at least the 'Core' lib has been loaded already..." >>/dev/stderr
		exit 1 # this must be `exit` and not `return` as this is critical and script MUST exit
	fi
}
SECFUNCfastInitCheck

##############################################################################
#################################### ALIASES #################################
##############################################################################
### all aliases from all libs should be defined here, so this fast lib     ###
### will grant all of them are working properly!                           ###
##############################################################################

#alias SECFUNCsingleLetterOptionsA='SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" '
# if echo "$1" |grep -q "[^-]?\-[[:alpha:]][[:alpha:]]";then
alias SECFUNCsingleLetterOptionsA='
 if echo "$1" |grep -q "^-[[:alpha:]]*$";then
   set -- `SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" -- "$1"` "${@:2}";
 fi'

: ${SEC_ShortFuncsAliases:=true}
export SEC_ShortFuncsAliases #help enable short function aliases
if [[ "$SEC_ShortFuncsAliases" != "false" ]]; then
	SEC_ShortFuncsAliases=true
fi

: ${SECfuncPrefix:=sec}
export SECfuncPrefix #help this can be modified to allow remapping custom function aliases for this lib
if $SEC_ShortFuncsAliases; then 
	#TODO validate if such aliases or executables exist before setting it here and warn about it
	#TODO for all functions, create these aliases automatically
	alias "$SECfuncPrefix"delay='SECFUNCdelay';
fi

declare -Ax SECastrDebugFunctionPerFile #must be here as arrays arent exported by bash
SECastrDebugFunctionPerFile[SECstrBashSourceIdDefault]="undefined" # SECstrBashSourceIdDefault is NOT a vaiable, it is an array ID. #TODO I couldnt find a way to show the script filename yet...
#this is slow -> export _SECmsgCallerPrefix='`SECFUNCbashSourceFiles`.${FUNCNAME-}@${SECastrDebugFunctionPerFile[${FUNCNAME-SECstrBashSourceIdDefault}]-undefined}(),L$LINENO;p$$[$(ps --no-headers -o comm -p $$)];bp$BASHPID;bss$BASH_SUBSHELL;pp$PPID[$(ps --no-headers -o comm -p $PPID)]' #TODO see "undefined", because I wasnt able yet to show something properly to the script filename there...
export _SECmsgCallerPrefix='`SECFUNCbashSourceFiles`.${FUNCNAME-}@${SECastrDebugFunctionPerFile[${FUNCNAME-SECstrBashSourceIdDefault}]-undefined}(),L$LINENO;p$$;bp$BASHPID;bss$BASH_SUBSHELL;pp$PPID' #TODO see "undefined", because I wasnt able yet to show something properly to the script filename there...

alias SECFUNCechoErrA="SECbBashSourceFilesForceShowOnce=true;SECFUNCechoErr --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoDbgA="if ! \$SEC_DEBUGX;then set +x;fi;SECFUNCechoDbg --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" " # this alias to the function can let it receive new parameters...
alias SECFUNCechoWarnA="SECFUNCechoWarn --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoBugtrackA="SECFUNCechoBugtrack --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA --funcin -- "$@" '
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA --funcout '

alias SECFUNCexecA="SECFUNCexec --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "

#TODO DO NOT USE _SECmsgCallerPrefix on these as they require more performance?
alias SECFUNCvalidateIdA="SECFUNCvalidateId --caller \"\${FUNCNAME-}\" "
alias SECFUNCfixIdA="SECFUNCfixId --caller \"\${FUNCNAME-}\" "
alias SECFUNCprcA="SECFUNCprc --calledWithAlias --caller \"\${FUNCNAME-}\" --callerOfCallerFunc \"\${SEClstrFuncCaller-}\""
alias SECFUNCbcPrettyCalcA="SECFUNCbcPrettyCalc --caller \"\${FUNCNAME-}\" "

alias SECFUNCreturnOnFailA='if(($?!=0));then return 1;fi'
alias SECFUNCreturnOnFailDbgA='if(($?!=0));then SECFUNCdbgFuncOutA;return 1;fi'

# SECFUNCtrapErr defined at Core 
#trap 'SECnRetTrap=$?;if ! SECFUNCtrapErr "${FUNCNAME-}" "${LINENO-}" "${BASH_COMMAND-}" "${BASH_SOURCE[@]-}";then echo "SECERROR:Exiting..." >>/dev/stderr;exit 1;fi' ERR
trap 'if ! SECFUNCtrapErr "$?" "${FUNCNAME-}" "${LINENO-}" "${BASH_COMMAND-}" "${BASH_SOURCE[@]-}";then echo "SECERROR(trap):Exiting..." >>/dev/stderr;exit 1;fi' ERR

function _SECFUNCcheckIfIsArrayAndInit() { #help only simple array, not associative -A arrays...
	#echo ">>>>>>>>>>>>>>>>${1}" >>/dev/stderr
	if ${!1+false};then 
		declare -a -x -g ${1}='()';
	else
		local lstrCheck="`declare -p "$1" 2>/dev/null`";
		if [[ "${lstrCheck:0:10}" != 'declare -a' ]];then
			echo "$1='${!1-}' MUST BE DECLARED AS AN ARRAY..." >>/dev/stderr
			_SECFUNCcriticalForceExit
		fi
	fi
}

_SECFUNCcheckIfIsArrayAndInit SECastrBashDebugFunctionIds # If any item of the array is "+all", all functions will match.
_SECFUNCcheckIfIsArrayAndInit SECastrFunctionStack
_SECFUNCcheckIfIsArrayAndInit SECastrBashSourceFilesPrevious

: ${SECbFuncArraysRestoreVerbose:=false}
export SECbFuncArraysRestoreVerbose
function SECFUNCarraysRestore() { #help restore all exported arrays
	if ${SECbHasExportedArrays+false};then #to speedup execution where no array has been exported
		return
	fi
	unset SECbHasExportedArrays
	
	# declare associative arrays to make it work properly
	eval "${SECcmdExportedAssociativeArrays-}"
	unset SECcmdExportedAssociativeArrays
	
	# restore the exported arrays
	# first, set the variable value WITHOUT export. Exporting with value will fail for some associative arrays (namely: SECastrDebugFunctionPerFile)
	local lstrEvalRest="`declare |sed -r "s%^${SECstrExportedArrayPrefix}([[:alnum:]_]*)='(.*)'$%\1=\2;%;tfound;d;:found"`"
	if $SECbFuncArraysRestoreVerbose;then
		echo "SECINFO: $FUNCNAME" >>/dev/stderr
		echo "$lstrEvalRest" >>/dev/stderr
	fi
	eval "$lstrEvalRest"
	# second, do re-export in a simple way, the env var id alone (without the value)
	eval "`declare |sed -r "s%^${SECstrExportedArrayPrefix}([[:alnum:]_]*)='(.*)'$%export \1;%;tfound;d;:found"`"
	
	# remove the temporary variables representing exported arrays
	eval "`declare |sed -r "s%^(${SECstrExportedArrayPrefix}[[:alnum:]_]*)='(.*)'$%unset \1;%;tfound;d;:found"`"
}

#function SECFUNCversionCheck() {
#	if [[ ! -d "$SECstrUserHomeConfigPath/" ]];then
#		mkdir -vp "$SECstrUserHomeConfigPath/"
#	fi
#}

SECFUNCarraysRestore #this is useful when SECFUNCarraysExport is used on parent shell
#echo "$SECbFuncArraysRestoreVerbose.$LINENO" >>/dev/stderr

###############################################################################
# LAST THINGS CODE
if [[ "$0" == */funcFast.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowHelp --onlyvars
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

#export SECnVersion="1414348722" #SECFUNCdtFmt --nonano

export SECnPidInitLibFast=$$

