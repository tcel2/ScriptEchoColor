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

eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed 's".*"\"&\""'`)
strFile="${astrFiles[0]}"

#xterm -e "bash -i -c \"echo '$strFile';read\"";exit

function FUNCrenameSymlink() {
	local lstrFile="${1-}"
	if [[ ! -L "$lstrFile" ]];then
		zenity --info --text "File is not a symlink: '$lstrFile'"
	else
		strNewSymlink="`zenity --entry --entry-text "\`readlink "$lstrFile"\`"`"
		echoc -x "rm -v '$lstrFile'"
		echoc -x "ln -sv '$strNewSymlink' '$lstrFile'"
		echoc -w -t 60
	fi
};export -f FUNCrenameSymlink

cd "/tmp" #NAUTILUS_SCRIPT_SELECTED_FILE_PATHS has absolute path to selected file
xterm -e "bash -i -c \"FUNCrenameSymlink '$strFile'\"" # -i required to force it work on ubuntu 12.10

