#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

if [[ -z "${1-}" ]];then #main loop
	while true;do
		echo $SECONDS
		SECFUNCsyncStopContinue -hp
		sleep 1
	done
elif [[ "$1" == "stop" ]];then
	SECFUNCsyncStopContinue -sp
elif [[ "$1" == "cont" ]];then
	SECFUNCsyncStopContinue -cp
elif [[ "$1" == "--help" ]];then
	echo "run without params to start the main loop."
	echo "open another terminal and call this script as: $0 stop"
	echo "at the other terminal call this script as: $0 cont"
fi

