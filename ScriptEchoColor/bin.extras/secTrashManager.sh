#!/bin/bash
# Copyright (C) 2015-2016 by Henrique Abdalla
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

strTrashFolderUser="$HOME/.local/share/Trash/files/"
echo "strTrashFolderUser='$strTrashFolderUser'"
strTrashFolder=""
nFSSizeAvailGoalMB=1500 #1.5GB 
nFileCountPerStep=100
: ${nSleepDelay:=30}

function FUNCmountedFs(){
	df --output=target |tail -n +2 
	#|sed 's@.*@"&"@'
}

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
bTest=false
bDummyRun=false
strFilterRegex=""
bRunOnce=false
strChkTrashConsistencyFolder=false
#bTouchToDelDT=false
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo "Mounted FS (to use on filter):";FUNCmountedFs
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--goal" || "$1" == "-g" ]];then #help <nFSSizeAvailGoalMB> 
		shift
		nFSSizeAvailGoalMB="${1-}"
	elif [[ "$1" == "--step" || "$1" == "-s" ]];then #help <nFileCountPerStep> per check will work with this files count
		shift
		nFileCountPerStep="${1-}"
	elif [[ "$1" == "--test1" ]];then #help will work in one trashed file
		bTest=true
	elif [[ "$1" == "--chk" ]];then #help <strChkTrashConsistencyFolder> ~single check trashinfo consistency and exit
		shift
		strChkTrashConsistencyFolder="${1-}"
	elif [[ "$1" == "--dummy" ]];then #help ~debug will not remove the trashed files
		bDummyRun=true
	elif [[ "$1" == "--once" ]];then #help will run once and exit
		bRunOnce=true
	elif [[ "$1" == "--filter" ]];then #help <strRegex> will only work on the devices matching it
		shift
		strFilterRegex="${1-}"
#	elif [[ "$1" == "--touch" ]];then #help will touch all files at trash to their trashing datetime
#		bTouchToDelDT=true
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

#if $bTouchToDelDT;then
#	strTouchDT="`egrep "^DeletionDate=" "$strFile" |cut -d'=' -f2`"
#	exit 0
#fi

if [[ -d "$strChkTrashConsistencyFolder" ]];then
	cd "$strChkTrashConsistencyFolder/"
	FUNCchkTrashInfo(){ 
#		if [[ "$1" == "." ]];then return;fi
		strTrashInfoFile="../info/$1.trashinfo"; 
		if [[ ! -f "$strTrashInfoFile" ]];then 
			echo "MISSING: $strTrashInfoFile";
		else
			echo -ne "`date`: Still checking...\r"
		fi; 
	};export -f FUNCchkTrashInfo;
	find "./" -maxdepth 1 -not -iname "." -exec bash -c "FUNCchkTrashInfo '{}'" \;
	
	exit 0
fi

# Main code
if ! $bRunOnce;then
	SECFUNCuniqueLock --waitbecomedaemon
fi

function FUNCavailFS(){
	df -BM --output=avail "$strTrashFolder" |tail -n 1 |tr -d M
}

function FUNCrm(){
	local lOpt="$1";shift
	local lstrFile="$1";shift #or directory
	
	if ! [[ -L "$lstrFile" ]];then #TODO this may let a symlink outside of trash (by using ex.: ../../..) to be removed
		if [[ "$lstrFile" =~ .*[.][.].* ]];then
			lstrFile="`readlink -en "$lstrFile"`"
		fi
	fi
	
	#safety
	if ! [[ "$lstrFile" =~ [/].*[/][.]*Trash[-/].* ]];then
		echoc -p "invalid trash path: $lstrFile"
		exit 1
	fi
	
	if [[ ! -L "$lstrFile" ]];then
		if [[ -d "$lstrFile" ]];then
			if ! SECFUNCexecA -ce chmod -Rv +w "$lstrFile";then
				SECFUNCechoWarnA "failed to chmod at dir lstrFile='$lstrFile'"
			fi
		else
			if ! SECFUNCexecA -ce chmod -v +w "$lstrFile";then
				SECFUNCechoWarnA "failed to chmod at lstrFile='$lstrFile'"
			fi
		fi
	fi
	
	if ! SECFUNCexecA -ce rm -vf "$lOpt" "$lstrFile";then
		SECFUNCechoWarnA "failed to rm lstrFile='$lstrFile'"
	fi
}

while true;do
	IFS=$'\n' read -d '' -r -a astrMountedFSList < <(FUNCmountedFs)&&:
	astrMountedFSList+=("$strTrashFolderUser")
	for strMountedFS in "${astrMountedFSList[@]}";do
		if [[ -n "$strFilterRegex" ]];then
			if ! [[ "$strMountedFS" =~ $strFilterRegex ]];then continue;fi
		fi
		
		function FUNCcheckFS() {
			# Validations
			if [[ "$strMountedFS" == "$strTrashFolderUser" ]];then
				strTrashFolder="$strMountedFS"
			else
				strTrashFolder="$strMountedFS/.Trash-$UID/files/"
			fi
			SECFUNCdrawLine --left "=== Check: '$strTrashFolder' " "="
			if ! echo "$strTrashFolder" |grep -qi "trash";then 
				# minimal :( safety check ...
				SECFUNCechoWarnA "not a valid trash folder strTrashFolder='$strTrashFolder'"
				return 0 #continue;
			fi
	#		ls -ld "$strTrashFolder"&&:
			if [[ ! -d "$strTrashFolder" ]];then return 0;fi #continue;fi
		
			SECFUNCexecA -ce cd "$strTrashFolder"
			nTrashSizeMB="`du -BM -s ./ |cut -d'M' -f1`"
			echoc --info "Available `FUNCavailFS`MB,nFSSizeAvailGoalMB='$nFSSizeAvailGoalMB',nTrashSizeMB='$nTrashSizeMB',strTrashFolder='$strTrashFolder'"
			if((nTrashSizeMB==0));then return 0;fi #continue;fi
		
			# Remove files
			if $bTest || ((`FUNCavailFS`<nFSSizeAvailGoalMB));then
	#			nTrashSizeMB="`du -sh ./ |cut -d'M' -f1`"
	#			echoc --info "nTrashSizeMB='$nTrashSizeMB'"
			
				if false;then # BAD.. will not consider the file trashing time...
					IFS=$'\n' read -d '' -r -a astrEntryList < <( \
						find "./" -type f -printf '%T+\t%p\n' \
							|sort \
							|head -n $nFileCountPerStep)&&:
				fi
				if false;then # BAD... too many files on the list, will fail cmd param size limit...
					IFS=$'\n' read -d '' -r -a astrEntryList < <( \
						egrep "^DeletionDate=" -H ../info/*.trashinfo \
							|sed -r 's"(.*).trashinfo:DeletionDate=(.*)"\2\t\1"' \
							|sort \
							|head -n $nFileCountPerStep)&&:
				fi
				if false;then # Good and precise but too slow if there are too many files...
					IFS=$'\n' read -d '' -r -a astrEntryList < <( \
						find "../info/" -iname "*.trashinfo" -exec egrep "^DeletionDate=" -H '{}' \; \
							|sed -r 's"^[.][.]/info/(.*).trashinfo:DeletionDate=(.*)"\2\t\1"' \
							|sort \
							|head -n $nFileCountPerStep)&&:
				fi
				# This will use the trashinfo file datetime as reference! probably 100% precise!
				# A token '&' is used to help on precisely parsing the `ls` output making it usable with `cut`.
				IFS=$'\n' read -d '' -r -a astrEntryList < <( \
					ls -ltr --time-style='+&%Y%m%d+%H%M%S.%N' "../info/" \
						|head -n $((nFileCountPerStep+1)) \
						|tail -n +2 \
						|sed -r -e 's"^[^&]*&([^[:blank:]]*)[[:blank:]]*(.*)"\1\t\2"' -e 's".trashinfo$""' )&&:
	#			# `tail` +2 to skip total line. `sed` to convert 1st space to tab making it usable with `cut`
	#			IFS=$'\n' read -d '' -r -a astrEntryList < <( \
	#				ls -ltr --time-style='+%Y%m%d+%H%M%S.%N' "../info/" \
	#					|tail -n +2 \
	#					|head -n $nFileCountPerStep \
	#					|cut -d' ' -f6- \
	#					|sed -r -e 's" "\t"' -e 's".trashinfo$""' )&&:
	#			IFS=$'\n' read -d '' -r -a astrEntryList < <( \
	#				ls -ltr --time-style=full-iso "../info/" \
	#					|tail -n +2 \
	#					|head -n $nFileCountPerStep \
	#					|cut -d' ' -f6-7,9- \
	#					|sed -r -e 's" "+"' -e 's" "\t"' -e 's".trashinfo$""' )&&:
			
				if((`SECFUNCarraySize astrEntryList`>0));then
					nRmCount=0
					nRmSizeTotalB=0
					nAvailSizeB4RmB=$((`FUNCavailFS`*1000000))&&: # from M to B
					# has date and filename
					for strEntry in "${astrEntryList[@]}";do
						strFileDT="`echo "$strEntry" |cut -f1`"
						strFile="`echo "$strEntry" |cut -f2`"
	#					echo "strEntry='$strEntry',strFileDT='$strFileDT',strFile='$strFile',"
					
						bDirectory=false
						if [[ -d "$strFile" ]];then 
							bDirectory=true
	#						SECFUNCechoWarnA "Directories are not supported yet '$strFile'" #TODO remove directories?
	#						continue
						elif [[ -L "$strFile" ]];then 
							: # symbolic links are ok
						elif [[ ! -f "$strFile" ]];then 
							# delete the trashinfo file for a missing trashed file
							SECFUNCechoWarnA "Missing real file strFile='$strFile', removing trashinfo for it."
							if ! $bDummyRun;then
								FUNCrm -vf "/$strTrashFolder/../info/${strFile}.trashinfo"&&:
							fi
							continue; 
						fi 
					
						if $bDirectory;then
							nFileSizeB="`du -bs "./$strFile/" |cut -f1`"
						else
							nFileSizeB="`stat -c "%s" "./$strFile"`"
						fi
						nFileSizeMB=$((nFileSizeB/(1024*1024)))&&:
						((nRmCount++))&&:
					
						strReport=""
						strReport+="nRmCount='$nRmCount',"
						strReport+="strFile='$strFile',"
						strReport+="nFileSizeB='$nFileSizeB',"
						strReport+="strFileDT='$strFileDT',"
						strReport+="AvailMB='`FUNCavailFS`',"
						strReport+="(prev)nRmSizeTotalB='$nRmSizeTotalB',"
						echo "$strReport"
					
						if ! $bDummyRun;then
							if ! $bDirectory;then
								# extra security on removing a file, will use it's full path, therefore surely inside of trash folder
								FUNCrm -vf "/$strTrashFolder/$strFile"
							else
								# removes directory recursively
								FUNCrm -rvf "/$strTrashFolder/$strFile/"
							fi
							FUNCrm -vf "/$strTrashFolder/../info/${strFile}.trashinfo"&&:
						fi
					
						((nRmSizeTotalB+=nFileSizeB))&&:
				
						if $bTest;then break;fi # to work at only with one file
						# FS seems to not get updated so fast, so this fails:	if ((`FUNCavailFS`>nFSSizeAvailGoalMB));then
						if (( (nAvailSizeB4RmB+nRmSizeTotalB) > (nFSSizeAvailGoalMB*1000000) ));then
							break;
						fi
					done
				else
					echoc --info "trash is empty"
				fi
			fi
			
			return 0
		};export -f FUNCcheckFS
		(FUNCcheckFS) # to make the "pid using FS detection system" unlink with this script
		
		#if $bTest;then break;fi # to work at only the user default trash folder
		
	done

	if $bRunOnce;then break;fi
	
	echoc -w -t $nSleepDelay
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


#IFS=$'\n' read -d '' -r -a astrTrashList < <(mount |sed -r 's".* on (.*) type .*"\1/.Trash-$UID"' |sort)&&:

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

