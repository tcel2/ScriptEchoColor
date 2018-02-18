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

source <(secinit --extras)

function FUNCdoIt() {
	source <(secinit --extras) #to apply aliases. TODO --fast wasnt enough at @RefLink:1, complaining about unbound SECbExecJustEcho at SECFUNCexec
	
	#sedUrlDecoder='s % \\\\x g'
	#path=`echo "$NAUTILUS_SCRIPT_CURRENT_URI" |sed -r 's"^file://(.*)"\1"' |sed "$sedUrlDecoder" |xargs printf`
	#eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
	IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")
	#for((n=0;n<${#astrFiles[@]};n++));do
	for strFile in "${astrFiles[@]}";do
		echo "will run: $strFile"
	done
	local lbFirstDone=false
	for strFile in "${astrFiles[@]}";do
		if $lbFirstDone;then
			echoc -w "any key to run next"
		fi
		
		#strFile="${astrFiles[n]}"
		#strFile="${astrFiles[0]}"
		#xterm -e "$strFile"
		#xterm -e "bash -i -c \"$strFile\"" # -i required to force it work on ubuntu 12.10
		(
			cd "`dirname "${strFile}"`"
			SECFUNCexecA -ce pwd # @RefLink:1
			SECFUNCexecA -ce secXtermDetached.sh "$strFile"
		)
		lbFirstDone=true
		
		echoc -w -t 60 "check command output above"
	done
};export -f FUNCdoIt

#echo "NAUTILUS_SCRIPT_CURRENT_URI='$NAUTILUS_SCRIPT_CURRENT_URI'"
#if [[ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]];then
	SECFUNCexecA -ce secXtermDetached.sh --ontop --title "`SECFUNCfixId --justfix "${SECstrScriptSelfName}"`" --skiporganize FUNCdoIt "$@"
#else
#	SECFUNCexecA -ce FUNCdoIt "$@" #user at commandline
#fi

