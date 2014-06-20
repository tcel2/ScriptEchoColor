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
bDownloadLyrics=true
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--lyricspath" ]];then #help <path> set lyrics path
		shift
		strPathLyrics="$1"
	elif [[ "$1" == "-x" ]];then #help use graphical interface 
		bGraphicalDialog=true
	elif [[ "$1" == "--nodownload" ]];then #help do not try to download missing lyrics, btw to the download try to find lyrics online, the music Name and Artist Name must be correctly spelled (not 100% granted anyway...)
		bDownloadLyrics=false
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
				if pgrep "^banshee$" >/dev/null;then
					if ! pgrep -fx "evince ${strFileLyricsTmp}.pdf" >/dev/null;then
						evince "${strFileLyricsTmp}.pdf" 2>/dev/null
					fi
				fi
				sleep 1
			done
		}
		FUNCreader&
	fi
fi

strTabChar="`echo -e "\t"`"
aLyricsSiteAndStrings=()
#aLyricsSiteAndStrings+=("lstrLyricsUrl\
#${strTabChar}lstrValidationRegex\
#${strTabChar}lstrEndingRegex\
#${strTabChar}lstrSpacesReplacedBy\
#${strTabChar}lstrCharBetweenArtistAndMusicName")
aLyricsSiteAndStrings+=("http://www.absolutelyrics.com/lyrics/view\
${strTabChar}[*][*][*][*][*]\
${strTabChar}[*][*][*][*][*] comments [*][*][*][*][*]\
${strTabChar}_\
${strTabChar}/")
aLyricsSiteAndStrings+=("http://music-tube.eu/lyrics/view\
${strTabChar}[-]--------------\
${strTabChar}===============================================================================\
${strTabChar}-\
${strTabChar}_")

#alias SECFUNCreturnOnFailA='if(($?!=0));then set +x;return 1;fi;'
function FUNCdownloadLyrics(){
	local lnIndex=${1}
	local lstrLyricsMissingFile="${2}"
	
	if ! $bDownloadLyrics;then return;fi
	
	#set -x
	local lstrSpacesReplacedBy="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f4`"
	local lstrCharBetweenArtistAndMusicName="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f5`"
	
	function FUNCfixNames(){
		echo "$1" |tr "[:upper:]" "[:lower:]" |tr " " "$lstrSpacesReplacedBy"
	}
	
	local lstrLyricsId="`basename "${lstrLyricsMissingFile}"`";lstrLyricsId="${lstrLyricsId%.lyrics}"
#	local lstrLyricsArtistName="`echo "$lstrLyricsId" |cut -d'_' -f1`"
#	local lstrLyricsMusicName="`echo "$lstrLyricsId" |cut -d'_' -f2`"
	local lstrLyricsArtistName="`echo "$lstrLyricsId" |cut -d'_' -f1`";
	lstrLyricsArtistName="`FUNCfixNames "$lstrLyricsArtistName"`"
	local lstrLyricsMusicName="`echo "$lstrLyricsId" |cut -d'_' -f2`";
	lstrLyricsMusicName="`FUNCfixNames "$lstrLyricsMusicName"`"
#	local lstrLyricsRemoteFileId="`echo "${lstrLyricsArtistName}${lstrCharBetweenArtistAndMusicName}${lstrLyricsMusicName}" |tr "[:upper:]" "[:lower:]" |tr " " "$lstrSpacesReplacedBy"`"
	local lstrLyricsRemoteFileId="${lstrLyricsArtistName}${lstrCharBetweenArtistAndMusicName}${lstrLyricsMusicName}"

	local lstrLyricsUrl="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f1`"
	local lstrLyricsFullUrl="$lstrLyricsUrl/$lstrLyricsRemoteFileId"
	local lstrValidationRegex="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f2`"
	local lstrEndingRegex="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f3`"
	
	function FUNClocalFileIdSlashFix(){
		if [[ "${lstrCharBetweenArtistAndMusicName}" == "/" ]];then
			lstrLyricsLocalFileId="`echo "$lstrLyricsLocalFileId" |tr "/" "_"`"
			mv -v "$lstrLyricsMusicName" "${lstrLyricsLocalFileId}"
		fi
	}
	
	strFolderTmpLyricsDownload="/tmp/.$SECscriptSelfName.lyricsDownload"
	mkdir -vp "$strFolderTmpLyricsDownload"
	cd "$strFolderTmpLyricsDownload";SECFUNCreturnOnFailA
	local lstrLyricsLocalFileId="$lstrLyricsRemoteFileId"
	FUNClocalFileIdSlashFix
	if [[ ! -f "$lstrLyricsLocalFileId" ]];then
		wget "$lstrLyricsFullUrl"
		FUNClocalFileIdSlashFix
	fi
	if [[ -f "$lstrLyricsLocalFileId" ]];then
		mv -v "$lstrLyricsLocalFileId" "${lstrLyricsLocalFileId}.html";SECFUNCreturnOnFailA
	  html2text "${lstrLyricsLocalFileId}.html" >"${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  grep -q "^${lstrValidationRegex}$" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  # remove above lyrics
	  sed -i "0,/^${lstrValidationRegex}$/d" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  # remove after lyrics
	  sed -i "/^${lstrEndingRegex}$/,$""d" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  sed -i "1i ..." "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  sed -i "1i DownloadedWith:$SECscriptSelfName" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  sed -i "1i DownloadedFrom:$lstrLyricsFullUrl" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailA
	  cp -v "${lstrLyricsLocalFileId}.txt" "$lstrLyricsMissingFile";SECFUNCreturnOnFailA
	  #enscript "${lstrLyricsLocalFileId}.txt" -p "${lstrLyricsLocalFileId}.pdf";SECFUNCreturnOnFailA
	  #set +x
	  return 0
	fi
	
  #set +x
	return 1
};export -f FUNCdownloadLyrics

pidLess=""
strMusic="";
bJustDownloadedLyrics=false
while true; do
	pidBanshee="`pgrep banshee`"
	
	if [[ -n "$pidBanshee" ]];then
		read strMusicNew < <(\
			echo "`xdotool search --pid $pidBanshee 2>/dev/null`" |\
				while read nWindowId;do \
					xdotool getwindowname $nWindowId |grep -v "^Banshee";\
				done);
				
		if [[ -n "$strMusicNew" ]] && ( [[ "$strMusicNew" != "$strMusic" ]] || $bJustDownloadedLyrics );then
			bJustDownloadedLyrics=false
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
				for nIndex in "${!aLyricsSiteAndStrings[@]}";do
					if FUNCdownloadLyrics $nIndex "$strLyricsFile";then
						bJustDownloadedLyrics=true
						break
					fi
				done
				if ! $bJustDownloadedLyrics;then
					echo "Lyrics for '`basename "${strLyricsFile%.lyrics}"`' is Missing..." |enscript -f "Times-Roman14" -p "${strFileLyricsTmp}.pdf"
				fi
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

