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

trap 'if echoc -q -t 10 "@s@{R}ERROR:@S waiting you review the log. DO NOT EXIT ON TIMEOUT?";then read;fi' ERR

: ${nShortDur:=$((60*1))}
export nShortDur #help short duration limit check

: ${CFGnCPUPerc:=5} # as background as possible and still useful
export CFGnCPUPerc #help overall CPUs percentage

: ${bLossLessMode:=false}
export bLossLessMode #help for conversion, test once at least to make sure is what you really want...

n1MB=$((1024*1024))
: ${CFGnPartMinMB:=1}
#export CFGnPartMinMB #help when splitting, parts will have this minimum MB size if possible

: ${CFGnPartSeconds:=60}; # from tests, max bitrate encoding perf is reached around 5s to 10s so 30s may overall speedup, but 60s may provide better conversion results regarding sound TODO confirm this is a good tip or not
export CFGnPartSeconds #help when splitting, parts will have around this length

: ${nSlowQSleep:=60}
export nSlowQSleep #help every question will wait this seconds
CFGnDefQSleep=$nSlowQSleep

: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
: ${bMaintCompletedMode:=false} #help

CFGstrKeepOriginalTag="KEEP_ORIGINAL" #help
bUseCPUlimit=true
astrVidExtList=(3gp avi flv gif mkv mov mp4 mpeg)
strVidExtListToGrep="`echo "${astrVidExtList[@]}" |sed -r 's" "\\\|"g'`";declare -p strVidExtListToGrep >&2
strExample="DefaultValue"
strNewFormatSuffix="x265-HEVC"
bDaemonContinueMode=false
CFGstrTest="Test"
astrRemainingParams=()
CFGastrTmpWorkPathList=()
CFGastrFileList=();export CFGastrFileList
CFGastrFailedList=();export CFGastrFailedList
astrAllParams=("${@-}") # this may be useful
strWorkWith=""
bWorkWith=false
bTrashMode=false
bAddFiles=false
bFindWorks=false
#: ${bRetryFailedMode:=false};export 
bRetryFailedMode=false
bCompletedMaintenanceMode=false
strFlRmSubtCC=""
#: ${astrOpenCloseCC[0]:="["};#help
#: ${astrOpenCloseCC[1]:="]"};#help
#declare -p astrOpenCloseCC >&2
: ${strOpenCloseCC:="[]"};#help
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
		bDaemonContinueMode=true
	elif [[ "$1" == "-C" || "$1" == "--Continue" ]];then #help ~daemon like --continue but will clear the last work reference and start from the first on the list
		bDaemonContinueMode=true
    SECFUNCcfgWriteVar -r CFGstrContinueWith=""
	elif [[ "$1" == "-f" || "$1" == "--findworks" ]];then #help ~single search for convertable videos (will ignore videos in the final format and filenames containing CFGstrKeepOriginalTag)
    bFindWorks=true
	elif [[ "$1" == "-m" || "$1" == "--maintcompl" ]];then #help ~single maintain completed works like finish&cleanup, play or cancel&trash WIP
		bCompletedMaintenanceMode=true
	elif [[ "$1" == "-o" || "$1" == "--onlyworkwith" ]];then #help ~single <strWorkWith> process a single file
		shift
		strWorkWith="${1-}"
    bWorkWith=true
	elif [[ "$1" == "-r" || "$1" == "--retryfailed" ]];then #help ~single list failed to let one be retried
		bRetryFailedMode=true
	elif [[ "$1" == "--trash" ]];then #help ~single files maintenance (mainly for this script development)
		bTrashMode=true
  elif [[ "$1" == "--rmSubtCC" ]];then #help ~single <strFlRmSubtCC> remove CC from subtitle file. Prior to calling, set this if needed: [strOpenCloseCC]
    shift;strFlRmSubtCC="$1"
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
if $bWriteCfgVars;then SECFUNCcfgAutoWriteAllVars;fi #this will also show all config vars

function FUNCflFinal() { #help <lstrFl>
  local lstrFl="$1"
  local lstrSuffix="`SECFUNCfileSuffix "$lstrFl"`"
  echo "${lstrFl%.$lstrSuffix}.${strNewFormatSuffix}.mp4"
}

function FUNCflSizeBytes() { # in bytes
  stat -c "%s" "$1"
}

function FUNCflKeep() { #help <lstrFl>
  local lstrFl="$1"
  local lstrSuffix="`SECFUNCfileSuffix "$lstrFl"`"
  echo "${lstrFl%.$lstrSuffix}.${CFGstrKeepOriginalTag}.${lstrSuffix}"
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

function FUNCacceptFinalFile() { # <lstrFileAbs>
  local lstrFileAbs="$1"
  
  local lstrFlTmpWorkPath="$(FUNCflTmpWorkPath "$lstrFileAbs")";declare -p lstrFlTmpWorkPath
  
  local lstrFileBN="$(basename "$lstrFileAbs")";declare -p lstrFileBN
  local lstrFlBNHash="$(FUNCflBNHash "$lstrFileBN")";declare -p lstrFlBNHash
  
  SECFUNCtrash "${lstrFlTmpWorkPath}/${lstrFlBNHash}"*
  SECFUNCtrash "$lstrFileAbs"
  FUNCflCleanFromDB "$lstrFileAbs"
}

function FUNCflAddFailedToDB() {
  SECFUNCcfgReadDB;
  CFGastrFailedList+=("$1");
  SECFUNCarrayWork --uniq CFGastrFailedList
  SECFUNCcfgWriteVar CFGastrFailedList
}

function FUNCflCleanFromDB() {
  local lstrFl="$1"
  
  #####
  ## Database consistency:
  #####
  # merge current list with possible new values
  local lastrFileListBKP=( "${CFGastrFileList[@]}" );echo "$LINENO: `date` ${FUNCNAME[@]} $lstrFl"
  SECFUNCcfgReadDB;echo "$LINENO: `date`"
  SECFUNCarrayWork --merge CFGastrFileList lastrFileListBKP;echo "$LINENO: `date`"
  # clean final list from current file
  SECFUNCarrayClean CFGastrFileList "^\"$lstrFl\"$";echo "$LINENO: `date`"
  SECFUNCcfgWriteVar CFGastrFileList;echo "$LINENO: `date`" #SECFUNCarrayClean CFGastrFileList "$CFGstrFileAbs"
  echo "$LINENO: `date`"
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
};export -f FUNCworkWith

function FUNCmaintWorkFolders() {
  echoc --info "FuncStak: ${FUNCNAME[@]}" >&2
  
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

function FUNCmaintValidateOrigFiles() {
  echoc --info "FuncStak: ${FUNCNAME[@]}" >&2
  
  local lbTrash=false;
  if [[ "${1-}" == "--clean" ]];then
    lbTrash=true;
    shift
  fi
  
  local lbFoundIssue=false
  local -i liTotalMissing=0
  local -i liTotalAlreadyConv=0
  local lastrMissingPaths=()
  for strFl in "${CFGastrFileList[@]}";do
    if $lbTrash;then SECFUNCdrawLine;fi
    
    if ! ls -l "$strFl" >/dev/null;then # will only output on failure
      local lstrDir="$(dirname "$strFl")" #declare -p lstrDir >&2
      if [[ -d "$lstrDir" ]];then
        lbFoundIssue=true # here it means that some maintenance action can be performed as the file is missing
        ((liTotalMissing++))&&:
        if $lbTrash;then FUNCflCleanFromDB "$strFl";fi
        SECFUNCechoWarnA -a "Missing File: '$strFl'" >&2
      else
        lastrMissingPaths+=( "$lstrDir" )
      fi
    else
      if FUNCisHevc "$strFl";then
        lbFoundIssue=true
        ((liTotalAlreadyConv++))&&:
        SECFUNCechoWarnA -a "Is already HEVC: '$strFl'" >&2
        if $lbTrash;then FUNCflCleanFromDB "$strFl";fi
      fi
    fi
  done
  
  if SECFUNCarrayCheck -n lastrMissingPaths;then
    echoc -p "these paths are not available, were their medias mounted?"
    SECFUNCarrayUniq lastrMissingPaths
    SECFUNCarrayShow lastrMissingPaths >&2
  fi

  if ! $lbFoundIssue;then return 1;fi
  
  declare -p liTotalMissing liTotalAlreadyConv >&2
  
  return 0
}

function FUNCmaintNewFiles() {
  echoc --info "FuncStak: ${FUNCNAME[@]}" >&2
  
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

function FUNCmaintCompletedFiles() {
  echoc --info "FuncStak: ${FUNCNAME[@]}" >&2
  
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

##################################################################################################
##################################################################################################
##################################################################################################
### Main code ####################################################################################
##################################################################################################
##################################################################################################
##################################################################################################

function MAIN() { :; } #source editor tag trick
if [[ -n "$strFlRmSubtCC" ]];then
  strSubtSfx="`SECFUNCfileSuffix "$strFlRmSubtCC"`"
  strFlSubtNew="${strFlRmSubtCC%.$strSubtSfx}.NoCC.${strSubtSfx}"
  strMatchCC="^([${strOpenCloseCC:0:1}].*[${strOpenCloseCC:1:1}])$";declare -p strMatchCC >&2
  nTot="`cat "$strFlRmSubtCC" |tr -d "\r" |egrep "${strMatchCC}" |wc -l`";declare -p nTot >&2
  if((nTot>0));then
    if [[ -f "$strFlSubtNew" ]];then SECFUNCtrash "$strFlSubtNew";fi
    cat "$strFlRmSubtCC" |tr -d "\r" |sed -r "s/${strMatchCC}/./" >"$strFlSubtNew"
    if echoc -t 10 -q "see diff?";then
      SECFUNCexecA -ce `SECFUNCternary which meld ? echo meld : echo colordiff` "$strFlRmSubtCC" "$strFlSubtNew"
    fi
  else
    echoc --info "no CC found on it..."
  fi
  
  exit 0
elif $bFindWorks;then 
  #~ SECFUNCexecA -ce SECFUNCarrayShow -v CFGastrFileList
#  IFS=$'\n' read -d '' -r -a astrFileList < <(find -iregex ".*[.]\(mp4\|avi\|mkv\|mpeg\|gif\)" -not -iregex ".*\(HEVC\|x265\|${CFGstrKeepOriginalTag}\).*")&&:
  IFS=$'\n' read -d '' -r -a astrFileList < <(\
    SECFUNCexecA -ce find \
      -iregex ".*[.]\(${strVidExtListToGrep}\)" \
      -not -iregex ".*\(HEVC\|x265\|$(basename $(FUNCflTmpWorkPath))\|${CFGstrKeepOriginalTag}\).*"\
  )&&:
  if ! SECFUNCarrayCheck -n astrFileList;then echoc --info "nothing found...";exit 0;fi
  
  SECFUNCexecA -ce SECFUNCarrayShow -v astrFileList
  astrCanWork=()
  for strFile in "${astrFileList[@]}";do
    echo -n .
    strFileR="`realpath "$strFile"`"
    if SECFUNCarrayContains CFGastrFileList "$strFileR";then echo "AlreadyAdded: '$strFileR'";continue;fi
    
    if FUNCisHevc "$strFile";then continue;fi #already is
    #~ strInfo="`mediainfo "$1"`"
    #~ if FUNCisHevc --info "$strInfo";then continue;fi
    
#    SECFUNCdrawLine --left " Checking: `basename "$strFile"` "
#    echo "Can work with it!" >&2
    echo "CanWorkWith: $strFileR"
    astrCanWork+=( "$strFileR" )
  done
  echo
  
  SECFUNCexecA -ce SECFUNCarrayShow -v astrCanWork
  if SECFUNCarrayCheck -n astrCanWork;then
    if echoc -q "add all the above?";then
      $0 --add "${astrCanWork[@]}"
    fi
  else
    echoc --info "nothing new/usable found..."
  fi
  exit 0
elif $bRetryFailedMode;then
  SECFUNCarrayShow CFGastrFailedList

  strNewWork="`echoc -S "paste the abs filename to work on it now"`"
  if [[ -f "$strNewWork" ]];then
    SECFUNCarrayClean CFGastrFailedList "^\"$strNewWork\"$"
    SECFUNCcfgWriteVar CFGastrFailedList
    #SECFUNCcfgWriteVar -r CFGstrPriorityWork="$strNewWork"
    SECFUNCcfgWriteVar -r CFGnDefQSleep=3600
#    nSlowQSleep=3600 $0 --onlyworkwith "$strNewWork"&&:
    bCleanTmpRelatedFiles=true $0 --onlyworkwith "$strNewWork"&&:
  fi
  exit 0
elif $bCompletedMaintenanceMode;then
  declare -i nSelectedIndex=-1
  while true;do
    astrMaintListDiag=()
    echoc --info "Preparing List"
    SECFUNCcfgReadDB
    bSelOk=false
    nTotReady=0
    for nIndex in "${!CFGastrFileList[@]}";do
      echo -en "."
      strFl="${CFGastrFileList[nIndex]}"
      strFlC="`FUNCflFinal "$strFl"`"
      #echo "(( (`FUNCflSizeBytes "$strFlC"` * 100) / `FUNCflSizeBytes "$strFl"` ))"
      if [[ -f "$strFl" ]] && [[ -f "$strFlC" ]];then
        if((nSelectedIndex==-1));then nSelectedIndex=$nIndex;fi
        bSel=false;if ! $bSelOk && ((nIndex>=nSelectedIndex));then bSel=true;bSelOk=true;fi
#        astrMaintListDiag+=("`SECFUNCternary --tf test $nIndex = $nSelectedIndex`" "$nIndex" "`basename "$strFlC"`" "$strFlC");
        astrMaintListDiag+=(
          #~ "`SECFUNCternary --tf $bSel`" 
          false
          "$nIndex" 
          "`SECFUNCfileSuffix "$strFl"`"
          "`FUNCflSizeBytes "$strFl"`"
          "$(( (`FUNCflSizeBytes "$strFlC"` * 100) / `FUNCflSizeBytes "$strFl"` ))"
          "`basename "$strFlC"`" 
          "`FUNCflBNHash "$strFl"`"
          "$strFlC"
        );
        ((nTotReady++))&&:
      fi
    done
    echo "$nTotReady"
    
    function FUNCCompletedMaintenanceMode() {
      local lnSelectedIndex="$2" # yad list index column, important to let the other columns be more easily modified as they will be ignored on return yad's value!
      
      declare -p FUNCNAME >&2
      SECFUNCarraysRestore #TODO (w/o this aliases wont expand preventing using ex.: SECFUNCexecA) why this fails and prevents this function from being run? -> source <(secinit) #to restore arrays
      echo "(${FUNCNAME[@]}) params: `SECFUNCparamsToEval "$@"`" >&2
      local lstrFlSel="${CFGastrFileList[$lnSelectedIndex]}"
      declare -p lnSelectedIndex lstrFlSel >&2
      if [[ -f "$lstrFlSel" ]];then
        local lastrCmd=( secTerm.sh --focus -- -e "$SECstrScriptSelfName" --onlyworkwith "$lstrFlSel" )
        #bMaintCompletedMode=true bWriteCfgVars=false bMenuTimeout=false \
          #SECFUNCexecA -ce secTerm.sh --focus -- -e \
            #"$SECstrScriptSelfName" --onlyworkwith "$lstrFlSel"
        declare -p lastrCmd >&2
#        bMaintCompletedMode=true bWriteCfgVars=false bMenuTimeout=false "${lastrCmd[@]}"
        bMaintCompletedMode=true bWriteCfgVars=false "${lastrCmd[@]}"
      else
        SECFUNCechoErrA "file not found lstrFlSel='$lstrFlSel'"
      fi
      #declare -p LINENO >&2
      
      return 0
    };export -f FUNCCompletedMaintenanceMode
    
    astrYadCmd=(
      yad 
      --button="gtk-close:1" 
      --button="TrashFinal!!Trash the FINAL new generated files selected:2"
      --button="AcceptFinal!!Trash the ORIGINAL OLD files selected:4"
      --button="RefreshList:3"
      --maximized 
      --center 
      --no-markup 
      --selectable-labels
      --title="$(basename $0) maintain completed jobs" 
      --text="double click for specific entry actions"
      --list 
      --checklist 
#      --dclick-action="bash -c 'source <(secinit --force);FUNCCompletedMaintenanceMode %s'"
      --dclick-action="bash -c 'FUNCCompletedMaintenanceMode %s'"
      
      --column "Action" # keep as first column!
      --column "Index:NUM" # keep as 2nd column! modify columns at will below here! xD
      --column "OrigExt"
      --column "OrigSz:NUM" 
      --column "%:NUM" 
      --column "basename" 
      --column "TmpBNHash"
      --column "full path" 
      
      "${astrMaintListDiag[@]}"
    )
    SECFUNCarraysExport
    SECFUNCarrayShow astrYadCmd #TODO why it is too much (errors out) for SECFUNCexecA as `SECFUNCexecA -ce "${astrYadCmd[@]}"` ?
    strSelectedEntries="`"${astrYadCmd[@]}"`"&&:;nRet=$?;declare -p nRet
    declare -p strSelectedEntries
    if((nRet==126));then SECFUNCechoErrA "some error happened nRet='$nRet'";exit 1;fi
    if((nRet==1 || nRet==252)) || [[ -z "$strSelectedEntries" ]];then exit 0;fi
    
    IFS=$'\n' read -d '' -r -a anSelectedIndexList < <(echo "$strSelectedEntries" |egrep "^TRUE" |tr "|" " " |awk '{print $2}')&&:
    if SECFUNCarrayCheck -n anSelectedIndexList;then
      echoc --info "Selected files:"
      case $nRet in
        2) #TrashFinal, this was used to recode gif conversion easily. TODO To continue being useful, let it trash also the tmp files.
          astrToTrashList=()
          for nSel in "${anSelectedIndexList[@]}";do
            strFlFinal="`FUNCflFinal "${CFGastrFileList[$nSel]}"`"
            astrToTrashList+=( "$strFlFinal" )
          done
          SECFUNCarrayShow astrToTrashList
          ls -l "${astrToTrashList[@]}"
          if echoc -q "Trash the above files?";then
            for strToTrash in "${astrToTrashList[@]}";do
              SECFUNCtrash "$strToTrash"
            done
          fi
          ;;
        4) #AcceptFinal
          astrFlList=()
          astrFlFinalList=()
          for nSel in "${anSelectedIndexList[@]}";do
            astrFlList+=( "${CFGastrFileList[$nSel]}" )
            
            strFlFinal="`FUNCflFinal "${CFGastrFileList[$nSel]}"`"
            astrFlFinalList+=( "$strFlFinal" )
          done
          SECFUNCarrayShow astrFlList
          ls -l "${astrFlList[@]}" "${astrFlFinalList[@]}"
          if echoc -q "Accept the final files for the above files?";then
            for strChosen in "${astrFlList[@]}";do
              FUNCacceptFinalFile "$strChosen"
            done
          fi
          ;;
      esac
    fi
  done
  exit 0 #~single
elif $bTrashMode;then
  SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run
  
  if FUNCmaintCompletedFiles && [[ "`echoc -S "Above are shown the old (original) and new (completed) files. To trash all (and only) the OLD files, type 'YES'"`" == "YES" ]];then
    FUNCmaintCompletedFiles --trash
  fi
  
  if FUNCmaintValidateOrigFiles && [[ "`echoc -S "clean from DB invalid file (missing or no conversion needed) requests as above? type 'YES'"`" == "YES" ]];then
    FUNCmaintValidateOrigFiles --clean
  fi
  
  if FUNCmaintWorkFolders && [[ "`echoc -S "trash all temp folders above? type 'YES'"`" == "YES" ]];then
    FUNCmaintWorkFolders --trash
  fi
  
  if FUNCmaintNewFiles && [[ "`echoc -S "trash all newly enconded files above (to let'em be recreated)? type 'YES'"`" == "YES" ]];then
    FUNCmaintNewFiles --trash
  fi

  SECFUNCarrayShow -v CFGastrFailedList
  if [[ "`echoc -S "clear failed works (skipper) list? type 'YES'"`" == "YES" ]];then
    CFGastrFailedList=()
    SECFUNCcfgWriteVar CFGastrFailedList
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
elif $bDaemonContinueMode;then
  export bMenuTimeout=true
  export bShowDaemonOpts=true
  #~ astrFinalWorkListPrevious=()
  while true;do
    SECFUNCcfgReadDB
    echoc --info " Continue @s@{By}Loop@S: "
    #SECFUNCarrayShow -v CFGastrFileList
    if((`SECFUNCarraySize CFGastrFileList`==0));then echoc -w -t $CFGnDefQSleep "Waiting new job requests";continue;fi #break;fi
    
    #~ astrFinalWorkList=()
    
    SECFUNCarrayShow -v CFGastrFileList
    : ${bWorkWithSmallerFilesFirst:=true}
    export bWorkWithSmallerFilesFirst #help will acomplish more works faster this way than by name sorting
    astrLsCmd=(ls -1)
    if $bWorkWithSmallerFilesFirst;then
      astrLsCmd+=(-S -r)
      #~ IFS=$'\n' read -d '' -r -a astrSmallFirstFileList < <(ls -1Sr "${CFGastrFileList[@]}"&&:)&&: #this also cleans missing files from the list
      #~ astrFinalWorkList=( "${astrSmallFirstFileList[@]}" )
      echoc --info "Smallers first!"
    #~ else
      #~ astrFinalWorkList=( "${CFGastrFileList[@]}" )
      #~ IFS=$'\n' read -d '' -r -a astrFinalWorkList < <(ls -1 "${CFGastrFileList[@]}"&&:)&&: #this also cleans missing files from the list
    fi
    IFS=$'\n' read -d '' -r -a astrFinalWorkList < <("${astrLsCmd[@]}" "${CFGastrFileList[@]}"&&:)&&: #this also cleans missing files from the list
    SECFUNCarrayShow -v astrFinalWorkList
    SECFUNCarrayShow -v CFGastrFailedList
    
    nCompletedCount=0
    nIgnoredCount=0
    for strFileAbs in "${astrFinalWorkList[@]}";do
      SECFUNCcfgReadDB
      
      while [[ -f "${CFGstrPriorityWork-}" ]];do
        echoc --info "@s@{By}PRIORITY:@S CFGstrPriorityWork='$CFGstrPriorityWork'"
        strPriorityWork="$CFGstrPriorityWork";SECFUNCcfgWriteVar -r CFGstrPriorityWork="" # to let it be skipped on next run
        FUNCflAddToDB "$strPriorityWork" #to grant it will be there too
        FUNCworkWith "$strPriorityWork"&&:
        SECFUNCcfgReadDB
      done
      
      #echoc --info "Seeking '$CFGstrContinueWith'" >&2
      if [[ -f "${CFGstrContinueWith-}" ]] && [[ "${CFGstrContinueWith}" != "$strFileAbs" ]];then 
        #echo "Seeking '$CFGstrContinueWith' (skipping '$strFileAbs')" >&2
        echo "Seeking continue work (skipping '$strFileAbs')" >&2
        ((nIgnoredCount++))&&:
        continue;
      fi
      
      if SECFUNCarrayContains CFGastrFailedList "$strFileAbs";then
        echo "!!!FAILED(skipping): $strFileAbs" >&2
        ((nIgnoredCount++))&&:
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
    
    declare -p nCompletedCount nIgnoredCount >&2
    if(( (nCompletedCount+nIgnoredCount) == ${#astrFinalWorkList[@]} ));then
      SECFUNCarrayShow CFGastrFileList
      echoc --info "All the above works completed!"
      
      if SECFUNCarrayCheck -n CFGastrFailedList;then
        SECFUNCarrayShow CFGastrFailedList
        echoc -p "Unable to work with the above files!"
      fi
      
      echoc -w -t 3600 "sleeping..."
      
      # just to let the interactive mode kick in
      SECFUNCcfgWriteVar -r CFGstrContinueWith=""
      FUNCworkWith "${astrFinalWorkList[0]}"&&: #TODO RANDOM file?
    fi
    
    echoc -w -t 10 "sleeping a bit..."
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
  #FUNCflCleanFromDB "$strFileAbs"
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
  local lstrPartID=""
  if [[ "$1" == "--PartID" ]];then 
    shift;lstrPartID=".${1}";
    shift; 
  fi
  
  if $bUseCPUlimit;then SECFUNCCcpulimit -r "avconv.*${lstrPartID}" -l $CFGnCPUPerc;fi #TODO difficult to get the params to avconv to match here...
  
  ( # subshell to let `tail` use the right pid TODO right?
    nBPid=$BASHPID
    strFlLog="${strAbsFileNmHashTmp}${lstrPartID}.pid${nBPid}.log"
    echo "DBG: $$ $strFlLog" >&2
    echo -n >>"$strFlLog"
    tail -F --pid=$nBPid "$strFlLog" |egrep "^ *(Input|Output|Duration|Stream|frame=)"& #TODO this was assigning the `tail` PID, how!??! the missing '=' for --pid= ? -> tail -F --pid $BASHPID "$strFlLog"&
    astrExecCmd=(nice -n 19 avconv "$@")
    echo "EXEC: `SECFUNCparamsToEval "${astrExecCmd[@]}"`" >&2
    SECFUNCexecA -ce "${astrExecCmd[@]}" >"$strFlLog" 2>&1 ; nRet=$?
    
    echo >>"${strAbsFileNmHashTmp}.log"
    echo "=================================================" >>"${strAbsFileNmHashTmp}.log"
    echo "LOGFILE=$strFlLog" >>"${strAbsFileNmHashTmp}.log"
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
  local lstrPartID=""
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #FUNCavconvConv_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "--io" ]];then #FUNCavconvConv_help <lstrIn> <lstrOut>
			shift;lstrIn="$1"
      shift;lstrOut="$1"
    elif [[ "$1" == "-p" || "$1" == "--part" ]];then #FUNCavconvConv_help <lstrPartID>
      lbPart=true
      shift;lstrPartID="$1"
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
  lastrPartParms=(-c:v libx265 -map 0:v);if $lbLossless;then lastrPartParms+=(-x265-params lossless=1);fi
  if ! $lbMute;then lastrPartParms+=(-c:a libmp3lame -map 0:a);fi
  if   $lbPart;then lastrPartParms+=(-fflags +genpts);fi
  if((`SECFUNCarraySize lastrRemainingParams`>0));then
    lastrPartParms+=( "${lastrRemainingParams[@]}" )
  fi
  
  local lstrFlTmp="${lstrOut}.TEMP_INCOMPLETE.mp4"
  SECFUNCtrash "$lstrFlTmp"&&:
  if FUNCavconvRaw --PartID "$lstrPartID" -i "$lstrIn" "${lastrPartParms[@]}" "$lstrFlTmp";then
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
        laOpts+=(-crf 10) # gifs lose too much quality, this is important to provide an acceptable alternative with good quality but much bigger size
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

function FUNCflDurationMillis() {
  local lstrFl="$1";shift
  local lstrExt="`SECFUNCfileSuffix "$lstrFl"`"
  local -i lnDur=0 #TODO -1 as an indicator of failure despite 0 is already..
  if SECFUNCarrayContains astrVidExtList "$lstrExt";then
    lnDur="`mediainfo -f "$lstrFl" |egrep "Duration .*: [[:digit:]]*$" |head -n 1 |grep -o "[[:digit:]]*"`"
  else
    SECFUNCarrayShow -v astrVidExtList >&2
    SEC_WARN=true SECFUNCechoWarnA "lstrExt='$lstrExt' not supported yet, lstrFl='$lstrFl'"
  fi
  
  echo "$lnDur"
  if((lnDur>0));then return 0;fi
  
  SECFUNCechoErrA "invalid lnDur='$lnDur' for lstrFl='$lstrFl'"
  exit 1
}
function FUNCflDurationSec() {
  local lstrFl="$1";shift
  local -i lnDurMill="`FUNCflDurationMillis "$lstrFl"`"
  local -i lnDuration=$((lnDurMill/1000))&&:
  #echo $((`FUNCflDurationMillis "$1"`/1000))&&:
  if((lnDuration<=0));then
     SECFUNCechoErrA "lnDuration=0 for lstrFl='$lstrFl' (lnDurMill='$lnDurMill')" #TODO less than 1s is not an error/problem tho...
    exit 1
  fi
  
  echo "$lnDuration"
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
  #~ local lstrFl="${1-}"
  
  #~ local lstrFlFinal
  #~ if [[ -n "$lstrFl" ]];then
    #~ lstrFlFinal="`FUNCflFinal "$strFl"`"
  #~ else #default
    #~ lstrFl="$strFileAbs"
    #~ lstrFlFinal="$strOrigPath/$strFinalFileBN"
  #~ fi
  #~ FUNCrecreateRaw FUNCavconvConv --io "$lstrFl" "$lstrFlFinal"
  if [[ -n "${1-}" ]];then       
    SECFUNCechoErrA "use FUNCrecreateRaw instead: $*"
    _SECFUNCcriticalForceExit
  fi

  FUNCrecreateRaw FUNCavconvConv --io "$strFileAbs" "$strOrigPath/$strFinalFileBN"
}

function FUNCvalidateFinal() { #[--ignoreFinalIfDoesntExist]
  local lbIgnFinal=false
  if [[ -n "${1-}" ]];then
    if [[ "$1" == "--ignoreFinalIfDoesntExist" ]];then
      lbIgnFinal=true
      shift
    fi
  fi
  
  #local lnRet=0
  local lstrAtt="@YATTENTION!!!@-n "
  local lstrErrMsg=""
  
  SECFUNCexecA -ce -m "failed if == 0" egrep "nTotKeyFrames" "${strAbsFileNmHashTmp}.log"&&:
  
  if SECFUNCexecA -ce egrep "Past duration .* too large" "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The individual parts processing encountered the problematic the warnings above!"
    lstrErrMsg+=" $LINENO" # lnRet=1
  fi

  if SECFUNCexecA -ce egrep "Non-monotonous DTS in output stream .* previous: .*, current: .*; changing to .*. This may result in incorrect timestamps in the output file." "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The parts joining encountered problematic the warnings above!"
    lstrErrMsg+=" $LINENO" # lnRet=2
  fi
  
  #~ if((`FUNCflSizeBytes "$strFileAbs"` < `FUNCflSizeBytes "$strOrigPath/$strFinalFileBN"`));then
    #~ echoc --alert "${lstrAtt}The final file size is BIGGER than the original one! pointless..."
    #~ lstrErrMsg+=" $LINENO"
  #~ fi
  
  if [[ -f "$strOrigPath/$strFinalFileBN" ]];then
    if((`FUNCflSizeBytes "$strOrigPath/$strFinalFileBN"` > `FUNCflSizeBytes "$strFileAbs"`));then
      echoc --alert "${lstrAtt}the new file is BIGGER than old one!"
      lstrErrMsg+=" $LINENO" # lnRet=3
    fi
    
    if [[ "`SECFUNCfileSuffix "$strFileAbs"`" != "gif" ]];then
      nDurSecOld="`FUNCflDurationSec "$strFileAbs"`"
      nDurSecNew="`FUNCflDurationSec "$strOrigPath/$strFinalFileBN"`"
      nMargin=$((nDurSecOld*5/100)) #TODO could just be a few seconds like 3 or 10 right? but small videos will not work like that...
      declare -p nDurSecOld nDurSecNew nMargin strFileAbs
      if((nMargin==0));then nMargin=1;fi
      declare -p nDurSecOld nDurSecNew nMargin
      if ! SECFUNCisSimilar "$nDurSecOld" "$nDurSecNew" "$nMargin";then
        echoc --alert "${lstrAtt}the new duration nDurSecNew='$nDurSecNew' is weird! nDurSecOld='$nDurSecOld'"
        lstrErrMsg+=" $LINENO" # lnRet=4
      fi
    fi
  else
    if ! $lbIgnFinal;then
      SECFUNCechoErrA "The validation REQUIRES the final file '$strOrigPath/$strFinalFileBN' to be READY!"
      _SECFUNCcriticalForceExit
      #~ SEC_WARN=true SECFUNCechoWarnA "final file '$strOrigPath/$strFinalFileBN' is not ready yet"
      #~ lnRet=5
    fi
  fi
  
  if [[ -n "$lstrErrMsg" ]];then 
    echo "$FUNCNAME lstrErrMsg='$lstrErrMsg'"
    return 1
  fi
#  if((lnRet!=0));then echo "$FUNCNAME lnRet=$lnRet";fi
  
  #return $lnRet
  return 0
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
      ls -l "${strAbsFileNmHashTmp}.recreated"
    else
      if $lbReady && ! FUNCvalidateFinal;then
        lstrReco="@s@n!RECOMMENDED!@S "
      fi
    fi
    
    local lstrGifCycleSuffix="-Cycle.gif"
    local lbIsGifCycle=false;if [[ "$strFileAbs" =~ $lstrGifCycleSuffix ]];then lbIsGifCycle=true;fi
    astrOpt=(
      "apply patrol _cycle (reverse gif effect) `SECFUNCternary -e "(@s@yALREADY DID@S) " "" $lbIsGifCycle` on original file? #gif"
      "_diff old from new media info? #ready"
      "list fail_ed?"
      "_fast mode? current CFGnDefQSleep=${CFGnDefQSleep} #timeout"
      "_keep original (trash the new one) and apply tag on it's filename?"
      "_list all files with (probably) useful details?"
      "play the _old file?"
      "_play the new file? #ready"
      "_recreate ${lstrReco}the new file now using it's full length (ignore split parts)?"
      "_s `SECFUNCternary -e "skip this @s@{yn}COMPLETED@S file for now?" "continue working on current file now?" $lbReady`"
      "_trash files (more options on next prompt)?"
      "_use cpulimit (`SECFUNCternary --onoff $bUseCPUlimit`)?"
      "re-_validate `SECFUNCternary -e "logs and final file?" "existing incomplete logs?" $lbReady`"
      "set a new video to _work with? #daemon" # this only works when in daemon loop as is used on next loop
    )
    #############
    ### removed option keys will be ignored and `echoc -Q` will just return 0 for them and any other non set keys
    #############
    if ! $lbReady;then
      SECFUNCarrayClean astrOpt ".*[#]ready.*"
    fi
    if [[ "$strSuffix" != "gif" ]];then
      SECFUNCarrayClean astrOpt ".*[#]gif.*"
    fi
    #if $bMaintCompletedMode;then 
      #SECFUNCarrayClean astrOpt ".*[#]maintcompl.*"
    #fi
    : ${bShowDaemonOpts:=false}
    if ! $bShowDaemonOpts;then
      SECFUNCarrayClean astrOpt ".*[#]daemon.*"
    fi
    
    astrEchocCmd=(echoc)
    #: ${bMenuTimeout:=true};export bMenuTimeout #help
    : ${bMenuTimeout:=false} #;if $bDaemonContinueMode;then bMenuTimeout=true;fi
    if $bMenuTimeout;then 
      astrEchocCmd+=(-t $CFGnDefQSleep);
    else
      SECFUNCarrayClean astrOpt ".*[#]timeout.*"
    fi
    #declare -p bDaemonContinueMode bMenuTimeout >&2
    
    "${astrEchocCmd[@]}" -Q "@O\n\t`SECFUNCarrayJoin "\n\t" "${astrOpt[@]}"`\n@Ds"&&:;nRet=$?;case "`secascii $nRet`" in 
      c)
        local lstrFlNewCycleGif="${strFileAbs%.${strSuffix}}${lstrGifCycleSuffix}"
        #~ SECFUNCCcpulimit -r "convert" -l $CFGnCPUPerc
        if SECFUNCexecA -ce convert "$strFileAbs" -coalesce -duplicate 1,-2-1 -verbose -layers OptimizePlus -loop 0 "$lstrFlNewCycleGif";then
          FUNCflAddToDB "$lstrFlNewCycleGif"
          FUNCflCleanFromDB "$strFileAbs"
          SECFUNCtrash "$strFileAbs" "$strOrigPath/$strFinalFileBN"&&:
          SECFUNCcfgWriteVar -r CFGstrPriorityWork="$lstrFlNewCycleGif"
          if $bMaintCompletedMode;then 
            SECFUNCuniqueLock --release # safe as will exit right after
            FUNCworkWith "$lstrFlNewCycleGif"
          fi
          #~ if $bDaemonContinueMode;then 
            #~ exit 0 #continue daemon mode
          #~ fi
          exit 0
        fi
        ;;
      d)
        SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
        ;;
      e)
        SECFUNCarrayShow CFGastrFailedList
        ;;
      f)
        if((CFGnDefQSleep>5));then
          CFGnDefQSleep=5
        else
          CFGnDefQSleep=$nSlowQSleep
        fi
        SECFUNCcfgWriteVar -r CFGnDefQSleep
        ;;
      k)
        if SECFUNCexecA -ce mv -v "$strFileAbs" "`FUNCflKeep "$strFileAbs"`";then
          SECFUNCtrash "${strTmpWorkPath}/${strFileBNHash}"* &&:
          SECFUNCtrash "$strOrigPath/$strFinalFileBN" &&:
          
          FUNCflCleanFromDB "$strFileAbs"
        fi
        
        #SECFUNCexecA -ce sleep 3;date;declare -p bMenuTimeout #TODO @@@rm
        if ! $bMenuTimeout;then echoc -w "waiting you review the trashing's log";fi
        #SECFUNCexecA -ce sleep 30;date #TODO @@@rm
        
        exit 0 # to work with the next one
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

        FUNCmaintWorkFolders
        ;;
      o)
        SECFUNCexecA -ce smplayer -ontop "$strFileAbs"&&:
        ;;
      p)
        SECFUNCexecA -ce smplayer -ontop "$strOrigPath/$strFinalFileBN"&&:
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
        declare -p strTmpWorkPath strFileBNHash
        if echoc -q "trash original and TMP files (and exit): '$strFileAbs'?";then
          FUNCacceptFinalFile "$strFileAbs"
          #SECFUNCtrash "${strTmpWorkPath}/${strFileBNHash}"*
          #SECFUNCtrash "$strFileAbs"&&:
          #FUNCflCleanFromDB "$strFileAbs"
        else
          strFlFinalToTrash="$(FUNCflFinal "$strFileAbs")"
          if echoc -q "trash completed final new file (allows recreating it directly from existing TMP parts): '$strFlFinalToTrash'?";then
            SECFUNCtrash "$strFlFinalToTrash"&&:
          fi
          
          if echoc -q "trash related TMP files (to generate them again)?";then
            SECFUNCtrash "${strTmpWorkPath}/${strFileBNHash}"*
          fi
        fi
        
        if ! $bMenuTimeout;then echoc -w "waiting you review the trashing's log";fi
        
        exit 0 # to work with the next one
        ;;
      u)
        SECFUNCtoggleBoolean --show bUseCPUlimit
        ;;
      v)
        FUNCvalidateFinal --ignoreFinalIfDoesntExist &&:
        ;;
      w)
        local lstrNewWork="`echoc -S "paste the abs filename to work on it now"`"
        if [[ -f "$lstrNewWork" ]];then
          #if $bMaintCompletedMode;then #this is like changing the current selected work
            ##(secTerm.sh $0 --onlyworkwith "$lstrNewWork")&
            #secTerm.sh --disown --focus -- -e "$SECstrScriptSelfName" --onlyworkwith "$lstrNewWork"
            #exit 0 # to end this one in favor of new term
          #else #this is to prevent proc nesting daemon clash
            #SECFUNCcfgWriteVar -r CFGstrPriorityWork="$lstrNewWork"
            #exit 0 # to let it be processed on next run/loop
          #fi
          SECFUNCcfgWriteVar -r CFGstrPriorityWork="$lstrNewWork"
          exit 0 # to let it be processed on next run/loop
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
: ${bCleanTmpRelatedFiles:=false};if $bCleanTmpRelatedFiles;then
  SECFUNCtrash "${strAbsFileNmHashTmp}."*
fi
if [[ ! -f "${strAbsFileNmHashTmp}.00000.mp4" ]];then
  echoc --info "Splitting" >&2
  
  #strOutputTotKF="`SECFUNCexecA -ce ffprobe -select_streams v:0 -skip_frame nokey -of csv=print_section=0 -show_entries frame=pkt_pts_time -loglevel error "$strFileAbs" |egrep "^[[:digit:]]*[.][[:digit:]]*$" |wc -l`"
  nTotKeyFrames="`SECFUNCexecA -ce ffprobe -select_streams v:0 -skip_frame nokey -of csv=print_section=0 -show_entries frame=pkt_pts_time -loglevel error "$strFileAbs" |egrep "^[[:digit:]]*[.][[:digit:]]*$" |tee /dev/stderr |wc -l`"
  declare -p nTotKeyFrames >&2
  
  if((nTotKeyFrames<2));then
    echoc -p "unable to fastly determine the frame count for strFileAbs='$strFileAbs' nTotKeyFrames='$nTotKeyFrames'"
#    if echoc -q -t `SECFUNCternary $bRetryFailedMode ? echo 3600 : echo $CFGnDefQSleep` "try again (slower method)?";then
    if echoc -q -t $CFGnDefQSleep "try again (slower method)?@Dy";then
      nTotKeyFrames="$(SECFUNCexecA -ce ffprobe "$strFileAbs" -show_entries frame=key_frame,pict_type,pkt_pts_time -select_streams v -of compact -v 0 |grep key_frame=1 |tee /dev/stderr |wc -l)"
      declare -p nTotKeyFrames >&2
      
      #echoc -w "IMPORTANT! the splitting may not work correctly providing a useless huge single part..."
    fi
  fi
  
  declare -p nTotKeyFrames >>"${strAbsFileNmHashTmp}.log"
  
  if((nTotKeyFrames<2));then
    echoc -p "unable to properly split strFileAbs='$strFileAbs' nTotKeyFrames='$nTotKeyFrames'"
    FUNCflAddFailedToDB "$strFileAbs"
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
  
  # subtitles will be ignored to let it work, by the missing option: -map 0:s
  FUNCavconvRaw -flags +global_header -fflags +genpts -i "$strFileAbs" -c copy -map 0:v -map 0:a -segment_time $CFGnPartSeconds -f segment "${strAbsFileNmHashTmp}."%05d".mp4" #|tee -a "${strAbsFileNmHashTmp}.log"
  #~ cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
fi

################################ WORK ON EACH PART ##############################

SECFUNCexecA -ce ls -l "${strAbsFileNmHashTmp}."* #|sort -n

IFS=$'\n' read -d '' -r -a astrFilePartList < <(ls -1 "${strAbsFileNmHashTmp}."?????".mp4" |sort -n)&&:
declare -p astrFilePartList |tr "[" "\n" >&2

nTotParts=`SECFUNCarraySize astrFilePartList`
if((nTotParts<2));then
  echoc -p "nTotParts=$nTotParts < 2"
  FUNCflAddFailedToDB "$strFileAbs"
  exit 1
fi

#nCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"

astrFilePartNewList=()
echoc --info "Converting" >&2
nCount=0
for strFilePart in "${astrFilePartList[@]}";do
  SECFUNCcfgReadDB # dynamic updates functionalities like cpulimit
  
  strFilePartNS="${strFilePart%.mp4}"
  
  strPartID="$(basename "$strFilePartNS")"
  strPartID="${strPartID#${strFileBNHash}.}";
  declare -p strPartID >&2
  
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
    if FUNCavconvConv --part "$strPartID" --io "$strFilePart" "$strPartTmp";then
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
