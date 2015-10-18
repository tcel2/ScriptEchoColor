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

eval `secinit`

#eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
#IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")
#strFile="${astrFiles[0]}"

#xterm -e "bash -i -c \"echo '$strFile';read\"";exit

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
strParamWithOptionalValue="OptinalValue"
astrRemainingParams=()
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Updates one or more symlinks to its relative target location, as long it is at same or child recursive path."
		SECFUNCshowHelp --colorize "Works at commandline or from nautilus."
		SECFUNCshowHelp
		exit 0
#	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
#		shift
#		strExample="${1-}"
#	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
#		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
#			shift
#			CFGstrTest="$1"
#		fi
#		
#		bCfgTest=true
	elif [[ "$1" == "--" ]];then #FUNCexample_help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift&&:
done


function FUNCloop() {
	local lbCommandLineByUser=false
	if [[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}" ]];then
		IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")
	else
		astrFiles=("$@")
		lbCommandLineByUser=true
	fi
	
	echo "NAUTILUS_SCRIPT_SELECTED_FILE_PATHS='${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}'"
	echo "PARAMS: @=`SECFUNCparamsToEval "$@"`"
	
	pwd
	declare -p astrFiles
	
	local lbFoundProblem=false
	for strFile in "${astrFiles[@]}";do 
		echoc --info "working with strFile='$strFile'"
		if ! FUNCmakeRelativeSymlink "$strFile";then # -i required to force it work on ubuntu 12.10
			echoc -p "failed to '$strFile'"
			lbFoundProblem=false;
			break;
		fi
	done
	
	if ! $lbCommandLineByUser;then
#	if $lbFoundProblem;then
		echoc -w -t 60
#	fi
	fi
};export -f FUNCloop

function FUNCmakeRelativeSymlink() {
	local lstrFile="${1-}"
	if [[ ! -L "$lstrFile" ]];then
		zenity --info --text "File is not a symlink: '$lstrFile'"
	else
		local lstrFilePath="`dirname "$lstrFile"`"
		if [[ "$lstrFilePath" == "." ]];then #is current path
			lstrFilePath="`pwd`/"
		elif [[ "${lstrFilePath:0:1}" != "/" ]];then #is child of current path
			lstrFilePath="`pwd`/$lstrFilePath"
		fi
		lstrFilePath="`readlink -e "$lstrFilePath"`/" #real canonical path
		echo "lstrFilePath='$lstrFilePath'"
		
		# update file with canonical
		echo "lstrFile='$lstrFile'"
		lstrFile="${lstrFilePath}`basename "$lstrFile"`"
		echo "lstrFile='$lstrFile'"
		
#		echoc --alert "TODO: this functionality is still limited to symlinks pointing to files at the same directory!!! "
		local lstrFullTarget="`readlink -f "$lstrFile"`"
		echo "lstrFullTarget='$lstrFullTarget'"
#		if [[ "${lstrFullTarget:0:1}" != "/" ]];then
#			echoc --info "Skipping: already relative symlink '$lstrFile' points to '$lstrFullTarget'."
#			return 0
#		fi

#		local lstrDirname="`dirname "$lstrFullTarget"`" #the path can be symlinked, the lstrFullTarget will work ok when matching for lstrDirname removal
#		echo "lstrDirname='$lstrDirname'"
		
#		local lstrNewSymlinkTarget="`basename "$lstrFullTarget"`"
#		local lstrNewSymlinkTarget="./${lstrFullTarget#$lstrDirname}"
#		local lstrNewSymlinkTarget="${lstrFullTarget#$lstrDirname}"
		local lstrNewSymlinkTarget="${lstrFullTarget#$lstrFilePath}"
		echo "lstrNewSymlinkTarget='$lstrNewSymlinkTarget'"
		while [[ "${lstrNewSymlinkTarget:0:1}" == "/" ]];do
			lstrNewSymlinkTarget="${lstrNewSymlinkTarget:1}"
			echo "lstrNewSymlinkTarget='$lstrNewSymlinkTarget'"
		done
		echo "lstrNewSymlinkTarget='$lstrNewSymlinkTarget'"
		
		( # work on working file path
			SECFUNCexecA -ce cd "$lstrFilePath"
	#		if [[ -a "`dirname "$lstrFile"`/$lstrNewSymlinkTarget" ]];then
	#		if [[ -a "$lstrDirname/$lstrNewSymlinkTarget" ]];then
			if [[ -a "$lstrNewSymlinkTarget" ]];then
				#echoc -x "rm -v '$lstrFile'"
				if ! echoc -x "ln -vsfT '$lstrNewSymlinkTarget' '$lstrFile'";then
					return 1
				fi
			else
	#			zenity --info --text "Symlink '$lstrFile' points to missing file '$lstrNewSymlinkTarget'"
				echoc -p "unable to make symlink '$lstrFile' point to missing '$lstrNewSymlinkTarget'"
				return 1
			fi
		)
	fi
	return 0
};export -f FUNCmakeRelativeSymlink

if [[ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS-}" ]];then
	#cd "/tmp" #NAUTILUS_SCRIPT_SELECTED_FILE_PATHS has absolute path to selected file
	#xterm -e "bash -i -c \"FUNCloop\"" # -i required to force it work
	secXtermDetached.sh --ontop --title "`SECFUNCfixId --justfix "${SECstrScriptSelfName}"`" --skiporganize FUNCloop "$@"
	#for strFile in "${astrFiles[@]}";do 
	#	if ! xterm -e "bash -i -c \"FUNCmakeRelativeSymlink '$strFile'\"";then # -i required to force it work on ubuntu 12.10
	#		break;
	#	fi
	#done
else
	SECFUNCexecA -ce FUNCloop "$@" #user is using commandline 
fi

