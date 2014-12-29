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

eval `secinit`

bAutoOpenTabs=false
fSafeDelay="3.0"
bPersist=false
bContinue=false
bJustSave=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "to disable speech, use as: SEC_SAYVOL=0 $SECstrScriptSelfName ..."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--autoopentabs" || "$1" == "-a" ]];then #help key strokes will be sent to nautilus to auto open tabs, but you can do them manually (may be safer) after selecting all folders and hitting ctrl+shift+t
		bAutoOpenTabs=true
	elif [[ "$1" == "--safedelay" ]];then #help <fSafeDelay> better not change this, unless it is more than default.
		shift
		fSafeDelay="${1-}"
	elif [[ "$1" == "--persist" || "$1" == "-p" ]];then #help it will just store the tabs folders symlinks at user home instead of /tmp
		bPersist=true
	elif [[ "$1" == "--continue" || "$1" == "-c" ]];then #help will continue from last session open tabs, does not requires nautilus to be opened
		bContinue=true
	elif [[ "$1" == "--justsave" || "$1" == "-s" ]];then #help just save current tabs session to be reused later
		bJustSave=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done
astrNewTabs=("$@")

if $bJustSave;then
	bPersist=true
	bContinue=false
fi

strStoreAt="/tmp"
if $bPersist;then
	strStoreAt="$SECstrUserScriptCfgPath"
fi

if ! SECFUNCisNumber -n "$fSafeDelay";then
	echoc -p "invalid fSafeDelay='$fSafeDelay'"
	exit 1 
fi

if ! nPidNautilus=`pgrep nautilus`;then
	echoc -p "nautilus is not running"
	exit 1
fi

echoc --info "Optional parameters can be a tab locations to be added to a running nautilus."
echoc --info "Unexpectedly it is usefull to mix all nautilus windows in a single multi-tabs window!"
echoc --alert "WARNING: This is extremely experimental code, the delays are blind, if nautilus cannot attend to the commands, things may go wrong..."
echoc --alert "WARNING: the window typing is blind, if another window pops up the typing will happen on that window and not at nautilus!"

function FUNCnautilusFocus() {
	#the last ones seems the right one, still a blind guess anyway...
	#xdotool windowactivate `xdotool search "^nautilus$" |tail -n 1` 
	xdotool windowactivate `xdotool search --pid $nPidNautilus 2>/dev/null |tail -n 1` 2>/dev/null 
}

sedUrlDecoder='s"%"\\x"g'

varset --show astrOpenLocations
for strOpenLocation in "${astrOpenLocations[@]}"; do 
	echo "$strOpenLocation"
done

strTmpFolderWithLinks="$strStoreAt/.${SECstrScriptSelfName}.linksToTabs/`SECFUNCdtFmt --filename`/"
if $bContinue;then
	strLast="`ls "$(dirname "$strTmpFolderWithLinks")/" -t1 |head -n 1`"
	if [[ -z "$strLast" ]];then
		echoc -p "invalid strLast='$strLast'"
		exit 1
	fi
	strTmpFolderWithLinks="`dirname "$strTmpFolderWithLinks"`/$strLast"
	if [[ ! -d "$strTmpFolderWithLinks" ]];then
		echoc -p "invalid strTmpFolderWithLinks='$strTmpFolderWithLinks'"
		exit 1
	fi
	if [[ -z "`ls "$strTmpFolderWithLinks/"`" ]];then
		echoc -p "strTmpFolderWithLinks='$strTmpFolderWithLinks' is empty"
		exit 1
	fi
else
	astrOpenLocations=()
	bJustAddTab=false
	if [[ -n "${astrNewTabs[0]-}" ]];then
		bJustAddTab=true
		for strNewTab in "${astrNewTabs[@]}";do
			astrOpenLocations+=("$strNewTab")
			#FUNCaddTab "$strNewTab"
		done
		#exit 0
	else
		astrOpenLocationsTmp=(`qdbus org.gnome.Nautilus /org/freedesktop/FileManager1 org.freedesktop.FileManager1.OpenLocations |tac`);
		if [[ -z "${astrOpenLocationsTmp[@]-}" ]];then
			echoc -p "astrOpenLocationsTmp is empty, is nautilus closed?"
			exit 1
		else
			for strOpenLocation in "${astrOpenLocationsTmp[@]}"; do 
				astrOpenLocations+=("`echo "$strOpenLocation" \
					|sed -r 's@^file://(.*)@\1@' \
					|sed "$sedUrlDecoder" \
					|sed 's;.*;"&";' \
					|xargs printf`")
			done
		fi
	fi

	mkdir -vp "$strTmpFolderWithLinks"
	nTabIndex=0
	for strOpenLocation in "${astrOpenLocations[@]}"; do 
		ln -vsf "$strOpenLocation" "$strTmpFolderWithLinks/$nTabIndex-`basename "$strOpenLocation"`"
		((nTabIndex++))&&:
	done
fi

echo "strTmpFolderWithLinks='$strTmpFolderWithLinks'"

if $bJustSave; then 
	SECFUNCexecA --echo -c ls -l "$strTmpFolderWithLinks/"
	exit 0;
fi

if ! echoc -q "continue at your own risk?";then
	exit
fi

SECFUNCdelay --init

if ! $bContinue;then
	echoc -x "nautilus -q"
	echoc -w -t $fSafeDelay #TODO alternatively check it stop running
fi
#echoc -x "nautilus '$strTmpFolderWithLinks'";
echoc -x "nautilus '$strTmpFolderWithLinks' >$strStoreAt/nautilus.log 2>&1 &"
echoc -w -t $fSafeDelay #TODO alternatively check it stop running

if $bAutoOpenTabs;then
	nPidNautilus=`pgrep nautilus`
#	lnSafeDelay="2.0"

	echoc --say --alert "wait script finish its execution as commands will be typed on the top window..." #could find no workaround that could type directly on specified window id ...	
	
	FUNCnautilusFocus
	xdotool key "ctrl+a" 2>/dev/null
	sleep $fSafeDelay
	
	FUNCnautilusFocus
	xdotool key "ctrl+shift+t" 2>/dev/null;
	sleep $fSafeDelay
	
	FUNCnautilusFocus
	xdotool key "ctrl+w" 2>/dev/null;
	#sleep $fSafeDelay
fi

echoc --info --say "Finished restoring nautilus tabs, it took `SECFUNCdelay --getsec` seconds."

