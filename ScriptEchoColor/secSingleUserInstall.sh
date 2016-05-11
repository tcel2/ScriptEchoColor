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

# these prevent continuing on errors...
trap 'echo "ERROR...";exit 1' ERR
set -u 

################## init 

function FUNCconsumeKeyBuffer() {
  while true;do
    read -n 1 -t 0.1&&:
    if(($?==142));then #142 is: no key was pressed
      break;
    fi;
  done
}
function FUNCexecEcho() {
  local lnRet
  echo -e "EXEC: \E[0m\E[37m\E[46m\E[1m$@\E[0m"
  "$@"&&:;lnRet=$?
  echo
  return $lnRet;
}
function echoi(){ #info
	echo -e "\E[0m\E[34m\E[47m$@\E[0m"
}
function echop(){ #problem
	echo -e "\E[0m\E[33m\E[41m\E[1mPROBLEM: $@\E[0m"
}
function echow(){ #wait
	echo -e "\E[0m\E[97m\E[44m$@\E[0m"
	FUNCconsumeKeyBuffer
	read -n 1
}
function echoa(){ #alert
	echo -e "\E[0m\E[31m\E[103m\E[5m$@\E[0m"
}

strSelfName="`basename "$0"`"
strMainFile="ScriptEchoColor/bin/ScriptEchoColor.sh"
strTmpSelf="/tmp/$strSelfName"
bOnlineCheck=true

: ${SECstrUserInstallPath:=$HOME/ScriptEchoColor}

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	if [[ "$1" == "--help" ]];then #help show this help
		grep "then \#help " "$0"
		echoi "Will install a clone for the current user only."
		echo "strSelfName='$strSelfName'"
		echo "strMainFile='$strMainFile'"
		echo "strTmpSelf='$strTmpSelf'"
		echoi "To change the default, before running this script, set this env var to something else:"
		echo "SECstrUserInstallPath='$SECstrUserInstallPath'"
		exit 0
	elif [[ "$1" == "--noOnlineCheck" || "$1" == "-O" ]];then #help skip online update, tho this is important in case of this script bug-fixes/improvements
		bOnlineCheck=false
	else
		echop "invalid option '$1'"
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done

# Main code

################ self check
if $bOnlineCheck;then
	echoi " checking for this script update... "
	FUNCexecEcho wget -O "$strTmpSelf" "http://sourceforge.net/projects/scriptechocolor/files/Ubuntu%20.deb%20packages/$strSelfName/download"
	if ! FUNCexecEcho cmp "$0" "$strTmpSelf";then
		(
			FUNCexecEcho ls -l "$0"
			FUNCexecEcho cp -vf "$strTmpSelf" "$0"
			FUNCexecEcho ls -l "$0"
			echoa "Installer Updated!"
			echoi "re-run '$strSelfName'"
		)&disown
		exit 0
	fi
fi

################## validate installation
bFirstClone=false
if [[ ! -d "$SECstrUserInstallPath" ]];then
	FUNCexecEcho mkdir -vp "$SECstrUserInstallPath"
	bFirstClone=true
fi
FUNCexecEcho cd "$SECstrUserInstallPath"
FUNCexecEcho pwd

if ! $bFirstClone;then
	if [[ ! -f "$strMainFile" ]];then
		echop "problem at installation? unable to find strMainFile='$strMainFile'"
		echoa "User action required!"
		echoi "remove/trash/rename its install path manually."
		FUNCexecEcho pwd
		#echop "'$0' must be run at '`dirname "$0"`/' like: './$strSelfName'"
		echow "press a key to exit..."
		exit 1
	fi
fi

################# MAIN

if $bFirstClone;then
	FUNCexecEcho git clone git://git.code.sf.net/p/scriptechocolor/git "$SECstrUserInstallPath"
	echoi "first clone done!"
fi
echo

############################ at ScriptEchoColor/
if ! $bFirstClone;then
	echoi ">>---> cleaning local and updating from git... <---<<"
	FUNCexecEcho pwd
	echow "continue? (ctrl+c to exit)"
	#git pull origin
	FUNCexecEcho git reset --hard HEAD;
	FUNCexecEcho git clean -f -d;
	FUNCexecEcho git pull
	echo
fi

FUNCexecEcho cd "ScriptEchoColor/bin" #################################### at ScriptEchoColor/bin/
echoi ">>---> creating/updating symlinks <---<<"
FUNCexecEcho pwd
ln -vs ../bin.extras/*   ./ 2>&1 |egrep -v ": File exists$"
ln -vs ../bin.examples/* ./ 2>&1 |egrep -v ": File exists$"
echo

echoi ">>---> initialize ScriptEchoColor <---<<"
strSecBin="$SECstrUserInstallPath/ScriptEchoColor/bin"
export PATH="$PATH:$strSecBin"
echo "PATH='$PATH'"
echo "secGetInstallPath.sh '`secGetInstallPath.sh`'"
./echoc --info "Success! ScriptEchoColor @nenabled!" #will initialize it
echo

echoa ">>---> Configure PATH variable!!! <---<<"
echoi "now add the below to your PATH variable"
echo "$strSecBin"
echo

