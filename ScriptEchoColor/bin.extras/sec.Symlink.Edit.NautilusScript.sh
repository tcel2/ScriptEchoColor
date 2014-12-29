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

eval `secinit --extras`

#eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")&&:
strFile="${astrFiles[0]}"

#echo "NAUTILUS_SCRIPT_CURRENT_URI=$NAUTILUS_SCRIPT_CURRENT_URI"
#echoc -w 

#xterm -e "bash -i -c \"echo '$strFile';read\"";exit

function FUNCretargetSymlink() {
	local lstrFile="${1-}"
	echo "lstrFile='$lstrFile'"
	local lstrFilePath="`dirname "$lstrFile"`"
	echo "lstrFilePath='$lstrFilePath'"
	echoc -x pwd
	if [[ ! -L "$lstrFile" ]];then
		zenity --info --text "File is not a symlink: '$lstrFile'"
	else
		local lstrTarget="`readlink -f "$lstrFile"`"
		echo "lstrTarget='$lstrTarget'"
#		if [[ "${lstrTarget:0:1}" != "/" ]];then
#			lstrTarget="`pwd`/$lstrTarget"
#		fi
		bForceDirectory=false
		bTextFieldEditMode=false
		if [[ ! -a "$lstrTarget" ]];then
			if echoc -q "missing lstrTarget='$lstrTarget', is directory?";then
				bForceDirectory=true
			fi
			if echoc -q "as the file is missing, it is suggested that you edit using the '@s@yZenity Text Field@S' dialog, do it?";then
				bTextFieldEditMode=true
			fi
		fi
		strOptDirectory=""
		strOptLnDir=""
		if $bForceDirectory || [[ -d "$lstrTarget" ]];then
			strOptDirectory="--directory"
			strOptLnDir="-T"
			echo "Symlinking to directory."
		fi
		
		if ! $bTextFieldEditMode;then
			if echoc -t 15 -q "use TextField symlink edit mode?";then
				bTextFieldEditMode=true
			fi
		fi
		
		if $bTextFieldEditMode;then
			local lstrNewSymlink="`zenity \
				--title "$SECstrScriptSelfName" \
				--entry \
				--width=750 \
				--entry-text "\`readlink "$lstrFile"\`"`"
		else
			local lstrNewSymlink="`zenity \
				--title "$SECstrScriptSelfName" \
				--file-selection \
				$strOptDirectory \
				--filename=\"$lstrTarget\"`"
		fi
		
#		# in case user typed relative path
#		if [[ "${lstrNewSymlink:0:1}" != "/" ]];then
#			lstrNewSymlink="$lstrFilePath/$lstrNewSymlink"
#		fi
		
		cd "`dirname "$lstrFile"`"
		echoc -x pwd
		if [[ -a "$lstrNewSymlink" ]];then
			#echoc -x "rm -v '$lstrFile'"
			echoc -x "ln -vsfT $strOptLnDir '$lstrNewSymlink' '$lstrFile'"
		else
			echoc -p "invalid symlink target '$lstrNewSymlink'"
		fi
		echoc -w -t 60
	fi
};export -f FUNCretargetSymlink

cd "/tmp" #safe place as NAUTILUS_SCRIPT_SELECTED_FILE_PATHS has absolute path to selected file
#xterm -e "bash -i -c \"FUNCretargetSymlink '$strFile'\"" # -i required to force it work on ubuntu 12.10
#strTitle="${SECstrScriptSelfName}_pid$$"
#SECFUNCCwindowOnTop --delay 1 "${strTitle}.*"
#secXtermDetached.sh --ontop --title "${strTitle}" --skiporganize FUNCretargetSymlink "$strFile"
secXtermDetached.sh --ontop --title "${SECstrScriptSelfName}" --skiporganize FUNCretargetSymlink "$strFile"
#SECFUNCCwindowOnTop --stop "${strTitle}.*"
#secXtermDetached.sh --skiporganize --ontop FUNCretargetSymlink "$strFile"

