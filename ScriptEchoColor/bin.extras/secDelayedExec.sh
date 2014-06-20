#!/bin/bash
# Copyright (C) 2013-2014 by Henrique Abdalla
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

#TODO check at `info at` if the `at` command can replace this script?

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then
		echo "<delay> <command> <params>..."
		echo "Sleep for delay time before executing the command with its params."
		exit
	#elif [[ "$1" == "--help" ]];then
	else
		echo "invalid option '$1'" >>/dev/stderr
	fi
	shift
done

nDelay="$1"
if [[ -z "$nDelay" ]] || [[ -n "`echo "$nDelay" |tr -d "[:digit:]"`" ]];then
	echo "invalid nDelay='$nDelay'" >>/dev/stderr
	exit 1
fi

shift

if [[ -z "$@" ]];then
	echo "invalid command '$@'" >>/dev/stderr
	exit 1
fi

sleep $nDelay

echo " -> `date "+%Y%m%d+%H%M%S.%N"`;nDelay='$nDelay';$@" >>"/tmp/.`basename "$0"`.`SECFUNCgetUserName`.log"

"$@"

