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

source <(secinit)

#~ : ${strEnvVarUserCanModify:="test"}
#~ export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
#~ export strEnvVarUserCanModify2 #help test
: ${CFGstrFlHist:="$HOME/.bash_eternal_history"};declare -p CFGstrFlHist
export CFGstrFlHist #help 
strExample="DefaultValue"
bMaint=false
CFGstrTest="Test"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t append '#@BKP' to every command you want to backup when you run it (between # and @ you can add your custom comment)"
		SECFUNCshowHelp --colorize "\t tip: sort by comment, select all redundant, sort by time, keep (unselect) the last one (probably)"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift;strExample="${1-}"
	elif [[ "$1" == "-m" || "$1" == "--maintenance" ]];then #help to help on deleting history entries to cleanup the mess
		bMaint=true
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
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

# Main code
if [[ ! -f "$CFGstrFlHist" ]];then
  echoc -p "invalid CFGstrFlHist='$CFGstrFlHist'"
  exit 1 
fi

declare -p CFGstrFlHist
if((`SECFUNCarraySize astrRemainingParams`>0));then :;fi

# if a daemon or to prevent simultaneously running it: 
SECFUNCuniqueLock --waitbecomedaemon

strNewBkpTmpFile="`mktemp`"
strBkpFile="$HOME/.bashHistoryBkp.log"

function FUNCflInfo() { #<mode> <file>
  local lstrMode="$1";shift
  local lstrFile="$1";shift
  case "$lstrMode" in
    lines)
      cat "$lstrFile" |wc -l
      ;;
    size)
      stat -c %s "$lstrFile"
      ;;
    *)
      SECFUNCechoErrA "invalid lstrMode='$lstrMode'"
      _SECFUNCcriticalForceExit
      ;;
  esac
  return 0
}

function FUNCupdateTmpBkp() {
  if ! egrep "#.*[@]BKP" "${CFGstrFlHist}" -aw -B 1 |egrep -v "^--$" >"${strNewBkpTmpFile}";then
    echoc -p "there is no history to backup, create some or restore the backup file"
    if [[ -f "$strBkpFile" ]];then
      SECFUNCexecA -ce wc -l "$strBkpFile"
      echo "meld '$strBkpFile' '${CFGstrFlHist}' #Compare" >&2
      echo "cp -vf '$strBkpFile' '${CFGstrFlHist}' #Restore (OVERWRITE)" >&2
      echo "cat '$strBkpFile' >>'${CFGstrFlHist}' #Append, even if datetime is not in correct order, it will still work. Btw, \`history -w\` will not sort it." >&2
    fi
    exit 1
  fi
  SECFUNCexecA -ce ls -l "${strNewBkpTmpFile}"
}

FUNCupdateTmpBkp

if $bMaint;then
  echoc --info "maintenance sector"

  IFS=$'\n' read -d '' -r -a astrList < <(cat "$strNewBkpTmpFile"&&:)&&:
  #~ declare -p astrList
  #egrep "#.*[@]BKP" $HOME/.bash_eternal_history -aw |sort -u >"$strNewBkpTmpFile";
  declare -a astrNewList;astrNewList=()
  for((i=0;i<"${#astrList[*]}";i++));do
    strLine="${astrList[i]}"
    if((i%2==0));then strTime="$strLine";continue;fi
    nTime="${strTime###}"
    astrNewList[$nTime]="$strLine"
  done
  #~ declare -p astrNewList
  #SECFUNCexecA -ce SECFUNCarrayShow -v astrNewList
  
  #~ astrMainList=()
  #~ for nTime in "${!astrNewList[@]}";do
    #~ #nHistIndex="`egrep "^#${nTime}$" ~/.bash_eternal_history -n |cut -d ':' -f 1`"
    #~ #echo " history -d $nHistIndex; # ${astrNewList[nTime]}"
#~ #    astrMainList+=(false "`printf "%q" ${astrNewList[nTime]}` #$nTime")
    #~ astrMainList+=(false "${astrNewList[nTime]} #$nTime")
  #~ done
#  IFS=$'\n' read -d '' -r -a astrMainListSorted < <(for strEntry in "${astrMainList[@]}";do echo "$strEntry";done |sort)&&:
#  IFS=$'\n' read -d '' -r -a astrMaintListSorted < <(for nTime in "${!astrNewList[@]}";do echo "${astrNewList[nTime]} #$nTime";done |sort)&&:
  #~ IFS=$'\n' read -d '' -r -a astrMaintListSorted < <(for nTime in "${!astrNewList[@]}";do echo "${astrNewList[nTime]}";done |sort)&&:
  
  astrMaintListDiag=()
  #~ for strEntry in "${astrMaintListSorted[@]}";do 
  for nTime in "${!astrNewList[@]}";do  
    #~ nTime="`echo "${strEntry}" |sed -r 's@.*[#]([[:digit:]]*)$@\1@'`"
    strEntry="${astrNewList[nTime]}"
    strTime="`date +"%Y-%m-%d %H:%M:%S" --date="@${nTime}"`"
    strComment="`echo "${strEntry}" |sed -r 's".*([#][^#]*@BKP.*)"\1"'`"
    astrMaintListDiag+=(false "$nTime" "$strTime" "$strComment" "${strEntry}")
  done
  
  # apparently `history` is only accessible if bash is interactive!
  #history -d 1
  #history |tail
  declare -p LINENO
  IFS=$'\n' read -d '' -r -a astrChosenList < <(yad --maximized --center --no-markup --title="`basename $0` select items to be deleted" --list --checklist --column="DEL" --column "nTime" --column "Time" --column="comment" --column="command" "${astrMaintListDiag[@]}"&&:)&&:
  #~ declare -p LINENO
  if SECFUNCarrayCheck -n astrChosenList;then
    SECFUNCtrash "${CFGstrFlHist}.bkp"&&:
    SECFUNCexecA -ce cp -vf "${CFGstrFlHist}" "${CFGstrFlHist}.bkp"
    for strChosen in "${astrChosenList[@]}";do
      nTime="`echo "$strChosen" |cut -d '|' -f 2`"
      strTime="`echo "$strChosen" |cut -d '|' -f 3`"
      SECFUNCdrawLine " $strTime "
      #strHistEntry="`history |egrep "[[:digit:]]* *[[]${strTime}[]] "`"&&:
      nLine="`egrep -n "^#${nTime}$" "${CFGstrFlHist}" |cut -d ':' -f 1`"
      strHistEntry="`head -n $((nLine+1)) "${CFGstrFlHist}" |tail -n 1`"
      #nHistIndex="`echo "$strHistEntry" |awk '{print $1}'`"
      declare -p nTime strTime nLine strHistEntry
      SECFUNCexecA -m "REMOVING from history" -ce sed -i -r -e "/^[#]${nTime}/ { N; d; }" "${CFGstrFlHist}"
    done
    SECFUNCexecA -ce colordiff "${CFGstrFlHist}.bkp" "${CFGstrFlHist}"&&:
    
    FUNCupdateTmpBkp
    
  #  echo "Remember to 'history -w' after finished..."
    echoc --info "history -w # if run @s@{ny}NOW@S will restore all erased entries on this terminal session (as they are still in memory)"
    echoc --info "# To see the changes open a new terminal to check'em"
  fi
fi

#~ for strLine in "${astrNewList[@]}";do
  #~ echo "$strLine"
#~ done |sort -u >"$strNewBkpTmpFile";
#~ ## $nTime=[`date +"%Y-%m-%d %H:%M:%S" --date="@${nTime}"`] delHistIndex='history -d $((i/2+1))'
#~ SECFUNCexecA -ce cat "$strNewBkpTmpFile"

#~ ################ keep #############
#~ exit 0 # uncomment for tests above ################################
#~ ################ keep #############

#~ # fix the final file
#~ strSortUniqueTmp="`cat "$strBkpFile" |sort -u`"
#~ echo "$strSortUniqueTmp" >"$strBkpFile"

#~ # only appends to the final file what is missint on it (next run will be sorted tho)
#~ SECFUNCexecA -ce diff "$strBkpFile" "$strNewBkpTmpFile" |grep "^> " |sed 's"^> ""' |tee -a "$strBkpFile"

#~ SECFUNCexecA -ce cat "$strBkpFile"

#SECFUNCexecA -ce meld <(cat "${strBkpFile}"|sort -u) <(cat "${strNewBkpTmpFile}"|sort -u)&&:

if SECFUNCexecA -ce colordiff "${strBkpFile}" "${strNewBkpTmpFile}";then
  echoc --info "nothing changed!"
else
  nLnOld="`FUNCflInfo lines "${strBkpFile}"`"
  nLnNew="`FUNCflInfo lines "${strNewBkpTmpFile}"`"
  nSzOld="`FUNCflInfo size  "${strBkpFile}"`"
  nSzNew="`FUNCflInfo size  "${strNewBkpTmpFile}"`"
  #~ FUNCflInfo "${strBkpFile}"      ;nLnOld=$FUNCflInfo_nLn;nSzOld=$FUNCflInfo_nSz
  #~ FUNCflInfo "${strNewBkpTmpFile}";nLnNew=$FUNCflInfo_nLn;nSzNew=$FUNCflInfo_nSz
  #~ nLnOld="`cat "${strBkpFile}"|wc -l`"
  #~ nLnNew="`cat "${strNewBkpTmpFile}"|wc -l`"
#  if((nLnNew<nLnOld)) || ((`stat -c %s "${strNewBkpTmpFile}"`<`stat -c %s "${strBkpFile}"`));then
  if((nLnNew<nLnOld)) || ((nSzNew<nSzOld));then
    SECFUNCexecA -ce -m "extra safety" cp -vf "${strBkpFile}" "${strBkpFile}.Safe.bkp"
    SECFUNCexecA -ce ls -l "${strNewBkpTmpFile}" "${strBkpFile}"
    declare -p nLnOld nSzOld nLnNew nSzNew >&2
    if ! echoc -q "the new backup is smaller than the old one`SECFUNCternary -e " (possibly due to maintenance mode)" "" $bMaint`, ignore and overwrite the backup (if not it will compare with meld)?";then
      SECFUNCexecA -ce meld "${strBkpFile}" "${strNewBkpTmpFile}"
      SECFUNCexecA -ce colordiff "${strBkpFile}" "${strNewBkpTmpFile}"&&:
      if ! echoc -q "is everything correct?";then
        echoc -p "backup not done."
        exit 0
      fi
    fi
  fi
  SECFUNCexecA -ce cp -vf "${strBkpFile}" "${strBkpFile}.bkp"
  SECFUNCtrash "${strBkpFile}.bkp"
  SECFUNCexecA -ce cp -vf "${strNewBkpTmpFile}" "${strBkpFile}"
  ls -l "${strBkpFile}"
  wc -l "${strBkpFile}"
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
