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

export astrFiles=()
if [[ -n "${NAUTILUS_SCRIPT_WINDOW_GEOMETRY-}" ]];then #from nautilus
	if [[ "$1" == "--execOnXterm" ]];then
		shift
		
		declare -p \
			NAUTILUS_SCRIPT_SELECTED_FILE_PATHS \
			NAUTILUS_SCRIPT_SELECTED_URIS \
			NAUTILUS_SCRIPT_CURRENT_URI \
			NAUTILUS_SCRIPT_WINDOW_GEOMETRY
			
		IFS=$'\n' read -d '' -r -a astrFiles < <(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS")&&:
	else
		#xterm -e "$0 --execOnXterm $@;echoc -w -t 61"
		secXtermDetached.sh --ontop -w 60 --title "`SECFUNCfixId --justfix "${SECstrScriptSelfName}"`" --skiporganize $0 --execOnXterm "$@"
		exit 0
	fi
else
	astrFiles=("$@") #not thru nautilus, but command line
fi
export strFile1st="${astrFiles[0]}"
if [[ "${strFile1st:0:1}" != "/" ]];then
	strFile1st="`pwd`/$strFile1st"
fi

echo "HELP: the first filename will provide the compressed filename prefix" >&2

########## WORK

cd "`dirname "${strFile1st}"`"
SECFUNCexecA -ce pwd # @RefLink:1

if [[ -f "${strFile1st}.7z" ]];then SECFUNCexecA -ce trash -v "${strFile1st}.7z";fi

SECFUNCexecA -ce 7z a "${strFile1st}.7z" "${astrFiles[@]}"
