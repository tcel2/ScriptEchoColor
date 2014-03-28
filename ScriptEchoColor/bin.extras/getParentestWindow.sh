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

function FUNCparent() {
	xwininfo -tree -id $1 |grep "Parent window id"
};export -f FUNCparent

function FUNCparentest() {
	echo "windowid is: $1" >&2
	if [[ -z "$1" ]]; then
		echoc -p "FUNCparentest missing windowId"
		exit 1
	fi
	
	local check=`printf %d $1`
	local parent=-1
	local parentest=-1
	
	while ! FUNCparent $check |grep -q "(the root window)"; do
		echo "Child is: $check" >&2
	  #echo "a $check" >&2 #DEBUG info
		xwininfo -id $check |grep "Window id" >&2 #report
		parent=`FUNCparent $check |egrep -o "0x[^ ]* "`
		parent=`printf %d $parent`
		check=$parent
		#echoc -w -t 1
		echo "Parent is: $parent" >&2
	done
	if((parent!=-1));then
		parentest=$parent
	fi
	echo "Parentest is: $parentest" >&2
	
	if((parentest!=-1));then
		echo $parentest
		#echo "Parentest is: $check" >&2
	else
		echo $1
		#echo "Child has no parent." >&2
	fi
};export -f FUNCparentest

FUNCparentest $1

