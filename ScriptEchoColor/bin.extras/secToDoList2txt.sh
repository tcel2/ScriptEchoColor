#!/bin/bash

# Copyright (C) 2013-2014 by Henrique Abdalla
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

##################### INIT/CFG/FUNCTIONS
source <(secinit)

bHTML=true

if ! type -P echoc >/dev/null 2>&1 ; then
	function echoc() {
		echo "$@"
	}
fi

strDiskByUUIDpath="/dev/disk/by-uuid/"
varset --show strBackupPath="`readlink -f "$HOME/Documents/"`"
SECFUNCcfgFileName #to prepare the filename variable $SECcfgFileName

function FUNCbluetoothChannel () {
	sdptool browse "$1" |grep "Service Name: Object Push" -A 20 |grep "Channel: "|head -n 1 |tr -d ' ' |cut -d: -f2
}

function FUNCdebugVar () {
	echoc --info "$1"
	eval "echo \"\$$1\""
	echoc -w
	exit
}

##################### OPTIONS

bHasOptions=false
if [[ -n ${1-} ]];then
	bHasOptions=true
fi

#strSDCardName=""
strSDCardUUID=""
strBluetoothAddress=""
bStoreConfiguration=false
varset bDoAllGroups=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
	if [[ "$1" == "--help" ]];then #help show this help
		echoc --info "Parser for xml exported from app @rToDo List@b for @rAndroid@b."
		echoc --info "At @{y}https://play.google.com/store/apps/details?id=net.sf.swatwork.android.todo@b."
		echoc --alert "Group names begginning with '-' will be ignored."
		SECFUNCshowHelp
		
		echoc --info "current auto config in case of no commandline options:"
		cat "$SECcfgFileName"
		
		exit
	elif [[ "$1" == "--sdcarduuid" ]];then #help <uuid> mounted SDCard uuid of your smartphone where ToDo List is installed
		shift
		varset --show strSDCardUUID="$1"
		if [[ ! -a "$strDiskByUUIDpath/$strSDCardUUID" ]];then
			echoc -x "ls -l \"$strDiskByUUIDpath\""
			echoc -w -p "invalid SDCard UUID, check above..."
			exit 1
		fi
	elif [[ "$1" == "--bluetoothaddress" ]];then #help <btaddr> bluetooth address of your other cellphone to send file to
		shift
		varset --show strBluetoothAddress="$1"
	elif [[ "$1" == "--backupto" ]];then #help <path> backup xml file to
		shift
		varset --show strBackupPath="$1"
	elif [[ "$1" == "--detect" ]];then #help find bluetooth and list uuids
		echoc -x "mount |grep \"^/dev/\""
		echoc -x "ls -l \"$strDiskByUUIDpath\""
		echoc -x "hcitool scan #--bluetoothaddress"
		exit
	elif [[ "$1" == "--cfg" ]];then #help store all the setup made on the current command line for later automatic use in case there is no options in the command line then
		bStoreConfiguration=true
	elif [[ "$1" == "--doallgroups" ]];then #help will not ignore any groups
		varset --show bDoAllGroups=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

varset --show strFile="`readlink -f "${1-}"`"

################## SAVE/LOAD AUTO CONFIG
if $bStoreConfiguration;then
	echoc -x "rm -v \"$SECcfgFileName\""
	SECFUNCcfgWriteVar strSDCardUUID
	SECFUNCcfgWriteVar strBluetoothAddress
	echoc -x "cat \"$SECcfgFileName\""
fi

if ! $bHasOptions;then
	SECFUNCcfgReadDB
	echoc -x "cat \"$SECcfgFileName\""
	echoc --info "automatic config options loaded!"
	if ! echoc -t 3 -q "proceed?@Dy";then
		exit
	fi
fi

################ CHOOSE FILE
if [[ -z "$strFile" ]];then
	if [[ -n "$strSDCardUUID" ]];then
		while ! strLinksTo="`readlink "$strDiskByUUIDpath/$strSDCardUUID"`";do
			echoc --alert "waiting sdcard be connected and available strSDCardUUID='$strSDCardUUID'"
			sleep 3
		done
		strDeviceName="`basename "$strLinksTo"`"
		strDevice="/dev/$strDeviceName"
		echo "strDevice='$strDevice'"
		while ! strMountMICROSD="`mount |grep "^${strDevice} "`";do
			tree -if /dev/disk/by-label/ |egrep "/${strDeviceName}$"
			echoc -w "you need to mount strDevice='$strDevice'"
		done
		strPathMICROSD="`echo "$strMountMICROSD" |cut -d' ' -f3`"
		strFileMICROSD="`find "$strPathMICROSD" -maxdepth 1 -name "ToDoList_*.xml" |sort |tail -n 1`"
		
		if [[ -f "${strFileMICROSD-}" ]];then
			varset --show strFile="$strFileMICROSD"
			echoc -x "cp -v \"$strFileMICROSD\" \"$strBackupPath\" #simple backup"
		else
			echoc -w -p "failed: strFileMICROSD='$strFileMICROSD'"
			exit 1
		fi
	else
		varset --show strFile="`ls -1 $HOME/Documents/ToDoList_*.xml |sort |tail -n 1`"
	fi
fi

if [[ ! -f "$strFile" ]];then
	echoc -p "invalid file '$strFile'"
	exit 1
fi

####################### MAIN

# to work on memory
strFileData=`cat "$strFile"`

# make all xml blocks become single lined
strFileData=`echo "$strFileData" |tr -d "\n" |sed 's"</[[:alnum:]]*>"&\n"g'`

# create group array
nIndexMax=0
aGroupName=()
eval `echo "$strFileData" |grep "^<group" |sed -r 's#\
^<group id="([[:digit:]]*)"><\!\[CDATA\[(.*)\]\]></group>$#\
if((\1>nIndexMax));then varset nIndexMax=\1;fi;aGroupName[\1]="\2";#'`
varset --show aGroupName
varset --show nIndexMax="$nIndexMax"

#varset --show nIndexBegin=0
#while [[ -z "${aGroupName[nIndexBegin]-}" ]];do
#	((nIndexBegin++))
#done

#varset --show nIndexEnd=$nIndexBegin
#while [[ -n "${aGroupName[nIndexEnd]-}" ]];do
#	((nIndexEnd++))
#done

# prepare output
strFileOuput="${strFile}.txt"
#for((nIndex=nIndexBegin;nIndex<nIndexEnd;nIndex++));do
for((nIndex=0;nIndex<=nIndexMax;nIndex++));do
	if [[ -z "${aGroupName[nIndex]-}" ]];then
		continue
	fi
	#strFileData=`echo "$strFileData" |sed "s;group=\"$nIndex\";group=\"${aGroupName[nIndex]}\";g"`
	#echo
	if $bDoAllGroups || [[ "${aGroupName[nIndex]:0:1}" != "-" ]];then
		echo "GROUP: ${aGroupName[nIndex]}"
		echo "$strFileData" \
			|grep "^<item" \
			|grep "status=\"0\"" \
			|grep "group=\"$nIndex\"" \
			|sed -r 's".*<!\[CDATA\[(.*)\]\]>.*" + \1"' \
			|sort
		echo "$strFileData" \
			|grep "^<item" \
			|grep "status=\"1\"" \
			|grep "group=\"$nIndex\"" \
			|sed -r 's".*<!\[CDATA\[(.*)\]\]>.*" ? \1"' \
			|sort
	fi
done >"$strFileOuput"

echoc -x "cat \"$strFileOuput\""

# HTML output
strFileOuputHTML="${strFile}.html"
strTitle=`basename "$strFile"`
nLineCount=`cat "$strFileOuput" |wc -l`
# coded for 3 columns
strTagTD='td valign="top" width="33%"'
#strTDbreak="</small></td><$strTagTD><small>"
#sedColumn2break="$((  nLineCount   /3 ))a $strTDbreak"
#sedColumn3break="$(( (nLineCount*2)/3 ))a $strTDbreak"
if $bHTML;then
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
		<html>
			<head>
				<meta http-equiv="content-type" content="text/html; charset=UTF-8">
				<title>'"$strTitle"'</title>
			</head>
			<body>
				<table border="1" cellpadding="2" cellspacing="2" width="100%">
				  <tbody>
				    <tr>
				      <'"$strTagTD"'><small>' >"$strFileOuputHTML"
	cat "$strFileOuput" \
		|sed -r 's"^GROUP:(.*)$"</small><b>\1</b><small>"' \
		|sed 's"^.*$"&<br>"' \
		|sed "$((nLineCount/3))b idAction; \
					$(((nLineCount*2)/3))b idAction; \
					b; : idAction; a </small></td><$strTagTD><small>" \
		>>"$strFileOuputHTML"
#		|sed "$sedColumn2break" \
#		|sed "$sedColumn3break" \
	echo '</small></td>
				    </tr>
				  </tbody>
				</table>
				<b><br>
				</b>
			</body>
		</html>' >>"$strFileOuputHTML"
fi

echoc --info "ORIGINAL: $strFile"
echoc --info "TXT: $strFileOuput"
echoc --info "HTML: $strFileOuputHTML"

#echo ">>>`dirname "$strFileOuput"`"
if [[ "`dirname "$strFileOuput"`" != "$strBackupPath" ]];then
	echoc -x "cp -v \"$strFileOuput\" \"$strBackupPath\" #simple backup"
	echoc -x "cp -v \"$strFileOuputHTML\" \"$strBackupPath\" #simple backup"
fi

############# SEND HTML THRU BLUETOOTH
if [[ -n "$strBluetoothAddress" ]];then
	nRet=1
	while((nRet==1));do
		if ! echoc -t 3 -q "send to bluetooth?@Dy";then
			break;
		fi
		
		varset --show nBluetoothChannel="`FUNCbluetoothChannel "$strBluetoothAddress"`"
		obexftp --nopath --noconn --uuid none --bluetooth "$strBluetoothAddress" --channel "$nBluetoothChannel" --put "$strFileOuputHTML"&&:
		nRet=$?
		
	done
fi

#if echoc -t 5 -q "edit txt with libreoffice writer?";then
#	soffice --writer "$strFileOuput"&
#fi

