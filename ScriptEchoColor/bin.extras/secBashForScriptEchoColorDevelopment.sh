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

export SECDEVbRunLog=false #if 'true' will restore at user session at the end
if ! ${SECbRunLog+false};then # SECbRunLog must be false (secinit --nolog) or this script will freeze when `bash` is run at the end
	SECDEVbRunLog=$SECbRunLog
fi

eval `secinit --extras --nolog`

export SECDEVstrSelfName="`readlink -f "$0"`";SECDEVstrSelfName="`basename "$SECDEVstrSelfName"`"
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
		unset SECDEVastrCmdTmp
		unset SECDEVbHasCmdTmp
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
		if ${SECDEVastrCmdTmp+false};then SECDEVastrCmdTmp=();fi;export SECDEVastrCmdTmp
		: ${SECDEVbHasCmdTmp:=false};export SECDEVbHasCmdTmp
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

# custom first command by user
SECDEVastrCmdTmp=("$@")
if [[ -n "${SECDEVastrCmdTmp[@]-}" ]];then
	SECDEVbHasCmdTmp=true
fi

function SECFUNCaddToRcFile() {
	source "$HOME/.bashrc";
	export SECbRunLog=false #to make it sure it wont mess in case .bashrc has it 'true'
	
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
	
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin"
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin.extras"
	echo " PATH='$PATH'" >>/dev/stderr
	
	###################################### TWICE MODE ###########################################
	if $SECDEVbExecTwice;then #this grants all is updated
		echo
		echo " SECDEVbExecTwice='$SECDEVbExecTwice'" >>/dev/stderr
		echoc --info " Loading '$SECstrScriptSelfName' twice as the project development one differs."
		echo
		SECDEVbExecTwice=false #prevent infinite recursive loop
		$SECDEVstrSelfName #all options are already in exported variables
		exit #must exit to not execute the options twice, only once above.
	fi
	###################################### TWICE MODE - EXIT ###########################################
	
	# must be after PATH setup !!!
	if $SECDEVbSecInit;then
		local lstrInitCmd="secinit --extras --force"
		echoc --info " $lstrInitCmd"
		eval `$lstrInitCmd`;
	fi

	# Must be after secinit!!!
	if $SECDEVbRunLog;then
		export SECbRunLog="$SECDEVbRunLog" #this shell wont be logged, but commands run on it will be properly logged again IF user had it previously setup for ex. at .bashrc
	fi
	
	# must come after secinit !!!
	if $SECDEVbUnboundErr;then
		echoc --alert ' Unbound vars NOT allowed at terminal, beware bash completion...'
	else
#		echo ' Unbound vars allowed at terminal (unless you exec by hand: eval `secinit -f`)' >>/dev/stderr;set +u;
		echo ' Unbound vars allowed at terminal' >>/dev/stderr
	fi
	
	echo
	echo " SECstrTmpFolderLog='$SECstrTmpFolderLog'"
	echo
	
	if $SECDEVbCdDevPath;then
		echo " cd '$SECinstallPath'" >>/dev/stderr
		cd "$SECinstallPath"
	fi
	
	# when developing, this will be helpful
	export SEC_WARN=true
	
	# user custom initial command
	if $SECDEVbHasCmdTmp;then
#		eval `secinit --force` # mainly to restore the exported arrays and initialize the log
		#SECFUNCarraysRestore
		#echo "SECDEVastrCmdTmp[@]=(${SECDEVastrCmdTmp[@]})"
#		if [[ -n "${SECDEVastrCmdTmp[@]-}" ]];then
			#echo "SECDEVastrCmdTmp[@]=(${SECDEVastrCmdTmp[@]})"
			( #eval `secinit --force`;
				SECbRunLog=true #force log!
				eval `secinit --extras --force` # mainly to restore the exported arrays and initialize the log
				astrCmdTmp=("${SECDEVastrCmdTmp[@]}");
#				echo "SECbRunLog=$SECbRunLog;SECbRunLogDisable=$SECbRunLogDisable;" >>/dev/stderr;
				#SECFUNCcheckActivateRunLog; #force log!
				if ! $SECDEVbSecInit;then SECFUNCcleanEnvironment;fi #all SEC environment will be cleared
				echo " EXEC: '${astrCmdTmp[@]}'" >>/dev/stderr
				"${astrCmdTmp[@]}";
			)&&:;nRet=$?
			if((nRet!=0));then
				SEC_WARN=true SECFUNCechoWarnA "cmd='${SECDEVastrCmdTmp[@]}';nRet='$nRet';"
			fi
#		fi
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
SECFUNCarraysExport
#set |grep "^SEC_EX"
bash --rcfile <(echo 'SECFUNCaddToRcFile;')


