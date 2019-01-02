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
strNewFormatSuffix="x265-HEVC"
bContinue=false
CFGstrTest="Test"
astrRemainingParams=()
CFGastrTmpWorkPathList=()
CFGastrFileList=()
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

function FUNCflFinal() { #help <lstrFl>
  local lstrFl="$1"
  local lstrSuffix="`SECFUNCfileSuffix "$strFileBN"`"
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

sedRegexPreciseMatch='s"(.)"[\1]"g'
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
  declare -p FUNCNAME lstrFl lstrRegexPreciseMatch CFGastrFileList
}

# Main code

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
      if((`SECFUNCarraySize CFGastrFileList`==0));then echoc -w -t 60 "Waiting new job requests";continue;fi #break;fi
      #~ strFileAbs="${CFGastrFileList[0]-}"
      #~ if [[ -f "$strFileAbs" ]];then
        #~ $0 --workonlywith "$strFileAbs" &&:
      #~ fi
      
      #~ strRegexPreciseMatch="^`echo "$strFileAbs" |sed -r "$sedRegexPreciseMatch"`$"
      #~ SECFUNCarrayClean CFGastrFileList "$strRegexPreciseMatch"
      #~ SECFUNCcfgWriteVar CFGastrFileList
      for strFileAbs in "${CFGastrFileList[@]}";do
        SECFUNCexecA -ce $0 --workonlywith "$strFileAbs" &&:
        #while SECFUNCuniqueLock --isdaemonrunning;do echoc -w -t 1 "wait daemon exit";done
        #~ echoc -w -t 60
      done
    done
    #~ echoc -w -t 60
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
: ${strTmpWorkPath:="`FUNCflTmpWorkPath "$strFileAbs"`"} #help

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
  FUNCflCleanFromDB "$strFileAbs"
  exit 0
fi

strFileBN="`basename "$strFileAbs"`"
strFileNmHash="`FUNCflBNHash "$strFileBN"`" #the file may contain chars avconv wont accept at .join file

#strFileNoSuf="${strTmpWorkPath}/${strFileNmHash%.$strSuffix}"
strAbsFileNmHashTmp="${strTmpWorkPath}/${strFileNmHash}"
#strFinalFileBN="${strFileBN%.$strSuffix}.${strNewFormatSuffix}.mp4"
strFinalFileBN="`FUNCflFinal "$strFileBN"`"

function FUNCflSize() {
  stat -c "%s" "$1"
}

function FUNCflDurationMillis() {
  mediainfo -f "$1" |egrep "Duration .*: [[:digit:]]*$" |head -n 1 |grep -o "[[:digit:]]*"
}
function FUNCflDurationSec() {
  echo $((`FUNCflDurationMillis "$1"`/1000))&&:
  return 0
}

function FUNCavconvRaw() {
  #~ SECFUNCexecA -ce avconv -i "$strFileAbs" -c copy -flags +global_header -segment_time $nPartSeconds -f segment "${strAbsFileNmHashTmp}."%05d".mp4" #|tee -a 
  #~ SECFUNCexecA -ce avconv -f concat -i "$strFileJoin" -c copy -fflags +genpts "$strFinalTmp"
  #~ SECFUNCexecA -ce nice -n 19 avconv -i "$lstrIn" "${lastrPartParms[@]}" "$lstrOut" #|tee -a "${strAbsFileNmHashTmp}.log"
  : ${nCPUPerc:=50} #help overall CPUs percentage
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
    tail -F --pid $BASHPID "$strFlLog"&
    SECFUNCexecA -ce nice -n 19 avconv "$@" >"$strFlLog" 2>&1 ; nRet=$?
    cat "$strFlLog" >>"${strAbsFileNmHashTmp}.log"
    exit $nRet
  )
  return $?
}

function FUNCavconvConv() { #help [--part] <lstrIn> <lstrOut>
  local lastrPartParms=(-c:v libx265 -c:a libmp3lame) #libx265 -x265-params lossless=1
  if [[ "$1" == "--part" ]];then lastrPartParms+=(-fflags +genpts);shift;fi
  local lstrIn="$1";shift
  local lstrOut="$1";shift
  FUNCavconvRaw -i "$lstrIn" "${lastrPartParms[@]}" "$lstrOut"
  #~ : ${nCPUPerc:=50} #help overall CPUs percentage
  #~ SECFUNCCcpulimit -r "avconv" -l $nCPUPerc
  #~ (
    #~ exec 2>&1 
    #~ exec > >(tee -a "${strAbsFileNmHashTmp}.log")
    #~ SECFUNCexecA -ce nice -n 19 avconv -i "$lstrIn" "${lastrPartParms[@]}" "$lstrOut" #|tee -a "${strAbsFileNmHashTmp}.log"
    #~ #cat "$SECstrRunLogFile" >>"${strAbsFileNmHashTmp}.log"
  #~ )
}

function FUNCrecreate() {
  SECFUNCtrash "$strOrigPath/$strFinalFileBN"
  FUNCavconvConv "$strFileAbs" "$strOrigPath/$strFinalFileBN"
  echo -n >"${strAbsFileNmHashTmp}.recreated"
}

#~ function FUNCplay() {
  #~ if echoc -t 60 -q "play the new file?";then
    #~ SECFUNCexecA -ce smplayer "$strOrigPath/$strFinalFileBN"&&:
  #~ fi
#~ }

#~ function FUNCmiOrigNew() {
  #~ SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
  
  #~ FUNCplay
  
  #~ if FUNCtrashTmpOld;then
    #~ # merge current list with possible new values
    #~ astrFileListBKP=( "${CFGastrFileList[@]}" ); 
    #~ SECFUNCcfgReadDB
    #~ SECFUNCarrayWork --merge CFGastrFileList astrFileListBKP
    
    #~ # clean final list from current file
    #~ # sedRegexPreciseMatch='s"(.)"[\1]"g'
    #~ strRegexPreciseMatch="^`echo "$strFileAbs" |sed -r "$sedRegexPreciseMatch"`$"
    #~ SECFUNCarrayClean CFGastrFileList "$strRegexPreciseMatch"
    #~ #unset CFGastrFileList[0]; 
    #~ #CFGastrFileList=( "${CFGastrFileList[@]}" ); 
    #~ SECFUNCcfgWriteVar CFGastrFileList #SECFUNCarrayClean CFGastrFileList "$CFGstrFileAbs"
    
    #~ return 0
  #~ fi
  
  #~ return 1
#~ }

#~ function FUNCrecreate() {
  #~ if echoc -t 60 -q "recreate the new file now using it's full length (ignore split parts) ?";then
    #~ SECFUNCtrash "$strOrigPath/$strFinalFileBN"
    #~ FUNCavconvConv "$strFileAbs" "$strOrigPath/$strFinalFileBN"
    #~ echo -n >"${strAbsFileNmHashTmp}.recreated"
    #~ FUNCplay
    #~ return 0
  #~ fi
  #~ return 1
#~ }

#~ function FUNCtrashTmpOld() {
  #~ SECFUNCexecA -ce ls -l "${strTmpWorkPath}/${strFileNmHash}"* &&:
  #~ bRecreatedNow=false
  
  #~ for((iLoop2=0;iLoop2<2;iLoop2++));do
    #~ if SECFUNCexecA -ce ls -l "$strFileAbs" "$strOrigPath/$strFinalFileBN";then
      #~ if((`FUNCflSize "$strOrigPath/$strFinalFileBN"` > `FUNCflSize "$strFileAbs"`));then
        #~ echoc -w -t 60 --alert "@YATTENTION!!!@-n the new file is BIGGER than old one!"
      #~ fi
      
      #~ nDurSecOld="`FUNCflDurationSec "$strFileAbs"`"
      #~ nDurSecNew="`FUNCflDurationSec "$strOrigPath/$strFinalFileBN"`"
      #~ nMargin=$((nDurSecOld*5/100)) #TODO could just be a few seconds like 3 or 10 right? but small videos will not work like that...
      #~ if((nMargin==0));then nMargin=1;fi
      #~ declare -p nDurSecOld nDurSecNew nMargin
      #~ if ! SECFUNCisSimilar $nDurSecOld $nDurSecNew $nMargin;then
        #~ echoc -w -t 60 --alert "@YATTENTION!!!@-n the new duration nDurSecNew='$nDurSecNew' is weird! nDurSecOld='$nDurSecOld'"
        #~ if FUNCrecreate;then bRecreatedNow=true;continue;fi #iLoop2
      #~ fi
      
      #~ if SECFUNCexecA -ce egrep "Past duration .* too large" "${strAbsFileNmHashTmp}.log";then
        #~ echoc -w -t 60 --alert "@YATTENTION!!!@-n The individual parts processing encountered the problematic the warnings above!"
        #~ if FUNCrecreate;then bRecreatedNow=true;continue;fi #iLoop2
      #~ fi

      #~ if SECFUNCexecA -ce egrep "Non-monotonous DTS in output stream .* previous: .*, current: .*; changing to .*. This may result in incorrect timestamps in the output file." "${strAbsFileNmHashTmp}.log";then
        #~ echoc -w -t 60 --alert "@YATTENTION!!!@-n The parts joining encountered problematic the warnings above!"
        #~ if FUNCrecreate;then bRecreatedNow=true;continue;fi #iLoop2
      #~ fi
    #~ fi
    #~ break #iLoop2
  #~ done
  
  #~ if ! $bRecreatedNow;then
    #~ if [[ -f "${strAbsFileNmHashTmp}.recreated" ]];then # created before this current run
      #~ FUNCplay
    #~ else
      #~ if ! FUNCrecreate;then
        #~ FUNCplay
      #~ fi
    #~ fi
  #~ fi
  
  #~ if echoc -t 60 -q "trash tmp and old files?";then
    #~ SECFUNCtrash "${strTmpWorkPath}/${strFileNmHash}"*
    #~ SECFUNCtrash "$strFileAbs"&&:
    #~ SECFUNCexecA -ce ls -l "$strOrigPath/$strFinalFileBN" &&:
  #~ else
    #~ return 1
  #~ fi
  
  #~ echoc -w -t 60
  #~ return 0
#~ }

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
      "_list all?"
      "_play the new file?"
      "_recreate ${strReco}the new file now using it's full length (ignore split parts)?"
      "_skip this file for now?"
      "_trash tmp and old files?"
      "set a new one to _work with?"
    )
    #~ strOpts="`for strOpt in "${astrOpt[@]}";do echo -n "${strOpt}\n";done`"
    #~ echoc -t 60 -Q "@O\n ${strOpts}"&&:; nRet=$?; case "`secascii $nRet`" in 
    echoc -t 60 -Q "@O\n\t`SECFUNCarrayJoin "\n\t" "${astrOpt[@]}"`\n@Ds"&&:;nRet=$?;case "`secascii $nRet`" in 
      d)
        SECFUNCexecA -ce colordiff -y <(mediainfo "$strFileAbs") <(mediainfo "$strOrigPath/$strFinalFileBN") &&:
        ;;
      l)
        SECFUNCcfgReadDB
        
        echoc --info "Files:"
        for strFl in "${CFGastrFileList[@]}";do
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
          echo -n "OrigDurSec=`FUNCflDurationSec "$strFl"`, "
          echo -n "\"`du -h "$strFl"`\", "
          if [[ -f "$lstrFlFinal" ]];then echo -n "\"${lstrFlFinal}\", ";fi
          echo -n "$lstrFlBNHash, "
          #~ echo -n "`basename "$strFl"`, "
          #~ echo -n "at `dirname "$strFl"`"
          echo
        done
        
        echoc --info "TmpFolders:"
        SECFUNCarrayWork --uniq CFGastrTmpWorkPathList;#SECFUNCcfgWriteVar CFGastrTmpWorkPathList
        for strTmpPh in "${CFGastrTmpWorkPathList[@]}";do
          if [[ -d "$strTmpPh" ]];then
            du -sh "$strTmpPh" 2>/dev/null
          fi
        done
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
          $0 --workonlywith "$lstrNewWork"
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
#~ if [[ -f "$strOrigPath/$strFinalFileBN" ]];then
  #~ FUNCmiOrigNew&&:
  #~ ls -l "$strOrigPath/$strFinalFileBN" "$strFileAbs" &&:
  #~ echoc --info "already converted to strFinalFileBN='$strFinalFileBN'"
  #~ exit 0
#~ fi

#~ CFGstrFileAbs="$strFileAbs"        ;SECFUNCcfgWriteVar CFGstrFileAbs
#~ CFGstrOrigPath="$strOrigPath"      ;SECFUNCcfgWriteVar CFGstrOrigPath
#~ CFGstrTmpWorkPath="$strTmpWorkPath";SECFUNCcfgWriteVar CFGstrTmpWorkPath
#~ SECFUNCcfgWriteVar CFGastrFileList

SECFUNCexecA -ce mkdir -vp "$strTmpWorkPath"
CFGastrTmpWorkPathList+=("$strTmpWorkPath");SECFUNCcfgWriteVar CFGastrTmpWorkPathList

nDurationSeconds="`FUNCflDurationSec "$strFileAbs"`"

if(( nDurationSeconds <= (60*5) ));then
  echoc --info "short video nDurationSeconds='$nDurationSeconds'"
  FUNCrecreate
  #~ FUNCavconvConv "$strFileAbs" "$strOrigPath/$strFinalFileBN"
  FUNCmiOrigNew&&:
  exit 0
fi

nFileSz="`FUNCflSize "$strFileAbs"`";
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
    if FUNCavconvConv --part "$strFilePart" "$strPartTmp";then
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
    
    SECFUNCexecA -ce mv -vf "$strFinalTmp" "$strFinalFileBN"
    SECFUNCexecA -ce mv -vf "$strFinalFileBN" "${strOrigPath}/"
    #~ FUNCmiOrigNew&&:
    FUNCfinalMenuChk
    
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
