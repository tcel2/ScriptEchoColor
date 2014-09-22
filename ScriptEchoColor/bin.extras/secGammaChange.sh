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

bUp=false
bDown=false
fStep=0.25
bReset=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "up or down gamma"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--up" ]];then #help
		bUp=true
	elif [[ "$1" == "--down" ]];then #help
		bDown=true
	elif [[ "$1" == "--step" ]];then #help the float step ammount when changing gamma
		shift
		fStep="${1-}"
	elif [[ "$1" == "--reset" ]];then #help gamma 1.0
		bReset=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bReset;then
	xgamma -gamma 1
	exit
fi

if ! SECFUNCisNumber -n "${fStep}";then
	echoc -p "invalid fStep='$fStep'"
	exit 1
fi

fCurrentGamma="`xgamma 2>&1 |awk '{print $3}' |sed -r 's"(.*),"\1"'`";

strOperation="+"
if $bDown;then
	strOperation="-"
fi

fNewGamma="`SECFUNCbcPrettyCalc "${fCurrentGamma}${strOperation}${fStep}"`"
xgamma -gamma "$fNewGamma"

