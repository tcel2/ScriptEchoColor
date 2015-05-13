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

eval `secinit`

bCreateThumbnailersFile=false
strSetupFolder="/usr/share/thumbnailers/"
strSetupFileName="secwebp.thumbnailer"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "generate .webp previews for thumbnailers like the ones used by nautilus"
		SECFUNCshowHelp --colorize "required params <strInFile> <nMaxDimension> <strOutFile> "
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--setup" || "$1" == "-s" ]];then #help setup the thumbnailers file
		bCreateThumbnailersFile=true
	elif [[ "$1" == "--setupfilename" ]];then #help <strSetupFileName>
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
	
	strSetupData="[Thumbnailer Entry]\nExec=$0 %i %s %o\nMimeType=image/x-webp;"
	echoc --info "this will be written at setup file strSetupFile='$strSetupFile'"
	echo -e "$strSetupData"
	if echoc -q "do it?";then
		echo -e "[Thumbnailer Entry]\nExec=$0 %i %s %o\nMimeType=image/x-webp;" \
			|SECFUNCexecA -c --echo sudo -k tee "$strSetupFile"
	fi
	exit 0
fi

strInFile="$1"
nMaxDimension="$2"
strOutFile="$3"


# this is a trick to prevent vwebp from actually showing the image and still give the required information
strInfo="`DISPLAY=NONE SECFUNCexecA -c --echo vwebp -info "$strInFile"`"&&:
strSize="`echo "$strInfo" |grep Canvas |sed -r 's"Canvas: (.*) x (.*)"\1\t\2"'`"

nWidth="`echo "$strSize" |cut -f1`"
nHeight="`echo "$strSize" |cut -f2`"

if((nWidth>nHeight));then
	nNewWidth=$nMaxDimension
	nNewHeight=`bc <<< "scale=10;f=$nHeight*($nNewWidth /$nWidth );scale=0;f/1"` #proportionality
else
	nNewHeight=$nMaxDimension
	nNewWidth=` bc <<< "scale=10;f=$nWidth *($nNewHeight/$nHeight);scale=0;f/1"` #proportionality
fi

SECFUNCexecA -c --echo /usr/bin/dwebp "$strInFile" -scale $nNewWidth $nNewHeight -o "$strOutFile"

