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

# environment must have been already initialized on parent
function SECFUNCfastInitCheck() {
	if ${SECinstallPath+false};then
		echo "SECERROR: the 'Fast' lib can only work after at least the 'Core' lib has been loaded already..." >>/dev/stderr
		exit 1 # this must be `exit` and not `return` as this is critical and script MUST exit
	fi
}
SECFUNCfastInitCheck

# ALIASES

#alias SECFUNCsingleLetterOptionsA='SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" '
# if echo "$1" |grep -q "[^-]?\-[[:alpha:]][[:alpha:]]";then
alias SECFUNCsingleLetterOptionsA='
 if echo "$1" |grep -q "^-[[:alpha:]]*$";then
   set -- `SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" -- "$1"` "${@:2}";
 fi'

: ${SEC_ShortFuncsAliases:=true}
if [[ "$SEC_ShortFuncsAliases" != "false" ]]; then
	export SEC_ShortFuncsAliases=true
fi
: ${SECfuncPrefix:=sec} #this prefix can be setup by the user
export SECfuncPrefix #help function aliases for easy coding
if $SEC_ShortFuncsAliases; then 
	#TODO validate if such aliases or executables exist before setting it here and warn about it
	#TODO for all functions, create these aliases automatically
	alias "$SECfuncPrefix"delay='SECFUNCdelay';
fi

declare -Ax SECastrDebugFunctionPerFile #must be here as arrays arent exported by bash
SECastrDebugFunctionPerFile[SECstrBashSourceIdDefault]="undefined" #TODO I couldnt find a way to show the script filename yet...
export _SECmsgCallerPrefix='`SECFUNCbashSourceFiles`.${FUNCNAME-}@${SECastrDebugFunctionPerFile[${FUNCNAME-SECstrBashSourceIdDefault}]-undefined}(),L$LINENO;p$$;bp$BASHPID;bss$BASH_SUBSHELL;pp$PPID' #TODO see "undefined", because I wasnt able yet to show something properly to the script filename there...

alias SECFUNCechoErrA="SECbBashSourceFilesForceShowOnce=true;SECFUNCechoErr --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoDbgA="if ! \$SEC_DEBUGX;then set +x;fi;SECFUNCechoDbg --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoWarnA="SECFUNCechoWarn --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoBugtrackA="SECFUNCechoBugtrack --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA --funcin -- "$@" '
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA --funcout '

alias SECFUNCexecA="SECFUNCexec --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCvalidateIdA="SECFUNCvalidateId --caller \"\${FUNCNAME-}\" "
alias SECFUNCfixIdA="SECFUNCfixId --caller \"\${FUNCNAME-}\" "

alias SECFUNCreturnOnFailA='if(($?!=0));then return 1;fi'
alias SECFUNCreturnOnFailDbgA='if(($?!=0));then SECFUNCdbgFuncOutA;return 1;fi'

# SECFUNCtrapErr defined at Core 
trap 'if ! SECFUNCtrapErr "${FUNCNAME-}" "${LINENO-}" "${BASH_COMMAND-}" "${BASH_SOURCE[@]-}";then echo "SECERROR:Exiting..." >>/dev/stderr;exit 1;fi' ERR

function SECFUNCarraysRestore() { #help restore all exported arrays
	if ${SECbHasExportedArrays+false};then #to speedup execution where no array has been exported
		return
	fi
	unset SECbHasExportedArrays
	
	# declare associative arrays to make it work properly
	eval "${SECcmdExportedAssociativeArrays-}"
	unset SECcmdExportedAssociativeArrays
	
	# restore the exported arrays
	eval "`declare |sed -r "s%^${SECstrExportedArrayPrefix}([[:alnum:]_]*)='(.*)'$%\1=\2;%;tfound;d;:found"`"
	
	# remove the temporary variables representing exported arrays
	eval "`declare |sed -r "s%^(${SECstrExportedArrayPrefix}[[:alnum:]_]*)='(.*)'$%unset \1;%;tfound;d;:found"`"
}

SECFUNCarraysRestore #this is useful when SECFUNCarraysExport is used on parent shell

# LAST THINGS CODE
if [[ "$0" == */funcFast.sh ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

export SECnPidInitLibFast=$$

