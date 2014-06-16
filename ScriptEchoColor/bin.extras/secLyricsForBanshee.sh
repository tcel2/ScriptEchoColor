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

SECFUNCuniqueLock --daemonwait

strFileLyricsTmp="/tmp/$SECscriptSelfName.lyrics.tmp"
strPathLyrics="$HOME/.cache/banshee-1/extensions/lyrics/"

bGraphicalDialog=false
bCloseWithWindow=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--lyricspath" ]];then #help <path> set lyrics path
		shift
		strPathLyrics="$1"
	elif [[ "$1" == "-x" ]];then #help use graphical interface 
		bGraphicalDialog=true
	elif [[ "$1" == "--closewithwindow" ]];then #help if graphical interface is closed, script exits
		bCloseWithWindow=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if [[ ! -f "${strFileLyricsTmp}.pdf" ]];then
	# evince will auto-refresh if the file already exists
	echo |enscript -p "${strFileLyricsTmp}.pdf"
fi

pidGfxReader=""
if $bGraphicalDialog;then
	#yad --title "$SECscriptSelfName" --text-info --listen --filename="$strFileLyricsTmp"&
	
	if $bCloseWithWindow;then
		evince "${strFileLyricsTmp}.pdf" 2>/dev/null&
		pidGfxReader=$!
	else
		function FUNCreader() {
			while true;do
				if pgrep "^banshee$";then
					evince "${strFileLyricsTmp}.pdf" 2>/dev/null
				fi
				sleep 1
			done
		}
		FUNCreader&
	fi
fi

pidLess=""
strMusic="";
while true; do
	pidBanshee="`pgrep banshee`"
	
	if [[ -n "$pidBanshee" ]];then
		read strMusicNew < <(\
			echo "`xdotool search --pid $pidBanshee 2>/dev/null`" |\
				while read nWindowId;do \
					xdotool getwindowname $nWindowId |grep -v "^Banshee";\
				done);
				
		if [[ "$strMusicNew" != "$strMusic" ]];then \
			if [[ -n "$pidLess" ]] && ps -p $pidLess 2>/dev/null;then
				echoc -x "kill $pidLess"
			
				#echoc -x "wait $pidLess"
				while ps -p $pidLess 2>&1 >/dev/null;do
					echoc -w -t 1 "waiting pid $pidLess terminate..."
				done
			fi
			strMusic="$strMusicNew";
			echoc -t 1 --info "$strMusic";
			strLyricsFile="`echo "$strMusic" |sed -r "s'(.*) by (.*) - Banshee Media Player$'\2_\1.lyrics'"`"
			export strLyricsFile="$strPathLyrics/$strLyricsFile";
			#echoc -w 60
			if [[ -f "$strLyricsFile" ]];then
				if $bGraphicalDialog;then
					#cat "$strLyricsFile" >"$strFileLyricsTmp"
					ln -sf "$strLyricsFile" "$strFileLyricsTmp"
					echoc -x "enscript -f \"Times-Roman14\" \"`readlink -f "$strFileLyricsTmp"`\" -p \"${strFileLyricsTmp}.pdf\""
				else
					cat "$strLyricsFile" |less & pidLess="$!"
				fi
			else
				echoc --alert "File not found: '$strLyricsFile'"
			fi
			#pidLess="$(sh -c 'cat "$strLyricsFile" |less & echo ${!}')" #less wont work this way
		fi;
	
		if $bCloseWithWindow;then
			if ! ps -p $pidGfxReader 2>&1 >/dev/null;then
				echoc --info "lyrics window closed"
				break;
			fi
		fi
	fi
	
	if SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	sleep 3;
done

