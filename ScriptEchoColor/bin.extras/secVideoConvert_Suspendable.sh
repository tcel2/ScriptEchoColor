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
: ${strTmpWorkPath:="`pwd`/.${SECstrScriptSelfName}.tmp/"}
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#[strFileAbs] video to work with"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
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
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code
SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run

if $bContinue;then
  strFileAbs="$CFGstrFile"
  strOrigPath="$CFGstrOrigPath"
else
  strFileAbs="$1"; #help
  if [[ "${strFileAbs:0:1}" == "/" ]];then
    strOrigPath="`dirname "$strFileAbs"`"
  else
    strOrigPath="`pwd`/`dirname "$strFileAbs"`/"
  fi
fi

if [[ ! -f "$strFileAbs" ]];then
  echoc -p "missing strFileAbs='$strFileAbs'"
  exit 1
fi

if mediainfo "$strFileAbs" |grep "Format.*:.*HEVC";then
  echoc --info "Already HEVC format."
  exit 0
fi

nDurationMillis="`mediainfo -f "$strFileAbs" |egrep "Duration.*: [[:digit:]]*$" |head -n 1 |grep -o "[[:digit:]]*"`"
nDurationSeconds=$((nDurationMillis/1000))

nFileSz="`stat -c "%s" "$strFileAbs"`";
n1MB=1000000 #TODO 1024*1024
: ${nMinMB:=1} #help
nMinPartSz=$((nMinMB*n1MB))
if((nFileSz<nMinPartSz));then
  echoc -p "file is too small for this feature"
  exit 1
fi
nParts=$((nFileSz/nMinPartSz))

nPartSeconds=$((nDurationSeconds/nParts));
((nPartSeconds+=1))&&: # to compensate for remaining milliseconds

declare -p nDurationMillis nDurationSeconds nFileSz nMinPartSz nParts nPartSeconds

strFileBN="`basename "$strFileAbs"`"
strFileHash="`echo "$strFileBN" |md5sum |awk '{print $1}'`" #the file may contain chars avconv wont accept at .join file

strSuffix="`SECFUNCfileSuffix "$strFileHash"`"
strFileNoSuf="${strTmpWorkPath}/${strFileHash%.$strSuffix}"

strNewFormatSuffix="x265-HEVC"
strFinalFileBN="${strFileBN}.${strNewFormatSuffix}.mp4"

function FUNCmiOrigNew() {
  SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
  return 0
}

if [[ -f "$strOrigPath/$strFinalFileBN" ]];then
  FUNCmiOrigNew
#  ls -l "$strOrigPath/$strFinalFileBN" "$strFileAbs"
  ls -l "$strFinalFileBN" "$strFileAbs"
  echoc --info "already converted!"
  exit 0
fi

CFGstrFile="$strFileAbs"     ;SECFUNCcfgWriteVar CFGstrFile
CFGstrOrigPath="$strOrigPath";SECFUNCcfgWriteVar CFGstrOrigPath

SECFUNCexecA -ce mkdir -vp "$strTmpWorkPath"

if [[ ! -f "${strFileNoSuf}.00000.mp4" ]];then
  echoc --info "Splitting" >&2
  SECFUNCexecA -ce avconv -i "$strFileAbs" -c copy -flags +global_header -segment_time $nPartSeconds -f segment "${strFileNoSuf}."%05d".mp4"
fi

SECFUNCexecA -ce ls -l "${strFileNoSuf}."* #|sort -n

IFS=$'\n' read -d '' -r -a astrFilePartList < <(ls -1 "${strFileNoSuf}."?????".mp4" |sort -n)&&:
declare -p astrFilePartList |tr "[" "\n" >&2

#nCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"

astrFilePartNewList=()
echoc --info "Converting" >&2
for strFilePart in "${astrFilePartList[@]}";do
  strFilePartNS="${strFilePart%.mp4}"
  strPartTmp="${strFileNoSuf}.NewPart.${strNewFormatSuffix}.TEMP.mp4"
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
    SECFUNCCcpulimit "avconv" -l $nCPUPerc
    if SECFUNCexecA -ce nice -n 19 avconv -i "$strFilePart" -c:v libx265 -c:a libmp3lame -fflags +genpts "$strPartTmp";then # libx265 -x265-params lossless=1
      SECFUNCexecA -ce mv -vf "$strPartTmp" "$strFilePartNew"
      #SECFUNCtrash "$strFilePart"
    else
      echoc -p "failed to prepare strFilePartNew='$strFilePartNew'"
      exit 1
    fi
  fi
  
  astrFilePartNewList+=( "`basename "$strFilePartNew"`" )
done
declare -p astrFilePartNewList |tr "[" "\n" >&2

( # to cd
  SECFUNCexecA -ce cd "$strTmpWorkPath"
  
  strFileJoin="`basename "${strFileNoSuf}.join"`"
  
  echoc --info "Joining" >&2
  SECFUNCtrash "$strFileJoin" &&:
  for strFilePartNew in "${astrFilePartNewList[@]}";do
    #strSafeFileName="`basename "$strFilePartNew" |tr -d " "`"
    #mv -vf "$strFilePartNew" "$strSafeFileName"
    echo "file '$strFilePartNew'" >>"$strFileJoin"
  done
  SECFUNCexecA -ce cat "$strFileJoin"

  strFinalTmp="${strFileNoSuf}.${strNewFormatSuffix}-TMP.mp4"
  SECFUNCtrash "$strFinalTmp"&&:
  if SECFUNCexecA -ce avconv -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalTmp";then
    SECFUNCexecA -ce mv -vf "$strFinalTmp" "$strFinalFileBN"
    SECFUNCexecA -ce mv -vf "$strFinalFileBN" "${strOrigPath}/"
    FUNCmiOrigNew
  fi
)

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
