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

# THIS FILE must contain only fastest and essential things like aliases and exported arrays restoring

if((`id -u`==0));then echo -e "\E[0m\E[33m\E[41m\E[1m\E[5m ScriptEchoColor is still beta, do not use as root... \E[0m" >>/dev/stderr;exit 1;fi

shopt -s expand_aliases
set -u #so when unset variables are expanded, gives fatal error

alias SECFUNCreturnOnFailA='if(($?!=0));then return 1;fi'
alias SECFUNCreturnOnFailDbgA='if(($?!=0));then SECFUNCdbgFuncOutA;return 1;fi'
alias SECFUNCechoErrA="SECFUNCechoErr --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoDbgA="set +x;SECFUNCechoDbg --callerfunc \"\${FUNCNAME-}\" --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoWarnA="SECFUNCechoWarn --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCechoBugtrackA="SECFUNCechoBugtrack --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCsingleLetterOptionsA='
 if echo "$1" |grep -q "^-[[:alpha:]]*$";then
   set -- `SECFUNCsingleLetterOptions --caller "${FUNCNAME-}" "$1"` "${@:2}";
 fi'
alias SECFUNCexecA="SECFUNCexec --caller \"$_SECmsgCallerPrefix\" "
alias SECFUNCvalidateIdA="SECFUNCvalidateId --caller \"\${FUNCNAME-}\" "
alias SECFUNCfixIdA="SECFUNCfixId --caller \"\${FUNCNAME-}\" "
alias SECFUNCdbgFuncInA='SECFUNCechoDbgA --funcin -- "$@" '
alias SECFUNCdbgFuncOutA='SECFUNCechoDbgA --funcout '
alias SECexitA='SECFUNCdbgFuncOutA;exit '
alias SECreturnA='SECFUNCdbgFuncOutA;return '

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

export SECstrExportedArrayPrefix="SEC_EXPORTED_ARRAY_"
function SECFUNCarraysRestore() { #restore all exported arrays
	# declare associative arrays to make it work properly
	eval "${SECcmdExportedAssociativeArrays-}"
	unset SECcmdExportedAssociativeArrays
	
	# restore the exported arrays
	eval "`declare |sed -r "s%^${SECstrExportedArrayPrefix}([[:alnum:]_]*)='(.*)'$%\1=\2;%;tfound;d;:found"`"
	
	# remove the temporary variables representing exported arrays
	eval "`declare |sed -r "s%^(${SECstrExportedArrayPrefix}[[:alnum:]_]*)='(.*)'$%unset \1;%;tfound;d;:found"`"
}

SECFUNCarraysRestore #this is useful when SECFUNCarraysExport is used on parent shell

export SECnPidInitLibCore=$$

