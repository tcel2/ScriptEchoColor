#!/bin/bash
# Copyright (C) 2018 by Henrique Abdalla
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

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strAddFolder=""
CFGastrFolderList=()
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
strExecQuietOpt="q"
bRemoteBkp=false
bDaemon=false
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-a" || "$1" == "--addfolder" ]];then #help <strAddFolder>
		shift
		strAddFolder="${1-}"
	elif [[ "$1" == "-A" || "$1" == "--addfolder" ]];then #help <strAddFolder> (will also add the compressed file to the remote backup)
		shift
		strAddFolder="${1-}"
    bRemoteBkp=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows all files being compressed
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
		strExecQuietOpt=""
	elif [[ "$1" == "--daemon" ]];then #help loop
    bDaemon=true
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
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

SECFUNCuniqueLock --waitbecomedaemon

# Main code
while true;do
  if $bDaemon;then SECFUNCcfgReadDB;fi #to know about additions
  
  if [[ -n "${strAddFolder-}" ]];then
    if [[ -d "${strAddFolder}" ]];then
      if [[ -L "$strAddFolder" ]];then
        echoc -p "symlinks to folders not yet supported"
        exit 1
      fi
      
      strAddFolder="`realpath -ezs "$strAddFolder"`"
      
      if ! [[ "$strAddFolder" =~ ^$HOME/.* ]];then
        echoc -p "for now, can only work at home tree..."
        exit 1
      fi
      
      #declare -p CFGastrFolderList
      if ! SECFUNCarrayContains CFGastrFolderList "$strAddFolder";then
        CFGastrFolderList+=("$strAddFolder")
        SECFUNCcfgAutoWriteAllVars #this will also show all config vars
        echoc --info "added: '$strAddFolder'"
      else
        echoc --info "already configured: '$strAddFolder'"
        exit 0
      fi
    else
      echoc -p "not a folder '$strAddFolder'"
      ls -l $strAddFolder
      exit 1
    fi
  fi

  for strFolder in "${CFGastrFolderList[@]}";do
    if [[ -n "${strAddFolder-}" ]];then
      if [[ "$strFolder" != "$strAddFolder" ]];then
        continue
      fi
    fi
    
    #SECFUNCdrawLine --left "$strFolder"
    SECFUNCdrawLine
    echo "Folder: $strFolder"
    
    strParentFolder="`dirname "$strFolder"`"
    SECFUNCexecA -cE cd "$strParentFolder"
    SECFUNCexecA -cE${strExecQuietOpt} pwd
    
    strName="`basename "$strFolder"`"
    
    strMvToFolder="$SECstrUserScriptCfgPath/Home/${strParentFolder#$HOME}/"
    
    strStatusNew="`ls -lR --time-style=full-iso "$strFolder"`" 
    strFileStatus="$strMvToFolder/${strName}.status"
    if [[ -f "$strFileStatus" ]];then
      strStatus="`cat "$strFileStatus"`"
      if [[ "$strStatusNew" == "$strStatus" ]];then echo "No changes found...";continue;fi # no chances, skip
    fi
    
    SECFUNCexecA -cE${strExecQuietOpt} trash -vf "${strName}.tar"&&: #safety
    SECFUNCexecA -cE${strExecQuietOpt} tar -vcf "${strName}.tar" "./${strName}/"
    
    SECFUNCexecA -cE${strExecQuietOpt} trash -vf "${strName}.tar.7z"&&: #may not exist yet
    SECFUNCexecA -ce${strExecQuietOpt} nice -n 19 7z a "${strName}.tar.7z" "${strName}.tar"
    
    strAbsFile="`realpath -e "${strName}.tar.7z"`"
    #strMvTo="$SECstrUserScriptCfgPath/Home/${strAbsFile#$HOME}"
    strMvToFile="$strMvToFolder/${strName}.tar.7z"
    mkdir -vp "`dirname "$strMvToFile"`"
    
    mv -vf "$strAbsFile" "$strMvToFile"
    echo "$strStatusNew" >"$strFileStatus"
    
    SECFUNCexecA -cE ls -l "$strMvToFile"
    #~ SECFUNCexecA -cE ls -l "${strName}.tar.7z"
    #~ SECFUNCexecA -cE realpath -e "${strName}.tar.7z"
    
    SECFUNCexecA -cE${strExecQuietOpt} trash -vf "${strName}.tar"&&: #cleanup
    
    if $bRemoteBkp;then
      secUpdateRemoteBackupFiles.sh "$strMvToFile" #"${strName}.tar.7z"
    fi
  done
  
  if ! $bDaemon;then break;fi
  echoc -w -t 1200
done

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
