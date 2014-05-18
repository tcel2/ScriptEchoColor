#!/bin/bash -i
# Copyright (C) 2004-2013 by Henrique Abdalla
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

trap 'bEcho=false;bWait=false;echo "(ctrl+c pressed, exiting...)";reset;exit 2;' INT

####### internal config/setup ############################################
#alias sudo='FUNCwaitEcho $LINENO;sudo '
#alias find='FUNCwaitEcho $LINENO;find '
#alias sudo='FUNCexecEcho sudo '
#alias find='FUNCexecEcho find '
export selfFile="`pwd`/`basename "$0"`"

####### FUNCTIONS #########################################################
function FUNCexecEcho() {
	if $bEcho;then
		echo "=========================================="
		echo "EXEC: $@"
	fi
	
	if $bWait;then
		read -s -n 1 -p "WAIT: press a key to exec..." >>/dev/stderr
		echo
		echo
	fi
	
	#shopt -u expand_aliases
	#eval "\\$@";local lnRet=$?
	"$@" #do not use `eval` !
	local lnRet=$?
	#shopt -s expand_aliases
	
	if((lnRet!=0));then
		echo "ERROR: $@ #returned $lnRet" >>/dev/stderr
		return $lnRet
	fi
};export -f FUNCexecEcho

function FUNCexit() {
	local lstrMsg="$1"
	shift
	local lnExitValue="$1"
	
	if [[ -z "$lnExitValue" ]];then
		lnExitValue=0
	elif [[ -n `echo "$lnExitValue" |tr -d '[:digit:]'` ]];then #has not only numbers
		echo "ERROR: invalid exit value '$lnExitValue'" >>/dev/stderr
		FUNCexecEcho exit 1
	fi
	
	local lstr=""
	if((lnExitValue!=0));then
		lstr="ERROR: "
	fi
	
	local lstrOuput="${lstr}${lstrMsg}"
	#if [[ -n "$lstrOuput" ]];then
		echo "EXIT: ${lstr}${lstrMsg}" >>/dev/stderr
	#fi
	FUNCexecEcho sudo -k
	FUNCexecEcho exit $lnExitValue
};export -f FUNCexit

function FUNCexitIfFail() {
	if(($1!=0));then
		FUNCexit "EXEC ERROR..." $1
	fi
};export -f FUNCexitIfFail

function FUNCcpChown() {
	local lstrPathAndFile="$1"
	shift
	local lstrBasePathTo="$1"
	
	local lstrFinalPathAndFile="$lstrBasePathTo/$lstrPathAndFile"
	local lstrFinalPathTo="`dirname "$lstrFinalPathAndFile"`"
	if [[ ! -d "$lstrFinalPathTo" ]];then
		mkdir -vp "$lstrFinalPathTo"; FUNCexitIfFail $?
	fi
	#cp -vf "$lstrPathAndFile" "$lstrBasePathTo"; FUNCexitIfFail $?
	cp -vf "$lstrPathAndFile" "$lstrFinalPathAndFile"; FUNCexitIfFail $?
	chown -v root:root "$lstrFinalPathAndFile"; FUNCexitIfFail $?
	echo
};export -f FUNCcpChown

function FUNCfindCpChown() {
	local lstrPathFrom="$1"
	shift
	local lstrPathTo="$1"
	
	local lstrPwdBkp="`pwd`"
	cd "$lstrPathFrom/"; FUNCexitIfFail $?
	#find -not -type d -exec bash -c "FUNCcpChown \"{}\" \"$lstrPathTo\"" \;; FUNCexitIfFail $?
	local lstrFile=""
	find -not -type d |while read lstrFile; do
		FUNCcpChown "$lstrFile" "$lstrPathTo"
	done; FUNCexitIfFail $?
	cd "$lstrPwdBkp"
};export -f FUNCfindCpChown

#function FUNCwaitEcho() {
#	local lnLineToBePrinted="$1" #not that good if command has more than one line...
#	if $bEcho;then
#		echo "=========================================="
#		echo -n "EXEC:";sed -n "${lnLineToBePrinted}p" "$selfFile" #show what will be executed
#	fi
#	if $bWait;then
#		echo "WAIT: press a key to exec...";read -s -n 1 #@@@!!! comment later if all is ok
#	fi
#};export -f FUNCwaitEcho

#function FUNCsudo() {
#	eval "SUDOEXEC: $@"
#	eval "$@"
#}

####### OPTIONS #########################################################
export pathInstallPrefix=""
export pathLibPrefix=""
export pathBinPrefix=""
export pathDocPrefix=""
export pathGoboPrefix=""

export bWait=false
export bEcho=true
export bBackupOldPrefix=false
export bInstallExtras=false
export bInstallExamples=false
export bInstallMain=true

while [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--prefix" ]];then #help <path> set the main path to install everything
		shift
		pathInstallPrefix="$1"
	elif [[ "$1" == "--wait" ]];then #help wait before executing a command
		bWait=true
	elif [[ "$1" == "--no-echo" ]];then #help do NOT echo the command that will be executed
		bEcho=false
	elif [[ "$1" == "--help" ]];then
		grep "#help" "$selfFile" |grep -v grep
		FUNCexit
	elif [[ "$1" == "--bkp" ]];then #help backup old prefix before installing (only gobo prefix)
		bBackupOldPrefix=true
	elif [[ "$1" == "--LikeGoboPrefix" ]];then #help simulates the way gobolinux uses to install files!
		shift
		pathGoboPrefix="$1"
	elif [[ "$1" == "--no-main" ]];then #help usefull to help on installing only extras and examples alone
		bInstallMain=false
	elif [[ "$1" == "--extras" ]];then #help install extras
		bInstallExtras=true
	elif [[ "$1" == "--examples" ]];then #help install examples
		bInstallExamples=true
	else
		FUNCexit "invalid option '$1'" 1
	fi
	shift
done

####### MAIN CODE #########################################################
if((UID!=0));then #all sudo cmds on this script became redundant!
	FUNCexit "must be run as root" 1	
fi

if [[ "$pathGoboPrefix" == "/" ]];then
	FUNCexit "invalid gobo prefix, should be ex.: '/Programs'" 1
fi

if [[ -z "$pathInstallPrefix" ]];then
	FUNCexit "missing prefix path to install" 1
fi
if [[ -z "$pathBinPrefix" ]];then
	pathBinPrefix="$pathInstallPrefix/usr/bin"
fi
if [[ -z "$pathLibPrefix" ]];then
	pathLibPrefix="$pathInstallPrefix/usr/lib"
fi
if [[ -z "$pathDocPrefix" ]];then
	pathDocPrefix="$pathInstallPrefix/usr/share/doc/ScriptEchoColor"
fi

echo "INFO: Deploying at: $pathInstallPrefix"

####### clean previously deployed
if $bBackupOldPrefix && [[ -d "$pathGoboPrefix" ]];then
	if [[ "${pathInstallPrefix:0:${#pathGoboPrefix}}" == "$pathGoboPrefix" ]];then
		if [[ -d "$pathInstallPrefix" ]];then
			FUNCexecEcho mv -v "$pathInstallPrefix" "${pathInstallPrefix}.dtBkp`date +"%Y%m%d_%H%M%S_%N"`" #to be able to revert easly
	#	else
	#		echo "nothing to backup at: "
		fi
	else
		echo "INFO: only backups '$pathInstallPrefix' if at Gobo prefix" >>/dev/stderr
	fi
fi

####### prepare paths for new deploy
if [[ ! -d "$pathInstallPrefix" ]];then
	FUNCexecEcho mkdir -vp "$pathInstallPrefix"
fi
if [[ ! -d "$pathInstallPrefix" ]];then
	FUNCexit "failed to create prefix path '$pathInstallPrefix'" 1
fi

if [[ ! -d "$pathLibPrefix" ]];then
	FUNCexecEcho mkdir -vp "$pathLibPrefix"
fi
if [[ ! -d "$pathBinPrefix" ]];then
	FUNCexecEcho mkdir -vp "$pathBinPrefix"
fi
if [[ ! -d "$pathDocPrefix" ]];then
	FUNCexecEcho mkdir -vp "$pathDocPrefix"
fi

####### copy application
if $bInstallMain;then
	FUNCexecEcho FUNCfindCpChown "share/doc/ScriptEchoColor/" "$pathDocPrefix"; FUNCexitIfFail $?
	FUNCexecEcho FUNCfindCpChown "lib/" "$pathLibPrefix"; FUNCexitIfFail $?
	FUNCexecEcho FUNCfindCpChown "bin/" "$pathBinPrefix"; FUNCexitIfFail $?
fi

if $bInstallExtras;then
	FUNCexecEcho FUNCfindCpChown "bin.extras/"	"$pathBinPrefix"; FUNCexitIfFail $?
fi

if $bInstallExamples;then
	FUNCexecEcho FUNCfindCpChown "bin.examples/"	"$pathBinPrefix"; FUNCexitIfFail $?
fi

# Symlinks to GoboPrefix !
if [[ -n "$pathGoboPrefix" ]] && [[ -d "$pathGoboPrefix" ]]; then
	####### symlink EXECUTABLES
	#pathApplications=`dirname "$pathInstallPrefix"`
	
	FUNCexecEcho ln -vsf "$pathBinPrefix/"* $pathGoboPrefix/Executables/ ; FUNCexitIfFail $?
#	if $bInstallExtras;then
#		FUNCexecEcho ln -vsf "$pathInstallPrefix/bin.extras/"* $pathGoboPrefix/Executables/ ; FUNCexitIfFail $?
#	fi

	####### copy LIBs
	export workFrom="$pathLibPrefix";
	export workTo="$pathGoboPrefix/Libraries"
	cd "$workFrom"
	pwd
	function FUNCcp() {
		#bEcho=false
		echo "$FUNCNAME: working with '$1'"; 
		if [[ -d "$workFrom/$1" ]]; then 
			FUNCexecEcho mkdir -vp "$workTo/$1" ; FUNCexitIfFail $?
		elif [[ -f "$workFrom/$1" ]]; then
			FUNCexecEcho cp -vf "$workFrom/$1" "$workTo/$1" ; FUNCexitIfFail $?
		else
			ls "$workFrom/$1" ; FUNCexitIfFail $?
		fi
	};export -f FUNCcp;
	#TODO is failing with FUNCexecEcho... #find ./ -not -name "." -not -name ".." -not -name "*~" -exec bash -c "FUNCcp '{}'" \; ; FUNCexitIfFail $?
	find ./ -not -name "." -not -name ".." -not -name "*~" -exec bash -c "FUNCcp '{}'" \; ; FUNCexitIfFail $?

fi

####### END
#ls -lR "$pathInstallPrefix"
echo "Installed at: '$pathInstallPrefix'"
FUNCexit

