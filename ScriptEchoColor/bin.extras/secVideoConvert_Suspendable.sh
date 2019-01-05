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

: ${nShortDur:=$((60*5))}
export nShortDur #help short duration limit check

: ${nCPUPerc:=50}
export nCPUPerc #help overall CPUs percentage

: ${bLossLessMode:=false}
export bLossLessMode #help for conversion, test once at least to make sure is what you really want...

n1MB=$((1024*1024))
: ${nPartMinMB:=1}
export nPartMinMB #help when splitting, parts will have this minimum MB size if possible

: ${nSlowQSleep:=60}
export nSlowQSleep #help every question will wait this seconds
CFGnDefQSleep=$nSlowQSleep

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
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#[strNewFiles...] add videos to work with"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-o" || "$1" == "--onlyworkwith" ]];then #help <strWorkWith> process a single file
		shift
		strWorkWith="${1-}"
    bWorkWith=true
	elif [[ "$1" == "-c" || "$1" == "--continue" ]];then #help resume last work if any
		bContinue=true
	elif [[ "$1" == "--trash" ]];then #help tmp and new files maintenance
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
  declare -p CFGastrFileList |tr '[' '\n'
}

function FUNCflAddToDB() {
  CFGastrFileList+=("`realpath "$1"`")
  SECFUNCarrayWork --uniq CFGastrFileList
  SECFUNCcfgWriteVar CFGastrFileList
}

function FUNCworkWith() {
  if ! SECFUNCexecA -ce $0 --onlyworkwith "$1";then
    echoc -t $CFGnDefQSleep -p "failed '$1'"
    return 1
  fi
  return 0
}

function FUNCtmpFolders() {
  local lbTrash=false;
  if [[ "${1-}" == "--trash" ]];then
    lbTrash=true;
    shift
  fi
  
  echoc --info "TmpFolders:"
  SECFUNCarrayWork --uniq CFGastrTmpWorkPathList;#SECFUNCcfgWriteVar CFGastrTmpWorkPathList
  for strTmpPh in "${CFGastrTmpWorkPathList[@]}";do
    if [[ -d "$strTmpPh" ]];then
      if $lbTrash;then SECFUNCdrawLine;fi
      du -sh "$strTmpPh" 2>/dev/null
      
      if $lbTrash;then
        echoc -w -t 5 "trashing it..."
        SECFUNCtrash "$strTmpPh/"
      fi
    fi
  done
  return 0
}

function FUNCnewFiles() {
  local lbTrash=false;
  if [[ "${1-}" == "--trash" ]];then
    lbTrash=true;
    shift
  fi
  
  for strFl in "${CFGastrFileList[@]}";do
    if $lbTrash;then SECFUNCdrawLine;fi
    strFlNEW="`FUNCflFinal "$strFl"`"
    if ls -l "$strFlNEW";then
      if $lbTrash;then
        echoc -w -t 5 "trashing it..."
        SECFUNCtrash "$strFlNEW"
      fi
    fi
  done
  return 0
}

# Main code ######################################################################################

if $bTrashMode;then
  FUNCtmpFolders
  if echoc -q "trash all temp folders above?";then
    FUNCtmpFolders --trash
  fi
  
  FUNCnewFiles
  if echoc -q "trash all newly enconded files above?";then
    FUNCnewFiles --trash
  fi
  
  exit 0
fi

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
  #~ if ! SECFUNCarrayCheck CFGastrFileList;then
    #~ CFGastrFileList=()
  #~ fi
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
  declare -p CFGastrFileList |tr '[' '\n'
  
  if $bContinue;then
    while true;do
      SECFUNCcfgReadDB
      echoc --info " Continue @s@{By}Loop@S: "
      declare -p CFGastrFileList |tr '[' '\n'
      if((`SECFUNCarraySize CFGastrFileList`==0));then echoc -w -t $CFGnDefQSleep "Waiting new job requests";continue;fi #break;fi
      
      for strFileAbs in "${CFGastrFileList[@]}";do
        SECFUNCcfgReadDB
        
        if [[ -f "${CFGstrPriorityWork-}" ]];then
          echoc --info "@s@{By}PRIORITY:@S CFGstrPriorityWork='$CFGstrPriorityWork'"
          SECFUNCcfgWriteVar CFGstrPriorityWork="" # to let it be skipped
          FUNCworkWith "$CFGstrPriorityWork"&&:
        fi
        
        if [[ -f "${CFGstrContinueWith-}" ]] && [[ "${CFGstrContinueWith}" != "$strFileAbs" ]];then 
          echo "Seeking '$CFGstrContinueWith' (skipping '$strFileAbs')" >&2
          continue;
        fi
        
        SECFUNCcfgWriteVar CFGstrContinueWith="$strFileAbs" #this is intended if current work is interrupted by any reason
        FUNCworkWith "$strFileAbs"&&:
        SECFUNCcfgWriteVar CFGstrContinueWith="" #this grants consistency in case the work is not on the list #TODO re-add it?
      done
    done
    
    exit 0
  else
    # choses 1st to work on it
    strFileAbs="${CFGastrFileList[0]-}"
  fi
fi

#~ if SECFUNCuniqueLock --isdaemonrunning;then
  #~ echoc --info "daemon already running, exiting."
  #~ exit 0
#~ fi

SECFUNCuniqueLock --waitbecomedaemon #to prevent simultaneous run

strOrigPath="`FUNCflOrigPath "$strFileAbs"`"
#: ${strTmpWorkPath:="$strOrigPath/.${SECstrScriptSelfName}.tmp/"} #help
: ${strTmpWorkPath:="`FUNCflTmpWorkPath "$strFileAbs"`"}
export strTmpWorkPath #help if not set will be automatic based on current work file
SECFUNCexecA -ce mkdir -vp "$strTmpWorkPath"
CFGastrTmpWorkPathList+=("$strTmpWorkPath");SECFUNCcfgWriteVar CFGastrTmpWorkPathList

declare -p strFileAbs strOrigPath strTmpWorkPath
echoc --info " CURRENT WORK: @{Gr}$strFileAbs "

if [[ ! -f "$strFileAbs" ]];then
  SECFUNCechoErrA "missing strFileAbs='$strFileAbs'"
  if echoc -t $CFGnDefQSleep -q "remove missing file from list?";then
    FUNCflCleanFromDB "$strFileAbs"
    exit 0
  fi
  exit 1
fi

if mediainfo "$strFileAbs" |grep "Format.*:.*HEVC";then
  echoc --info "Already HEVC format."
  FUNCflCleanFromDB "$strFileAbs"
  exit 0
fi

strFileBN="`basename "$strFileAbs"`"
strFileNmHash="`FUNCflBNHash "$strFileBN"`" #the file may contain chars avconv wont accept at .join file

#strFileNoSuf="${strTmpWorkPath}/${strFileNmHash%.$strSuffix}"
strAbsFileNmHashTmp="${strTmpWorkPath}/${strFileNmHash}"
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
  #~ SECFUNCexecA -ce avconv -i "$strFileAbs" -c copy -flags +global_header -segment_time $nPartSeconds -f segment "${strAbsFileNmHashTmp}."%05d".mp4" #|tee -a 
  #~ SECFUNCexecA -ce avconv -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalTmp"
  #~ SECFUNCexecA -ce nice -n 19 avconv -i "$lstrIn" "${lastrPartParms[@]}" "$lstrOut" #|tee -a "${strAbsFileNmHashTmp}.log"
  SECFUNCCcpulimit -r "avconv" -l $nCPUPerc
  #~ (
    #~ SECFUNCfdReport
    #~ exec 2>&1 
    #~ exec > >(tee -a "${strAbsFileNmHashTmp}.log")
    #~ ls -l ${strAbsFileNmHashTmp}.log
    #~ SECFUNCfdReport
    #~ SECFUNCexecA -ce nice -n 19 avconv "$@" >"${strAbsFileNmHashTmp}.log" 2>&1
    #~ ls -l ${strAbsFileNmHashTmp}.log
    #~ #cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
  #~ )
  (
    strFlLog="${strAbsFileNmHashTmp}.$BASHPID.log"
    echo -n >>"$strFlLog"
    tail -F --pid=$$ "$strFlLog"& #TODO this was assigning the `tail` PID, how!??! the missing '=' for --pid= ? -> tail -F --pid $BASHPID "$strFlLog"&
    SECFUNCexecA -ce nice -n 19 avconv "$@" >"$strFlLog" 2>&1 ; nRet=$?
    cat "$strFlLog" >>"${strAbsFileNmHashTmp}.log"
    if((nRet!=0));then
      SECFUNCechoErrA "failed nRet=$nRet"
    fi
    exit $nRet
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
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
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
  
  #~ local lstrTmpWorkPath="``"
  #~ local lstrFileNmHash="`FUNCflBNHash "$lstrIn"`"
  #~ local lstrAbsFileNmHashTmp="${strTmpWorkPath}/${lstrFileNmHash}"
  #~ local lstrFinalTmp="${lstrAbsFileNmHashTmp}.${strNewFormatSuffix}-TMP.mp4"
  #~ SECFUNCtrash "$lstrFinalTmp"&&:
  #~ if ! FUNCavconvRaw -i "$lstrIn" "${lastrPartParms[@]}" "$lstrFinalTmp";then
    #~ SECFUNCexecA -ce mv -vf "$lstrFinalTmp" "$lstrOut"
    #~ return 1
  #~ fi
  local lstrFlTmp="${lstrOut}.TEMP_INCOMPLETE.mp4"
  SECFUNCtrash "$lstrFlTmp"&&:
  if FUNCavconvRaw -i "$lstrIn" "${lastrPartParms[@]}" "$lstrFlTmp";then
    SECFUNCexecA -ce mv -vf "$lstrFlTmp" "$lstrOut"
  else
    SECFUNCtrash "$lstrFlTmp"&&:
    return 1
  fi
  #~ : ${nCPUPerc:=50} #help overall CPUs percentage
  #~ SECFUNCCcpulimit -r "avconv" -l $nCPUPerc
  #~ (
    #~ exec 2>&1 
    #~ exec > >(tee -a "${strAbsFileNmHashTmp}.log")
    #~ SECFUNCexecA -ce nice -n 19 avconv -i "$lstrIn" "${lastrPartParms[@]}" "$lstrOut" #|tee -a "${strAbsFileNmHashTmp}.log"
    #~ #cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
  #~ )
	
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

function FUNCextDirectConv() {
  local lstrExt="$1"
  if [[ "`SECFUNCfileSuffix "$strFileAbs"`" == "$lstrExt" ]];then
    #strFl3gpAsMp4="${strFileAbs%.${lstrExt}}.mp4"
    strFl3gpAsMp4="`FUNCflFinal "$strFileAbs"`"
    if [[ ! -f "$strFl3gpAsMp4" ]];then
      #TODO what about large 3gp files?
      case "$lstrExt" in
        "3gp") 
          if FUNCshortDurChk;then
            FUNCavconvConv --io "$strFileAbs" "$strFl3gpAsMp4" #avconv -i "$strFileAbs" -acodec copy "$strFl3gpAsMp4"
          fi
          ;;
        "gif")
          local laOpts=()
          laOpts+=(-movflags faststart -pix_fmt yuv420p) # options for better browsers compatibility and performance
          laOpts+=(-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2") # fix to valid size that must be mult of 2
          #avconv -i "$strFileAbs" "${laCompat[@]}" -vf "$lstrFixToValidSize" "$strFl3gpAsMp4"
          FUNCavconvConv --mute --io "$strFileAbs" "$strFl3gpAsMp4" -- "${laOpts[@]}"
          ;;
        *)
          SECFUNCechoErrA "unsupported lstrExt='$lstrExt'!!!"
          _SECFUNCcriticalForceExit
          ;;
      esac
    fi
    
    #~ if [[ -f "$strFl3gpAsMp4" ]];then
      #~ SECFUNCexecA -ce ls -l "$strFileAbs" "$strFl3gpAsMp4"
      #~ if echoc -t $CFGnDefQSleep -q "trash ${lstrExt} file?";then
        #~ FUNCflCleanFromDB "$strFileAbs"
        #~ #FUNCflAddToDB "$strFl3gpAsMp4"
        #~ #echoc --info ".${lstrExt} file was converted to .mp4 wich will now be used instead on next run"
        #~ # echoc --info ".${lstrExt} file was converted to .mp4"
        #~ # SECFUNCexecA -ce ls -l "${strFileAbs%.${lstrExt}}"*
        #~ SECFUNCtrash "$strFileAbs"
      #~ fi
    #~ fi
    
    #~ exit 0 #yes, exit to let the new full filename be used properly
  fi
  
  return 0
}

function FUNCflSize() {
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

function FUNCrecreate() {
  SECFUNCtrash "$strOrigPath/$strFinalFileBN"
  FUNCavconvConv --io "$strFileAbs" "$strOrigPath/$strFinalFileBN"
  echo -n >"${strAbsFileNmHashTmp}.recreated"
}

function FUNCvalidateFinal() {
  local lnRet=0
  local lstrAtt="@YATTENTION!!!@-n "
  
  if SECFUNCexecA -ce egrep "Past duration .* too large" "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The individual parts processing encountered the problematic the warnings above!"
    ((lnRet++))&&:
  fi

  if SECFUNCexecA -ce egrep "Non-monotonous DTS in output stream .* previous: .*, current: .*; changing to .*. This may result in incorrect timestamps in the output file." "${strAbsFileNmHashTmp}.log";then
    echoc --alert "${lstrAtt}The parts joining encountered problematic the warnings above!"
    ((lnRet++))&&:
  fi
  
  if((`FUNCflSize "$strOrigPath/$strFinalFileBN"` > `FUNCflSize "$strFileAbs"`));then
    echoc --alert "${lstrAtt}the new file is BIGGER than old one!"
    ((lnRet++))&&:
  fi
  
  nDurSecOld="`FUNCflDurationSec "$strFileAbs"`"
  nDurSecNew="`FUNCflDurationSec "$strOrigPath/$strFinalFileBN"`"
  nMargin=$((nDurSecOld*5/100)) #TODO could just be a few seconds like 3 or 10 right? but small videos will not work like that...
  if((nMargin==0));then nMargin=1;fi
  declare -p nDurSecOld nDurSecNew nMargin
  if ! SECFUNCisSimilar $nDurSecOld $nDurSecNew $nMargin;then
    echoc --alert "${lstrAtt}the new duration nDurSecNew='$nDurSecNew' is weird! nDurSecOld='$nDurSecOld'"
    ((lnRet++))&&:
  fi
  
  return $lnRet
}

function FUNCfinalMenuChk() {
  while true;do
    if ! SECFUNCexecA -ce ls -l "$strFileAbs" "$strOrigPath/$strFinalFileBN";then return 0;fi
    
    strReco=""
    if ! FUNCvalidateFinal;then
      strReco="@s@n!RECOMMENDED!@S "
    fi
    if [[ -f "${strAbsFileNmHashTmp}.recreated" ]];then # even if re-created before this current run
      strReco="(already did) "
    fi
    
    astrOpt=(
      "_diff old from new media info?"
      "_fast mode? current CFGnDefQSleep=${CFGnDefQSleep}"
      "_list all?"
      "_play the new file?"
      "_recreate ${strReco}the new file now using it's full length (ignore split parts)?"
      "_skip this file for now?"
      "_trash tmp and old files?"
      "set a new one to _work with?"
    )
    #~ strOpts="`for strOpt in "${astrOpt[@]}";do echo -n "${strOpt}\n";done`"
    #~ echoc -t $CFGnDefQSleep -Q "@O\n ${strOpts}"&&:; nRet=$?; case "`secascii $nRet`" in 
    echoc -t $CFGnDefQSleep -Q "@O\n\t`SECFUNCarrayJoin "\n\t" "${astrOpt[@]}"`\n@Ds"&&:;nRet=$?;case "`secascii $nRet`" in 
      d)
        SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
        ;;
      f)
        if((CFGnDefQSleep>5));then
          CFGnDefQSleep=5
        else
          CFGnDefQSleep=$nSlowQSleep
        fi
        SECFUNCcfgWriteVar CFGnDefQSleep
        ;;
      l)
        SECFUNCcfgReadDB
        
        echoc --info "Files:"
        for strFl in "${CFGastrFileList[@]}";do
          local lstrSuf="`SECFUNCfileSuffix "$strFl"`"
          local lstrFlFinal="`FUNCflFinal "$strFl"`"
          local lstrTmpPh="`FUNCflTmpWorkPath "$strFl"`";CFGastrTmpWorkPathList+=("$lstrTmpPh")
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

        FUNCtmpFolders
        ;;
      p)
        SECFUNCexecA -ce smplayer "$strOrigPath/$strFinalFileBN"&&:
        ;;
      r)
        FUNCrecreate
        ;;
      s)
        break;
        ;;
      t)
        SECFUNCtrash "${strTmpWorkPath}/${strFileNmHash}"*
        SECFUNCtrash "$strFileAbs"&&:
        
        FUNCflCleanFromDB "$strFileAbs"
        break
        ;;
      w)
        local lstrNewWork="`echoc -S "paste the abs filename to work on it now"`"
        if [[ -f "$lstrNewWork" ]];then
          #$0 --onlyworkwith "$lstrNewWork"
          SECFUNCcfgWriteVar CFGstrPriorityWork="$lstrNewWork"
          break; 
        else
          SECFUNCechoErrA "not found lstrNewWork='$lstrNewWork'"
        fi
        ;;
      *)
        continue
        ;;
    esac
  done
  
  exit 0
}

FUNCfinalMenuChk
FUNCextDirectConv "3gp"
FUNCextDirectConv "gif"
FUNCfinalMenuChk

nDurationSeconds="`FUNCflDurationSec "$strFileAbs"`"

nFileSz="`FUNCflSize "$strFileAbs"`";
nMinPartSz=$((nPartMinMB*n1MB)) #not precise tho as split is based on keyframes #TODO right?

bJustRecreateDirectly=false
if(( nDurationSeconds <= nShortDur ));then
  echoc --info "short video nDurationSeconds='$nDurationSeconds'"
  bJustRecreateDirectly=true
fi
if((nFileSz<nMinPartSz));then
  echoc --info "small file nFileSz='$nFileSz'"
  bJustRecreateDirectly=true
fi
if $bJustRecreateDirectly;then
  FUNCrecreate
  #~ FUNCavconvConv --io "$strFileAbs" "$strOrigPath/$strFinalFileBN"
  #~ FUNCmiOrigNew&&:
  FUNCfinalMenuChk
  exit 0
fi

#~ nFileSz="`FUNCflSize "$strFileAbs"`";
#~ n1MB=1000000 #TODO 1024*1024
#~ nPartMinMB=1
#~ nMinPartSz=$((nPartMinMB*n1MB))
#~ if((nFileSz<nMinPartSz));then
  #~ SECFUNCechoErrA "file is too small for this feature"
  #~ exit 1
#~ fi
nParts=$((nFileSz/nMinPartSz))

nPartSeconds=$((nDurationSeconds/nParts));
((nPartSeconds+=1))&&: # to compensate for remaining milliseconds

declare -p nDurationSeconds nFileSz nMinPartSz nParts nPartSeconds

if [[ ! -f "${strAbsFileNmHashTmp}.00000.mp4" ]];then
  echoc --info "Splitting" >&2
  FUNCavconvRaw -i "$strFileAbs" -c copy -flags +global_header -segment_time $nPartSeconds -f segment "${strAbsFileNmHashTmp}."%05d".mp4" #|tee -a "${strAbsFileNmHashTmp}.log"
  #~ cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
fi

SECFUNCexecA -ce ls -l "${strAbsFileNmHashTmp}."* #|sort -n

IFS=$'\n' read -d '' -r -a astrFilePartList < <(ls -1 "${strAbsFileNmHashTmp}."?????".mp4" |sort -n)&&:
declare -p astrFilePartList |tr "[" "\n" >&2

#nCPUs="`lscpu |egrep "^CPU\(s\)" |egrep -o "[[:digit:]]*"`"

astrFilePartNewList=()
echoc --info "Converting" >&2
nCount=0
for strFilePart in "${astrFilePartList[@]}";do
  strFilePartNS="${strFilePart%.mp4}"
  strPartTmp="${strAbsFileNmHashTmp}.NewPart.${strNewFormatSuffix}.TEMP.mp4"
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
    #: ${nCPUPerc:=50} #help overall CPUs percentage
    #SECFUNCCcpulimit -r "avconv" -l $nCPUPerc
    echoc --info "PROGRESS: $nCount/${#astrFilePartList[*]}, `bc <<< "scale=2;($nCount*100/${#astrFilePartList[*]})"`%"
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

  strFinalTmp="${strAbsFileNmHashTmp}.${strNewFormatSuffix}-TMP.mp4"
  SECFUNCtrash "$strFinalTmp"&&:
  if FUNCavconvRaw -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalTmp";then
    #~ cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
    
    #~ SECFUNCexecA -ce mv -vf "$strFinalTmp" "$strFinalFileBN"
    #~ SECFUNCexecA -ce mv -vf "$strFinalFileBN" "${strOrigPath}/"
    SECFUNCexecA -ce mv -vf "$strFinalTmp" "${strOrigPath}/"
    #~ FUNCmiOrigNew&&:
    FUNCfinalMenuChk
  fi
  exit 0
)

echoc -w -t $CFGnDefQSleep

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
