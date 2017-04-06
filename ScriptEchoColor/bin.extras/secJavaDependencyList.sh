#!/bin/bash
# Copyright (C) 2017 by Henrique Abdalla
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

eval `secinit`

#~ astrFilter=(
	#~ ^java
#~ )

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
echo "${astrAllParams[@]}"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t<folderWithClassFiles> [[filter] [filter] ...]"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code
strWorkPath="${1-.}"

#~ if [[ -n "${astrRemainingParams[@]-}" ]];then
	#~ astrFilter+=("${astrRemainingParams[@]}")
#~ fi
#~ strFilter="`echo "${astrFilter[@]}" |tr " " "|"`"
#~ echoc --info "strFilter='$strFilter'"

IFS=$'\n' read -d '' -r -a astrFileList < <(find "${strWorkPath}/" -iname "*.class")&&:
for strFile in "${astrFileList[@]}";do
	# tr: libs end with ';'
	# egrep: libs begin with 'L'
	# egrep: libs have '/' in-between
	# sort: remove repetitions and sort
	# sed: show only the lib string part
	strDeps="`strings "$strFile" |tr ';' '\n' |egrep "L.*/.*" -o |sort -u |sed -r "s'L(.*)'\1'"`"
	#~ strDeps="`echo "$strDeps" |egrep -v "$strFilter"`"&&: # remove what is to be ignored
	strDeps="`echo "$strDeps" |sed -r "s'.*'$strFile:&'"`" # prepend analized class file
	echo "$strDeps"
done

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
