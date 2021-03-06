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

source <(secinit)

# nautilus passing params is strange, dont try to use them...
#while [[ -n "$1" ]]; do
#	echoc --info "$1"
#	shift
#done
#echoc --info "nautilus params: $@"

function FUNCdoIt() {
	secUpdateRemoteBackupFiles.sh #has builtin support to work with nautilus!
#	echoc -w 
};export -f FUNCdoIt
SECFUNCexecA -ce secXtermDetached.sh --ontop --title "`SECFUNCfixId --justfix -- "${SECstrScriptSelfName}"`" --skiporganize FUNCdoIt "$@" # it is OnTop because is a temporary xterm.
