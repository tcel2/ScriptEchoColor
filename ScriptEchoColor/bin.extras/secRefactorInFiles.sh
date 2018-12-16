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

source <(secinit)

strOldBkpToken="_SEC_OLD_TOKEN_"
bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
strRegexMatch=""
strReplaceWith=""
strRegexFileFilter=".*[.]java"
strBkpSuffix="secrfbkp"
bWrite=false
strWorkPath="."
bAskSkip=true
bRevertToBackups=false
bBkpTrash=false
#bBkpHidden=true
astrFileIgnore=()
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "<strRegexMatch> <strReplaceWith> will replace the matching regex in all source files." 
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--filefilter" || "$1" == "-f" ]];then #help <strRegexFileFilter> it is a `find` param
		shift
		strRegexFileFilter="${1-}"
	elif [[ "$1" == "--ignore" || "$1" == "-i" ]];then #help <strFileToIgnore> it is a `find` param
		shift
		astrFileIgnore+=("${1-}")
	elif [[ "$1" == "--write" ]];then #help this option will actually make `sed` write to files. Or --revertbkps actually do the undo.
		bWrite=true
#	elif [[ "$1" == "--makewritable" ]];then #help if t
#		bMakeWritable=true
	elif [[ "$1" == "--bkpsuffix" || "$1" == "-b" ]];then #help <strBkpSuffix> if empty, `sed` will not create backups
		shift
		strBkpSuffix="${1-}"
#	elif [[ "$1" == "--bkphidden" || "$1" == "-h" ]];then #help prefix backups with a dot "."
#		bBkpHidden=true
	elif [[ "$1" == "--trashbkp" || "$1" == "-t" ]];then #help ~single will remove the backup files and exit
		bBkpTrash=true
	elif [[ "$1" == "--workpath" || "$1" == "-w" ]];then #help <strWorkPath> used with `find`
		shift
		strWorkPath="${1-}"
	elif [[ "$1" == "--noaskskip" || "$1" == "-n" ]];then #help when --write is used, it will ask if current file must be skipped, this disables that question.
		bAskSkip=false
#	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
#		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
#			shift
#			CFGstrTest="$1"
#		fi
#		
#		bCfgTest=true
	elif [[ "$1" == "--revertbkps" ]];then #help undo/revert to latest backup of each file
		bRevertToBackups=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

#astrParamIgnore=()
#for strIgnore in "${#astrFileIgnore[@]}";do
#	astrParamIgnore+=();
#done

strBkpKey="`SECFUNCdtFmt --filename`"

strRegexMatchBkpFiles="[.]${strRegexFileFilter}.*[.]${strBkpSuffix}"
declare -p strRegexMatchBkpFiles
function FUNCfindAllPossibleBkpWork(){
	local astrParams=(find "$strWorkPath" -type f -regex ".*[.]${strBkpSuffix}")
	
	if [[ "$1" == "--report" ]];then
		echoc --info "bkp files size: @r`"${astrParams[@]}" -print0 | du -ch --files0-from=- |tail -n 1 |tr '\t' ' '` "
	else
		astrParams+=("$@")
		
		if [[ "$1" == "-exec" ]];then
			astrParams+=(";")
		fi
		
#		echoc --info "EXEC: ${astrParams[@]}"
		SECFUNCexecA -ce "${astrParams[@]}"
	
	fi
	
	return 0
}

if $bBkpTrash;then
	strOutput="`FUNCfindAllPossibleBkpWork -exec ls -l '{}'`"&&:
	if [[ -n "$strOutput" ]];then
		echo "$strOutput"
		FUNCfindAllPossibleBkpWork --report
		if echoc -q "trash all backup files?";then
			FUNCfindAllPossibleBkpWork -exec trash -v '{}'
		fi
	else
		echoc --info "no bkp files"
	fi
	exit 0
fi

strRegexMatch="${1-}"
shift&&:
strReplaceWith="${1-}"
shift&&:

if $bRevertToBackups;then
	if ! echoc -q "this will revert only to the latest backup (of each file)! are you sure?";then
		exit 0
	fi
	
	export SECbExecJustEcho=true
	if $bWrite;then
		SECbExecJustEcho=false
	fi
	
	IFS=$'\n' read -d '' -r -a astrBkpFileList < <(find "${strWorkPath}/" -regex ".*/$strRegexMatchBkpFiles")&&:
	if((${#astrBkpFileList[@]-}>0));then
		for strBkpFile in "${astrBkpFileList[@]-}";do
			if [[ "$strBkpFile" =~ .*$strOldBkpToken.* ]];then
				echo "SKIPPING: $strBkpFile"
				continue
			fi
		
			SECFUNCdrawLine --left "strBkpFile='$strBkpFile'"
			strBaseName="`basename "$strBkpFile"`"
			strFile="${strBaseName:1}" #remove the dot
			strFile="${strFile%.${strBkpSuffix}}"
			strFile="`dirname "$strBkpFile"`/$strFile"
			if [[ -f "$strFile" ]];then
				SECFUNCexecA -ce mv -vT "$strFile" "${strFile}.RefactoredWrong.$strBkpKey.${strBkpSuffix}"
				SECFUNCexecA -ce mv -vT "$strBkpFile" "${strFile}"
			else
				echoc -p "unable to find strFile='$strFile'"
			fi
		done
	else
		echoc --info "no backups found..."
	fi
#	declare -p astrBkpFileList
#	if ! SECFUNCexecA -ce find "${strWorkPath}/" -iname "*.${strBkpSuffix}" -exec ls -l "{}" \; ; then
#		echoc -p "no backup found..."
#		exit 1
#	fi
	exit 0
fi

if [[ -z "$strRegexMatch" ]];then
	echoc -p "invalid strRegexMatch='$strRegexMatch'"
	exit 1
fi
if [[ -z "$strReplaceWith" ]];then
	echoc -p "invalid strReplaceWith='$strReplaceWith'"
	exit 1
fi

# Main code
function _FUNCreportMatches() {
	SECFUNCdrawLine --left "=== strFile='$strFile'"
	
	echoc --info "color diff prevision"
	
	#echoc --info "BEFORE"
	local lstrBefore="`SECFUNCexecA -ce egrep --color=always "${strRegexMatch}" "$strFile"&&:`"
	
	# this check may not work if sed replacing string is too complex to be ready to fgrep
	local lstrBeware="`SECFUNCexecA -ce fgrep --color=always "${strReplaceWith}" "$strFile"&&:`"
	if [[ -n "$lstrBeware" ]];then echoc --alert "Beware, replace already exists!!"; echo "$lstrBeware";fi
	
	#echoc --info "AFTER"
	local lstrAfter="`SECFUNCexecA -ce sed -n -r "s@${strRegexMatch}@${strReplaceWith}@gp" "$strFile"&&:`" #|SECFUNCexecA -ce fgrep --color=always "${strReplaceWith}"&&:
	
	if SECFUNCexecA -ce colordiff <(echo "$lstrBefore") <(echo "$lstrAfter");then :;fi #TODO why &&: didnt work?
}

SECFUNCuniqueLock --waitbecomedaemon

IFS=$'\n' read -d '' -r -a astrFileList < <(find "${strWorkPath}/" -regex ".*/${strRegexFileFilter}")&&:
#declare -p strRegexFileFilter strWorkPath
if((`SECFUNCarraySize astrFileList`>0));then
	for strFile in "${astrFileList[@]}";do
		if [[ -L "$strFile" ]];then
			SECFUNCdrawLine --left "=== SymlinkFound: strFile='$strFile'"
			ls -l "$strFile"
			strFile="`readlink -e "$strFile"`" # sed would replace symlinks with real files...
		fi
		
		if egrep -q "$strRegexMatch" "$strFile";then
			egrep -Hc "$strRegexMatch" "$strFile"
			if SECFUNCarrayContains astrFileIgnore "$strFile";then
				echoc --info "@s@rIgnoring file:@S strFile='$strFile'"
				continue;
			fi
		
			if $bWrite;then
				if $bAskSkip;then
					_FUNCreportMatches
					# default answer is to skip, so user have to think/check more to help on preventing trouble
					if echoc -q "skip above strFile='$strFile'?";then
						continue
					fi
				fi
				
				strFileBkp="${strFile}.${strBkpSuffix}"
				strFileBkpNormal="$strFileBkp"
#				if $bBkpHidden;then
					strFileBkp="`echo "$strFileBkp" |sed -r "s'(.*)/(.*)'\1/.\2'"`" #prefix the basename with a dot
#				fi
				
				if [[ -f "$strFileBkp" ]];then
					echoc --info "backup already exists, moving it to old"
					strFileBkpOld="`echo "$strFileBkp" |sed -r "s'(.*)/(.*)'\1/\2.${strOldBkpToken}$strBkpKey.${strBkpSuffix}'"`"
					SECFUNCexecA -ce mv -vT "$strFileBkp" "$strFileBkpOld"
				fi
				SECFUNCexecA -ce sed -i".${strBkpSuffix}" -r "s@${strRegexMatch}@${strReplaceWith}@g" "$strFile"
#				if $bBkpHidden;then
					mv "$strFileBkpNormal" "$strFileBkp" #overcome sed restriction of only suffixing the file
#				fi
				if [[ -f "$strFileBkp" ]];then
					SECFUNCexecA -ce ls -l "$strFileBkp"
					SECFUNCexecA -ce colordiff "$strFileBkp" "$strFile"&&:
				else
					SECFUNCexecA -ce egrep --color=always "${strReplaceWith}" "$strFile"&&:
				fi
			else
				_FUNCreportMatches
			fi
		fi
	done
fi
if ! $bWrite;then
	echoc --alert "nothing was changed!"
fi
#echoc --info ""
#SECFUNCexecA -ce du --exclude "$strRegexFileFilter" -hs "`readlink -f "$strWorkPath"`"&&:
echoc --info "Backup files size (see --trashbkp help): "
FUNCfindAllPossibleBkpWork --report

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

