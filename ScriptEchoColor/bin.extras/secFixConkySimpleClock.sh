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

eval `secinit --extras`

bCreateClock=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "makes Conky Simple Clock work better"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--createconfig" || "$1" == "-c" ]];then #help create/replace the simple clock config, modify it as you like
		bCreateClock=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bCreateClock;then
	strPath="$HOME/.conky/SimpleDateTimeClock"
	SECFUNCexecA --echo -c mkdir -vp "$strPath"
	cd "$strPath"
	SECFUNCexecA --echo -c pwd
	SECFUNCexecA --echo -c mv -vf SimpleDatetimeClock.cfg "SimpleDatetimeClock.cfg.`SECFUNCdtFmt --filename`.bkp"&&:
	echo 'use_xft yes
xftfont Sans:style=Bold:size=10
own_window yes
own_window_title Conky - SimpleDatetimeClock
own_window_hints undecorated,above,sticky,skip_taskbar,skip_pager
own_window_colour darkblue
gap_x 10
gap_y 30
alignment top_right

# with date shell command: ${color grey}${execi 1 date +"%d %b"}${color yellow}${execi 1 date +" %H:%M"}${color grey}${execi 1 date +":%S"}
# beggin of current clipboard entry: ${color darkgrey}${execi 3 bash -c '"'"'nWidth=50;printf "%-${nWidth}s\n" "`xclip -o -selection clipboard |head -n 1 |cut -c1-${nWidth}`"'"'"'}

TEXT
${color darkgrey}${time %a}${color lightgrey}${time %d}${color darkgrey}${time %b}${color yellow}${time %H}${color cyan}${time %M}${color darkgrey}${time %S}' >SimpleDatetimeClock.cfg
	SECFUNCexecA --echo -c cat SimpleDatetimeClock.cfg
	echoc --info "now you can run Conky Manager to easily activate it on startup"
	exit 0
fi

SECFUNCuniqueLock --waitbecomedaemon

while true; do
	if [[ "`xdotool getwindowname $(xdotool getactivewindow)`" == "Yakuake" ]];then
		echo "activate conky simple clock"
		if ! xdotool windowactivate `xdotool search "Conky - SimpleDatetimeClock"`;then
			echo "failed..."
		fi
	else
		echo "waiting yakuake focus"
	fi
	
	if SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	sleep 3;
done
