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

strId="FancyWork"
if [[ "$1" == "request" ]];then
	SECFUNCsimpleSyncRequest -rwp "$strId"
elif [[ "$1" == "requestnowait" ]];then
	SECFUNCsimpleSyncRequest -rp "$strId"
elif [[ "$1" == "listen" ]];then
	nSpeep=20
	while true;do
		SECFUNCsimpleSyncRequest -lwp "$strId"
		echo "Expl: (NL)"
		echo "Expl: request accepted at ${SECONDS}s, performing $strId, pseudo working (actually sleeping ${nSpeep}s)..."
		sleep $nSpeep
	done
elif [[ "$1" == "listenstack" ]];then
	nSpeep=20
	while true;do
		SECFUNCsimpleSyncRequest --stack -lwp "$strId"
		echo "Expl: (NL)"
		echo "Expl: request accepted at ${SECONDS}s, performing $strId, pseudo working (actually sleeping ${nSpeep}s)..."
		sleep $nSpeep
	done
elif [[ "$1" == "--help" ]];then
	echo "run as: $0 listen"
	echo "at several other terminals run: $0 request|requestnowait (they will not stack, the 1st will be accepted and others dropped)"
	echo "To test a stack of requests, run as: $0 listenstack"
fi

