#!/bin/bash
# Copyright (C) 2015-2018 by Henrique Abdalla
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

source <(secinit)

strTrashFolderUser="`realpath -ezs "$HOME/.local/share/Trash/files/"`"
declare -p strTrashFolderUser
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
bTest1=false
bDummyRun=false
strFilterRegex=""
bRunOnce=false
strChkTrashConsistencyFolder=false
#bTouchToDelDT=false
SECFUNCcfgReadDB #after default variables value setup above
bAskedCustomGoal=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\tIt will respect asked goal if has filter and on run once mode."
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo "#TODO use \`trash-rm\` one day."
		echo "Mounted FS (to use on filter):";FUNCmountedFs
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--goal" || "$1" == "-g" ]];then #help <nFSSizeAvailGoalMB> 
		shift
		nFSSizeAvailGoalMB="${1-}"
		bAskedCustomGoal=true
	elif [[ "$1" == "--step" || "$1" == "-s" ]];then #help <nFileCountPerStep> per check will work with this files count
		shift
		nFileCountPerStep="${1-}"
	elif [[ "$1" == "--test1" ]];then #help will work in one trashed file
		bTest1=true
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

n1MB=$((1024**2))

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

#~ function FUNCavailFS(){
	#~ df -BM --output=avail "$strTrashFolder" |tail -n 1 |tr -d M
#~ }
function FUNCavailMB(){ #help <strTrashFolder>
	local lstrTrashFolder="$1"
	df -BM --output=avail "$lstrTrashFolder" |tail -n 1 |tr -d M
}

function _FUNCrm_deprecated(){
  SECFUNCdbgFuncInA
	local lstrFile="$1";shift #or directory
	
  if [[ ! -a "$lstrFile" ]];then
		SECFUNCechoWarnA "file already does not exist lstrFile='$lstrFile', skipping..." # user may have deleted manually b4 this script
    SECFUNCdbgFuncOutA;return 0;
  fi
  
  if [[ ! -L "$lstrFile" ]];then
    local lstrChkCanonical="`realpath -ezs "$lstrFile"`" # despite not being a symlink, the param must match a canonical file
    if [[ "$lstrFile" != "$lstrChkCanonical" ]];then
      SECFUNCechoErrA "filename param should be the canonical file '$lstrFile'!='$lstrChkCanonical' ?"
      SECFUNCdbgFuncOutA;return 1; 
    fi
  fi
  
	if [[ "$lstrFile" =~ .*/[.][.]/.* ]];then
    SECFUNCechoErrA "filename param must not contain '..' to remain inside the Trash lstrFile='$lstrFile'"
    SECFUNCdbgFuncOutA;return 1; 
	fi
	
  if ! [[ "$lstrFile" =~ [/].*[/][.]*Trash[-/].* ]];then
    SECFUNCechoErrA "not inside a Trash path: lstrFile='$lstrFile'"
    SECFUNCdbgFuncOutA;return 1
  fi
	
	if [[ ! -L "$lstrFile" ]];then # CHMOD only real files and paths not symlinks
		if [[ -d "$lstrFile" ]];then
			if ! SECFUNCexecA -ce chmod -Rc +w "$lstrFile";then
				SECFUNCechoWarnA "failed to chmod at dir lstrFile='$lstrFile'"
			fi
		else
			if ! SECFUNCexecA -ce chmod -c +w "$lstrFile";then
				SECFUNCechoWarnA "failed to chmod at lstrFile='$lstrFile'"
			fi
		fi
	fi
	
  strRmOpt="-vf"
	if [[ ! -L "$lstrFile" ]];then # !!! for recursiveness on directory, MUST NOT BE SYMLINK !!!
    if [[ -d "$lstrFile" ]]; then strRmOpt+="r";fi
  fi
	if ! SECFUNCexecA -ce rm $strRmOpt --one-file-system --preserve-root "$lstrFile";then # THE REMOVAL
		SECFUNCechoWarnA "failed to rm lstrFile='$lstrFile'"
	fi
  
  SECFUNCdbgFuncOutA;return 0;
}

strRmLog="$SECstrUserScriptCfgPath/rm.log"
mv -vf "${strRmLog}.2" "${strRmLog}.3"&&: # these are to keep logs for old runs but not eternally.
mv -vf "${strRmLog}.1" "${strRmLog}.2"&&:
mv -vf "${strRmLog}"   "${strRmLog}.1"&&:
mkdir -vp "`dirname "${strRmLog}"`"
#echo -n >"${strRmLog}" #just create it to make `tee -a` work
strRmLogTmp="`mktemp`"
while true;do
	IFS=$'\n' read -d '' -r -a astrMountedFSList < <(FUNCmountedFs)&&:
	astrMountedFSList+=("$strTrashFolderUser")
	for strMountedFS in "${astrMountedFSList[@]}";do
		if [[ -n "$strFilterRegex" ]];then
			if ! [[ "$strMountedFS" =~ $strFilterRegex ]];then continue;fi
		fi
		
		function FUNCcheckFS() {
      SECFUNCdbgFuncInA
      
			# Validations
			if [[ "$strMountedFS" == "$strTrashFolderUser" ]];then
				strTrashFolder="$strMountedFS"
			else
				strTrashFolder="$strMountedFS/.Trash-$UID/files/"
			fi
			SECFUNCdrawLine --left "=== Check: '$strTrashFolder' " "="
			if ! echo "$strTrashFolder" |grep -qi "trash";then 
				# minimal dumb :( safety check ...
				SECFUNCechoWarnA "not a valid trash folder strTrashFolder='$strTrashFolder'"
				SECFUNCdbgFuncOutA;return 0 #continue;
			fi
	#		ls -ld "$strTrashFolder"&&:
			if [[ ! -d "$strTrashFolder" ]];then SECFUNCdbgFuncOutA;return 0;fi #continue;fi
			strTrashFolder="`realpath -ezs "$strTrashFolder"`"
      declare -p strTrashFolder
		
			SECFUNCexecA -ce cd "$strTrashFolder" ################## AT TRASH FOLDER
			
			nFSTotalSizeMB="`df --block-size=1MiB --output=size . |tail -n 1 |awk '{print $1}'`"
			nGoal5Perc=$((nFSTotalSizeMB/20)) # goal as 5% of FS total size
			nThisFSAvailGoalMB=$nFSSizeAvailGoalMB
			if $bRunOnce && $bAskedCustomGoal && [[ -n "$strFilterRegex" ]];then
				echoc --info "Special condition: has filter, is run once, asked custom goal. Will keep the specified goal for these conditions"
			else
				if((nGoal5Perc<nThisFSAvailGoalMB));then
					nThisFSAvailGoalMB=$nGoal5Perc
					echoc --info "Using 5% goal"
				fi
			fi
#			if [[ -z "$strFilterRegex" ]] && ! $bRunOnce && ((nGoal5Perc<nThisFSAvailGoalMB));then
#			if((nGoal5Perc<nThisFSAvailGoalMB));then
#				nThisFSAvailGoalMB=$nGoal5Perc
#			fi
			
			nTrashSizeMB="`du -BM -s ./ |cut -d'M' -f1`"
			nAvailMB="`FUNCavailMB "$strTrashFolder"`"
			echoc --info "nAvailMB=${nAvailMB},nThisFSAvailGoalMB='$nThisFSAvailGoalMB',nTrashSizeMB='$nTrashSizeMB',strTrashFolder='$strTrashFolder'"
			if((nTrashSizeMB==0));then SECFUNCdbgFuncOutA;return 0;fi #continue;fi
			
			# Remove files
			if $bTest1 || ((${nAvailMB}<nThisFSAvailGoalMB));then
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
				#####
				## It has to be `ls` because it sorts by datetime! TODO `find` cant do it too?
				## This will use the trashinfo file datetime as reference, probably 100% precise! 
				## `grep` is important to make it sure it will remove really trashed files by it's info that ends with '.trashinfo' !!!!!!!!
				## A token '&' is used to help on precisely parsing the `ls` output making it easier to be used with `sed`.
				#####
        while true;do
          astrHexaChars=(`egrep -oh "%.." ../info/*.trashinfo |sed 's"%"0x"'`)&&:
          bAllOk=true
          if((`SECFUNCarraySize astrHexaChars`>0));then
            for strHexa in "${astrHexaChars[@]}";do 
              if((strHexa>=0x20 && strHexa<=0x7E));then 
                :
              else
                bAllOk=false
              fi;
            done
          fi
          
          if $bAllOk;then 
            break;
          else
            echoc --alert "invalid filenames!!!"
            egrep "%.." ../info/*.trashinfo
            echoc --info "there are files with invalid names on the trash! they have to be cleaned manually for now @g:@r(" #TODO inodes?
            echoc -w
          fi
        done
        
        #######################################################################################
        ### The real filenames are based on entries that come from the '*.trashinfo' files. ###
        #######################################################################################
				sedStripDatetimeAndFilename='s"^[^&]*&([^[:blank:]]*)[[:blank:]]*(.*)"\1\t\2"'
				IFS=$'\n' read -d '' -r -a astrEntryList < <( \
					ls -altr --time-style='+&%Y%m%d+%H%M%S.%N' "../info/" \
						|egrep ".trashinfo$" \
						|head -n $((nFileCountPerStep+1)) \
						|sed -r -e "$sedStripDatetimeAndFilename" -e 's".trashinfo$""' )&&:
#						|head -n $((nFileCountPerStep+1)) \
#						|tail -n +2 \
				## grep -v eliminates "." and ".."
#						|egrep -v "[.]$|[.][.]$" \
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
			
				if((`SECFUNCarraySize astrEntryList`>0));then #has files on trash to be deleted
					nRmCount=0
					nRmSizeTotalB=0
					nAvailSizeB4RmB=$((${nAvailMB}*n1MB))&&: # from M to B
					# has date and filename
					for strEntry in "${astrEntryList[@]}";do
						strFileDT="`echo "$strEntry" |cut -f1`"
						strFile="`echo "$strEntry" |cut -f2`"
	#					echo "strEntry='$strEntry',strFileDT='$strFileDT',strFile='$strFile',"
            
            bSymlink=false
						bDirectory=false
            
						bRmTrashInfo=true
            strRmTrashInfoFile="`realpath -ezs "/$strTrashFolder/../info/${strFile}.trashinfo"`"&&:
            if [[ ! -f "$strRmTrashInfoFile" ]];then bRmTrashInfo=false;fi
            
						bRmFileOrPath=true
            strRPExist="e" #only allow existing target
            
            if [[ -L "$strFile" ]];then  # symlinks are ok to be removed directly. SYMLINK TEST above/before all others IS MANDATORY to not consider it as a directory!
              bSymlink=true;
              strRPExist="m" #allow not existing target
            fi 
            
            if ! $bSymlink;then
              if [[ -d "$strFile" ]];then 
                bDirectory=true;
              elif [[ ! -f "$strFile" ]];then 
                SECFUNCechoWarnA "Missing real file strFile='$strFile', just removing trashinfo for it."
                bRmFileOrPath=false
              fi 
            fi
            
            nFileSizeB=0
            nFileSizeMB=0
            if $bRmFileOrPath;then
              if $bDirectory;then
                nFileSizeB="`du -bs "./$strFile/" |cut -f1`"
              else
                nFileSizeB="`stat -c "%s" "./$strFile"`"
              fi
              nFileSizeMB=$((nFileSizeB/n1MB))&&:
              ((nRmCount++))&&:
            
              strReport=""
              strReport+="nRmCount='$nRmCount',"
              strReport+="strFile='$strFile',"
              strReport+="nFileSizeB='$nFileSizeB',"
              strReport+="strFileDT='$strFileDT',"
              strReport+="AvailMB='`FUNCavailMB "$strTrashFolder"`'," #avail after each rm
              strReport+="(prev)nRmSizeTotalB='$nRmSizeTotalB',"
              echo "$strReport"
            fi
					
						if ! $bDummyRun;then
              
              ################ file/path
              if $bRmFileOrPath;then
                if ! strWorkFile="`realpath -${strRPExist}zs "$strTrashFolder/$strFile"`";then
                  SECFUNCechoWarnA "what happened? strTrashFolder='$strTrashFolder' strFile='$strFile' strWorkFile='$strWorkFile'" 
                fi
                strRmOpt="-vf"
                
                if $bSymlink;then
#                  strWorkFile="`realpath -z --strip "$strTrashFolder/$strFile"`"
                  echo "Removing symlink: '$strWorkFile'"
                else
#                  strWorkFile="`readlink -en "$strWorkFile"`" # canonical for normal file/path, just to make it double sure...
                
                  # CHMOD only real files and paths and NOT to where symlinks are pointing!
                  if $bDirectory;then
                    if ! SECFUNCexecA -ce chmod -Rc +w "$strWorkFile/";then
                      SECFUNCechoWarnA "failed to chmod at dir strWorkFile='$strWorkFile'"
                    fi
                    
                    strRmOpt+="r"
                  else
                    if ! SECFUNCexecA -ce chmod -c +w "$strWorkFile";then
                      SECFUNCechoWarnA "failed to chmod at strWorkFile='$strWorkFile'"
                    fi
                  fi
                fi
                
                if ! SECFUNCexecA -ce rm $strRmOpt --one-file-system --preserve-root "$strWorkFile" >"$strRmLogTmp" 2>&1;then #################### FILE/PATH REMOVAL
                  SECFUNCechoWarnA "failed to rm strWorkFile='$strWorkFile'"
                fi
                cat "$strRmLogTmp" |tee -a "$strRmLog" # using tee directly on the command will not return the command exit value...
                
                ########### CRITICAL DOUBLE CHECK. 
                ### Despite all checks already performed, make it sure nothing wrong was removed! 
                ### But... this is quite useless tho...
                ### it is mainly to make it sure the script isnt broken...
                ### but the related file(s) will already be lost...
                ### TODO may be, find a way to restore the removed files, using inodes?
                ###########
                strCriticalCheckRmLog="[\"']`realpath -ezs /$strTrashFolder/`" #checks if there is a rm message containing 'The trash folder/...' or "The trash folder/..."
                #echo test >>"$strRmLogTmp"
                strWrong="`egrep -v "$strCriticalCheckRmLog" "$strRmLogTmp"`"&&:
                if [[ -n "$strWrong" ]];then
                  echoc --say "sec trash cleaner error"
                  echoc -p "below should not have happened..."
                  declare -p strWrong
                  _SECFUNCcriticalForceExit
                fi
              fi
              
              ################ trashinfo ##################################################################
							if $bRmTrashInfo;then rm -vf "$strRmTrashInfoFile"&&:;fi ############### TRASH INFO REMOVAL #
						fi
					
						((nRmSizeTotalB+=nFileSizeB))&&:
				
						if $bTest1;then break;fi # to work at only with one file
						# FS seems to not get updated so fast, so this fails:	if ((`FUNCavailMB $strTrashFolder`>nThisFSAvailGoalMB));then
						if (( (nAvailSizeB4RmB+nRmSizeTotalB) > (nThisFSAvailGoalMB*n1MB) ));then
							break;
						fi
					done
				else
					echoc --info "trash is empty"
					
					if(( nAvailMB < (nThisFSAvailGoalMB/2) ));then
						echoc -p --say "unable to free disk space!"&&:
					fi
				fi
			fi
			
			SECFUNCdbgFuncOutA;return 0
		};export -f FUNCcheckFS
		(FUNCcheckFS) # to make the "pid using FS detection system" unlink with this script
		
		#if $bTest1;then break;fi # to work at only the user default trash folder
		
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

