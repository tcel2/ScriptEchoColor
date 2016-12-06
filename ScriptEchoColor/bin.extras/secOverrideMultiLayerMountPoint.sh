#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

eval `secinit`

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
CFGnLayerNumberGap=10
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
bUmount=false
bReadOnly=false
bChkIsMultiLayer=false
bRenumber=false
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t[strMountAt]"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-u" ]];then #help ~single unmount and exit
		bUmount=true;
	elif [[ "$1" == "--ro" ]];then #help the mount point will be readonly
		bReadOnly=true;
	elif [[ "$1" == "--is" ]];then #help ~single check if the specified folder is mounted as multilayer mountpoint, and exit status
		bChkIsMultiLayer=true;
	elif [[ "$1" == "--reorder" ]];then #help ~single will find all layers and renumber them with the pre-defined gap <CFGnLayerNumberGap>
		bRenumber=true;
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help <strExample> MISSING DESCRIPTION
		shift
		strExample="${1-}"
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
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

strMountAt="${1-}"

if [[ -z "$strMountAt" ]];then
	echoc -p "invalid strMountAt='$strMountAt'"
	exit 1
fi

function FUNCumount(){
	SECFUNCexecA -ce sudo -k umount "$strMountAt"
	SECFUNCexecA -ce trash -v "$strMountAt"
}

pwd
if [[ "${strMountAt:0:1}" == "/" ]];then #absolute path
	strMountedChk="`readlink -e "${strMountAt}"`"&&:
else
	strMountedChk="`readlink -e "$(pwd)"`/${strMountAt}"&&:
fi
declare -p strMountedChk

bAlreadyMounted=false
if mount |grep "on $strMountedChk type aufs";then # MUST BE A NON-REGEX grep!!
	bAlreadyMounted=true;
fi

if $bUmount;then
	FUNCumount
	exit 0
elif $bChkIsMultiLayer;then
	if $bAlreadyMounted;then
		exit 0
	fi
	exit 1
fi

if $bAlreadyMounted;then
	echoc --info "already mounted!"
	exit 0
else
	if [[ -d "$strMountAt" ]];then
		echoc --info "the mount point strMountAt='$strMountAt' access would be overriden, and its files will not be accessible..."
#		echoc -p "strMountAt='$strMountAt' should not exist..."
		
		if [[ -z "`ls -A "$strMountAt/"`" ]];then
			echoc --info "it is empty..."
			SECFUNCexecA -ce trash -v "$strMountAt"
		else
			echoc -p "strMountAt='$strMountAt' not empty!"
			SECFUNCexecA -ce du -sh $strMountAt
			exit 1
		fi
	else
		if [[ -a "$strMountAt" ]];then
			echoc -p "should be a directory strMountAt='$strMountAt', or should not exist..."
			exit 1
		fi
	fi
fi

#declare -A astrLayerList
IFS=$'\n' read -d '' -r -a astrLayerList < <(find "./" -maxdepth 1 -type d -iname "${strMountAt}.layer*" |sort &&:)&&:
#if [[ -z "$strLayerBranch" ]];then
if [[ -z "${astrLayerList[@]-}" ]];then # no layers found
	echoc --info "create layers like (same size for numeric field) ex.:"
	echo "${strMountAt}.layer010.SomeDescription"
	echo "${strMountAt}.layer020.Some Description a"
	echo "${strMountAt}.layer030.Some Description too"
	echo "..."
	echoc --info "the high value layers will override lower value ones"
	echoc --info "run it again..."
	exit 1
fi
for strLayer in "${astrLayerList[@]-}";do
	if [[ "$strLayer" =~ .*[:=].* ]];then
		echoc -p "invalid layer name (must not contain ':' or '=' used by aufs): $strLayer"
		exit 1
	fi
done
					
if $bRenumber;then
	if $bAlreadyMounted;then
		if echoc -q "umounting required, do it?";then
			FUNCumount
		else
			exit 1
		fi
	fi
	
#	declare -a astrOrderLayerList
	SECbExecJustEcho=true
	for((i=0;i<2;i++));do # 1st time will be just a preview
		iOrder=$CFGnLayerNumberGap
		for strLayer in "${astrLayerList[@]}";do
			strOrder="`echo "${strLayer}" |sed -r "s'(.*${strMountAt}[.]layer)([[:digit:]]*)([.].*)'\2'"`" #collect the numeric order 
	#		astrOrderLayerList[$((10#$strOrder))]="$strOrder:${strLayer}"
			strNewOrder="`printf "%04d" $iOrder`" #$((10#$strOrder))`"
			strNewName="`echo "${strLayer}" |sed -r "s'(.*${strMountAt}[.]layer)([[:digit:]]*)([.].*)'\1${strNewOrder}\3'"`" #modify the numeric order
			if [[ "${strLayer}" != "$strNewName" ]];then
				SECFUNCexecA -cej mv -vT "${strLayer}" "$strNewName"
			else
				echoc --info "skipping unmodified folder name: '${strLayer}'"
			fi
			((iOrder+=CFGnLayerNumberGap))&&:
		done
		
		if ! $SECbExecJustEcho;then break;fi
		if echoc -q "apply it?";then
			SECbExecJustEcho=false # affects the mv command above
		else
			exit 1
		fi
	done
	
	#declare -p astrOrderLayerList
#	iOrder=10
#	for strOrderLayer in "${astrOrderLayerList[@]}";do
#	done
	
	exit 0
fi

# the layers override priority is from left (top override) to right
strLayerBranch=""
for strLayer in "${astrLayerList[@]}";do
	if [[ -n "$strLayerBranch" ]];then strLayerBranch=":$strLayerBranch";fi
	strLayerBranch="${strLayer}${strLayerBranch}"
done
#strLayerBranch="`ls -d "${strMountAt}.layer"* |sort -r |tr "\n" ":" |sed -r 's"(.*):"\1"'`"&&:
declare -p strLayerBranch

########
### the leftmost layer will be the one receiving all writes made at the mounted folder, 
### even if it is a write on a file present in a lower layer (such file will remain the same,
### at such lower layer, as long it is modified at the mounted folder)!
########
strWriteLayer="${strMountAt}.writeLayer"
SECFUNCexecA -ce mkdir -vp "$strWriteLayer"

astrOpts=()
if $bReadOnly;then
	astrOpts+=(-o ro)
fi

SECFUNCexecA -ce mkdir -vp "$strMountAt"
declare -p strLayerBranch |tr ":" "\n"
SECFUNCexecA -ce sudo -k mount -t aufs -o br="$strWriteLayer:$strLayerBranch" ${astrOpts[@]-} none "$strMountAt"

SECFUNCexecA -ce ls -d "${strMountAt}"*

#echoc -w "to umount and remove"
#FUNCumount


