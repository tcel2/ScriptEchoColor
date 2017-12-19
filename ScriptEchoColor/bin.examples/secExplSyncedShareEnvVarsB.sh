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

source <(secinit) #auto creates the DB based on script pid

pidOtherScript=`ps -A -o pid,command |grep "secExplSyncedShareEnvVarsA.sh" |grep -v grep |sed -r 's"^[ ]*([[:digit:]]*) .*"\1"'`
varsetdb $pidOtherScript #changes the auto created DB to be the other script DB

#varset varA=10; #do not set it here; Script A is the main one.
#varset varPid=$$ #do not set it here; Script A is the main one.

while true; do 
	varsyncwrdb; 
	if(($$==varPid));then
		pidThatSet="SELF"
	else
		pidThatSet=$varPid
	fi
	echo "[`SECFUNCdtFmt --pretty`] this pid is $$ (exec count ${SECmultiThreadEvenPids[$$]}); $varA was set by pid $pidThatSet; next varA=$((++varA)) set by SELF.";
	varPid=$$;
done

