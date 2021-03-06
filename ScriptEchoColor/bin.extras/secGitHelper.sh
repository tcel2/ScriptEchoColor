#!/bin/bash
# Copyright (C) 2004-2014 by Henrique Abdalla
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

source <(secinit --extras -i)

strDpkgPackage=""
export strDevPath="`pwd`/"
strChangesFile="./CHANGES.txt"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "This script only works properly with package 'Version-Revision' in the format 'YYYYMMDD-HHMMSS'"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--package" || "$1" == "-p" ]];then #help <strDpkgPackage> package name to be queried with dpkg
		shift
		strDpkgPackage="${1-}"
	elif [[ "$1" == "--devpath" || "$1" == "-d" ]];then #help <strDevPath> development path where .git directory can be found into
		shift
		strDevPath="${1-}"
	elif [[ "$1" == "--changes" ]];then #help <strChangesFile> set the changes log file. It can be relative to the dev path.
		shift
		strChangesFile="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if [[ ! -d "$strDevPath" ]];then
	# if being run just after login, do not use $USER on paths at command line parameters, it may not expand. No idea why...
	echoc -p "invalid strDevPath='$strDevPath'" #, $USER"
	
#	# TODO -d failed just after login time, why?
#	
#	ls -ld "$strDevPath" &&: >&2
#	if test -a "$strDevPath";then echo a >&2;fi
#	if test -d "$strDevPath";then echo d >&2;fi
#	if test -e "$strDevPath";then echo e >&2;fi
#	if test -r "$strDevPath";then echo r >&2;fi
#	if test -s "$strDevPath";then echo s >&2;fi
#	if test -w "$strDevPath";then echo w >&2;fi
#	if test -x "$strDevPath";then echo x >&2;fi
#	if test -O "$strDevPath";then echo O >&2;fi
#	if test -G "$strDevPath";then echo G >&2;fi
#	SECFUNCdrawLine >&2
#	
#	strFormat="`stat --help |egrep "%." |head -n 30 |sed -r 's"[ ]*%(.)[ ]*(.*)"\1 #\2"' |tr -d "%" |sed -r "s'.*'%&'"`"&&:
#	stat -c "$strFormat" "$strDevPath" &&: >&2
#	SECFUNCdrawLine >&2
#	
#	strace bash -c "[[ -d '$strDevPath' ]]" &&: >&2
	
	exit 1
fi
strDevPath="`readlink -f "$strDevPath"`"
if [[ ! -d "$strDevPath/.git" ]];then
	echoc -p "missing .git at strDevPath='$strDevPath'"
	exit 1
fi
ls -ld "$strDevPath/.git"

bIsPkg=false
if [[ -n "$strDpkgPackage" ]];then
  if dpkg -s "$strDpkgPackage";then
    bIsPkg=true;
  else
    echoc -p "invalid strDpkgPackage='$strDpkgPackage'"
    exit 1
  fi
fi

cd "$strDevPath"
echoc -x "pwd"

#strDevPath="`basename "$0"`";strDevPath="`readlink -f "$strDevPath"`";strDevPath="`dirname "$strDevPath"`"
##echo "(`pwd`)($strDevPath)"
#if [[ "$strDevPath" != "`pwd`" ]];then
#	pwd
#	echoc --alert "invalid run path, should be where '$0' is."
#	cd "$strDevPath"
#	pwd
#fi

if [[ -n "$strChangesFile" ]];then
	echo -n >>"$strChangesFile"
	if [[ ! -f "$strChangesFile" ]];then
		echoc -p "unable to create strChangesFile='$strChangesFile'"
		exit 1
	fi
	strChangesFile="`readlink -f "$strChangesFile"`"
	echo "strChangesFile='$strChangesFile'"
fi

function FUNCgitDiffCheckShow() {
	local lastrCmd=("$@")
	local lstrDiff="`git diff "${lastrCmd[@]}"`"&&:;
	local lnDiffCount="`echo -n "$lstrDiff" |wc -l`"
	if((lnDiffCount==0));then
		echoc --alert "THERE IS NO DIFFERENCE!"
	else
		SECFUNCexec -c --echo git difftool -d "${lastrCmd[@]}"&&:
	fi
	return 0
}

function FUNCCHILDgenerateChangesLogFileGitGuiLoop() {
  local lbChildLoopExit=false
  trap 'lbChildLoopExit=true' SIGUSR1
  echoc --info "$FUNCNAME: Starting child proccess $BASHPID"
  sleep 3; # so git gui have some time to start..
#	while pgrep -fx "git gui" >/dev/null;do #TopLoop
	while true;do #TopLoop
    if $lbChildLoopExit;then
      echoc --info "$FUNCNAME: Stop requested $BASHPID"
      break;
    fi
  
    local lanPid=(`ps --no-headers -o pid -p $(pgrep -fx "git gui")`);
    local lnPid
    local bFound=false;
    if [[ -n "${lanPid[@]-}" ]];then
      for lnPid in "${lanPid[@]}";do 
        local lstrPidPath="`readlink /proc/$lnPid/cwd`"
        #declare -p lnPid lstrPidPath strDevPath
        if [[ "$lstrPidPath" == "$strDevPath" ]];then
          bFound=true
          break
        fi
      done
    fi
    if ! $bFound;then 
      echoc --info "git gui exited."
      break;
    fi
    
		nLastSize="`stat -c %s "$strChangesFile"`"
		FUNCgenerateChangesLogFile; 
		nNewSize="`stat -c %s "${strChangesFile}.NEW"`"
		if((nLastSize!=nNewSize));then
      SECFUNCexecA -ce trash -v "${strChangesFile}"
      SECFUNCexecA -ce mv -Tv "${strChangesFile}.NEW" "${strChangesFile}"
			echoc --info "updated: '`basename "$strChangesFile"`'"
    else
      rm -v "${strChangesFile}.NEW"
		fi
		sleep 3;
	done
}

function FUNCgenerateChangesLogFile() {
	echo "# do not edit by hand, this file is auto generated by: $SECstrScriptSelfName" >"${strChangesFile}.NEW"
	git log --full-history --date=iso \
		|egrep -v "^$|^commit |^Author: |^    [.]" \
		|grep "^    " -B 1 \
		|grep -v "^--" >>"${strChangesFile}.NEW";
}

function FUNCshowCommits() { #param: lbShowAll
	local lbShowAll=false
	if [[ "${1-}" == "true" ]];then
		lbShowAll=true
		shift
	fi
	
#	nMaxShownCommits=20
#	echoc --info "last $nMaxShownCommits commits:"
	echoc --info "last commits (highlited the one previous to install):"
#	echo "$strCommits" |sed "s@.*@'&'@" |head -n $nMaxShownCommits |column
	nNewestCommitsLimit=1000 #just an "absurd?" number to make it easier to code...
	nTerminalWidth="`stty size 2>/dev/null |cut -d" " -f2`" #instead of `tput cols`
	local lstrOutput="`echo "$strCommits" |sed "s@.*@'&'@"`"
	local lnAfter=1
	if $lbShowAll;then
		lnAfter=$nNewestCommitsLimit
	fi
  
  local lstrMatchCmt="$strLastCommitBeforeInstall"
  if [[ -z "$lstrMatchCmt" ]];then
    lstrMatchCmt="`echo "$lstrOutput" |head -n 1`"
  fi
  
  lstrOutput="`echo "$lstrOutput" |grep "$lstrMatchCmt" -A $lnAfter -B $nNewestCommitsLimit --color=always`"
  
	if((lnAfter==1));then
		echo "$lstrOutput"
	else
		#SECFUNCcheckActivateRunLog --restoredefaultoutputs
		#echoc -w -t 3 "press 'q' to quit it -> using \`|less\` loads of commits will be shown"
		echo "$lstrOutput" # do not use `|less -R`, seems buggy... some weird files were created when using it...
		#SECFUNCcheckActivateRunLog
	fi
	#|column -c $nTerminalWidth
}

strProjectMainNameAtURL="`echo "$(egrep "url = .*" .git/config)" |sed -r 's".*url = (.*)"\1"'`"
declare -p strProjectMainNameAtURL

strLockRawId="`basename $0`_${strProjectMainNameAtURL}";declare -p strLockRawId
SECFUNCuniqueLock --id "$strLockRawId" --daemonwait

while true;do
	### ASK WHAT TO DO ###
  #~ function FUNCopts() {
    #~ while [[ -n "${1-}" ]];do echo "\t${1}/\n";done
    #~ return 0
  #~ }
  astrOpts=()
  astrOpts+=("diff d_ate from master")
  astrOpts+=("_browse with gitk")
  astrOpts+=("_commit with 'git gui'")
  astrOpts+=("_diff last tag from master")
  astrOpts+=("_g show changes log file")
  if $bIsPkg;then
    astrOpts+=("diff _installed from dev folder")
  fi
  astrOpts+=("_nautilus at dev path")
  astrOpts+=("_push tags to remote")
  astrOpts+=("_terminal at dev path")
  astrOpts+=("diff to be p_ushed")
  strOpts="$(for strOpt in "${astrOpts[@]}";do echo -nE "\t${strOpt}/\n";done)" 
	echoc -Q "git helper (hit ctrl+c to exit) @O\n${strOpts}"&&:
	nRetValue=$?
	strRetLetter="`secascii $nRetValue`"
	
	### UPDATE CONTROL DATA AND SHOW INFORMATION ###
	
	#|sed -r "s'.* ([[:digit:]-]* [[:digit:]:]*) .*'\1'" |tr -d ':-' |tr ' ' '-' 
	strCommits="`git log --full-history --date=iso |grep Date |sed -r "s@.* ([[:digit:]-]*) ([[:digit:]:]*) .*@\1 \2@"`"
  
	#echoc --info "Git helper (hit ctrl+c to exit)"
  strSECInstalledVersion=""
  strLastCommitBeforeInstall=""
  if $bIsPkg;then
    strSECInstalledVersion="`dpkg -s "$strDpkgPackage" |grep Version |grep "[[:digit:]]*-[[:digit:]]*$" -o`"
    strSECInstalledVersionFormatted="`echo "$strSECInstalledVersion" |sed -r "s'(....)(..)(..)-(..)(..)(..)'\1-\2-\3 \4:\5:\6'"`"
    echoc "strDpkgPackage='@r$strDpkgPackage@{-a}';"
    echoc "strSECInstalledVersion='@{c}$strSECInstalledVersion@{-a}';"
    strLastCommitBeforeInstall="`(echo "$strCommits";echo "$strSECInstalledVersionFormatted") |sort -r |grep "$strSECInstalledVersionFormatted" -A 1 |tail -n 1`"
    declare -p strLastCommitBeforeInstall
  fi
	echoc "strDevPath='@y$strDevPath';"
	
	FUNCshowCommits
	
	### EXEC USER OPTION ###
	case "$strRetLetter" in 
		a)
			FUNCshowCommits true
			strDateTime="`echoc -S "type/paste date and time with this format @s@{Yb}AAAA-MM-DD hh:mm:ss@S"`"
			if [[ -n "$strDateTime" ]];then
				FUNCgitDiffCheckShow "HEAD@{$strDateTime}..master"&&:
			fi
			;;
		b)
			echoc -x "gitk"&&: 
			;; 
		c)
			echoc --alert "SOURCEFORGE PassWord @{-n} may be asked...";
			strTitleRegex="^Git Gui [(]`basename "$strDevPath"`[)] ${strDevPath}$"
			#SECFUNCCwindowCmd --timeout 1200 --focus "$strTitleRegex"
			(sleep 3;FUNCCHILDgenerateChangesLogFileGitGuiLoop)&nChildPidGenCLFGGL=$!
			echoc --alert "REFRESH @{-n} as the change log will be updated after normal commit!"
      xterm -e "(nohup git gui&disown)&disown;sleep 3"
      #SECFUNCexecA -ce SECFUNCCwindowCmd --timeout 60 --wait "$strTitleRegex" # til it kicks in
      #SECFUNCexecA -ce SECFUNCCwindowCmd --timeout 3600 --waitexit "$strTitleRegex" 
      SECFUNCexecA -ce kill -SIGUSR1 $nChildPidGenCLFGGL&&:
			;; 
		d)
			FUNCgitDiffCheckShow "`git tag |tail -n 1`..master"&&:
			;;
		g)
			#FUNCgenerateChangesLogFile
			#if echoc -t 1 -q "view changes file '$strChangesFile'?";then
				SECFUNCexecA -ce gedit "${strChangesFile}" >/dev/null 2>&1 &
			#fi
			;;
		i)
			if [[ -z "$strSECInstalledVersion" ]];then
				echoc --alert "package scriptechocolor is not installed."
			else
				FUNCgitDiffCheckShow "HEAD@{$strLastCommitBeforeInstall}" -- "./"&&:
			fi
			;;
		n)
			echoc -x "nautilus ./"&&: 
			;;
		p)
			echoc --alert "SOURCEFORGE PassWord may be asked...";
			echoc -x "git push --tags"&&: 
			;;
		t)
			echoc -x "gnome-terminal"&&: 
			;;
		u)
			FUNCgitDiffCheckShow origin/master&&: 
			;;
	esac
	
done

