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

#SECFUNCexecA -ce yad --question&&:

echoc --alert "DEPRECATED!!! @-n prefer secEnvDev.sh"

if ! type -P secinit >/dev/null;then #this is better than `which` TODO why?
	echo "'secinit' executable not found, install ScriptEchoColor before running this..." >&2
	exit 1
fi

export SECDEVbRunLog=false #if 'true' will restore at user session at the end
if ! ${SECbRunLog+false};then # SECbRunLog must be false (secinit --nolog) or this script will freeze when `bash` is run at the end
	SECDEVbRunLog=$SECbRunLog
fi

export SEC_WARN=true
export SECbFuncArraysRestoreVerbose=true
declare -p SEC_WARN SECbFuncArraysRestoreVerbose SECDEVbRunLog >&2

source <(secinit --extras --nolog --force)&&:;nRetSecInit=$? #see SECbRunLog=false above
if((nRetSecInit!=0));then echo "secinit error $nRetSecInit" >&2;exit 1;fi #TODO not working :(
declare -p SECDEVastrCmdTmp&&: >&2 #no problem if not set, this is just a report...

SECFUNCcheckActivateRunLog --report
if [[ "$TERM" != "dumb" ]];then
	SECFUNCcheckActivateRunLog -v --forcestdin
fi

#declare -p astr;set |egrep "^SEC_EXPORTED_ARRAY_" &&: >&2;exit 

export SECDEVstrSelfName="`readlink -f "$0"`";SECDEVstrSelfName="`basename "$SECDEVstrSelfName"`"
echo "Self: $0" >&2
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
		unset SECDEVbIsInExecTwiceMode
		unset SECDEVbExecTwiceTest
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
		: ${SECDEVbIsInExecTwiceMode:=false};export SECDEVbIsInExecTwiceMode
		: ${SECDEVbExecTwiceTest:=false};export SECDEVbExecTwiceTest
	fi
};export -f SECDEVFUNCoptions
SECDEVFUNCoptions
bCfgPath=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
	SECFUNCsingleLetterOptionsA; #this wont work if there is no secinit yet ...
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "[user command and params] to be run initially"
		SECFUNCshowHelp --nosort
		SECFUNCexecA -ce cat "$strFileCfg"
		exit 0
	elif [[ "$1" == "--cddevpath" || "$1" == "-c" ]];then #help initially cd to development path
		SECDEVbCdDevPath=true
	elif [[ "$1" == "--exit" || "$1" == "-e" ]];then #help exit after running user command
		SECDEVbExitAfterUserCmd=true
	elif [[ "$1" == "-u" ]];then #help enforce 'unbound variable' error, beware at bash completion...
		SECDEVbUnboundErr=true
	elif [[ "$1" == "--noinit" ]];then #help dont: source <(secinit)
		SECDEVbSecInit=false
	elif [[ "$1" == "--dbg" ]];then #help enable all debug options
		SECDEVbFullDebug=true
	elif [[ "$1" == "--cfg" ]];then #help <SECDEVstrProjectPath> configure the project path if not already
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
	SECDEVstrProjectPath="`cat "$strFileCfg"`"
fi
if [[ ! -f "$SECDEVstrProjectPath/bin.extras/$SECDEVstrSelfName" ]];then
	echo "invalid project development path '$SECDEVstrProjectPath'" >&2
	exit 1
fi

export SECDEVbExecTwice=false # keep this here, it is important to prevent infinite loop!
if $SECDEVbExecTwiceTest || ! SECFUNCexecA -ce cmp "$0" "$SECDEVstrProjectPath/bin.extras/$SECDEVstrSelfName";then
	SECDEVbExecTwice=true
	SECDEVbExecTwiceTest=false # disabled now to prevent infinite loop
fi
declare -p SECDEVbExecTwice >&2

if $SECDEVbFullDebug;then
	export SEC_DEBUG=true
	export SEC_WARN=true
	export SEC_BUGTRACK=true
	#set -x
fi

# custom first command by user
if ! $SECDEVbIsInExecTwiceMode;then # there should have no params anyway..
	SECDEVastrCmdTmp=("${@-}")
fi

if [[ -n "${SECDEVastrCmdTmp[@]-}" ]];then
	SECDEVbHasCmdTmp=true
fi

declare -p SECDEVastrCmdTmp&&: >&2

function SECFUNCaddToRcFile() {
	source "$HOME/.bashrc";
	export SECbRunLog=false #to make it sure it wont mess in case .bashrc has it 'true'
	
	source "$SECDEVstrProjectPath/lib/ScriptEchoColor/extras/secFuncPromptCommand.sh"
	function FUNCcleanTraps(){
		set +E #without this, causes trouble too with bash auto completion
		trap -- ERR #trap ERR must be disabled to avoid problems while typing commands that return false...
		
#		declare -p SECDEVbUnboundErr
		# good way to avoid bash completion problem, but why it happens?
		if $SECDEVbUnboundErr;then 
			set -u;
		else 
			set +u;
		fi
	}
	function SECFUNCbeforePromptCommand_CustomUserCommand(){
		:
	}
	function SECFUNCpromptCommand_CustomUserText(){ # function redefined from secFuncPromptCommand.sh
		# Result of: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
		local lstrBanner="\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"
		
		local lstrInternetConn=""
		if nmcli d |egrep -q "ethernet[ ]*connected";then lstrInternetConn+="Ether";fi
		if nmcli d |egrep -q "wifi[ ]*connected";then lstrInternetConn+="Wifi";fi
		if [[ -z "$lstrInternetConn" ]];then lstrInternetConn="OFF";fi

		echo "${lstrBanner}[INET:${lstrInternetConn}]"
		#echo -e \"$lstrBanner\"
	}
	function SECFUNCpromptCommand_CustomUserCommand(){
		FUNCcleanTraps #put here to avoid segfaulting current bash with user commands
	}
	
	#export PROMPT_COMMAND="${PROMPT_COMMAND-}${PROMPT_COMMAND+;} echo -e \"$lstrBanner\"; ";
	#export PS1="$(echo -e "\E[0m\E[34m\E[106mDev\E[0m")$PS1";\
	echo " PROMPT_COMMAND='$PROMPT_COMMAND'" >&2
	
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin"
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin.extras"
	SECFUNCaddToString PATH ":" "-$SECDEVstrProjectPath/bin.examples"
	#echo " PATH='$PATH'" >&2
	echo -e "PATH=(\t`echo $PATH |sed 's":"\n\t"g'`)" >&2	
	
	# must be after PATH setup !!!
	if $SECDEVbSecInit;then
		local lstrInitCmd="secinit --extras --force"
		echoc --info " $lstrInitCmd"
		eval `$lstrInitCmd`;
	fi
	
	###################################### TWICE MODE ###########################################
	# Must be after secinit!!! TODO if it is before secinit, SECFUNCbcPrettyCalcA "will not be recognized" but... aparently will cause any trouble? now what????
	if $SECDEVbExecTwice;then #this grants all is updated
		echo
		echo " SECDEVbExecTwice='$SECDEVbExecTwice'" >&2
		echoc --info " Loading '$SECstrScriptSelfName' twice as the project development one differs."
		echo
		SECDEVbExecTwice=false #prevent infinite recursive loop
		SECDEVbIsInExecTwiceMode=true
		declare -p SECDEVastrCmdTmp&&: >&2
#		$SECDEVstrSelfName "${SECDEVastrCmdTmp[@]}" #all options are already in exported variables
		SECFUNCexecA -ce SECFUNCarraysExport -v
		
		declare -p SECDEVstrSelfName >&2
		alias >&2
		type SECFUNCbcPrettyCalcA&&: >&2 # alias not set yet
		
#		export SEC_DEBUGX=true;set -x
		SECFUNCexecA -ce $SECDEVstrSelfName # No params needed. All options are already in exported variables
#		set +x
		echo "SECDEVINFO: just after twice run" >&2
#		type SECFUNCbcPrettyCalcA&&: >&2
		echo "SECDEVINFO: just before twice exit" >&2
		#TODO 2 lines? echo "SECDEVINFO: just before twice exit: `type SECFUNCbcPrettyCalcA&&: 2>&1`" >&2
		ps;SECFUNCechoWarnA "exiting";exit 0 #must exit to not execute the options twice, only once above.
	fi
	###################################### TWICE MODE - EXIT ###########################################
	
	# Must be after secinit!!!
	if $SECDEVbRunLog;then
		export SECbRunLog="$SECDEVbRunLog" #this shell wont be logged, but commands run on it will be properly logged again IF user had it previously setup for ex. at .bashrc
	fi
	
	# must come after secinit !!!
	if $SECDEVbUnboundErr;then
		echoc --alert ' Unbound vars NOT allowed at terminal, beware bash completion...'
	else
#		echo ' Unbound vars allowed at terminal (unless you exec by hand: source <(secinit -f))' >&2;set +u;
		echo ' Unbound vars allowed at terminal' >&2
	fi
	
	echo
	echo " SECstrTmpFolderLog='$SECstrTmpFolderLog'"
	echo
	ps -o pid,cmd
	echo
	
	if $SECDEVbCdDevPath;then
		echo " cd '$SECinstallPath'" >&2
		cd "$SECinstallPath"
	fi
	
	# when developing, this will be helpful
	export SEC_WARN=true
	
	# user custom initial command
	if $SECDEVbHasCmdTmp;then
#		source <(secinit --force) # mainly to restore the exported arrays and initialize the log
		#SECFUNCarraysRestore
		#echo "SECDEVastrCmdTmp[@]=(${SECDEVastrCmdTmp[@]})"
#		if [[ -n "${SECDEVastrCmdTmp[@]-}" ]];then
			#echo "SECDEVastrCmdTmp[@]=(${SECDEVastrCmdTmp[@]})"
#			set |egrep "^SEC_EXPORTED_ARRAY_" >&2
			declare -p SECDEVastrCmdTmp&&: >&2
			( #source <(secinit --force);
				SECbRunLog=true #force log!
				source <(secinit --extras --force) # mainly to restore the exported arrays and initialize the log
				set |egrep "^SEC_EXPORTED_ARRAY_" >&2
				declare -p SECDEVastrCmdTmp&&: >&2
				astrCmdTmp=("${SECDEVastrCmdTmp[@]}");
				declare -p astrCmdTmp
#				type "${astrCmdTmp[0]}"&&:
#				echo "SECbRunLog=$SECbRunLog;SECbRunLogDisable=$SECbRunLogDisable;" >&2;
				#SECFUNCcheckActivateRunLog; #force log!
#				SECFUNCcheckActivateRunLog -v --restoredefaultoutputs

#				SECFUNCcheckActivateRunLog -v --forcestdin
				
#				ls -l --color /proc/$$/fd/*
#				exec 1>&0 2>&0
#				ls -l --color /proc/$$/fd/*
				if ! $SECDEVbSecInit;then 
					# all SEC environment will be cleared. 
					# A SEC script will setup it again. 
					# This is good because a few applications may not handle so much env vars.
					SECFUNCcleanEnvironment;
				fi 
				echo " EXEC: '${astrCmdTmp[@]}'" >&2
				"${astrCmdTmp[@]}";
			)&&:;nRet=$?
			if((nRet!=0));then
				SEC_WARN=true SECFUNCechoWarnA "cmd='${SECDEVastrCmdTmp[@]}';nRet='$nRet';"
			fi
#		fi
	fi
	
	if $SECDEVbExitAfterUserCmd;then
		echo " SECDEVINFO: Exiting after user command..." >&2
		sleep 1
#		ps >&2
#		type SECFUNCbcPrettyCalcA&&: >&2
		ps;SECFUNCechoWarnA "exiting";exit 0
	fi

	if ! $SECDEVbExecTwice;then
		SECDEVFUNCoptions --defaults #this helps on running this script again with default options...
	fi
	
  echoc --alert "DEPRECATED!!! @-n prefer secEnvDev.sh"
  
	#history -r
};export -f SECFUNCaddToRcFile

#history -a
#SECFUNCdrawLine A
#set |egrep "^SEC_EXPORTED_ARRAY_" &&: >&2
#SECFUNCdrawLine B
SECFUNCexecA -ce SECFUNCarraysExport -v
#set |grep "^SEC_EX"
#SECFUNCdrawLine C
#set |egrep "^SEC_EXPORTED_ARRAY_" &&: >&2
#SECFUNCdrawLine D
echoc --info "now running bash with modified/increased rc file"
if ! SECFUNCexecA -ce bash --rcfile <(echo 'SECFUNCaddToRcFile;');then
	SECFUNCechoErrA "exited with problem, what is happening?"
	ps;SECFUNCechoWarnA "exiting";exit 1
fi

ps;SECFUNCechoWarnA "exiting";exit 0

