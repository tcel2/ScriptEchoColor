#!/bin/bash
# Copyright (C) 2004-2012 by Henrique Abdalla
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

if [[ "$TERM" == "xterm" ]];then #TODO xterm variants will match this?
  SECstrXtermBgBkp="`xtermcontrol --get-bg 2>/dev/null`"
fi
: ${SECstrXtermBgBkp:="black"}
function SECFUNCcheckIfSudoIsActive() { #help 
	# this would update the timestamp and so the timeout, therefore it is useless...
	#nPts=`ps --no-headers -p $$ |sed -r 's".*pts/([0-9]*).*"\1"'`; now=`date +"%s"`; echo "remaining $((now-`sudo stat -c '%Y' /var/lib/sudo/\`SECFUNCgetUserName\`/$nPts`))s"
	
	#if sudo -nv 2>/dev/null 1>/dev/null; then 
	if sudo -n uptime 2>/dev/null 1>/dev/null; then
    echo -ne "\E[0m\E[33m\E[41m \E[0m\E[93m\E[41mS\E[0m\E[93m\E[41m\E[1mU\E[0m\E[93m\E[41m\E[1mD\E[0m\E[93m\E[41m\E[1mO \E[0m"
    #echo -ne "\E[0m\E[33m\E[41m\E[5m \E[0m\E[93m\E[41m\E[5mS\E[0m\E[93m\E[41m\E[1m\E[5mU\E[0m\E[93m\E[41m\E[1m\E[5mD\E[0m\E[93m\E[41m\E[1m\E[5mO \E[0m" # GENERATOR: echoc --escapedchars "@{Ry} @lS@oU@lD@oO " #blink not used as some terms like rxvt wont blink and will change bg color
		#echo #without newline, the terminal seems to bugout with lines that are too big... discomment this if you find any problems...
		#SECstrXtermBgBkp="`xtermcontrol --get-bg 2>/dev/null`"
    if [[ "$TERM" == "xterm" ]];then #TODO xterm variants will match this?
      xtermcontrol --bg darkred
    else
      setterm -background red #TODO dark red? #TODO make it sure the command will work?
    fi
	else
#		if [[ -n "$SECstrXtermBgBkp" ]];then
		#if [[ "$SECstrXtermBgBkp" != "`xtermcontrol --get-bg 2>/dev/null`" ]];then
    if [[ "$TERM" == "xterm" ]];then
      xtermcontrol --bg "$SECstrXtermBgBkp"
    else
      setterm -background black #TODO how to get the default/previous console color??? #TODO make it sure the command will work?
    fi
		#fi
#		fi
	fi; 
}

function SECFUNCbeforePromptCommand_CustomUserCommand(){ #help you can redefine this function, see its example at secBashForScriptEchoColorDevelopment.sh, will run as first thing
	:
}

function SECFUNCpromptCommand_CustomUserCommand(){ #help you can redefine this function, see its example at secBashForScriptEchoColorDevelopment.sh, will run as last thing
	:
}

function SECFUNCpromptCommand_CustomUserText(){ #help you can redefine this function, see its example at secBashForScriptEchoColorDevelopment.sh
	:
}

function SECFUNCbeforePromptCommand(){ #help this happens many times (why?) so the uninitialized variable below will control it to happen only once
	# will initialize if it is unset, can be with Sec or Nano
	if ${SECdtBeforeCommandSec+false};then #&& [[ -z "$SECdtBeforeCommand" ]];then
		SECFUNCbeforePromptCommand_CustomUserCommand;
    
    eval "`date +"SECdtBeforeCommandSec=%s;SECdtBeforeCommandNano=%N;"`"
    
    ###
    # DO NOT echo ANYTHING HERE (before)!!! it will just mess the output :/, better just at SECFUNCpromptCommand (AFTER)
    ###
    
    #~ local lbEcho=true
    #~ if [[ -z "$BASH_COMMAND" ]];then lbEcho=false;
    #~ elif [[ "$BASH_COMMAND" =~ .*command-not-found.* ]];then lbEcho=false;
    #~ elif [[ "$BASH_COMMAND" =~ ^SECFUNCpromptCommand$ ]];then lbEcho=false;
    #~ elif [[ "$BASH_COMMAND" =~ ^return$ ]];then lbEcho=false;
    #~ fi
    #~ if $lbEcho;then
      #~ #(
      #~ #  sleep 0.25
        #~ # GENERATOR: echoc --escapedchars "@c (@gCmdBeginAt@y=@r'@c`date +"$formatFullDateTime"`@r'@c) "
        #~ local lstrEchoNL="-n"
        #~ local lbDevMode=false;if ! ${SECDEVstrProjectPath+false};then lbDevMode=true;fi
        #~ if $lbDevMode;then lstrEchoNL="";fi
        #~ echo -e $lstrEchoNL "\E[0m\E[36m (\E[0m\E[32mCmdBeginAt\E[0m\E[33m=\E[0m\E[31m'\E[0m\E[36m`date +"$formatFullDateTime"`\E[0m\E[31m'\E[0m\E[36m) \E[0m" >&2
        #~ echo >&2
      #~ #) >/dev/null & 
    #~ fi
    #~ echo "BEFORE: `date` $BASH_COMMAND" >>/tmp/SEC_DEBUG_PROMPT_CMD.log
	fi
}
trap 'SECFUNCbeforePromptCommand;' DEBUG
function SECFUNCpromptCommand () { #help at .bashrc put this: if [[ -f "`secGetInstallPath.sh`/lib/ScriptEchoColor/extras/secFuncPromptCommand.sh" ]];then source "`secGetInstallPath.sh`/lib/ScriptEchoColor/extras/secFuncPromptCommand.sh";fi
	#TODO if time() is used with a command, the delay messes up becoming very low...
  eval "`date +"SECdtAfterCommandSec=%s;SECdtAfterCommandNano=%N;"`"
  #~ local lstrDtEnd="`date +"%s.%N"`"
	SECfCommandDelay="`bc <<< "($SECdtAfterCommandSec.$SECdtAfterCommandNano)-($SECdtBeforeCommandSec.$SECdtBeforeCommandNano)"`"
	if [[ "${SECfCommandDelay:0:1}" == "." ]];then
		SECfCommandDelay="0$SECfCommandDelay"
	fi
	
	history -a; # append to history at each command issued!!!
	local lnWidth=`tput cols`;
	local lnHalf=$((lnWidth/2))
	local lstrBegin="`date --date="@$SECdtBeforeCommandSec" +"%H:%M:%S"`.$SECdtBeforeCommandNano"
	local lstrEnd="`  date --date="@$SECdtAfterCommandSec"  +"%H:%M:%S"`.$SECdtAfterCommandNano"
#	local lstrEnd="`date +"%H:%M:%S.%N"`"
	local lstrText="`SECFUNCcheckIfSudoIsActive`[${lstrBegin}->${lstrEnd}](${SECfCommandDelay}s)`SECFUNCpromptCommand_CustomUserText`";
	local lstrTextToCalcSize="`echo "$lstrText" |sed -r 's"[\]E[[][[:digit:]]*m""g'`" #remove any formatting characters
	local lnSizeTextHalf=$((${#lstrTextToCalcSize}/2))
	echo #this prevents weirdness when the previous command didnt output newline at the end...
	#local lstrOutput="`printf "%*s%*s" $((lnHalf+lnSizeTextHalf)) "$lstrText" $((lnHalf-lnSizeTextHalf)) "" |sed 's" "="g';`"
	local lstrPadChars="`eval "printf '%.s=' {1..$((lnHalf-lnSizeTextHalf))}"`"
	local lstrPadCharsRight="${lstrPadChars:0:${#lstrPadChars}-1}"
#	if((${#lstrTextToCalcSize}%1==0));then
#		lstrPadCharsRight="${lstrPadCharsRight:0:${#lstrPadCharsRight}-1}"
#	fi
	#local lstrOutput="`eval 'printf "%.s " {1..'$((lnHalf-lnSizeTextHalf))'}';echo "$lstrText";eval 'printf "%.s " {1..'$((lnHalf-lnSizeTextHalf))'}'`"
	#local lstrOutput="`echo "${lstrPadChars}${lstrText}${lstrPadChars}"`"
	#echo "${lstrOutput}"
	#echo -e "${lstrOutput}"
  #echo "ATPCMD: `date` $BASH_COMMAND" >>/tmp/SEC_DEBUG_PROMPT_CMD.log
	echo -e "${lstrPadChars}${lstrText}${lstrPadCharsRight}" >&2
	
	SECFUNCpromptCommand_CustomUserCommand
	
	unset SECdtBeforeCommandNano #TODO explain WHY this is NOT together with SECdtBeforeCommandSec ???
	
	##########################################
	### IMPORTANT !!!!!!!!!!!!!!!!!!!!!!!! ###
	##########################################
	# as this is the control variable while unset, it MUST be unset as the very LAST command!!!!
	unset SECdtBeforeCommandSec 
}
export PROMPT_COMMAND=SECFUNCpromptCommand
#export PS1="\`FUNCsudoOn\`$PS1" #use this or PROMPT_COMMAND

