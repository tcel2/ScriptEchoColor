#!/bin/bash
# Copyright (C) 2018-2019 by Henrique Abdalla
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

: ${nShortDur:=$((60*1))}
export nShortDur #help short duration limit check

: ${CFGnCPUPerc:=50}
export CFGnCPUPerc #help overall CPUs percentage

: ${bLossLessMode:=false}
export bLossLessMode #help for conversion, test once at least to make sure is what you really want...

n1MB=$((1024*1024))
: ${CFGnPartMinMB:=1}
#export CFGnPartMinMB #help when splitting, parts will have this minimum MB size if possible

: ${CFGnPartSeconds:=30}; # from tests, max bitrate encoding perf is reached around 5s to 10s so 30s may overall speedup TODO confirm this is a good tip or not
export CFGnPartSeconds #help when splitting, parts will have around this length

: ${nSlowQSleep:=60}
export nSlowQSleep #help every question will wait this seconds
CFGnDefQSleep=$nSlowQSleep

bUseCPUlimit=true
astrVidExtList=(mp4 3gp flv avi mov mpeg)
strExample="DefaultValue"
strNewFormatSuffix="x265-HEVC"
bContinue=false
CFGstrTest="Test"
astrRemainingParams=()
CFGastrTmpWorkPathList=()
CFGastrFileList=()
astrAllParams=("${@-}") # this may be useful
sedRegexPreciseMatch='s"(.)"[\1]"g'
strWorkWith=""
bWorkWith=false
bTrashMode=false
bAddFiles=false
bFindWorks=false
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#[strNewFiles...] add videos to work with"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-a" || "$1" == "--add" ]];then #help ~single add one or more files
		bAddFiles=true
	elif [[ "$1" == "-c" || "$1" == "--continue" ]];then #help ~daemon resume work list
		bContinue=true
	elif [[ "$1" == "-C" || "$1" == "--Continue" ]];then #help ~daemon like --continue but will clear the last work reference and start from the first on the list
		bContinue=true
    SECFUNCcfgWriteVar -r CFGstrContinueWith=""
	elif [[ "$1" == "-o" || "$1" == "--onlyworkwith" ]];then #help ~single <strWorkWith> process a single file
		shift
		strWorkWith="${1-}"
    bWorkWith=true
	elif [[ "$1" == "-f" || "$1" == "--findworks" ]];then #help ~single search for convertable videos
    bFindWorks=true
	elif [[ "$1" == "--trash" ]];then #help ~single files maintenance (mainly for this script development)
		bTrashMode=true
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

function FUNCflFinal() { #help <lstrFl>
  local lstrFl="$1"
  local lstrSuffix="`SECFUNCfileSuffix "$lstrFl"`"
  echo "${lstrFl%.$lstrSuffix}.${strNewFormatSuffix}.mp4"
}

function FUNCflBNHash() {
  echo "`basename "$1"`" |md5sum |awk '{print $1}'
}

function FUNCflOrigPath() {
  local lstr="`dirname "$1"`"
  if [[ -z "$lstr" ]];then
    SECFUNCechoErrA "empty dirname, not abs filename"
    exit 1
  fi
  echo "$lstr"
}

function FUNCflTmpWorkPath() {
  #: ${strTmpWorkPath:="$strOrigPath/.${SECstrScriptSelfName}.tmp/"} #help
  echo "`FUNCflOrigPath "$1"`/.${SECstrScriptSelfName}.tmp/"
}

function FUNCflCleanFromDB() {
  local lstrFl="$1"
  
  #####
  ## Database consistency:
  #####
  # merge current list with possible new values
  local lastrFileListBKP=( "${CFGastrFileList[@]}" ); 
  SECFUNCcfgReadDB
  SECFUNCarrayWork --merge CFGastrFileList lastrFileListBKP
  # clean final list from current file
  local lstrRegexPreciseMatch="^`echo "$lstrFl" |sed -r "$sedRegexPreciseMatch"`$"
  SECFUNCarrayClean CFGastrFileList "$lstrRegexPreciseMatch"
  SECFUNCcfgWriteVar CFGastrFileList #SECFUNCarrayClean CFGastrFileList "$CFGstrFileAbs"
  declare -p FUNCNAME lstrFl lstrRegexPreciseMatch
  #SECFUNCarrayShow CFGastrFileList
}

function FUNCflAddToDB() {
  CFGastrFileList+=("`realpath "$1"`")
  SECFUNCarrayWork --uniq CFGastrFileList
  SECFUNCcfgWriteVar CFGastrFileList
}

function FUNCworkWith() {
  if ! SECFUNCexecA -ce $0 --onlyworkwith "$1";then
    echoc -w -t $CFGnDefQSleep -p "failed '$1'"
    return 1
  fi
  return 0
}

function FUNCworkFolders() {
  local lbTrash=false;
  if [[ "${1-}" == "--trash" ]];then
    lbTrash=true;
    shift
  fi
  
  for strFl in "${CFGastrFileList[@]}";do # grant nothing is missing
    CFGastrTmpWorkPathList+=("`FUNCflTmpWorkPath "$strFl"`")
  done
  SECFUNCarrayWork --uniq CFGastrTmpWorkPathList;SECFUNCcfgWriteVar CFGastrTmpWorkPathList
  
  local lbFound=false
  echoc --info "TmpFolders:"
  for strTmpPh in "${CFGastrTmpWorkPathList[@]}";do
    if [[ -d "$strTmpPh" ]];then
      lbFound=true
      
      if $lbTrash;then SECFUNCdrawLine;fi
      du -sh "$strTmpPh" 2>/dev/null
      
      if $lbTrash;then
        echoc -w -t 5 "trashing it..."
        SECFUNCtrash "$strTmpPh/"
      fi
    fi
  done
  
  if ! $lbFound;then return 1;fi
  
  return 0
}

function FUNCisHevc() { # <lstrFile>
  local lstrFile="$1"
  if [[ -f "$lstrFile" ]];then
    local lstrInfo
    if ! lstrInfo="`mediainfo "$lstrFile"`";then SECFUNCechoErrA "is not a video file lstrFile='$lstrFile'";return 1;fi
    local lstrFmt="`echo "$lstrInfo" |egrep "^Video$" -A 10 |egrep "Format *:"`" #TODO 10 lines after Video is a wild guess that may fail one day :(, seek for data sectors
    echo "$lstrFmt: $lstrFile" >&2
    #if echo "$lstrInfo" |grep -q "Format.*:.*HEVC";then
    if [[ "$lstrFmt" =~ .*HEVC.* ]];then
      return 0
    fi
  fi
  return 1
}

function FUNCvalidateOrigFiles() {
  local lbTrash=false;
  if [[ "${1-}" == "--clean" ]];then
    lbTrash=true;
    shift
  fi
  
  local lbFound=false
  for strFl in "${CFGastrFileList[@]}";do
    if $lbTrash;then SECFUNCdrawLine;fi
    
    if ! ls -l "$strFl" >/dev/null;then # will only output on failure
      lbFound=true
      if $lbTrash;then FUNCflCleanFromDB "$strFl";fi
    else
      if FUNCisHevc "$strFl";then
        lbFound=true
        echo "Is already HEVC: '$strFl'" >&2
        if $lbTrash;then FUNCflCleanFromDB "$strFl";fi
      fi
    fi
  done
  
  if ! $lbFound;then return 1;fi
  
  return 0
}

function FUNCnewFiles() {
  local lbTrash=false;
  if [[ "${1-}" == "--trash" ]];then
    lbTrash=true;
    shift
  fi
  
  local lbFound=false
  for strFl in "${CFGastrFileList[@]}";do
    if $lbTrash;then SECFUNCdrawLine;fi
    strFlNEW="`FUNCflFinal "$strFl"`"
    if ls -l "$strFlNEW";then
      lbFound=true
      if $lbTrash;then
        echoc -w -t 5 "trashing it..."
        SECFUNCtrash "$strFlNEW"
      fi
    fi
  done

  if ! $lbFound;then return 1;fi

  return 0
}

function FUNCcompletedFiles() {
  local lbTrash=false;
  if [[ "${1-}" == "--trash" ]];then
    lbTrash=true;
    shift
  fi
  
  local lbFound=false
  for strFl in "${CFGastrFileList[@]}";do
    if $lbTrash;then SECFUNCdrawLine;fi
    strFlNEW="`FUNCflFinal "$strFl"`"
    local lstrInfo
    if lstrInfo="`ls -l "$strFl" "$strFlNEW" 2>&1`";then
      echo "$lstrInfo"
      lbFound=true
      if $lbTrash;then
        echoc -w -t 5 "trashing OLD file..."
        SECFUNCtrash "$strFl"
      fi
    fi
  done

  if ! $lbFound;then return 1;fi

  return 0
}

# Main code ######################################################################################

if $bFindWorks;then
  IFS=$'\n' read -d '' -r -a astrFileList < <(find -iregex ".*[.]\(mp4\|avi\|mkv\|mpeg\|gif\)" -not -iregex ".*\(HEVC\|x265\).*")&&:
  astrCanWork=()
  for strFile in "${astrFileList[@]}";do
    echo -n .
    strFileR="`realpath "$strFile"`"
    if SECFUNCarrayContains CFGastrFileList "$strFileR";then continue;fi
    
    if FUNCisHevc "$strFile";then continue;fi #already is
    #~ strInfo="`mediainfo "$1"`"
    #~ if FUNCisHevc --info "$strInfo";then continue;fi
    
#    SECFUNCdrawLine --left " Checking: `basename "$strFile"` "
#    echo "Can work with it!" >&2
    echo "CanWorkWith: $strFileR"
    astrCanWork+=( "$strFileR" )
  done
  
  SECFUNCexecA -ce SECFUNCarrayShow astrCanWork
  if echoc -q "add all the above?";then
    $0 --add "${astrCanWork[@]}"
  fi
  exit 0
elif $bTrashMode;then
  SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run
  
  if FUNCcompletedFiles && [[ "`echoc -S "trash all the OLD files above (keeps the completed ones)? type 'YES'"`" == "YES" ]];then
    FUNCcompletedFiles --trash
  fi
  
  if FUNCvalidateOrigFiles && [[ "`echoc -S "clean from DB invalid file requests as above? type 'YES'"`" == "YES" ]];then
    FUNCvalidateOrigFiles --clean
  fi
  
  if FUNCworkFolders && [[ "`echoc -S "trash all temp folders above? type 'YES'"`" == "YES" ]];then
    FUNCworkFolders --trash
  fi
  
  if FUNCnewFiles && [[ "`echoc -S "trash all newly enconded files above (to let'em be recreated)? type 'YES'"`" == "YES" ]];then
    FUNCnewFiles --trash
  fi
  
  exit 0
elif $bWorkWith;then
  if ! strWorkWith="`realpath "$strWorkWith"`";then
    SECFUNCechoErrA "missing strWorkWith='$strWorkWith'"
    exit 1
  fi
  
  if ! SECFUNCarrayContains CFGastrFileList "$strWorkWith";then
    SECFUNCarrayPrepend CFGastrFileList "$strWorkWith"
  fi
  
  strFileAbs="$strWorkWith"
elif $bContinue;then
  while true;do
    SECFUNCcfgReadDB
    echoc --info " Continue @s@{By}Loop@S: "
    SECFUNCarrayShow CFGastrFileList
    if((`SECFUNCarraySize CFGastrFileList`==0));then echoc -w -t $CFGnDefQSleep "Waiting new job requests";continue;fi #break;fi
    
    astrFinalWorkList=()
    
    : ${bWorkWithSmallerFilesFirst:=true}
    export bWorkWithSmallerFilesFirst #help will acomplish more works faster this way than by name sorting
    if $bWorkWithSmallerFilesFirst;then
      IFS=$'\n' read -d '' -r -a astrSmallFirstFileList < <(ls -1Sr "${CFGastrFileList[@]}")&&:
      astrFinalWorkList=( "${astrSmallFirstFileList[@]}" )
    else
      astrFinalWorkList=( "${CFGastrFileList[@]}" )
    fi
    
    nCompletedCount=0
    for strFileAbs in "${astrFinalWorkList[@]}";do
      SECFUNCcfgReadDB
      
      while [[ -f "${CFGstrPriorityWork-}" ]];do
        echoc --info "@s@{By}PRIORITY:@S CFGstrPriorityWork='$CFGstrPriorityWork'"
        strPriorityWork="$CFGstrPriorityWork";SECFUNCcfgWriteVar -r CFGstrPriorityWork="" # to let it be skipped on next run
        FUNCflAddToDB "$strPriorityWork" #to grant it will be there too
        FUNCworkWith "$strPriorityWork"&&:
        SECFUNCcfgReadDB
      done
      
      if [[ -f "${CFGstrContinueWith-}" ]] && [[ "${CFGstrContinueWith}" != "$strFileAbs" ]];then 
        echo "Seeking '$CFGstrContinueWith' (skipping '$strFileAbs')" >&2
        continue;
      fi
      
      strFinalChk="`FUNCflFinal "$strFileAbs"`"
      if ls -l "$strFinalChk";then
        echo "Completed(skipping): $strFileAbs"
        if [[ "$CFGstrContinueWith" == "$strFileAbs" ]];then
          SECFUNCcfgWriteVar -r CFGstrContinueWith="" #this grants consistency in case the work is not on the list #TODO re-add it?
        fi
        ((nCompletedCount++))&&:
        continue;
      fi
      
      SECFUNCcfgWriteVar -r CFGstrContinueWith="$strFileAbs" #this is intended if current work is interrupted by any reason
      FUNCworkWith "$strFileAbs"&&:
      SECFUNCcfgWriteVar -r CFGstrContinueWith="" #this grants consistency in case the work is not on the list #TODO re-add it?
    done
    if((nCompletedCount==${#astrFinalWorkList[@]}));then
      SECFUNCarrayShow CFGastrFileList
      echoc --info "All the above works completed!"
      FUNCworkWith "${CFGastrFileList[0]}"&&: # just to let the interactive mode kick in #TODO RANDOM?
    fi
  done
  
  exit 0
elif $bAddFiles;then 
  for strNewFile in "$@";do
    if [[ -f "$strNewFile" ]];then
      echo "working with: strNewFile='$strNewFile'"
      FUNCflAddToDB "$strNewFile"
      #~ CFGastrFileList+=("`realpath "$strNewFile"`")
      #~ SECFUNCarrayWork --uniq CFGastrFileList
      #~ SECFUNCcfgWriteVar CFGastrFileList
    else  
      SEC_WARN=true SECFUNCechoWarnA "missing strNewFile='$strNewFile'"
    fi
  done
  SECFUNCarrayShow CFGastrFileList
  
  #~ # choses 1st to work on it
  #~ strFileAbs="${CFGastrFileList[0]-}"
  exit 0
else
  echoc -p "invalid usage"
  exit 1
fi

#~ if SECFUNCuniqueLock --isdaemonrunning;then
  #~ echoc --info "daemon already running, exiting."
  #~ exit 0
#~ fi

SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run

strSuffix="`SECFUNCfileSuffix "$strFileAbs"`"
strOrigPath="`FUNCflOrigPath "$strFileAbs"`"
#: ${strTmpWorkPath:="$strOrigPath/.${SECstrScriptSelfName}.tmp/"} #help
: ${strTmpWorkPath:="`FUNCflTmpWorkPath "$strFileAbs"`"}
export strTmpWorkPath #help if not set will be automatic based on current work file
SECFUNCexecA -ce mkdir -vp "$strTmpWorkPath"
CFGastrTmpWorkPathList+=("$strTmpWorkPath");SECFUNCarrayWork --uniq CFGastrTmpWorkPathList;SECFUNCcfgWriteVar CFGastrTmpWorkPathList

declare -p strFileAbs strOrigPath strTmpWorkPath
echoc --info " CURRENT WORK: @{Gr}$strFileAbs "

if [[ ! -f "$strFileAbs" ]];then
  SECFUNCechoErrA "missing strFileAbs='$strFileAbs'"
  #~ if echoc -t $CFGnDefQSleep -q "remove missing file from list?@Dy";then
    #~ FUNCflCleanFromDB "$strFileAbs"
    #~ exit 0
  #~ fi
  exit 1
fi

if FUNCisHevc "$strFileAbs";then
  echoc --info "Already HEVC format."
  #~ FUNCflCleanFromDB "$strFileAbs"
  exit 0
fi

strFileBN="`basename "$strFileAbs"`"
strFileBNHash="`FUNCflBNHash "$strFileBN"`" #the file may contain chars avconv wont accept at .join file

#strFileNoSuf="${strTmpWorkPath}/${strFileBNHash%.$strSuffix}"
strAbsFileNmHashTmp="${strTmpWorkPath}/${strFileBNHash}"
#strFinalFileBN="${strFileBN%.$strSuffix}.${strNewFormatSuffix}.mp4"
strFinalFileBN="`FUNCflFinal "$strFileBN"`"

function FUNCshortDurChk() {
  nDurationSeconds="`FUNCflDurationSec "$strFileAbs"`"
  if(( nDurationSeconds > nShortDur ));then
    if ! echoc -t $CFGnDefQSleep -q "this is a long file nDurationSeconds='$nDurationSeconds', work on it?";then
      return 1
    fi
  fi
  return 0
}

function FUNCavconvRaw() {
  if $bUseCPUlimit;then SECFUNCCcpulimit -r "avconv" -l $CFGnCPUPerc;fi
  (
    strFlLog="${strAbsFileNmHashTmp}.$BASHPID.log"
    echo -n >>"$strFlLog"
    tail -F --pid=$$ "$strFlLog"& #TODO this was assigning the `tail` PID, how!??! the missing '=' for --pid= ? -> tail -F --pid $BASHPID "$strFlLog"&
    SECFUNCexecA -ce nice -n 19 avconv "$@" >"$strFlLog" 2>&1 ; nRet=$?
    cat "$strFlLog" >>"${strAbsFileNmHashTmp}.log"
    if((nRet!=0));then
      SECFUNCechoErrA "failed nRet=$nRet"
    fi
    exit $nRet # subshell
  );local lnRet=$?;
  declare -p FUNCNAME lnRet
  return $lnRet
}

function FUNCavconvConv() { #help
	SECFUNCdbgFuncInA;
	# var init here
	local lstrExample="DefaultValue"
  local lbPart=false
  local lbMute=false
  local lbLossless=$bLossLessMode
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
  local lstrIn=""
  local lstrOut=""
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #FUNCavconvConv_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--io" ]];then #FUNCavconvConv_help <lstrExample> MISSING DESCRIPTION
			shift;lstrIn="$1"
      shift;lstrOut="$1"
    elif [[ "$1" == "-p" || "$1" == "--part" ]];then #FUNCavconvConv_help MISSING DESCRIPTION
      lbPart=true
    elif [[ "$1" == "-m" || "$1" == "--mute" ]];then #FUNCavconvConv_help MISSING DESCRIPTION
      lbMute=true
    elif [[ "$1" == "-m" || "$1" == "--mute" ]];then #FUNCavconvConv_help MISSING DESCRIPTION
      lbLossless=true
		elif [[ "$1" == "--" ]];then #FUNCavconvConv_help params after this are ignored as being these options, and stored at lastrRemainingParams. Will be used as extra avconv params between in and out files.
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift&&: #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			SECFUNCdbgFuncOutA;return 1
		fi
		shift&&:
	done
	
	#validate params here
	
	# work here
  local lastrPartParms=()
  lastrPartParms=(-c:v libx265);if $lbLossless;then lastrPartParms+=(-x265-params lossless=1);fi
  if ! $lbMute;then lastrPartParms+=(-c:a libmp3lame);fi
  if   $lbPart;then lastrPartParms+=(-fflags +genpts);fi
  if((`SECFUNCarraySize lastrRemainingParams`>0));then
    lastrPartParms+=( "${lastrRemainingParams[@]}" )
  fi
  
  local lstrFlTmp="${lstrOut}.TEMP_INCOMPLETE.mp4"
  SECFUNCtrash "$lstrFlTmp"&&:
  if FUNCavconvRaw -i "$lstrIn" "${lastrPartParms[@]}" "$lstrFlTmp";then
    SECFUNCexecA -ce mv -vf "$lstrFlTmp" "$lstrOut"
  else
    SECFUNCtrash "$lstrFlTmp"&&:
    return 1
  fi
	
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

function FUNCextDirectConv() {
  local lstrExt="$1"
  
  if [[ "`SECFUNCfileSuffix "$strFileAbs"`" != "$lstrExt" ]];then return 1;fi
  
  #strFl3gpAsMp4="${strFileAbs%.${lstrExt}}.mp4"
  strFl3gpAsMp4="`FUNCflFinal "$strFileAbs"`"
  if [[ ! -f "$strFl3gpAsMp4" ]];then
    #TODO what about large 3gp files?
    case "$lstrExt" in
      "3gp") 
        if FUNCshortDurChk;then
          FUNCrecreateRaw FUNCavconvConv --io "$strFileAbs" "$strFl3gpAsMp4"
          #FUNCavconvConv --io "$strFileAbs" "$strFl3gpAsMp4" #avconv -i "$strFileAbs" -acodec copy "$strFl3gpAsMp4"
          #echo -n >"${strAbsFileNmHashTmp}.recreated" # the small file fully created is equivalent to recreate function
        fi
        ;;
      "gif")
        local laOpts=()
        laOpts+=(-movflags faststart -pix_fmt yuv420p) # options for better browsers compatibility and performance
        laOpts+=(-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2") # fix to valid size that must be mult of 2
        #avconv -i "$strFileAbs" "${laCompat[@]}" -vf "$lstrFixToValidSize" "$strFl3gpAsMp4"
        FUNCrecreateRaw FUNCavconvConv --mute --io "$strFileAbs" "$strFl3gpAsMp4" -- "${laOpts[@]}"
        #echo -n >"${strAbsFileNmHashTmp}.recreated" # the small file fully created is equivalent to recreate function
        ;;
      *)
        SECFUNCechoErrA "unsupported lstrExt='$lstrExt'!!!"
        _SECFUNCcriticalForceExit
        ;;
    esac
  fi
  
  return 0
}

function FUNCflSizeBytes() { # in bytes
  stat -c "%s" "$1"
}

function FUNCflDurationMillis() {
  if SECFUNCarrayContains astrVidExtList "`SECFUNCfileSuffix "$1"`";then
    mediainfo -f "$1" |egrep "Duration .*: [[:digit:]]*$" |head -n 1 |grep -o "[[:digit:]]*"
  else
    echo "0" #TODO -1 as an indicator?
  fi
  return 0
}
function FUNCflDurationSec() {
  echo $((`FUNCflDurationMillis "$1"`/1000))&&:
  return 0
}

function FUNCrecreateRaw() {
  SECFUNCtrash "$strOrigPath/$strFinalFileBN"
  
  "$@"&&:;lnRet=$?;
  if((lnRet!=0));then 
    SECFUNCechoErrA "failed executing (lnRet=$?) '$*'"
    exit 1 # it is good to exit here to avoid having to capture this func return value TODO provide a better explanation :P
  fi
  
  echo -n >"${strAbsFileNmHashTmp}.recreated"
}

function FUNCrecreate() {
  if [[ -n "${1-}" ]];then       
    SECFUNCechoErrA "use FUNCrecreateRaw instead: $*"
    _SECFUNCcriticalForceExit
  fi

  FUNCrecreateRaw FUNCavconvConv --io "$strFileAbs" "$strOrigPath/$strFinalFileBN"
}

function FUNCvalidateFinal() {
  local lnRet=0
  local lstrAtt="@YATTENTION!!!@-n "
  
  if SECFUNCexecA -ce egrep "Past duration .* too large" "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The individual parts processing encountered the problematic the warnings above!"
    lnRet=1
  fi

  if SECFUNCexecA -ce egrep "Non-monotonous DTS in output stream .* previous: .*, current: .*; changing to .*. This may result in incorrect timestamps in the output file." "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The parts joining encountered problematic the warnings above!"
    lnRet=2
  fi
  
  if [[ -f "$strOrigPath/$strFinalFileBN" ]];then
    if((`FUNCflSizeBytes "$strOrigPath/$strFinalFileBN"` > `FUNCflSizeBytes "$strFileAbs"`));then
      echoc --alert "${lstrAtt}the new file is BIGGER than old one!"
      lnRet=3
    fi
    
    nDurSecOld="`FUNCflDurationSec "$strFileAbs"`"
    nDurSecNew="`FUNCflDurationSec "$strOrigPath/$strFinalFileBN"`"
    nMargin=$((nDurSecOld*5/100)) #TODO could just be a few seconds like 3 or 10 right? but small videos will not work like that...
    if((nMargin==0));then nMargin=1;fi
    declare -p nDurSecOld nDurSecNew nMargin
    if ! SECFUNCisSimilar $nDurSecOld $nDurSecNew $nMargin;then
      echoc --alert "${lstrAtt}the new duration nDurSecNew='$nDurSecNew' is weird! nDurSecOld='$nDurSecOld'"
      lnRet=4
    fi
  else
    SECFUNCechoErrA "The validation REQUIRES the final file '$strOrigPath/$strFinalFileBN' to be READY!"
    _SECFUNCcriticalForceExit
    #~ SEC_WARN=true SECFUNCechoWarnA "final file '$strOrigPath/$strFinalFileBN' is not ready yet"
    #~ lnRet=5
  fi
  
  if((lnRet!=0));then echo "$FUNCNAME lnRet=$lnRet";fi
  
  return $lnRet
}

function FUNCrecreateExtChk() {
  if FUNCextDirectConv "3gp" || FUNCextDirectConv "gif";then
    return 0
  fi
  return 1
}

function FUNCfinalMenuChk() {
  while true;do
    local lbReady=false
    if SECFUNCexecA -ce ls -l "$strFileAbs" "$strOrigPath/$strFinalFileBN";then 
      lbReady=true
    fi
    
    local lstrReco=""
    if [[ -f "${strAbsFileNmHashTmp}.recreated" ]];then # even if re-created before this current run
      lstrReco="(already did tho) "
    else
      if $lbReady && ! FUNCvalidateFinal;then
        lstrReco="@s@n!RECOMMENDED!@S "
      fi
    fi
    
    local lstrGifCycleSuffix="-Cycle.gif"
    local lbIsGifCycle=false;if [[ "$strFileAbs" =~ $lstrGifCycleSuffix ]];then lbIsGifCycle=true;fi
    astrOpt=(
      "apply patrol _cycle `SECFUNCternary -e "(@s@yALREADY DID@S) " "" $lbIsGifCycle`reverse gif effect on original file? #gif"
      "_diff old from new media info? #ready"
      "_fast mode? current CFGnDefQSleep=${CFGnDefQSleep}"
      "_list all probably useful details?"
      "_play the new file? #ready"
      "_recreate ${lstrReco}the new file now using it's full length (ignore split parts)?"
      "_s `SECFUNCternary -e "skip this @s@{yn}COMPLETED@S file for now?" "continue working on current file now?" $lbReady`"
      "_trash tmp and original video files?"
      "_use cpulimit (`SECFUNCternary --onoff $bUseCPUlimit`)?"
      "re-_validate `SECFUNCternary -e "logs and final file?" "existing incomplete logs?" $lbReady`"
      "set a new video to _work with?"
    )
    #############
    ### removed option keys will be ignored and `echoc -Q` will just return 0 for them and any other non set keys
    #############
    if ! $lbReady;then
      SECFUNCarrayClean astrOpt ".*[#]ready$"
    fi
    if [[ "$strSuffix" != "gif" ]];then
      SECFUNCarrayClean astrOpt ".*[#]gif$"
    fi
    echoc -t $CFGnDefQSleep -Q "@O\n\t`SECFUNCarrayJoin "\n\t" "${astrOpt[@]}"`\n@Ds"&&:;nRet=$?;case "`secascii $nRet`" in 
      c)
        local lstrFlNewCycleGif="${strFileAbs%.${strSuffix}}${lstrGifCycleSuffix}"
        SECFUNCCcpulimit -r "convert" -l $CFGnCPUPerc
        if SECFUNCexecA -ce convert "$strFileAbs" -coalesce -duplicate 1,-2-1 -verbose -layers OptimizePlus -loop 0 "$lstrFlNewCycleGif";then
          FUNCflAddToDB "$lstrFlNewCycleGif"
          FUNCflCleanFromDB "$strFileAbs"
          SECFUNCtrash "$strFileAbs" "$strOrigPath/$strFinalFileBN"&&:
          SECFUNCcfgWriteVar -r CFGstrPriorityWork="$lstrFlNewCycleGif"
          exit 0
        fi
        ;;
      d)
        SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
        ;;
      f)
        if((CFGnDefQSleep>5));then
          CFGnDefQSleep=5
        else
          CFGnDefQSleep=$nSlowQSleep
        fi
        SECFUNCcfgWriteVar -r CFGnDefQSleep
        ;;
      l)
        SECFUNCcfgReadDB
        
        echoc --info "Files:"
        for strFl in "${CFGastrFileList[@]}";do
          local lstrSuf="`SECFUNCfileSuffix "$strFl"`"
          local lstrFlFinal="`FUNCflFinal "$strFl"`"
          local lstrTmpPh="`FUNCflTmpWorkPath "$strFl"`";#CFGastrTmpWorkPathList+=("$lstrTmpPh")
          local lstrFlBNHash="`FUNCflBNHash "$strFl"`"
          local lstrFlRec="$lstrTmpPh/${lstrFlBNHash}.recreated";#declare -p lstrFlRec
          local lstrFlFinalSz="";if [[ -f "$lstrFlFinal" ]];then lstrFlFinalSz="$(du -h "$lstrFlFinal" |awk '{print $1}')";fi
          local lstrHasRec="$(SECFUNCternary --echotf "wasR" "" test -f "$lstrFlRec")"
          local lnParts="`ls "$lstrTmpPh/$lstrFlBNHash"*.mp4 2>/dev/null |wc -l`"
          
          echo -n "  $(SECFUNCternary --echotf "DONE${lstrHasRec}=${lstrFlFinalSz}" "ToDo" test -f "$lstrFlFinal"), "
          echo -n "Parts=$lnParts, "
#          echo -n "Dur=`FUNCflDurationSec "$lstrFlFinal"`/`FUNCflDurationSec "$strFl"`"
          if [[ "$lstrSuf" == "mp4" ]];then echo -n "OrigDurSec=`FUNCflDurationSec "$strFl"`, ";fi
          echo -n "\"`du -h "$strFl"`\", "
          if [[ -f "$lstrFlFinal" ]];then echo -n "\"${lstrFlFinal}\", ";fi
          echo -n "$lstrFlBNHash, "
          #~ echo -n "`basename "$strFl"`, "
          #~ echo -n "at `dirname "$strFl"`"
          echo
        done

        FUNCworkFolders
        ;;
      p)
        SECFUNCexecA -ce smplayer "$strOrigPath/$strFinalFileBN"&&:
        ;;
      r)
        if ! FUNCrecreateExtChk;then
          FUNCrecreate
        fi
        ;;
      s) # DEFAULT from timeout
        if $lbReady;then
          exit 0 # to work with the next one
        else
          return 0 # will just continue the flow and work on the current file
        fi
        ;;
      t)
        SECFUNCtrash "${strTmpWorkPath}/${strFileBNHash}"*
        SECFUNCtrash "$strFileAbs"&&:
        
        FUNCflCleanFromDB "$strFileAbs"
        exit 0 # to work with the next one
        ;;
      u)
        SECFUNCtoggleBoolean --show bUseCPUlimit
        ;;
      v)
        FUNCvalidateFinal&&:
        ;;
      w)
        local lstrNewWork="`echoc -S "paste the abs filename to work on it now"`"
        if [[ -f "$lstrNewWork" ]];then
          #$0 --onlyworkwith "$lstrNewWork"
          SECFUNCcfgWriteVar -r CFGstrPriorityWork="$lstrNewWork"
          exit 0 # to let it be processed on next run
        else
          SECFUNCechoErrA "not found lstrNewWork='$lstrNewWork'"
        fi
        ;;
      *) ############## 
         ### a wrong key pressed will just show the menu again
         ##############
        ;;
    esac
  done
}

#####################################################################
#####################################################################
########################## WORK ON FILE #############################
#####################################################################
#####################################################################

FUNCfinalMenuChk
if FUNCrecreateExtChk;then
  FUNCfinalMenuChk
  exit 0 # because is an alternative video processing mode
fi

nDurationSeconds="`FUNCflDurationSec "$strFileAbs"`"

nFileSzBytes="`FUNCflSizeBytes "$strFileAbs"`";
nMinPartSzBytes=$((CFGnPartMinMB*n1MB)) #not precise tho as split is based on keyframes #TODO right?

bJustRecreateDirectly=false
if(( nDurationSeconds <= nShortDur ));then
  echoc --info "short video nDurationSeconds='$nDurationSeconds'"
  bJustRecreateDirectly=true
fi
if((nFileSzBytes<nMinPartSzBytes));then
  echoc --info "small file nFileSzBytes='$nFileSzBytes'"
  bJustRecreateDirectly=true
fi
if $bJustRecreateDirectly;then ################ ALTERNATIVE PROCESSING ##################
  FUNCrecreate
  #~ FUNCavconvConv --io "$strFileAbs" "$strOrigPath/$strFinalFileBN"
  #~ FUNCmiOrigNew&&:
  FUNCfinalMenuChk
  exit 0
fi

############################
### normal video processing mode
############################

###################################### SPLIT ORIGINAL ##############################
if [[ ! -f "${strAbsFileNmHashTmp}.00000.mp4" ]];then
  echoc --info "Splitting" >&2
  
  nTotKeyFrames="`SECFUNCexecA -ce ffprobe -select_streams v:0 -skip_frame nokey -of csv=print_section=0 -show_entries frame=pkt_pts_time -loglevel error "$strFileAbs" |egrep "^[[:digit:]]*[.][[:digit:]]*$" |wc -l`"
  declare -p nTotKeyFrames >&2
  
  if((nTotKeyFrames<2));then
    echoc -p "unable to properly split strFileAbs='$strFileAbs' nTotKeyFrames='$nTotKeyFrames'"
    exit 1
  fi
  
  nDurMillis="`FUNCflDurationMillis "$strFileAbs"`"
  nMillisPerKeyFrame=$((nDurMillis/nTotKeyFrames)) # average
  nBytesPerKeyFrame=$((nFileSzBytes/nTotKeyFrames)) # average
  nTargetPartBytes=$((10*n1MB))
  nKeyFramesPerPart=$((nTargetPartBytes/nBytesPerKeyFrame))
  
  declare -p nDurMillis nMillisPerKeyFrame nBytesPerKeyFrame nTargetPartBytes nKeyFramesPerPart >&2
  
  ############ keep this to re-think if ever..
  ###  nParts=$((nFileSzBytes/nMinPartSzBytes))
  ###  CFGnPartSeconds=$((nDurationSeconds/nParts));
  ###  ((CFGnPartSeconds+=1))&&: # to compensate for remaining milliseconds
  ###  if((CFGnPartSeconds<30));then
  ###    CFGnPartSeconds=30; # max bitrate encoding perf is reached around 5s to 10s so this may overall speedup
  ###  fi
  ###  declare -p nDurationSeconds nFileSzBytes nMinPartSzBytes nParts CFGnPartSeconds
  ############
  
  FUNCavconvRaw -i "$strFileAbs" -c copy -flags +global_header -segment_time $CFGnPartSeconds -f segment "${strAbsFileNmHashTmp}."%05d".mp4" #|tee -a "${strAbsFileNmHashTmp}.log"
  #~ cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
fi

################################ WORK ON EACH PART ##############################

SECFUNCexecA -ce ls -l "${strAbsFileNmHashTmp}."* #|sort -n

IFS=$'\n' read -d '' -r -a astrFilePartList < <(ls -1 "${strAbsFileNmHashTmp}."?????".mp4" |sort -n)&&:
declare -p astrFilePartList |tr "[" "\n" >&2

#nCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"

astrFilePartNewList=()
echoc --info "Converting" >&2
nCount=0
for strFilePart in "${astrFilePartList[@]}";do
  SECFUNCcfgReadDB # dynamic updates functionalities like cpulimit
  
  strFilePartNS="${strFilePart%.mp4}"
  strPartTmp="${strAbsFileNmHashTmp}.NewPart.${strNewFormatSuffix}.TEMP.mp4"
  strFilePartNew="${strFilePartNS}.NewPart.${strNewFormatSuffix}.mp4"
  #~ strFilePartNewUnsafeName="${strFilePartNS}.NewPart.${strNewFormatSuffix}.mp4"
  #~ strSafeFileName="`dirname "$strFilePartNewUnsafeName"`/`basename "$strFilePartNewUnsafeName" |md5sum |awk '{print $1}'`" #|tr -d " "
  #~ strFilePartNew="$strSafeFileName"
#  declare -p strFilePart strFilePartNS strPartTmp strFilePartNewUnsafeName strSafeFileName strFilePartNew >&2
  declare -p strFilePart strFilePartNS strPartTmp strFilePartNew strTmpWorkPath strFileBNHash >&2
  
  if [[ -f "$strPartTmp" ]];then
    SECFUNCtrash "$strPartTmp"&&:
  fi
  
  if [[ ! -f "$strFilePartNew" ]];then
#    SECFUNCCcpulimit "avconv" -- -l $((25*nCPUs))
    #: ${CFGnCPUPerc:=50} #help overall CPUs percentage
    #SECFUNCCcpulimit -r "avconv" -l $CFGnCPUPerc
    nPerc="`bc <<< "scale=2;($nCount*100/${#astrFilePartList[*]})"`"
    #~ acmdFind=(find "${strTmpWorkPath}/" -maxdepth 1 -iregex ".*/${strFileBNHash}[.].*NewPart.*[.]mp4$")
    IFS=$'\n' read -d '' -r -a astrNewPartsList < <(find "${strTmpWorkPath}/" -maxdepth 1 -iregex ".*/${strFileBNHash}[.].*NewPart.*[.]mp4$")&&:
    #~ declare -p acmdFind
    #SECFUNCarrayShow astrNewPartsList
    nPercComp=0
    if((`SECFUNCarraySize astrNewPartsList`>0));then
      nNewPartsCurSizeKB=$((0+`du "${astrNewPartsList[@]}" |awk '{print $1 "+"}' |tr -d '\n'`0)) # the du size is in KB but makes no diff in this calc mode/way
      nEstimFinalSzKB="`bc <<< "scale=0;100*$nNewPartsCurSizeKB/$nPerc"`"
      nFileSzKB=$((nFileSzBytes/1024))
      nPercComp="`bc <<< "scale=2;100*$nEstimFinalSzKB/$nFileSzKB"`"
      declare -p nNewPartsCurSizeKB nEstimFinalSzKB nFileSzKB
    fi
    echoc --info "PROGRESS: $nCount/${#astrFilePartList[*]}, ${nPerc}% (EstComp=${nPercComp}%) for '$strFileAbs'"
    if FUNCavconvConv --part --io "$strFilePart" "$strPartTmp";then
    #if SECFUNCexecA -ce nice -n 19 avconv -i "$strFilePart" -c:v libx265 -c:a libmp3lame -fflags +genpts "$strPartTmp";then # libx265 -x265-params lossless=1
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

################################# JOIN NEW PARTS ON FINAL FILE ########################

( # to cd
  SECFUNCexecA -ce cd "$strTmpWorkPath"
  
  strFileJoin="`basename "${strAbsFileNmHashTmp}.join"`"
  
  echoc --info "Joining" >&2
  SECFUNCtrash "$strFileJoin" &&:
  for strFilePartNew in "${astrFilePartNewList[@]}";do
    #strSafeFileName="`basename "$strFilePartNew" |tr -d " "`"
    #mv -vf "$strFilePartNew" "$strSafeFileName"
    echo "file '$strFilePartNew'" >>"$strFileJoin"
  done
  SECFUNCexecA -ce cat "$strFileJoin"

  strFinalFlHashNmTmp="${strAbsFileNmHashTmp}.${strNewFormatSuffix}-TMP.mp4"
  SECFUNCtrash "$strFinalFlHashNmTmp"&&:
  if FUNCavconvRaw -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalFlHashNmTmp";then
    #~ cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
    
    SECFUNCexecA -ce mv -vf "$strFinalFlHashNmTmp" "$strFinalFileBN" #rename from hashedNm to correct final name
    SECFUNCexecA -ce mv -vf "$strFinalFileBN" "${strOrigPath}/"
    #~ FUNCmiOrigNew&&:
    FUNCfinalMenuChk
  fi
  exit 0 # from subshell
)

echoc -w -t $CFGnDefQSleep "Finished work with strFinalFileBN='$strFinalFileBN'"

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
