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

if ! type -P secinit >/dev/null;then
	echo "'secinit' executable not found, install ScriptEchoColor before running this..." >>/dev/stderr
	exit 1
fi

export SECbRunLogForce=false #TODO if true, for some reason this script freezes?
eval `secinit` #if it is already installed on the system it will help!

export SECDEVstrSelfName="`basename "$0"`"
echo "Self: $0" >>/dev/stderr
strFileCfg="$HOME/.${SECDEVstrSelfName}.cfg"

export SECDEVbInitialized=false

# on the execute twice mode, if these vars are already set, default values are skipped and the second execution works fine!
function SECDEVFUNCoptions() {
	if [[ "${1-}" == "--defaults" ]];then
		#set |grep -v "^SECDEVFUNC" |grep "^SECDEV[[:alnum:]_]*" -o |sed -r 's".*"unset &;"'
		unset SECDEVbExitAfterUserCmd
		unset SECDEVbSecInit
		unset SECDEVbFullDebug
		unset SECDEVstrProjectPath
		unset SECDEVbCdDevPath
		unset SECDEVbUnboundErr
		SECDEVFUNCoptions #will now run just setting the defaults! yey!
	elif [[ -n "${1-}" ]];then
		echoc -p "invalid option '$1'"
		_SECFUNCcriticalForceExit
	else
		: ${SECDEVbExitAfterUserCmd:=false};export SECDEVbExitAfterUserCmd
		: ${SECDEVbSecInit:=true};export SECDEVbSecInit
		: ${SECDEVbFullDebug:=false};export SECDEVbFullDebug
		: ${SECDEVstrProjectPath:=""};export SECDEVstrProjectPath
		: ${SECDEVbCdDevPath:=false};export SECDEVbCdDevPath
		: ${SECDEVbUnboundErr:=false};export SECDEVbUnboundErr
	fi
};export -f SECDEVFUNCoptions
SECDEVFUNCoptions
bCfgPath=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
	SECFUNCsingleLetterOptionsA; #this wont work if there is no secinit yet ...
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "[user command and params] to be run initially"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--cddevpath" || "$1" == "-c" ]];then #help initially cd to development path
		SECDEVbCdDevPath=true
	elif [[ "$1" == "--exit" || "$1" == "-e" ]];then #help exit after running user command
		SECDEVbExitAfterUserCmd=true
	elif [[ "$1" == "-u" ]];then #help enforce 'unbound variable' error, beware at bash completion...
		SECDEVbUnboundErr=true
	elif [[ "$1" == "--noinit" ]];then #help dont: eval `secinit`
		SECDEVbSecInit=false
	elif [[ "$1" == "--dbg" ]];then #help enable all debug options
		SECDEVbFullDebug=true
	elif [[ "$1" == "--cfg" ]];then #help <path> configure the project path if not already
		shift
		SECDEVstrProjectPath="${1-}"
		
		bCfgPath=true
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bCfgPath;then
	if [[ "${SECDEVstrProjectPath:0:1}" != "/" ]];then
		SECDEVstrProjectPath="`pwd`/$SECDEVstrProjectPath"
	fi
	if [[ -f "$SECDEVstrProjectPath/bin.extras/$SECDEVstrSelfName" ]];then
		echo "$SECDEVstrProjectPath" >"$strFileCfg"
	fi
fi

if [[ -z "$SECDEVstrProjectPath" ]];then
	SECDEVstrProjectPath="`cat "$HOME/.${SECDEVstrSelfName}.cfg"`"
fi
if [[ ! -f "$SECDEVstrProjectPath/bin.extras/$SECDEVstrSelfName" ]];then
	echo "invalid project development path '$SECDEVstrProjectPath'" >>/dev/stderr
	exit 1
fi

export SECDEVbExecTwice=false
if ! cmp "$0" "$SECDEVstrProjectPath/bin.extras/$SECDEVstrSelfName";then
	SECDEVbExecTwice=true
fi

if $SECDEVbFullDebug;then
	export SEC_DEBUG=true
	export SEC_WARN=true
	export SEC_BUGTRACK=true
	#set -x
fi

## custom first command by user like found at SECFUNCparamsToEval
#export SECDEVstrCmdTmp=""
#for strParam in "$@";do
#	SECDEVstrCmdTmp+="'$strParam' "
#done

# custom first command by user
export SECDEVstrCmdTmp="" #good in case of child shell
if [[ -n "${1-}" ]];then
	SECDEVstrCmdTmp="`eval \`secinit --base\` >>/dev/stderr; SECFUNCparamsToEval "$@"`"
	#echo " SECDEVstrCmdTmp='$SECDEVstrCmdTmp'" >>/dev/stderr
fi

function SECFUNCaddToRcFile() {
	source "$HOME/.bashrc";
	export SECbRunLogForce=false #to make it sure it wont mess in case .bashrc has it 'true'
	
	source "$SECDEVstrProjectPath/lib/ScriptEchoColor/extras/secFuncPromptCommand.sh"
	function SECFUNCpromptCommand_CustomUserText(){ # function redefined from secFuncPromptCommand.sh
		# Result of: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
		local lstrBanner="\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"
		echo "$lstrBanner"
		#echo -e \"$lstrBanner\"
	}
	function SECFUNCpromptCommand_CustomUserCommand(){
		#good way to avoid bash completion not working well :)
		if $SECDEVbUnboundErr;then 
			set -u;
		else 
			set +u;
		fi 
	}
	#export PROMPT_COMMAND="${PROMPT_COMMAND-}${PROMPT_COMMAND+;} echo -e \"$lstrBanner\"; ";
	#export PS1="$(echo -e "\E[0m\E[34m\E[106mDev\E[0m")$PS1";\
	echo " PROMPT_COMMAND='$PROMPT_COMMAND'" >>/dev/stderr
	
#	export PATH="$SECDEVstrProjectPath/bin:$SECDEVstrProjectPath/bin.extras:$PATH";
#	echo " PATH='$PATH'" >>/dev/stderr
#	local lastrAddToPath=(
#		"$SECDEVstrProjectPath/bin"
#		"$SECDEVstrProjectPath/bin.extras"
#	)
#	local lstrAddToPath
#	for lstrAddToPath in ${lastrAddToPath[@]};do
#		if ! echo "$PATH" |grep -q "${lstrAddToPath}:";then #as will be added at beginning, must end with ':'
#			export PATH="$lstrAddToPath:$PATH";
#		fi
#	done
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin"
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin.extras"
	echo " PATH='$PATH'" >>/dev/stderr
	
	if $SECDEVbExecTwice;then #this grants all is updated
		echo
		echo " SECDEVbExecTwice='$SECDEVbExecTwice'" >>/dev/stderr
		echoc --info " Loading '$SECstrScriptSelfName' twice as the project development one differs."
		echo
		SECDEVbExecTwice=false #prevent infinite recursive loop
		$SECDEVstrSelfName #all options are already in exported variables
		exit #must exit to not execute the options twice, only once above.
	fi
	
	# must be after PATH setup
	if $SECDEVbSecInit;then
		echo ' eval `secinit --force`' >>/dev/stderr
		eval `secinit --force`;
	fi
	
	# must come after secinit
	if $SECDEVbUnboundErr;then
		echoc --alert ' Unbound vars NOT allowed at terminal, beware bash completion...'
	else
#		echo ' Unbound vars allowed at terminal (unless you exec by hand: eval `secinit -f`)' >>/dev/stderr;set +u;
		echo ' Unbound vars allowed at terminal' >>/dev/stderr
	fi
	
	if $SECDEVbCdDevPath;then
		echo " cd '$SECinstallPath'" >>/dev/stderr
		cd "$SECinstallPath"
	fi
	
	# user custom initial command
	if [[ -n "${SECDEVstrCmdTmp}" ]];then
		echo " EXEC: ${SECDEVstrCmdTmp}" >>/dev/stderr
		eval "${SECDEVstrCmdTmp}";
	fi

	if $SECDEVbExitAfterUserCmd;then
		echo " Exiting..." >>/dev/stderr
		sleep 1
		exit
	fi

	if ! $SECDEVbExecTwice;then
		SECDEVFUNCoptions --defaults #this helps on running this script again with default options...
	fi
	
	#history -r
};export -f SECFUNCaddToRcFile

#history -a
bash --rcfile <(echo 'SECFUNCaddToRcFile;')


