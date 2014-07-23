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

bDetach=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then
		SECFUNCshowHelp -c "<command> [params for command] will exec the command with specified options"
		SECFUNCshowHelp -c "this expands on SECFUNCexec by also mixing old secDelayedExec and secXtermDetached"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--detach" || "$1" == "-d" ]];then
		bDetach=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bDetach;then
	echo "#TODO"
fi

