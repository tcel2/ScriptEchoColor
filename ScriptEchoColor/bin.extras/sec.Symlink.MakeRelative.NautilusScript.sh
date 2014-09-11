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

function FUNCloop() {
	IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")
	for strFile in "${astrFiles[@]}";do 
		if ! FUNCmakeRelativeSymlink "$strFile";then # -i required to force it work on ubuntu 12.10
			echoc -p "failed to '$strFile'"
			break;
		fi
	done
	echoc -w -t 60
};export -f FUNCloop

function FUNCmakeRelativeSymlink() {
	local lstrFile="${1-}"
	if [[ ! -L "$lstrFile" ]];then
		zenity --info --text "File is not a symlink: '$lstrFile'"
	else
#		echoc --alert "TODO: this functionality is still limited to symlinks pointing to files at the same directory!!! "
		local lstrFullTarget="`readlink -f "$lstrFile"`"
		echo "lstrFullTarget='$lstrFullTarget'"
#		if [[ "${lstrFullTarget:0:1}" != "/" ]];then
#			echoc --info "Skipping: already relative symlink '$lstrFile' points to '$lstrFullTarget'."
#			return 0
#		fi
		local lstrDirname="`dirname "$lstrFullTarget"`" #the path can be symlinked, the lstrFullTarget will work ok when matching for lstrDirname removal
		echo "lstrDirname='$lstrDirname'"
#		local lstrNewSymlinkTarget="`basename "$lstrFullTarget"`"
#		local lstrNewSymlinkTarget="./${lstrFullTarget#$lstrDirname}"
		local lstrNewSymlinkTarget="${lstrFullTarget#$lstrDirname}"
		while [[ "${lstrNewSymlinkTarget:0:1}" == "/" ]];do
			lstrNewSymlinkTarget="${lstrNewSymlinkTarget:1}"
		done
		echo "lstrNewSymlinkTarget='$lstrNewSymlinkTarget'"
#		if [[ -a "`dirname "$lstrFile"`/$lstrNewSymlinkTarget" ]];then
		if [[ -a "$lstrDirname/$lstrNewSymlinkTarget" ]];then
			#echoc -x "rm -v '$lstrFile'"
			if ! echoc -x "ln -vsfT '$lstrNewSymlinkTarget' '$lstrFile'";then
				return 1
			fi
		else
#			zenity --info --text "Symlink '$lstrFile' points to missing file '$lstrNewSymlinkTarget'"
			echoc -p "unable to make symlink '$lstrFile' point to missing '$lstrNewSymlinkTarget'"
			return 1
		fi
	fi
	return 0
};export -f FUNCmakeRelativeSymlink

cd "/tmp" #NAUTILUS_SCRIPT_SELECTED_FILE_PATHS has absolute path to selected file
xterm -e "bash -i -c \"FUNCloop\"" # -i required to force it work
#for strFile in "${astrFiles[@]}";do 
#	if ! xterm -e "bash -i -c \"FUNCmakeRelativeSymlink '$strFile'\"";then # -i required to force it work on ubuntu 12.10
#		break;
#	fi
#done

