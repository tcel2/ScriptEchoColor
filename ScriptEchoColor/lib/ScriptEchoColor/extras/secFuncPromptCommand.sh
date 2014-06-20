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

function SECFUNCcheckIfSudoIsActive() { 
	# this would update the timestamp and so the timeout, therefore it is useless...
	#nPts=`ps --no-headers -p $$ |sed -r 's".*pts/([0-9]*).*"\1"'`; now=`date +"%s"`; echo "remaining $((now-`sudo stat -c '%Y' /var/lib/sudo/\`SECFUNCgetUserName\`/$nPts`))s"
	
	#if sudo -nv 2>/dev/null 1>/dev/null; then 
	if sudo -n uptime 2>/dev/null 1>/dev/null; then 
		#echo -ne "\E[0m\E[93m\E[41m\E[1m\E[5m SUDO \E[0m"; 
		echo -n "\E[0m\E[93m\E[41m\E[1m\E[5m SUDO \E[0m"; 
		echo #without newline, the terminal seems to bugout with lines that are too big... discomment this if you find any problems...
	fi; 
}

function SECFUNCcustomUserText(){ #redefine this function, see example at secBashForScriptEchoColorDevelopment.sh
	local lstrDummyVariable;
}

function SECFUNCbeforePromptCommand(){
	if ${SECdtBeforeCommandSec+false};then #&& [[ -z "$SECdtBeforeCommand" ]];then
		SECdtBeforeCommandSec="`date +"%s"`"
		SECdtBeforeCommandNano="`date +"%N"`"
	fi
}
trap 'SECFUNCbeforePromptCommand' DEBUG
function SECFUNCpromptCommand () { #at .bashrc put this: if [[ -f "/usr/lib/ScriptEchoColor/extras/funcPromptCommand.sh" ]];then source "/usr/lib/ScriptEchoColor/extras/funcPromptCommand.sh";fi
	#TODO if time() is used with a command, the delay messes up becoming very low...
	SECfCommandDelay="`bc <<< "\`date +"%s.%N"\`-($SECdtBeforeCommandSec.$SECdtBeforeCommandNano)"`"
	if [[ "${SECfCommandDelay:0:1}" == "." ]];then
		SECfCommandDelay="0$SECfCommandDelay"
	fi
	
	history -a; # append to history at each command issued!!!
	local lnWidth=`tput cols`;
	local lnHalf=$((lnWidth/2))
	local lstrBegin="`date --date="@$SECdtBeforeCommandSec" +"%H:%M:%S"`"
	local lstrEnd="`date +"%H:%M:%S"`"
	local lstrText="`SECFUNCcheckIfSudoIsActive`[${lstrBegin}->${lstrEnd}](${SECfCommandDelay}s)`SECFUNCcustomUserText`";
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
	echo -e "${lstrPadChars}${lstrText}${lstrPadCharsRight}"
	
	unset SECdtBeforeCommandSec
	unset SECdtBeforeCommandNano
}
export PROMPT_COMMAND=SECFUNCpromptCommand
#export PS1="\`FUNCsudoOn\`$PS1" #use this or PROMPT_COMMAND

