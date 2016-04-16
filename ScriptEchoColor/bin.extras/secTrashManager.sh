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

strTrashFolder="$HOME/.local/share/Trash/files/"
nFSSizeAvailGoalMB=1000 #1GB
nFileCountPerStep=100

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
bTest=false
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--goal" || "$1" == "-g" ]];then #help <nFSSizeAvailGoalMB> 
		shift
		nFSSizeAvailGoalMB="${1-}"
	elif [[ "$1" == "--step" || "$1" == "-s" ]];then #help <nFileCountPerStep> per check will work with this files count
		shift
		nFileCountPerStep="${1-}"
	elif [[ "$1" == "--test" || "$1" == "-t" ]];then #help <strExample> MISSING DESCRIPTION
#		shift
#		strExample="${1-}"
		bTest=true
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
if ! SECFUNCisNumber -dn $nFSSizeAvailGoalMB || ((nFSSizeAvailGoalMB<=0));then
	echoc -p "invalid nFSSizeAvailGoalMB='$nFSSizeAvailGoalMB'"
	exit 1
fi

if ! SECFUNCisNumber -dn $nFileCountPerStep || ((nFileCountPerStep<=0));then
	echoc -p "invalid nFileCountPerStep='$nFileCountPerStep'"
	exit 1
fi

SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code

function FUNCavailFS(){
	df -BM --output=avail "$strTrashFolder" |tail -n 1 |tr -d M
}

SECFUNCexecA -ce cd "$strTrashFolder"
while true;do
	echo "Available `FUNCavailFS`MB, nFSSizeAvailGoalMB='$nFSSizeAvailGoalMB'"
	if $bTest || ((`FUNCavailFS`<nFSSizeAvailGoalMB));then
		nTrashSize="`du -sh ./ |cut -d'M' -f1`"
		echoc --info "nTrashSize='$nTrashSize'"
		
		IFS=$'\n' read -d '' -r -a astrEntryList < <( \
			find "./" -type f -printf '%T+\t%p\n' \
				|sort \
				|head -n $nFileCountPerStep)&&:
		
		if((`SECFUNCarraySize astrEntryList`>0));then
			nRmCount=0
			# has date and filename
			for strEntry in "${astrEntryList[@]}";do
				strFile="`echo "$strEntry" |cut -f2`"
				nFileSizeB="`stat -c "%s" "$strFile"`"
				nFileSizeMB=$((nFileSizeB/(1024*1024)))&&:
				((nRmCount++))&&:
				
				echo "nRmCount='$nRmCount',strFile='$strFile',nFileSizeB='$nFileSizeB',AvailMB='`FUNCavailFS`'"
			
				rm -vf "$strFile"&&:
				
				if $bTest || ((`FUNCavailFS`>nFSSizeAvailGoalMB));then
					break;
				fi
			done
		else
			echoc --info "trash is empty"
		fi
	fi
	
	echoc -w -t 60
done		

#echoc --alert "work in progress..."

#declare -A astrTrashGoals
#while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
#	SECFUNCsingleLetterOptionsA;
#	if [[ "$1" == "--help" ]];then #help
#		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
#		SECFUNCshowHelp
#		exit 0
#	elif [[ "$1" == "--freespacegoal" || "$1" == "-f" ]];then #help <strTrashPath> <nSizeInMegabytes> define, for each possibly mounted trash, a minimum free space
#		shift;strTrashPath="${1-}"
#		if [[ ! -d "$strTrashPath" ]];then echoc -p "invalid strTrashPath='$strTrashPath'";exit 1;fi
#		shift;nSizeInMegabytes="${1-}"
#		if ! SECFUNCisNumber -dn "$nSizeInMegabytes";then echoc -p "invalid nSizeInMegabytes='$nSizeInMegabytes'";exit 1;fi
#		astrTrashGoals[$strTrashPath]=$nSizeInMegabytes
#	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
#		shift
#		break
#	else
#		echoc -p "invalid option '$1'"
#		$0 --help
#		exit 1
#	fi
#	shift
#done


#IFS=$'\n' read -d '' -r -a astrTrashList < <(mount |sed -r 's".* on (.*) type .*"\1/.Trash-1000"' |sort)&&:

#nTot=${#astrTrashList[@]}
##echo "DEBUG: tot $nTot"
#for((i=0;i<nTot;i++));do 
#	strTrash="${astrTrashList[i]}"; 
#	if [[ -d "$strTrash" ]];then 
#		echoc --info "found: $strTrash";
#	else 
##		echo "DEBUG: unsetting $i ${astrTrashList[i]} "
#		unset astrTrashList[i];
#	fi;
#done;

#for strTrash in "${astrTrashList[@]}";do 
#	nSizeGoal="${astrTrashGoals[$strTrash]-}"
#	if [[ -n "$nSizeGoal" ]];then
#		echoc --info "working with: $strTrash, current free space:, goal:${nSizeGoal}MB" 
#	else
#		echoc --info "no goal defined for: $strTrash"
#	fi
#done

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

