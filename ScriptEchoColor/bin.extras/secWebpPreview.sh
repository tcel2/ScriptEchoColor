#!/bin/bash
# Copyright (C) 2015 by Henrique Abdalla
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

#yad --text "$0" #@@@R

bCreateThumbnailersFile=false
strSetupFolder="/usr/share/thumbnailers/"
strSetupFileName="secwebp.thumbnailer"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\tGenerate .webp previews for thumbnailers like the ones used by nautilus."
		SECFUNCshowHelp --colorize "\tWhen generating a thumbnail, these are the required main params: <strInFile> <nMaxDimension> <strOutFile> "
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--setup" || "$1" == "-s" ]];then #help setup the thumbnailers file, this option must be run without the required main params
		bCreateThumbnailersFile=true
	elif [[ "$1" == "--setupfilename" ]];then #help <strSetupFileName> to be used by --setup
		shift
		strSetupFileName="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift
done

strSetupFile="$strSetupFolder/$strSetupFileName"
if $bCreateThumbnailersFile;then
	if [[ -f "$strSetupFile" ]];then
		echoc -p "file strSetupFile='$strSetupFile' already exists..."
		exit 1
	fi
	
	if ! [[ "$0" =~ /usr/bin.* ]];then
		echoc --alert "Executable location not system wide."
		echo "$0"
		exit 1
	fi
	if((`stat -c %u $0`!=0));then
		echoc --alert "This executable is not owned by root."
		ls -l $0
		exit 1
	fi
	
	strSetupData="[Thumbnailer Entry]\nExec=$0 %i %s %o\nMimeType=image/x-webp;image/webp;"
	echoc --info "this will be written at setup file strSetupFile='$strSetupFile'"
	echo -e "$strSetupData"
	if echoc -q "do it?";then
		echo -e "$strSetupData" \
			|SECFUNCexecA -c --echo sudo -k tee "$strSetupFile"
	fi
	exit 0
fi

if [[ -z "${1-}" ]];then exit 0;fi # dummy call is ok, just do nothing

strInFile="${1-}"
if [[ ! -f "$strInFile" ]];then echo "invalid params L$LINENO: $@" >&2;exit 1;fi

nMaxDimension="${2-}"
if ! SECFUNCisNumber -dn "$nMaxDimension";then echo "invalid params L$LINENO: $@" >&2;exit 1;fi

strOutFile="${3-}"
if [[ -z "$strOutFile" ]];then echo "invalid params L$LINENO: $@" >&2;exit 1;fi


# this is a trick to prevent vwebp from actually showing the image and still give the required information
if ! strInfo="`DISPLAY=NONE SECFUNCexecA -ce vwebp -info "$strInFile"`";then echo "vwebp failed." >&2;exit 1;fi
strSize="`echo "$strInfo" |grep Canvas |sed -r 's"Canvas: (.*) x (.*)"\1\t\2"'`"

nWidth="`echo "$strSize" |cut -f1`"
nHeight="`echo "$strSize" |cut -f2`"

declare -p strInfo strSize nWidth nHeight

if((nWidth>nHeight));then
	nNewWidth=$nMaxDimension
	nNewHeight=`bc <<< "scale=10;f=$nHeight*($nNewWidth /$nWidth );scale=0;f/1"` #proportionality
else
	nNewHeight=$nMaxDimension
	nNewWidth=` bc <<< "scale=10;f=$nWidth *($nNewHeight/$nHeight);scale=0;f/1"` #proportionality
fi

if ! SECFUNCisNumber -dn "$nNewHeight";then echo "invalid nNewHeight='$nNewHeight'" >&2;exit 1;fi
if ! SECFUNCisNumber -dn "$nNewWidth";then echo "invalid nNewWidth='$nNewWidth'" >&2;exit 1;fi

SECFUNCexecA -c --echo /usr/bin/dwebp "$strInFile" -scale $nNewWidth $nNewHeight -o "$strOutFile"

exit 0
