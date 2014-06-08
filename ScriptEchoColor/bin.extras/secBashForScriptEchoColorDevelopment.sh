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

#DO NOT USE secinit HERE!

export SECbSecInit=true
export SECbFullDebug=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	if [[ "$1" == "--help" ]];then #help --help show this help
		echo "TODO"
		return
	elif [[ "$1" == "--noinit" ]];then #help dont: eval `secinit`
		SECbSecInit=false
	elif [[ "$1" == "--dbg" ]];then #help 
		SECbFullDebug=true
	else
		echo "invalid option '$1'" >>/dev/stderr
		exit 1
	fi
	shift
done

if $SECbFullDebug;then
	export SEC_DEBUG=true
	export SEC_WARN=true
	export SEC_BUGTRACK=true
	#set -x
fi

## custom first command by user like found at SECFUNCparamsToEval
#export SECcmdDevTmp=""
#for strParam in "$@";do
#	SECcmdDevTmp+="'$strParam' "
#done

# custom first command by user
export SECcmdDevTmp="`eval \`secinit --base\` >>/dev/stderr; SECFUNCparamsToEval "$@"`"

function SECFUNCaddToRcFile() {
	source "$HOME/.bashrc";
	
	local lstrSECpath="$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor"
	
	source "$lstrSECpath/lib/ScriptEchoColor/extras/secFuncPromptCommand.sh"
	function SECFUNCcustomUserText(){
		# Result of: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
		local lstrBanner="\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"
		echo "$lstrBanner"
		#echo -e \"$lstrBanner\"
	}
	#export PROMPT_COMMAND="${PROMPT_COMMAND-}${PROMPT_COMMAND+;} echo -e \"$lstrBanner\"; ";
	#export PS1="$(echo -e "\E[0m\E[34m\E[106mDev\E[0m")$PS1";\
	echo " PROMPT_COMMAND='$PROMPT_COMMAND'" >>/dev/stderr
	
	export PATH="$lstrSECpath/bin:$lstrSECpath/bin.extras:$PATH";
	echo " PATH='$PATH'" >>/dev/stderr
	
	# must be after PATH setup
	if $SECbSecInit;then
		echo ' eval `secinit`' >>/dev/stderr
		eval `secinit`;
	fi
	
	# must come after secinit
	echo " Unbound vars allowed at terminal.";set +u;
	
	# user custom initial command
	if [[ -n "${SECcmdDevTmp}" ]];then
		echo " EXEC: ${SECcmdDevTmp}";
		eval "${SECcmdDevTmp}";
	fi
	
	#history -r
};export -f SECFUNCaddToRcFile

#history -a
bash --rcfile <(echo 'SECFUNCaddToRcFile;')

