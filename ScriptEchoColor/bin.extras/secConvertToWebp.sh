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
strExample="DefaultValue"
export bDryRun=false
export bTrash=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful

########################
export fQuality=80.0 #fotos
# export fQuality=10 #documentos
# export fQuality=5 #documentos
# export fQuality=1 #documentos
# export fQuality=0.1 #documentos BEST quality VS size if highly legible
# export fQuality=0.01 #documentos
# export fQuality=0.001 #documentos
########################

: ${CFGstrTagKeepOriginal:="KEEP_ORIGINAL"}
export CFGstrTagKeepOriginal #help wont touch files with that on their names

SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift;strExample="${1-}"
	elif [[ "$1" == "-d" || "$1" == "--dryrun" ]];then #help only shows what would be done
		bDryRun=true
	elif [[ "$1" == "-t" || "$1" == "--trash" ]];then #help trash already converted old files (use this on the 2nd run after confirming all is ok)
		bTrash=true
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
# if a daemon or to prevent simultaneously running it: SECFUNCuniqueLock --waitbecomedaemon

###
# QUALITY can be float like 0.1 or 0.001
#
# For documents, from 0.1 to 0.01 we gain little KBytes...
# 0.1 #documentos BEST quality VS size if highly legible
# 10.0 #documents lets read hard/light things too
###

function FUNCnewNm() { #<lstrFile>
	local lstrFile="$1";shift
	local lstrQual="`echo "$fQuality" |tr '.' '_'`"
  strExt="`SECFUNCfileSuffix "$lstrFile"`"
	local lstrFileWebp="${lstrFile%.$strExt}-q${lstrQual}.webp"
  echo "$lstrFileWebp"
}

astrFileFailList=()
astrFlOldSmaller=()
function FUNCconv() {
  #source <(secinit --fast)
  
	local lstrFile="$1"
	#~ local lstrQual="`echo "$fQuality" |tr '.' '_'`"
  #~ strExt="`SECFUNCfileSuffix "$lstrFile"`"
	#~ local lstrFileWebp="${lstrFile%.$strExt}-q${lstrQual}.webp"
  local lstrFileWebp="`FUNCnewNm "$lstrFile"`"
	if [[ ! -f "$lstrFileWebp" ]];then
		echo
		SECFUNCdrawLine --left ">>> working with $lstrFile <-> $lstrFileWebp "
#    strTmpFl="${lstrFileWebp}.${SECstrScriptSelfName}-TMP"
    strTmpFl=".${SECstrScriptSelfName}-TMP.webp"
    astrCmd=(nice -n 19 cwebp -q $fQuality "$lstrFile" -o "$strTmpFl")
    astrCmdMv=(mv -vf "$strTmpFl" "${lstrFileWebp}")
    echo "ToExecCMD: ${astrCmd[@]}" >&2
    echo "ToExecCMDMV: ${astrCmdMv[@]}" >&2
    if ! $bDryRun;then
      #cwebp is too fast to this be useful at all: SECFUNCCcpulimit -r "cwebp" -l 50
      if [[ -f "$strTmpFl" ]];then SECFUNCtrash "$strTmpFl";fi
      if SECFUNCexecA -ce "${astrCmd[@]}";then
        if SECFUNCexecA -ce "${astrCmdMv[@]}";then
          ls -l "$lstrFile" "$lstrFileWebp"
        fi
      else
        astrFileFailList+=("$lstrFile")
      fi
    fi
	else
		echo ">>> ($nCount/$nTotOld `bc <<< "scale=2;$nCount*100/$nTotOld"`%) found $lstrFileWebp"
	fi
  
  if $bTrash;then
    if [[ -f "$lstrFileWebp" ]];then
      nSzNew=`stat -c %s "$lstrFileWebp"`
      if ((nSzNew>0));then # this means webp is theoretically good TODO better integrity test? may be `identify`
        nSzOld=`stat -c %s "$lstrFile"`
        if((nSzOld<nSzNew));then
          astrFlOldSmaller+=("$lstrFile")
          SEC_WARN=true SECFUNCechoWarnA "old size smaller than new! $nSzOld < $nSzNew; eog '$lstrFile'&display '$lstrFileWebp'& wont trash old one! use tag $CFGstrTagKeepOriginal"
        else
          if $bDryRun;then
            echo "WouldTrash: $lstrFile" >&2
          else
            SECFUNCtrash "$lstrFile"
          fi
        fi
      else
        SECFUNCechoErrA "webp file size is 0 lstrFileWebp='$lstrFileWebp'"
      fi
    fi
  fi
};export -f FUNCconv

: ${strRegexTypes:="jpg\|jpeg\|png"} #help

function FUNCstats() {
  local lstrRgx="$1";shift
  local lType="$1";shift
  local nTotSz=0;
  local lastrFindCmd=(
    find ./ 
    -type f 
    -iregex ".*[.]\(${lstrRgx}\)" 
    -not -iregex ".*\(${CFGstrTagKeepOriginal}\).*" 
    -exec stat -c %s '{}' \; 
  )
  echo "DBG lastrFindCmd: `SECFUNCparamsToEval "${lastrFindCmd[@]}"`" >&2
  IFS=$'\n' read -d '' -r -a anList < <("${lastrFindCmd[@]}")&&:;
  #~ IFS=$'\n' read -d '' -r -a anList < <( \
    #~ find ./ \
      #~ -type f \
      #~ -iregex ".*[.]\(${lstrRgx}\)" \
      #~ -not -iregex ".*\(${CFGstrTagKeepOriginal}\).*" \
      #~ -exec stat -c %s '{}' \; \
  #~ )&&:;
  if SECFUNCarrayCheck -n anList;then
    for nSz in "${anList[@]}";do 
      ((nTotSz+=nSz))&&:;
      echo -n "." >&2;
    done;echo >&2
    echo "$lType: Tot=${#anList[*]}  nTotSz.MB=`bc <<< "scale=2;$nTotSz/(1024*1024)"`" >&2
    echo ${#anList[*]}
  else
    echoc --info "nothing found..." >&2
    return 1
  fi
  
  return 0
}
export nTotOld
if ! nTotOld="`FUNCstats "$strRegexTypes" "OldFormats"`";then
  exit 1
fi

#~ nTotSzNew=0;
#~ IFS=$'\n' read -d '' -r -a anList < <(find ./ -type f -iregex ".*[.]webp" -exec stat -c %s '{}' \;)&&:;
#~ for nSz in "${anList[@]}";do ((nTotSzNew+=nSz))&&:;echo -n "." >&2;done;
#~ echo "TotNew=${#anList[*]}  nTotSzNew.MB=`bc <<< "scale=2;$nTotSzNew/(1024*1024)"`"
FUNCstats "webp" "NewFormat"&&:

IFS=$'\n' read -d '' -r -a astrFileList < <( \
  find ./ \
    -type f \
    -iregex ".*[.]\(${strRegexTypes}\)" \
    -not -iregex ".*\(${CFGstrTagKeepOriginal}\).*" \
)&&:
export nCount=0
for strFile in "${astrFileList[@]}";do
  FUNCconv "$strFile"
  ((nCount++))&&:
done

if SECFUNCarrayCheck -n astrFlOldSmaller;then
  echoc -p "The old size is smaller than new one for these:"
  SECFUNCarrayShow -v astrFlOldSmaller
  if echoc -q "Trash new and tag old with CFGstrTagKeepOriginal='$CFGstrTagKeepOriginal' ?";then
    for strFileOld in "${astrFlOldSmaller[@]}";do 
      SECFUNCdrawLine " $strFileOld "
      strFlNew="`FUNCnewNm "$strFileOld"`"
      
      ls -l "$strFileOld" "$strFlNew"
      echo "# eog '$strFileOld' & display '$strFlNew' & "
      
      SECFUNCtrash "$strFlNew"
      
      strExt="`SECFUNCfileSuffix "$strFileOld"`"
      strFileTagged="${strFileOld%.$strExt}.${CFGstrTagKeepOriginal}.${strExt}"
      SECFUNCexecA -ce mv -v "$strFileOld" "$strFileTagged"
    done
  fi
fi

if((${#astrFileFailList[*]}>0));then
  declare -p astrFileFailList
  echoc -p "These failed because of not valid image format?"
  for strFileFail in "${astrFileFailList[@]}";do echo "$strFileFail";hexdump -C -n 48 "$strFileFail";done
  for strFileFail in "${astrFileFailList[@]}";do echo "$strFileFail";done
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
