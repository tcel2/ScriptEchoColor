#!/bin/bash
# Copyright (C) 2004-2018 by Henrique Abdalla
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
strExample="DefaultValue"
bContinue=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
strWorkWith=""
bWorkWith=false
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#[strNewFiles...] add videos to work with"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-o" || "$1" == "--workonlywith" ]];then #help <strWorkWith> process a single file
		shift
		strWorkWith="${1-}"
    bWorkWith=true
	elif [[ "$1" == "-c" || "$1" == "--continue" ]];then #help resume last work if any
		bContinue=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift&&: #will consume all remaining params
		done
	else
		SECFUNCechoErrA "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code
sedRegexPreciseMatch='s"(.)"[\1]"g'

if $bWorkWith;then
  if ! strWorkWith="`realpath "$strWorkWith"`";then
    SECFUNCechoErrA "missing strWorkWith='$strWorkWith'"
    exit 1
  fi
  
  if ! SECFUNCarrayContains CFGastrFileList "$strWorkWith";then
    SECFUNCarrayPrepend CFGastrFileList "$strWorkWith"
  fi
  
  strFileAbs="$strWorkWith"
else
  ######################
  ### the default is to add many files:
  ######################
  if ! SECFUNCarrayCheck CFGastrFileList;then
    CFGastrFileList=()
  fi
  for strNewFile in "$@";do
    if [[ -f "$strNewFile" ]];then
      CFGastrFileList+=("`realpath "$strNewFile"`")
      SECFUNCarrayWork --uniq CFGastrFileList
      SECFUNCcfgWriteVar CFGastrFileList
    else  
      SEC_WARN=true SECFUNCechoWarnA "missing strNewFile='$strNewFile'"
    fi
  done
  declare -p CFGastrFileList
  
  if $bContinue;then
    while true;do
      SECFUNCcfgReadDB
      echoc --info " Continue @s@{By}Loop@S: "
      declare -p CFGastrFileList |tr '[' '\n'
      if((`SECFUNCarraySize CFGastrFileList`==0));then break;fi
      #~ strFileAbs="${CFGastrFileList[0]-}"
      #~ if [[ -f "$strFileAbs" ]];then
        #~ $0 --workonlywith "$strFileAbs" &&:
      #~ fi
      
      #~ strRegexPreciseMatch="^`echo "$strFileAbs" |sed -r "$sedRegexPreciseMatch"`$"
      #~ SECFUNCarrayClean CFGastrFileList "$strRegexPreciseMatch"
      #~ SECFUNCcfgWriteVar CFGastrFileList
      for strFileAbs in "${CFGastrFileList[@]}";do
        SECFUNCexecA -ce $0 --workonlywith "$strFileAbs" &&:
        echoc -w -t 60
      done
    done
    exit 0
  else
    # choses 1st to work on it
    strFileAbs="${CFGastrFileList[0]-}"
  fi
fi

if SECFUNCuniqueLock --isdaemonrunning;then
  echoc --info "daemon already running, exiting."
  exit 0
fi

SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run

strOrigPath="`dirname "$strFileAbs"`"
: ${strTmpWorkPath:="$strOrigPath/.${SECstrScriptSelfName}.tmp/"} #help

declare -p strFileAbs strOrigPath strTmpWorkPath
echoc --info " CURRENT WORK: @{Gr}$strFileAbs "

#~ echoc --info "Continue:"
#~ if $bContinue;then
  #~ strFileAbs="${CFGastrFileList[0]-}"
  #~ echoc --info "Continue:"
#~ else
  #~ :
#~ fi

#~ if $bContinue;then
  #~ strFileAbs="$CFGstrFileAbs"
  #~ if [[ -z "$strFileAbs" ]];then
    #~ strFileAbs="${CFGastrFileList[0]-}"
  #~ fi
  
  #~ strOrigPath="$CFGstrOrigPath"
  #~ strTmpWorkPath="$CFGstrTmpWorkPath"
  
  #~ echoc --info "Continue:"
  #~ declare -p strFileAbs strOrigPath strTmpWorkPath
#~ else
  #~ strFileAbs="$1";
  #~ # if [[ "${strFileAbs:0:1}" == "/" ]];then
    #~ # strOrigPath="`dirname "$strFileAbs"`"
  #~ # else
    #~ # strOrigPath="`pwd`/`dirname "$strFileAbs"`/"
    #~ # strFileAbs="`pwd`/${strFileAbs}"
  #~ # fi
  #~ strFileAbs="`realpath "${strFileAbs}"`"
  #~ strOrigPath="`dirname "$strFileAbs"`"
#~ #  : ${strTmpWorkPath:="`pwd`/.${SECstrScriptSelfName}.tmp/"} #help
  #~ : ${strTmpWorkPath:="$strOrigPath/.${SECstrScriptSelfName}.tmp/"} #help
#~ fi

if [[ ! -f "$strFileAbs" ]];then
  SECFUNCechoErrA "missing strFileAbs='$strFileAbs'"
  exit 1
fi

if mediainfo "$strFileAbs" |grep "Format.*:.*HEVC";then
  echoc --info "Already HEVC format."
  exit 0
fi

strFileBN="`basename "$strFileAbs"`"
strFileHash="`echo "$strFileBN" |md5sum |awk '{print $1}'`" #the file may contain chars avconv wont accept at .join file

strSuffix="`SECFUNCfileSuffix "$strFileBN"`"
#strFileNoSuf="${strTmpWorkPath}/${strFileHash%.$strSuffix}"
strFileTmp="${strTmpWorkPath}/${strFileHash}"

strNewFormatSuffix="x265-HEVC"
strFinalFileBN="${strFileBN%.$strSuffix}.${strNewFormatSuffix}.mp4"

function FUNCmiOrigNew() {
  SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
  
  if echoc -t 60 -q "play the new file?";then
    SECFUNCexecA -ce smplayer "$strOrigPath/$strFinalFileBN"&&:
  fi
  
  if FUNCtrashTmpOld;then
    # merge current list with possible new values
    astrFileListBKP=( "${CFGastrFileList[@]}" ); 
    SECFUNCcfgReadDB
    SECFUNCarrayWork --merge CFGastrFileList astrFileListBKP
    
    # clean final list from current file
    sedRegexPreciseMatch='s"(.)"[\1]"g'
    strRegexPreciseMatch="^`echo "$strFileAbs" |sed -r "$sedRegexPreciseMatch"`$"
    SECFUNCarrayClean CFGastrFileList "$strRegexPreciseMatch"
    #unset CFGastrFileList[0]; 
    #CFGastrFileList=( "${CFGastrFileList[@]}" ); 
    SECFUNCcfgWriteVar CFGastrFileList #SECFUNCarrayClean CFGastrFileList "$CFGstrFileAbs"
    
    return 0
  fi
  
  return 1
}

function FUNCtrashTmpOld() {
  SECFUNCexecA -ce ls -l "${strTmpWorkPath}/${strFileHash}"* &&:
  SECFUNCexecA -ce ls -l "$strFileAbs" "$strOrigPath/$strFinalFileBN" &&:
  if echoc -t 60 -q "trash tmp and old files?";then
    SECFUNCtrash "${strTmpWorkPath}/${strFileHash}"*
    SECFUNCtrash "$strFileAbs"&&:
    SECFUNCexecA -ce ls -l "$strOrigPath/$strFinalFileBN" &&:
  else
    return 1
  fi
  
  echoc -w -t 60
  return 0
}

if [[ -f "$strOrigPath/$strFinalFileBN" ]];then
  FUNCmiOrigNew&&:
  #~ if FUNCmiOrigNew;then
    #~ if $bContinue;then
      #~ $0 --continue #TODO avoid nesting messing memory
      #~ exit 0
    #~ fi
  #~ else
  #  ls -l "$strOrigPath/$strFinalFileBN" "$strFileAbs"
    ls -l "$strOrigPath/$strFinalFileBN" "$strFileAbs" &&:
    echoc --info "already converted to strFinalFileBN='$strFinalFileBN'"
    exit 0
  #~ fi
fi

#~ CFGstrFileAbs="$strFileAbs"        ;SECFUNCcfgWriteVar CFGstrFileAbs
#~ CFGstrOrigPath="$strOrigPath"      ;SECFUNCcfgWriteVar CFGstrOrigPath
#~ CFGstrTmpWorkPath="$strTmpWorkPath";SECFUNCcfgWriteVar CFGstrTmpWorkPath
#~ SECFUNCcfgWriteVar CFGastrFileList

SECFUNCexecA -ce mkdir -vp "$strTmpWorkPath"

nDurationMillis="`mediainfo -f "$strFileAbs" |egrep "Duration.*: [[:digit:]]*$" |head -n 1 |grep -o "[[:digit:]]*"`"
nDurationSeconds=$((nDurationMillis/1000))

nFileSz="`stat -c "%s" "$strFileAbs"`";
n1MB=1000000 #TODO 1024*1024
: ${nMinMB:=1} #help
nMinPartSz=$((nMinMB*n1MB))
if((nFileSz<nMinPartSz));then
  SECFUNCechoErrA "file is too small for this feature"
  exit 1
fi
nParts=$((nFileSz/nMinPartSz))

nPartSeconds=$((nDurationSeconds/nParts));
((nPartSeconds+=1))&&: # to compensate for remaining milliseconds

declare -p nDurationMillis nDurationSeconds nFileSz nMinPartSz nParts nPartSeconds

if [[ ! -f "${strFileTmp}.00000.mp4" ]];then
  echoc --info "Splitting" >&2
  SECFUNCexecA -ce avconv -i "$strFileAbs" -c copy -flags +global_header -segment_time $nPartSeconds -f segment "${strFileTmp}."%05d".mp4"
fi

SECFUNCexecA -ce ls -l "${strFileTmp}."* #|sort -n

IFS=$'\n' read -d '' -r -a astrFilePartList < <(ls -1 "${strFileTmp}."?????".mp4" |sort -n)&&:
declare -p astrFilePartList |tr "[" "\n" >&2

#nCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"

astrFilePartNewList=()
echoc --info "Converting" >&2
nCount=0
for strFilePart in "${astrFilePartList[@]}";do
  strFilePartNS="${strFilePart%.mp4}"
  strPartTmp="${strFileTmp}.NewPart.${strNewFormatSuffix}.TEMP.mp4"
  strFilePartNew="${strFilePartNS}.NewPart.${strNewFormatSuffix}.mp4"
  #~ strFilePartNewUnsafeName="${strFilePartNS}.NewPart.${strNewFormatSuffix}.mp4"
  #~ strSafeFileName="`dirname "$strFilePartNewUnsafeName"`/`basename "$strFilePartNewUnsafeName" |md5sum |awk '{print $1}'`" #|tr -d " "
  #~ strFilePartNew="$strSafeFileName"
#  declare -p strFilePart strFilePartNS strPartTmp strFilePartNewUnsafeName strSafeFileName strFilePartNew >&2
  declare -p strFilePart strFilePartNS strPartTmp strFilePartNew >&2
  
  if [[ -f "$strPartTmp" ]];then
    SECFUNCtrash "$strPartTmp"&&:
  fi
  
  if [[ ! -f "$strFilePartNew" ]];then
#    SECFUNCCcpulimit "avconv" -- -l $((25*nCPUs))
    : ${nCPUPerc:=50} #help overall CPUs percentage
    SECFUNCCcpulimit -r "avconv" -l $nCPUPerc
    echoc --info "PROGRESS: $nCount/${#astrFilePartList[*]}, `bc <<< "scale=2;($nCount*100/${#astrFilePartList[*]})"`%"
    if SECFUNCexecA -ce nice -n 19 avconv -i "$strFilePart" -c:v libx265 -c:a libmp3lame -fflags +genpts "$strPartTmp";then # libx265 -x265-params lossless=1
      SECFUNCexecA -ce mv -vf "$strPartTmp" "$strFilePartNew"
      #SECFUNCtrash "$strFilePart"
    else
      SECFUNCechoErrA "failed to prepare strFilePartNew='$strFilePartNew'"
      exit 1
    fi
  fi
  
  echo ">>> DONE: $strFilePartNew" >&2
  
  ((nCount++))&&:
  
  astrFilePartNewList+=( "`basename "$strFilePartNew"`" )
done
declare -p astrFilePartNewList |tr "[" "\n" >&2

( # to cd
  SECFUNCexecA -ce cd "$strTmpWorkPath"
  
  strFileJoin="`basename "${strFileTmp}.join"`"
  
  echoc --info "Joining" >&2
  SECFUNCtrash "$strFileJoin" &&:
  for strFilePartNew in "${astrFilePartNewList[@]}";do
    #strSafeFileName="`basename "$strFilePartNew" |tr -d " "`"
    #mv -vf "$strFilePartNew" "$strSafeFileName"
    echo "file '$strFilePartNew'" >>"$strFileJoin"
  done
  SECFUNCexecA -ce cat "$strFileJoin"

  strFinalTmp="${strFileTmp}.${strNewFormatSuffix}-TMP.mp4"
  SECFUNCtrash "$strFinalTmp"&&:
  if SECFUNCexecA -ce avconv -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalTmp";then
    SECFUNCexecA -ce mv -vf "$strFinalTmp" "$strFinalFileBN"
    SECFUNCexecA -ce mv -vf "$strFinalFileBN" "${strOrigPath}/"
    FUNCmiOrigNew&&:
    
    # make it ready to continue on next run
    #~ if [[ "$CFGstrFileAbs" != "${CFGastrFileList[0]}" ]];then
      #~ SECFUNCechoErrA "CFGstrFileAbs='$CFGstrFileAbs' CFGastrFileList[0]='${CFGastrFileList[0]}' should be the same"
      #~ exit 1
    #~ fi
    
    #~ # merge current list with possible new values
    #~ astrFileListBKP=( "${CFGastrFileList[@]}" ); 
    #~ SECFUNCcfgReadDB
    #~ SECFUNCarrayWork --merge CFGastrFileList astrFileListBKP
    
    #~ # clean final list from current file
    #~ sedRegexPreciseMatch='s"(.)"[\1]"g'
    #~ strRegexPreciseMatch="^`echo "$strFileAbs" |sed -r "$sedRegexPreciseMatch"`$"
    #~ SECFUNCarrayClean CFGastrFileList "$strRegexPreciseMatch"
    #~ #unset CFGastrFileList[0]; 
    #~ #CFGastrFileList=( "${CFGastrFileList[@]}" ); 
    #~ SECFUNCcfgWriteVar CFGastrFileList #SECFUNCarrayClean CFGastrFileList "$CFGstrFileAbs"
    
    #~ CFGstrFileAbs="";SECFUNCcfgWriteVar CFGstrFileAbs
    
    #~ if((${#CFGastrFileList[*]}>0));then
      #~ "$0" --continue #TODO recursive means more memory used :(, make it a child and wait it end?
      #~ #TODO exit 0 # but wait the child(s) exit too!
    #~ fi
  fi
  exit 0
)

echoc -w -t 60

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
