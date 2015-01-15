#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

SECFUNCuniqueLock --daemonwait

strCurrent=""
while true;do
	if pgrep compiz;then
		strCurrent="compiz"
	elif pgrep metacity;then
		strCurrent="metacity"
	else
		strCurrent=""
	fi
	
	if [[ -z "$strCurrent" ]];then
		metacity --replace >>/dev/stderr & disown # stdout must be redirected or the terminal wont let it be disowned...
		continue;
	fi
	
	if [[ "$strCurrent" != "metacity" ]];then
		if echoc -q -t 10 "replace with metacity?";then
			metacity --replace >>/dev/stderr & disown # stdout must be redirected or the terminal wont let it be disowned...
			continue;
		fi
	fi

	if [[ "$strCurrent" != "compiz" ]];then
		if echoc -q -t 10 "replace with compiz?";then
			compiz --replace >>/dev/stderr & disown # stdout must be redirected or the terminal wont let it be disowned...
			continue;
		fi
	fi
	
done

