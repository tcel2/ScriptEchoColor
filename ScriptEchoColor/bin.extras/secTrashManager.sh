#!/bin/bash
# Copyright (C) 2015 by Henrique Abdalla
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

echoc --alert "work in progress..."

declare -A astrTrashGoals
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--freespacegoal" || "$1" == "-f" ]];then #help <strTrashPath> <nSizeInMegabytes> define, for each possibly mounted trash, a minimum free space
		shift;strTrashPath="${1-}"
		if [[ ! -d "$strTrashPath" ]];then echoc -p "invalid strTrashPath='$strTrashPath'";exit 1;fi
		shift;nSizeInMegabytes="${1-}"
		if ! SECFUNCisNumber -dn "$nSizeInMegabytes";then echoc -p "invalid nSizeInMegabytes='$nSizeInMegabytes'";exit 1;fi
		astrTrashGoals[$strTrashPath]=$nSizeInMegabytes
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift
done


IFS=$'\n' read -d '' -r -a astrTrashList < <(mount |sed -r 's".* on (.*) type .*"\1/.Trash-1000"' |sort)&&:

nTot=${#astrTrashList[@]}
#echo "DEBUG: tot $nTot"
for((i=0;i<nTot;i++));do 
	strTrash="${astrTrashList[i]}"; 
	if [[ -d "$strTrash" ]];then 
		echoc --info "found: $strTrash";
	else 
#		echo "DEBUG: unsetting $i ${astrTrashList[i]} "
		unset astrTrashList[i];
	fi;
done;

for strTrash in "${astrTrashList[@]}";do 
	nSizeGoal="${astrTrashGoals[$strTrash]-}"
	if [[ -n "$nSizeGoal" ]];then
		echoc --info "working with: $strTrash, current free space:, goal:${nSizeGoal}MB" 
	else
		echoc --info "no goal defined for: $strTrash"
	fi
done

