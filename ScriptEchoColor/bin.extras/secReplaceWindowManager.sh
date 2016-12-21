#!/bin/bash
# Copyright (C) 2004-2016 by Henrique Abdalla
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

#TODO check if jwm has --replace like feature
strPreferedWM="" 
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Recovers window manager after crash, and helps easily replacing them."
		SECFUNCshowHelp --colorize "The default auto-recovery window manager option (if not set) is the last detected. If none is detected, prefers in this order: compiz, metacity, xfwm4 (will check if they are installed)"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--compiz" || "$1" == "-c" ]];then #help force compiz the default auto recovery option
		strPreferedWM="compiz"
	elif [[ "$1" == "--metacity" || "$1" == "-m" ]];then #help force metacity the default auto recovery option
		strPreferedWM="metacity"
	elif [[ "$1" == "--xfwm4" || "$1" == "-x" ]];then #help force xfwm4 the default auto recovery option
		strPreferedWM="xfwm4"
#	elif [[ "$1" == "--jwm" || "$1" == "-j" ]];then #help force jwm the default auto recovery option
#		strPreferedWM="jwm"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift&&:
done

if [[ -n "$strPreferedWM" ]];then
	FUNCcheckGetPreferedWm "$strPreferedWM"
fi

SECFUNCuniqueLock --daemonwait

function FUNCcheckGetPreferedWm() {
	local lstrCheck="${1-}"
	local lbFail=false
	local lstrPreferedWM=""
	
	if [[ -n "$lstrCheck" ]];then
		if which "$lstrCheck" 2>&1 >>/dev/null;then
			lstrPreferedWM="$lstrCheck"
		else
			lbFail=true
		fi
	fi
	
	if   which compiz 2>&1 >>/dev/null;then
		lstrPreferedWM="compiz"
	elif which metacity 2>&1 >>/dev/null;then
		lstrPreferedWM="metacity"
	elif which xfwm4 2>&1 >>/dev/null;then
		lstrPreferedWM="xfwm4"
#	elif which jwm 2>&1 >>/dev/null;then
#		lstrPreferedWM="jwm"
	else
		lbFail=true
	fi
	
	if $lbFail;then
		echoc -p "no supported windowmanager available"
		echoc -w "exiting"
		exit 1
	fi
	
	echo "$lstrPreferedWM"
}

strCurrent=""
while true;do
	# check current
	if pgrep compiz 2>&1 >>/dev/null;then
		strCurrent="compiz"
	elif pgrep metacity 2>&1 >>/dev/null;then
		strCurrent="metacity"
	elif pgrep xfwm4 2>&1 >>/dev/null;then
		strCurrent="xfwm4"
#	elif pgrep jwm 2>&1 >>/dev/null;then
#		strCurrent="jwm"
	else
		strCurrent=""
	fi
	
	# set prefered window manager
	if [[ -z "$strPreferedWM" ]];then
		if [[ -n "$strCurrent" ]];then
			strPreferedWM="$strCurrent"
		else
			strPreferedWM=`FUNCcheckGetPreferedWm`
		fi
	fi
	
	echoc --info "strPreferedWM='$strPreferedWM'"
	
	if [[ -z "$strCurrent" ]];then #mainly for crash recovery
		SECFUNCexecA -ce $strPreferedWM --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
		continue;
	fi
	
	echoc -t 10 -Q "replace window manager@O_compiz/_metacity/_xfwm4/holdFor_60s"&&:;
	case "`secascii $?`" in 
		c)
			if [[ "$strCurrent" == "compiz" ]];then
				secFixWindow.sh --fixcompiz #this safely replaces compiz
			else
				SECFUNCexecA -ce secXtermDetached.sh compiz --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			fi
			strPreferedWM="compiz"
			;; 
		m)
			SECFUNCexecA -ce secXtermDetached.sh metacity --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="metacity"
			;; 
		x)
			SECFUNCexecA -ce secXtermDetached.sh xfwm4 --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="xfwm4"
			;; 
		6)
			echoc -w -t 60 "holding execution"
			;;
	esac
	
#	if [[ "$strCurrent" != "metacity" ]];then
#		if echoc -q -t 10 "replace with metacity?";then
#			SECFUNCexecA -ce metacity --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
#			strPreferedWM="metacity"
#			continue;
#		fi
#	fi

#	if [[ "$strCurrent" != "compiz" ]];then
#		if echoc -q -t 10 "replace with compiz?";then
#			SECFUNCexecA -ce compiz --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
#			strPreferedWM="compiz"
#			continue;
#		fi
#	fi
	
	echoc -w -t 3
done

