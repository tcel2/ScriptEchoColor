#!/bin/bash
# Copyright (C) 2015 by Henrique Abdalla
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

# $NAUTILUS_SCRIPT_SELECTED_FILE_PATHS
# $NAUTILUS_SCRIPT_SELECTED_URIS
# $NAUTILUS_SCRIPT_CURRENT_URI
# $NAUTILUS_SCRIPT_WINDOW_GEOMETRY

source <(secinit --extras)

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
strExtension=""
strFullAppPathAndFile=""
export astrRemainingParams=()
declare -Ax CFGastrAssigned=()
SECFUNCcfgReadDB #after default variables value setup above
declare -p CFGastrAssigned&&:

#strFileToOpen=""
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "[astrRemainingParams] file(s) from command line that will be opened if there is an opener assigned"
		SECFUNCshowHelp --colorize "alternatively, will open files pointed out by nautilus (in this case will ignore command line ones)"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--add" || "$1" == "-a" ]];then #help <strExtension> <strFullAppPathAndFile>
		shift
		strExtension="${1-}"
		shift
		strFullAppPathAndFile="${1-}"
		
#	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
#		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
#			shift
#			CFGstrTest="$1"
#		fi
#		
#		bCfgTest=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		break;
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
#strFileToOpen="${1-}"
#shift
while ! ${1+false};do	# checks if param is set
	astrRemainingParams+=("$1")
	shift #will consume all remaining params
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

if [[ -n "$strExtension" ]];then
	strExtension="${strExtension#.}"
	echo "strExtension='$strExtension'"
	if [[ ! -f "$strFullAppPathAndFile" ]];then
		echoc -p "missing executable strFullAppPathAndFile='$strFullAppPathAndFile'"
		exit 1
	fi
	CFGastrAssigned[$strExtension]="$strFullAppPathAndFile"
	SECFUNCcfgWriteVar CFGastrAssigned
	SECFUNCexecA -ce SECFUNCcfgFileName --show
	exit 0
fi
#yad --info --text=$LINENO
SECFUNCarraysExport
declare -p astrRemainingParams
declare -p SECcmdExportedAssociativeArrays
#declare |grep SEC_EXPORTED_ARRAY_
declare -p SEC_EXPORTED_ARRAY_astrRemainingParams
#yad --info --text=$LINENO
function FUNCopen() {
	#declare |grep SEC_EXPORTED_ARRAY_
	SECFUNCarraysRestore
	IFS=$'\n' read -d '' -r -a astrFiles < <(echo "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}")&&:
#	astrFiles+=("${strFileToOpen}")
	if ((`SECFUNCarraySize astrFiles`==0));then
		astrFiles+=("${astrRemainingParams[@]}")
	fi
	declare -p astrFiles
	if((`SECFUNCarraySize astrFiles`>0));then
		for strFile in "${astrFiles[@]}";do
			if [[ -f "$strFile" ]];then
				strExtension="`echo "$strFile" |sed -r 's".*[.](.*)$"\1"'`"
				if [[ -z "$strExtension" ]];then
					echoc -p "invalid strExtension='$strExtension'"
					exit 1
				fi
		
				strExec="${CFGastrAssigned[$strExtension]-}"
		
				if [[ -f "$strExec" ]];then
					SECFUNCexecA -ce "$strExec" "$strFile"
				else
					echoc -p "unassigned strExtension='$strExtension', or missing executable strExec='$strExec'"
					exit 1
				fi
			else
				echoc -p "missing strFile='$strFile'"
				exit 1
			fi
			#break; #TODO this is just to prevent opening more than one file, could open tho...
		done
	fi
};export -f FUNCopen
#yad --info --text=$LINENO
#TODO this is not accepting the exported arrays: secXtermDetached.sh --waitonexit 60 bash -c FUNCopen
xterm -e "bash -c FUNCopen;echoc -w -t 60"

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

