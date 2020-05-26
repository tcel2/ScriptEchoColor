#!/bin/bash
# Copyright (C) 2019 by Henrique Abdalla
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

source <(secinit); #SECFUNCchkLastRunVersion --dev

export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
bExample=false
CFGstrTest="Test"
astrRemainingParams=()
strFlGriveCfg=".grive"
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above, and BEFORE the skippable ones!!!
: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
: ${strEnvVarUserCanModify:="test"}
: ${bVerbose:=true}; #help
: ${CFGstrRegexExcludeFiles:="$strFlGriveCfg"};
: ${CFGstrExecGDrive:="gdrive-linux-x64"}
export CFGstrRegexExcludeFiles;#help this can be used to temporarily ignore some files
export CFGstrExecGDrive;#help change this to your installed gdrive exec filename
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
	elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #help MISSING DESCRIPTION
		bExample=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams. TODO explain how it will be used
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
if $bWriteCfgVars;then SECFUNCcfgAutoWriteAllVars;fi #this will also show all config vars

### collect required named params
# strParam1="$1";shift
# strParam2="$1";shift

# Main code
if SECFUNCarrayCheck -n astrRemainingParams;then :;fi

SECFUNCuniqueLock --waitbecomedaemon # if a daemon or to prevent simultaneously running it

#echoc --alert "TODO!@-n store link target as seccfg"

: ${strWorkPath:="$HOME/Google Drive/"} #help
SECFUNCexecA -ce cd "$strWorkPath";SECFUNCexecA -ce pwd

#nMax=$((`find "$strWorkPath/" |wc -l`+1000)) #TODO find a way to know how many files are there properly
nMax=30 #IMPORTANT! more than 1000 will fail with non clear (confusing) error message! using max as default gdrive 30 may prevent some remote problems btw.

function FUNCupdFileList() { # <lstrRefDtTm> find local updated files based on reference touched control file
  lstrRefDtTm="$1";shift
  
  if [[ "$CFGstrRegexExcludeFiles" != "$strFlGriveCfg" ]];then
    echoc --alert "IGNORING:@-n $CFGstrRegexExcludeFiles @C# ignored files should be a temporary thing."
  fi
#  IFS=$'\n' read -d '' -r -a astrFileList < <(SECFUNCexecA -ce find "$strWorkPath/" -type f -newer "$lstrRefDtTm" -not -name ${strFlGriveCfg})&&:
  #(cd "$strWorkPath/";pwd >&2;SECFUNCexecA -ce find -type f -newer "$lstrRefDtTm" |egrep -v "$strFlGriveCfg|$CFGstrFlLastUploadBkpBN|$CFGstrRegexExcludeFiles" |sed -r 's"[.]/(.*)"\1"')
  #declare -p astrFileList&&:
  IFS=$'\n' read -d '' -r -a astrFileList < <(cd "$strWorkPath/";pwd >&2;SECFUNCexecA -ce find -type f -newer "$lstrRefDtTm" |egrep -v "$strFlGriveCfg|$CFGstrFlLastUploadBkpBN|$CFGstrRegexExcludeFiles" |sed -r 's"[.]/(.*)"\1"')&&: #sed removes './' from beggining. KEEP the double check for ${strFlGriveCfg} FILE, should not be uploaded!
  declare -p LINENO astrFileList&&:
  if SECFUNCarrayCheck -n astrFileList;then
    declare -p LINENO
    IFS=$'\n' read -d '' -r -a astrFileList < <(ls -1Sr "${astrFileList[@]}")&&: # will upload smallers firsts
    SECFUNCarrayShow -v astrFileList
    declare -i nTotSize=0
    for strFl in "${astrFileList[@]}";do ((nTotSize+=`stat -c %s "$strFl"`))&&:;done
    n1MB=$((1024*1024))
    declare -p nTotSize;
    #echo -w -t 60 --info "total `bc <<< "scale=1;$nTotSize/$n1MB"`MB"
    SECFUNCexecA -ce ls -lc "${astrFileList[@]}"
    SECFUNCexecA -ce ls -lSr "${astrFileList[@]}"
    echoc --info -w -t 60 "@{C}total `SECFUNCbcPrettyCalcA "scale=1;$nTotSize/$n1MB"`MB"
    if(( nTotSize > 2*n1MB ));then
      if ! echoc -q "big upload, continue?";then exit 0;fi
    fi
  else
    echoc --info "nothing new to upload!"
    exit 0
  fi
}

function FUNCprotRm() {
  SECFUNCexecA -ce shred -vuz "$1"
}

function FUNCflKchkGrive() { # [--prot] <CFGstr...FlKRealAt> <CFGstr...FlK> the CFGs are the var names itself to be referenced!
  #TODO if ever revisiting this, prefer FUNCflKchkGDrive() code, is much simpler
  #echo "${FUNCNAME[@]}:Ln$LINENO:params:$@" >&2
  local lbProt=false;if [[ "${1-}" == "--prot" ]];then lbProt=true;shift;fi
  
  local -n lstrFlKRealAt="$1";shift;#declare -p lstrFlKRealAt >&2
  local -n lstrFlK="$1";shift;#declare -p lstrFlK >&2
  declare -p lstrFlKRealAt lstrFlK >&2
  
  if ! $lbProt;then # check and restore
    astrCmdRestore=(ln -vs "${lstrFlKRealAt-}" "`dirname "$lstrFlK"`/")
    if [[ -n "${lstrFlKRealAt-}" ]];then
      strMsgRestore="`SECFUNCparamsToEval "${astrCmdRestore[@]}"` # run this to restore the cfg file !!!"
    else
      strMsgRestore="move '$lstrFlK' elsewhere and make a symlink to it."
    fi
    
    if [[ ! -a "$lstrFlK" ]];then 
      echoc -p "missing ${!lstrFlK}='$lstrFlK'";
      #~ if [[ -n "${lstrFlKRealAt-}" ]];then
        echoc --info "$strMsgRestore"
      #~ else
        #~ echoc --info "move '$lstrFlK' elsewhere and make a symlink to it."
      #~ fi
      exit 1;
    else
      SECFUNCexecA -ce ls -l "$lstrFlK"
      if [[ ! -L "$lstrFlK" ]];then 
        echoc --alert "!!!@-n ${!lstrFlK}='$lstrFlK' was not protected!";
        #echoc --info "$strMsgRestore"
        FUNCprotRm "$lstrFlK"
        #~ exit 1
      fi
    fi
    
    if ! lstrFlKRealAt="`readlink -e "$lstrFlK"`";then 
      echoc -p "link '`readlink "$lstrFlK"`' for ${!lstrFlK}='$lstrFlK' is unavailable";
      ls --color -l "$lstrFlK"&&:;
      echoc --info "$strMsgRestore"
      exit 1;
    fi
    SECFUNCcfgWriteVar --report "${!lstrFlKRealAt}"
    
    if [[ ! -f "$lstrFlKRealAt" ]];then 
      echoc -p "missing ${!lstrFlKRealAt}='$lstrFlKRealAt'";
      exit 1;
    fi
    
    SECFUNCexecA -ce rm -v "$lstrFlK" # the link
    SECFUNCexecA -ce cp -Tv "$lstrFlKRealAt" "$lstrFlK" # only accepts the real file :(
  else # protect
    FUNCprotRm "$lstrFlK"
    SECFUNCexecA -ce ln -Tvs "$lstrFlKRealAt" "$lstrFlK" # only accepts the real file :(
  fi
}

function FUNCgriveWork() { #TODO zombie
  FUNCupdFileList "$HOME/Google Drive/${strFlGriveCfg}_state"

  CFGstrGriveFlK="$strWorkPath/${strFlGriveCfg}"
  FUNCflKchkGrive CFGstrGriveFlKRealAt CFGstrGriveFlK

  : ${bDirectCmd:=true}
  if $bDirectCmd;then # this will still download the files list "Reading remote server file list", about >=4MB...
    # --log "$HOME/log/grive.log" # the log is not very useful and shows the token.....
    SECFUNCexecA -ce grive --debug --path "$strWorkPath/" --progress-bar --upload-only
  else
    strLogFile="$HOME/${strFlGriveCfg}-last-sync.log"
    declare -p strLogFile

    if ! pgrep grive-indicator;then
      trash -v "$strLogFile" # trash the file to prevent wrong/previous "finished" detection
      echo -n > "$strLogFile" # create empty just to avoid non-existing problems...
      
      SECFUNCexecA -ce /opt/thefanclub/grive-tools/grive-indicator&
      
      echoc -w -t 10
    fi

    SECFUNCexecA -ce tail -F "$strLogFile"&

    while pgrep grive-indicator;do
      if egrep "^Finished[!]$" "$strLogFile";then
        SECFUNCexecA -ce notify-send -u critical -t 1 -i $HOME/Pictures/icons/Alert-ByMe.png "Grive finished but is still running!!!"
      fi
      echoc -w -t 30
    done
  fi

  FUNCflKchkGrive --prot CFGstrGriveFlKRealAt CFGstrGriveFlK
}
: ${bUseGRIVE:=false};export bUseGRIVE #help 
if $bUseGRIVE;then
  FUNCgriveWork
  exit 0
fi

##############################################################################
##############################################################################
##############################################################################
########################## GDrive #########################
##############################################################################
##############################################################################
##############################################################################

CFGstrFlRemoteFileInfo="$HOME/.gdrive/${SECstrScriptSelfName}.RemoteFilesInfo.txt"

CFGstrFlLastUpload="$HOME/.gdrive/${SECstrScriptSelfName}.LastUploadDtTm.cfg"
CFGstrFlLastUploadBkpBN="$(basename "$CFGstrFlLastUpload")"

FUNCupdFileList "$CFGstrFlLastUpload"

CFGstrGDriveFlK="$HOME/.gdrive/token_v2.json"
function FUNCflKchkGDrive() {
  declare -p CFGstrGDriveFlKRealAt&&: >&2
  if [[ ! -a "$CFGstrGDriveFlK" ]];then
    echoc -p "missing '$CFGstrGDriveFlK'"
    exit 1
  else
    if [[ ! -L "$CFGstrGDriveFlK" ]];then
      ls -l "$CFGstrGDriveFlK"
      echoc --alert "was not protected@-n '$CFGstrGDriveFlK' move it elsewere and create a symlink!"
      if [[ -f "$CFGstrGDriveFlKRealAt" ]];then
        echoc --info "auto-fixing it as CFGstrGDriveFlKRealAt='$CFGstrGDriveFlKRealAt'"
        FUNCprotRm "$CFGstrGDriveFlK" #TODO put something at `trap '...' EXIT`
        SECFUNCexecA -ce ln -vs "$CFGstrGDriveFlKRealAt" "`dirname "$CFGstrGDriveFlK"`/"
        SECFUNCexecA -ce ls --color -l "$CFGstrGDriveFlK"
      else
        exit 1
      fi
    else
      CFGstrGDriveFlKRealAt="$(readlink "$CFGstrGDriveFlK")"
      SECFUNCcfgWriteVar --report CFGstrGDriveFlKRealAt
    fi
    
    if ! grep -q "access" "$CFGstrGDriveFlK";then
      echoc -p "invalid '$CFGstrGDriveFlK' contents"
      exit 1
    fi
  fi
}
FUNCflKchkGDrive

CFGstrFlKnownIDs="$HOME/.gdrive/${SECstrScriptSelfName}.KnownIDs.cfg"
if [[ -f "$CFGstrFlKnownIDs" ]];then 
  SECFUNCtrash "${CFGstrFlKnownIDs}.7z"&&:
  SECFUNCexecA -ce 7z a "${CFGstrFlKnownIDs}.7z" "${CFGstrFlKnownIDs}"
  SECFUNCexecA -ce ls -l "${CFGstrFlKnownIDs}"
else
  echo -n >"$CFGstrFlKnownIDs";
fi

CFGstrFlSessionDoneJobs="$HOME/.gdrive/${SECstrScriptSelfName}.DoneUploads.cfg"
if [[ ! -f "$CFGstrFlSessionDoneJobs" ]];then echo -n >"$CFGstrFlSessionDoneJobs";fi
if((`cat "$CFGstrFlSessionDoneJobs" |wc -l`>0));then echoc --info "continuing from last session.";fi
SECFUNCexecA -ce cat "$CFGstrFlSessionDoneJobs"

function FUNCupdLastUpl() { 
  date +%s >"$CFGstrFlLastUpload"; 
  cp -v "$CFGstrFlLastUpload" "$strWorkPath/$CFGstrFlLastUploadBkpBN"
  ls -l "$CFGstrFlLastUpload" "$strWorkPath/$CFGstrFlLastUploadBkpBN";  
}
if [[ ! -f "$CFGstrFlLastUpload" ]];then FUNCupdLastUpl;fi

bTrashSessionCfg=true

function FUNCaddKnownIDs() {
  local lastrKnIDs=();IFS=$'\n' read -d '' -r -a lastrKnIDs < <(echo "$1")&&:
  local lstrKnID;for lstrKnID in "${lastrKnIDs[@]}";do
  #    if [[ "$1" =~ ^Failed\ to\ get\ file.*$ ]];then
    local lstrID="$(echo "$lstrKnID" |awk '{print $1}')"
    if((${#lstrID}!=33)) || [[ ! "$lstrKnID" =~ ^.*\ \ \ (bin|dir)\ \ \ .*$ ]];then
      SECFUNCechoErrA "invalid id text entry '$lstrKnID' ${#lstrID}"
      _SECFUNCcriticalForceExit
    fi
    echo "$lstrKnID" >>"$CFGstrFlKnownIDs" #TODO make unique latest per ID
  done
}

strFUNClistFromRemoteOutputRO=""
function FUNClistFromRemote() { # [--folder] <lstrBN>
  local lstrFolderChk="!=";if [[ "$1" == "--folder" ]];then lstrFolderChk="=";shift;fi
  local lstrParentID="$1";shift
  local lstrBN="$(basename "$1")";shift # grants BN
  
  local lstrParentQuery=""
  if [[ "$lstrParentID" != "0" ]];then 
    lstrParentQuery=" and '${lstrParentID}' in parents "
  fi
  
  local lastrCmdGDrList=(
    list 
    --max $nMax 
    --order modifiedTime 
    --no-header --bytes 
    --name-width 0 
    --absolute 
    --query
  )
  lastrCmdGDrList+=("name = \"${lstrBN}\" and mimeType ${lstrFolderChk} 'application/vnd.google-apps.folder' ${lstrParentQuery} and trashed = false")
  
  declare -g strFUNClistFromRemoteOutputRO="`FUNCrunGDrive "${lastrCmdGDrList[@]}"`"&&:;local lnRet=$?;
  if((lnRet==0));then
    if [[ -z "$strFUNClistFromRemoteOutputRO" ]];then 
      echo "INFO: lstrBN='$lstrBN' not found remotely." >&2
    else
      FUNCaddKnownIDs "$strFUNClistFromRemoteOutputRO"
    fi
    return 0
  fi
  
  return 1
}

#~ function FUNCgetExactOutputLine() { # <lstrFile> <lstrOutput> <lstrType>
  #~ local lstrFile="$1";shift
  #~ local lstrOutput="$1";shift
  #~ local lstrType="$1";shift
  
  #~ #only the ID for the file on the correct path!
  #~ if lstrOutput="`echo "$lstrOutput" |egrep " ${lstrFile} *${lstrType} "`";then 
    #~ lstrOutput="`echo "$lstrOutput" |tail -n 1`" #if there are many IDs with the same identical abs file path names, will update the newest one at least!
    #~ if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrOutput" >&2;fi
    #~ echo "$lstrOutput"
    #~ return 0
  #~ fi
  #~ return 1
#~ }

sedRegexPreciseMatch='s"(.)"[\1]"g'
function FUNCgetIDfromOutput() { # <lstrFile> <lstrOutput> <lstrType>
  local lstrFile="$1";shift
  local lstrOutput="$1";shift
  local lstrType="$1";shift
  local lstrParentID="$1";shift
  
  if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrFile $lstrType $lstrParentID" >&2;fi
  
  #only the ID for the file on the correct path!
  local lstrFilePM="`echo "$lstrFile" |sed -r "$sedRegexPreciseMatch"`";#declare -p lstrFilePM >&2
#  if lstrOutput="`echo "$lstrOutput" |egrep "[ /]${lstrFilePM} *${lstrType} "`";then 
  if lstrOutput="`echo "$lstrOutput" |egrep "   ${lstrFilePM} *${lstrType} "`";then 
    lstrOutput="`echo "$lstrOutput" |tail -n 1`" #if there are many IDs with the same identical abs file path names, will update the newest one at least!
    if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrOutput" >&2;fi # THIS OUTPUT WAS FILTERED ALREADY!!!!!!!!!!! YEY!!!!!!!!
    
  #~ if lstrOutput="`FUNCgetExactOutputLine "$lstrFile" "$lstrOutput"`";then
    if((`echo "$lstrOutput" |wc -l`==1));then
      lstrFileID="`echo "$lstrOutput" | awk '{print $1}'`"
      if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrOutput" >&2;declare -p lstrFileID >&2;fi
      echo "$lstrFileID"
      return 0
    fi
  #~ fi
  fi
  
  return 1
}

#~ function FUNCgetKnownID() { # <lstrFile> <lstrType>
  #~ local lstrFile="$1";shift
  #~ local lstrType="$1";shift
  #~ FUNCgetIDfromOutput "$lstrFile" "`cat "$CFGstrFlKnownIDs"`" "$lstrType"
#~ }
#~ function FUNCgetKnownID() { # <lstrFile>
  #~ local lstrFile="$1";shift
  #~ local lstrOutput
  #~ if lstrOutput="`cat "$CFGstrFlKnownIDs" |egrep "$strFile"`";then
    #~ if((`echo "$lstrOutput" |wc -l`>=1));then
      #~ lstrOutput="`echo "$lstrOutput" |tail -n 1`"
      #~ local lstrFileID="`echo "$lstrOutput" |awk '{print $1}'`"
#~        echoc --info "ID is known already!" >&2
      #~ if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrOutput" >&2;declare -p strFileID >&2;fi
      #~ echo "$lstrFileID"
      #~ return 0
    #~ fi
  #~ fi
  #~ return 1
#~ }

function FUNCgetID() { # <lstrFile> <lstrType>
  local lstrFile="$1";shift
  local lstrType="$1";shift
  local lstrParentID="$1";shift
  
  if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrFile $lstrType $lstrParentID" >&2;fi
  
  local lstrID
  # check if ID is stored locally at cfg file
  if lstrID="$(FUNCgetIDfromOutput "$lstrFile" "$(cat "$CFGstrFlKnownIDs")" "$lstrType" "$lstrParentID")";then
    echoc --info "$lstrType ID is known already! for '$lstrFile'" >&2
  else # gets the ID from the remote
    local lstrOptFolder="";if [[ "$lstrType" == "dir" ]];then lstrOptFolder="--folder";fi
    local lstrFileBN="$(basename "$lstrFile")"
    if FUNClistFromRemote $lstrOptFolder "$lstrParentID" "$lstrFileBN";then local lstrOutput="$strFUNClistFromRemoteOutputRO"
      if lstrID="$(FUNCgetIDfromOutput "$lstrFile" "$lstrOutput" "$lstrType" "$lstrParentID")";then
        echoc --info "ID found remotely!" >&2
      else
        declare -p lstrOutput >&2
        SEC_WARN=true SECFUNCechoWarnA "remote output above has not the ID for lstrFile='$lstrFile'"
        return 1
      fi
    else
      SEC_WARN=true SECFUNCechoWarnA "remote listing failed for lstrFile='$lstrFile'"
      return 1
    fi
  fi
  
  echo "$lstrID"
  return 0
}

function FUNCaddToSessionDoneJobs() {
  ls -l "$1" >>"$CFGstrFlSessionDoneJobs"
}

function FUNCwriteSimulatedKnownID() { # <lstrUploadedID> <lstrFile> <lstrType>
  local lstrUploadedID="$1";shift
  local lstrFile="$1";shift
  local lstrType="$1";shift
  
  # 3 spaces at least between each part 
  #TODO put trailing creation time? w/e...
  echo "$lstrUploadedID   $lstrFile   $lstrType   #LocallySimulatedKnownIDentry at `SECFUNCdtFmt --logmessages`" >>"$CFGstrFlKnownIDs"
  tail -n 1 "$CFGstrFlKnownIDs" >&2
}

: ${nMaxRetries:=20};#help
function FUNCrunGDrive() { # <params...>
  local lastrCmd=( "$CFGstrExecGDrive" )
  lastrCmd+=( "$@" )
  
  local li
  for((li=0;li<nMaxRetries;li++));do
    local lstrOutput="$(SECFUNCexecA -ce "${lastrCmd[@]}")"&&:;local lnRet=$?
    # !!!IMPORTANT!!! !!!!the output MAY have more than ONE LINE!!!! and "Failed" may be on the second line!!!!!!!
    if ((lnRet!=0)) || [[ "$lstrOutput" =~ .*Failed\ to.* ]];then # gdrive may return 0 and still error out with a message :(
      if(( li < (nMaxRetries-1) ));then # will use the critical message if this is the last retry
        local lbRetry=false
        if echo "$lstrOutput" |egrep -q "Failed to (list|upload|get) file[s]*: googleapi: Error 403: Rate Limit Exceeded, rateLimitExceeded";then
          lbRetry=true;
        fi
        if $lbRetry;then
          declare -p lstrOutput >&2
          echoc -w -t 10 "waiting remote 'calm down?' :) b4 retrying ($((li+1))/$nMaxRetries)..." >&2
          continue
        fi
      fi
      
      bTrashSessionCfg=false
      SECFUNCechoErrA "lnRet='$lnRet', invalid lstrOutput='$lstrOutput'"
      _SECFUNCcriticalForceExit
    else
      break
    fi
  done
  
  if $bVerbose;then echo "$LINENO:strFUNClistFromRemoteOutputRO='$strFUNClistFromRemoteOutputRO'" >&2;fi
  
  echo "$lstrOutput"
}

function FUNCchkOrCreateRemotePathTreeAndGetID() { # <lstrPath> RETURNS OUTPUT TOO!!!
  local lstrPath="$1";shift
  
  if $bVerbose;then echo "${FUNCNAME[@]}:$LINENO: $lstrPath" >&2;fi
  
  local lstrPathID=""
  if lstrPathID="$(FUNCgetID "$lstrPath" dir 0)";then
    echo "$lstrPathID"
    return 0
  fi
  
  local lastrPathParts=()
  IFS=$'\n' read -d '' -r -a lastrPathParts < <( echo "$lstrPath" |tr "/" "\n" )&&:
  
  local lstrPathID=""
  local lstrLastFoundParentPathID="0"
  local lstrFoundPathTree=""
  for lstrPathPart in "${lastrPathParts[@]}";do
    #~ local lbWriteNewFolderID=false
    local lstrJustCreatedFolderID=""
    
    local lstrFPT="";if [[ -n "$lstrFoundPathTree" ]];then lstrFPT="${lstrFoundPathTree}/";fi
    if lstrPathPartID="$(FUNCgetID "${lstrFPT}${lstrPathPart}" dir "${lstrLastFoundParentPathID}")";then
      lstrLastFoundParentPathID="$lstrPathPartID"
      declare -p lstrLastFoundParentPathID lstrPathPart >&2
    else
      local lastrCmdMkdir=( mkdir )
      if [[ "$lstrLastFoundParentPathID" != "0" ]];then # 0 means no ID therefore is root
        lastrCmdMkdir+=( -p "$lstrLastFoundParentPathID" )
      fi
      lastrCmdMkdir+=( "$lstrPathPart" )
      declare -p lastrCmdMkdir >&2
      #declare -p LINENO >&2
      #echo "going to create remote directory (waiting 60s)" >&2 #TODO echoc output below is broken, why?
      echoc -w -t 60 "going to create remote directory" >&2 #important to be able to read the long in case of some bug here...
      #declare -p LINENO >&2
      
      local lstrMkdirOutput="$(FUNCrunGDrive "${lastrCmdMkdir[@]}")" #TODO there is a success message output, catch and confirm based on it
      declare -p lstrMkdirOutput >&2
      
      if [[ "$lstrMkdirOutput" =~ ^Directory\ .*\ created$ ]];then
        lstrJustCreatedFolderID="$(echo "$lstrMkdirOutput" |awk '{print $2}')"
        #~ lbWriteNewFolderID=true
        lstrLastFoundParentPathID="$lstrJustCreatedFolderID"
        declare -p lstrLastFoundParentPathID lstrJustCreatedFolderID >&2
      else
        echoc -p "invalid remote mkdir output" >&2
        exit 1
      fi
    fi
    
    if [[ -n "$lstrFoundPathTree" ]];then lstrFoundPathTree+="/";fi
    lstrFoundPathTree+="$lstrPathPart"
    
    if [[ -n "$lstrJustCreatedFolderID" ]];then
      FUNCwriteSimulatedKnownID "$lstrJustCreatedFolderID" "$lstrFoundPathTree" "dir"
    fi
  done
  
  if [[ "$lstrLastFoundParentPathID" == "0" ]];then
    echoc -p "unable to get remote path ID" >&2
    exit 1
  fi
  
  echo "$lstrLastFoundParentPathID"
}


function FUNCcreateRemoteFile() { # <lstrFile>
  local lstrFile="$1";shift
  
  local lastrCmdCreateFl=( upload )
  
  local lstrPath="$(dirname "$lstrFile")";declare -p lstrPath >&2
  local lstrPathID=""
  if [[ "$lstrPath" != "." ]];then
    if lstrPathID="$(FUNCchkOrCreateRemotePathTreeAndGetID "$lstrPath")";then
      declare -p lstrPathID >&2
      lastrCmdCreateFl+=(--parent "$lstrPathID")
    else
      exit 1
    fi
    #~ if lstrPathID="$(FUNCgetID "$lstrPath" dir 0)";then
      #~ declare -p lstrPathID >&2
      #~ lastrCmdCreateFl+=(--parent "$lstrPathID")
    #~ else
      #~ FUNCcreatePathTree "$lstrPath"
      #~ #echoc -p "TODO: create remote path lstrPath='$lstrPath' for lstrFile='$lstrFile'"
      #~ #TODO "$CFGstrExecGDrive" mkdir -p "$lstrDNParentID" "$lstrPathBN"
      #~ exit 1 #TODO as is it
    #~ fi
    #FUNClistFromRemote --folder "$lstrPath"
  fi
  
  local lstrCreateOutput
  if lstrCreateOutput="$(FUNCrunGDrive "${lastrCmdCreateFl[@]}" "$lstrFile")";then
    if lstrCreateOutput="$(echo "$lstrCreateOutput" |egrep "^Uploaded .*")";then
      if [[ "$lstrCreateOutput" =~ ^Uploaded\ .* ]];then
        local lstrUploadedID="$(echo "$lstrCreateOutput" |awk '{print $2}')"
        FUNCwriteSimulatedKnownID "$lstrUploadedID" "$lstrFile" "bin"
        #~ echo "$lstrUploadedID   $lstrFile   bin   #LocallySimulatedKnownIDentry" >>"$CFGstrFlKnownIDs"
        #~ tail -n 1 "$CFGstrFlKnownIDs" >&2
        
        FUNCaddToSessionDoneJobs "$strFile"
        return 0
      fi
    fi
    
    declare -p lstrCreateOutput >&2
    echoc -p "uploaded output result was not recognized"
  else
    echoc -p "upload cmd failed"
  fi
  
  echoc -p "uploading lstrFile='$lstrFile' failed"
  return 1
}

function _FUNCbigListingDownloadsFlow() { #TODO zombie
  echoc --alert "TODO: BIG FLOW NOT READY (may never be...)";exit 1
  
  # BIG FLOW ONE DAY
  # get all files from remote
  if [[ -f "${CFGstrFlRemoteFileInfo}" ]];then
    if SECFUNCexecA -ce 7z a "${CFGstrFlRemoteFileInfo}-`SECFUNCdtFmt --filename`.7z" "${CFGstrFlRemoteFileInfo}";then
      SECFUNCtrash "${CFGstrFlRemoteFileInfo}"
    fi
  fi
  FUNCrunGDrive list --no-header --bytes --max $nMax --name-width 0 --absolute --query "mimeType = 'application/vnd.google-apps.folder' and trashed = false" |tee -a "$CFGstrFlRemoteFileInfo"

  astrFolderIdList=() #TODO from initial list
  for strFolderId in "${astrFolderIdList[@]}";do
    FUNCrunGDrive list --no-header --bytes --max $nMax --name-width 0 --absolute --query "mimeType != 'application/vnd.google-apps.folder' and '${strFolderId}' in parents and trashed = false" |tee -a "$CFGstrFlRemoteFileInfo"
  done
  
  #TODO
}
bSmallFlow=true
if ! $bSmallFlow;then
  _FUNCbigListingDownloadsFlow
  exit 0
fi

SECFUNCarrayShow -v astrFileList
if SECFUNCarrayWork --contains astrFileList "$CFGstrFlLastUploadBkpBN";then
  SECFUNCechoErrA "the list should not contain the control file yet!"
  _SECFUNCcriticalForceExit
fi
astrFileList+=( "$CFGstrFlLastUploadBkpBN" )
#~ if ! SECFUNCarrayCheck -n astrFileList;then
  #~ echoc --info "empty list"
#~ fi
#~ if((`SECFUNCarraySize astrFileList`==1)) && [[ "${astrFileList[0]}" == "$CFGstrFlLastUploadBkpBN" ]];then
  #~ echoc --info "nothing to upload (skipping control file)"
  #~ exit 0
#~ fi
#~ if SECFUNCarrayWork --contains astrFileList "$CFGstrFlLastUploadBkpBN";then
  #~ SECFUNCarrayWork --clean astrFileList "$CFGstrFlLastUploadBkpBN" #to grant it will be the last one!
  #~ astrFileList+=( "$CFGstrFlLastUploadBkpBN" )
#~ fi
#~ SECFUNCarrayShow -v astrFileList

for strFile in "${astrFileList[@]}";do
  SECFUNCdrawLine " $strFile "
  
  strPath="`dirname "${strFile}"`"
  strBN="`basename "${strFile}"`"
  
  strFileID=""
  
  if cat "$CFGstrFlSessionDoneJobs" |egrep "^`ls -l "$strFile"`$";then
    echoc --info "already uploaded on this session."
    continue
  fi
  
  if [[ "$strFile" == "$CFGstrFlLastUploadBkpBN" ]];then
    if $bTrashSessionCfg;then # only finishes the session if everything is ok!
      FUNCupdLastUpl
    fi
  fi
  
  if ! strFileID="`FUNCgetID "$strFile" bin 0`";then
    if ! FUNCcreateRemoteFile "$strFile";then
      bTrashSessionCfg=false
    fi
  else
    # updates the remote file
    if [[ -n "$strFileID" ]];then
      if FUNCrunGDrive update "$strFileID" "$strFile";then  #TODO there is a success message output, catch and confirm based on it
        FUNCaddToSessionDoneJobs "$strFile"

        #~ echo "$strOutput" >>"$CFGstrFlKnownIDs" #TODO make unique latest per ID
        #FUNCaddKnownIDs "$strOutput"
        
        : ${bVerboseGetInfo:=false};#help
        if $bVerboseGetInfo;then
          SECFUNCexecA -ce ls -l "$strFile"
          while true;do
            if strInfo="`FUNCrunGDrive info --bytes "$strFileID"`";then
              if ! echo "$strInfo" |egrep --color -e "^" -e "^Size: `stat -c %s "$strFile"` B$";then #exact size matching highlight only
                echoc -t 60 -w -p "failed to make sure the upload size did match local's" #TODO do not ignore one day
                bTrashSessionCfg=false
              fi
              break
            else
              if ! echoc -t 60 -q "retry get info?";then
                break;
              fi
            fi
          done
        fi
        echoc --info "success!"
      else
        echoc -p "failed while uploading the file!"
        bTrashSessionCfg=false
        exit 1
      fi
    fi
    
    if [[ -z "$strFileID" ]];then
      echoc -p "failed to get file ID for strFile='$strFile' #TODO file may not exist remotely"
      bTrashSessionCfg=false
    fi
  fi
  
  : ${bWaitBetweenEachWork:=false};if $bWaitBetweenEachWork;then echoc -w -t 60;fi #help
  
  : ${bExitAfter1st:=false};if $bExitAfter1st;then exit 0;fi;#help
done

if $bTrashSessionCfg;then # only finishes the session if everything is ok!
  #FUNCupdLastUpl
  SECFUNCtrash "$CFGstrFlSessionDoneJobs"
else
  echoc --info "session work have not completed yet..."
fi

FUNCflKchkGDrive #TODO should be on a `trap '' EXIT` 

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
