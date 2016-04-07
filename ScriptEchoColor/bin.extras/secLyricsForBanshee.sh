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

strFileLyricsTmp="/tmp/$SECstrScriptSelfName.lyrics.tmp"
strPathLyrics="$HOME/.cache/banshee-1/extensions/lyrics/"

bGraphicalDialog=false
bCloseWithWindow=false
bDownloadLyrics=true
bUseMozrepl=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		echo "default: strPathLyrics='$strPathLyrics'"
		SECFUNCshowHelp --nosort
		exit
	elif [[ "$1" == "--lyricspath" ]];then #help <strPathLyrics> set lyrics path
		shift
		strPathLyrics="$1"
	elif [[ "$1" == "--nodownload" ]];then #help do not try to download missing lyrics, btw music Name and Artist Name must be correctly spelled for a better chance of being found
		bDownloadLyrics=false
	elif [[ "$1" == "--mozreplyrics" ]];then #help load lyrics homepages at web browser. Start mozrepl (https://addons.mozilla.org/en-US/firefox/addon/mozrepl/) first. This overrides -x option.
		bUseMozrepl=true
	elif [[ "$1" == "-x" ]];then #help use GfxInterface
		bGraphicalDialog=true
	elif [[ "$1" == "--closewithwindow" ]];then #help when GfxInterface is closed, script exits
		bCloseWithWindow=true
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

SECFUNCuniqueLock --daemonwait

if [[ ! -f "${strFileLyricsTmp}.pdf" ]];then
	# evince will auto-refresh if the file already exists
	echo |enscript -p "${strFileLyricsTmp}.pdf"
fi

pidGfxReader=""
if ! $bUseMozrepl;then
	if $bGraphicalDialog;then
		#yad --title "$SECstrScriptSelfName" --text-info --listen --filename="$strFileLyricsTmp"&
	
		if $bCloseWithWindow;then
			evince "${strFileLyricsTmp}.pdf" 2>/dev/null&
			pidGfxReader=$!
		fi
	fi
fi

strTabChar="`echo -e "\t"`"
aLyricsSiteAndStrings=()
#aLyricsSiteAndStrings+=("lstrLyricsSiteBaseUrl\ #-f1
#${strTabChar}lstrValidationRegex\               #-f2
#${strTabChar}lstrEndingRegex\                   #-f3
#${strTabChar}lstrSpacesReplacedBy\              #-f4
#${strTabChar}lstrCharBetweenArtistAndMusicName\ #-f5
#${strTabChar}lstrQuestionSymbolTranslate")      #-f6
aLyricsSiteAndStrings+=("http://www.absolutelyrics.com/lyrics/view\
${strTabChar}[*][*][*][*][*]\
${strTabChar}[*][*][*][*][*] comments [*][*][*][*][*]\
${strTabChar}_\
${strTabChar}/\
${strTabChar},3f")
#aLyricsSiteAndStrings+=("http://music-tube.eu/lyrics/view\
#${strTabChar}[-]--------------\
#${strTabChar}===============================================================================\
#${strTabChar}-\
#${strTabChar}_")

function FUNCmozreplCoolness(){
	SECFUNCdbgFuncInA;
	local lstrUrl="$1"
	lstrUrl="`echo "$lstrUrl" |sed -r "s;';\\\\\';g"`" #result is from ' to \' ...
	#lstrUrl="`echo "$lstrUrl" |sed -r 's;'"'"';\\\'"'"';'`"
	#echo ">>>> lstrUrl='$lstrUrl'" >>/dev/stderr
	SECFUNCechoDbgA "lstrUrl='$lstrUrl'"
	#TODO some way to know if homepage was found and if not, return false?
	while true;do
		#TODO `sleep 3` is based on what? find a better way to know telnet command was accepted...
		if (echo "content.location.href = '$lstrUrl'";sleep 2;echo -e '\035';sleep 2) |telnet localhost 4242 >/dev/null;then
			break
		fi
		echoc -w -t 10 --alert "is MozRepl started?"
	done
	SECFUNCdbgFuncOutA;
}

#alias SECFUNCreturnOnFailA='if(($?!=0));then set +x;return 1;fi;'
function FUNConlineLyrics(){
	SECFUNCdbgFuncInA;
	local lbMozReplOnly=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--mozrepl-only" ]];then
			lbMozReplOnly=true
		else
			SECFUNCechoErrA "invalid option '$1'"
			_SECFUNCcriticalForceExit
		fi
		shift
	done
	
	local lnIndex=${1}
	local lstrLyricsMissingFile="${2}"
	
	#set -x
	# dismember aLyricsSiteAndStrings array item
	local lstrLyricsSiteBaseUrl="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f1`"
	local lstrValidationRegex="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f2`"
	local lstrEndingRegex="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f3`"
	local lstrSpacesReplacedBy="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f4`"
	local lstrCharBetweenArtistAndMusicName="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f5`"
	local lstrQuestionSymbolTranslate="`echo "${aLyricsSiteAndStrings[lnIndex]}" |cut -d"$strTabChar" -f6`"
	
	function FUNCfixNames(){
		echo "$1" \
			|tr "[:upper:]" "[:lower:]" \
			|tr " " "$lstrSpacesReplacedBy" \
			|sed "s'[?]'$lstrQuestionSymbolTranslate'g"
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
	
	if [[ -z "$lstrLyricsArtistName" ]];then
		SECFUNCechoWarnA "missing lstrLyricsArtistName='$lstrLyricsArtistName'"
		SECFUNCdbgFuncOutA;return 1
	fi
	if [[ -z "$lstrLyricsMusicName" ]];then
		SECFUNCechoWarnA "missing lstrLyricsMusicName='$lstrLyricsMusicName'"
		SECFUNCdbgFuncOutA;return 1
	fi
	
	local lstrLyricsFullUrl="$lstrLyricsSiteBaseUrl/$lstrLyricsRemoteFileId"
	#lstrLyricsFullUrl="`echo "$lstrLyricsFullUrl" |sed "s'[?]'$lstrQuestionSymbolTranslate'g"`"
	SECFUNCechoDbgA "lstrLyricsFullUrl='$lstrLyricsFullUrl'"
	if $bUseMozrepl;then
		if ! FUNCmozreplCoolness "$lstrLyricsFullUrl";then
			SECFUNCdbgFuncOutA;return 1
		fi
		if $lbMozReplOnly;then
			SECFUNCdbgFuncOutA;return
		fi
	fi
	
	# the actual lyrics downloading...
	function FUNClocalFileId(){
		if [[ "${lstrCharBetweenArtistAndMusicName}" == "/" ]];then
			# if slash separates artist from musicname, fix it for local file name
			lstrLyricsLocalFileId="`echo "$lstrLyricsLocalFileId" \
				|tr "/" "_" \
				|sed "s'$lstrQuestionSymbolTranslate'?'g" \
			`"
			mv -v "$lstrLyricsMusicName" "${lstrLyricsLocalFileId}"
		fi
	}
	
	strFolderTmpLyricsDownload="/tmp/.$SECstrScriptSelfName.lyricsDownload"
	mkdir -vp "$strFolderTmpLyricsDownload"
	cd "$strFolderTmpLyricsDownload";SECFUNCreturnOnFailDbgA
	
	local lstrLyricsLocalFileId="$lstrLyricsRemoteFileId"
	FUNClocalFileId
	
	# it may have downloaded from a previous attempt
	if [[ ! -f "$lstrLyricsLocalFileId" ]];then
		if $bDownloadLyrics;then
			wget "$lstrLyricsFullUrl"
			FUNClocalFileId
		fi
	fi

	if [[ -f "$lstrLyricsLocalFileId" ]];then
		mv -v "$lstrLyricsLocalFileId" "${lstrLyricsLocalFileId}.html";SECFUNCreturnOnFailDbgA
		html2text "${lstrLyricsLocalFileId}.html" >"${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		if ! grep -q "^${lstrValidationRegex}$" "${lstrLyricsLocalFileId}.txt";then
			SEC_WARN=true SECFUNCechoWarnA "unable to validate lyrics..."
			SECFUNCdbgFuncOutA;return 1
		fi
		# remove above lyrics
		sed -i "0,/^${lstrValidationRegex}$/d" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		# remove after lyrics
		sed -i "/^${lstrEndingRegex}$/,$""d" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		sed -i "1i ..." "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		sed -i "1i DownloadedWith:$SECstrScriptSelfName" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		sed -i "1i DownloadedFrom:$lstrLyricsFullUrl" "${lstrLyricsLocalFileId}.txt";SECFUNCreturnOnFailDbgA
		cp -v "${lstrLyricsLocalFileId}.txt" "$lstrLyricsMissingFile";SECFUNCreturnOnFailDbgA
		#enscript "${lstrLyricsLocalFileId}.txt" -p "${lstrLyricsLocalFileId}.pdf";SECFUNCreturnOnFailDbgA
		#set +x
		SECFUNCdbgFuncOutA;return 0
	fi
	
  #set +x
	SECFUNCdbgFuncOutA;return 1
};export -f FUNConlineLyrics

pidLess=""
strMusic="";
bJustDownloadedLyrics=false
bOpenOnce=true
if pgrep -fx "evince ${strFileLyricsTmp}.pdf" >/dev/null;then
	bOpenOnce=false
fi
while true; do
	pidBanshee="`pgrep banshee`"&&:
	
	if [[ -n "$pidBanshee" ]];then
#		read strMusicNew < <(\
#			echo "`xdotool search --pid $pidBanshee 2>/dev/null`" |\
#				while read nWindowId;do \
#					xdotool getwindowname $nWindowId |grep -v "^Banshee";\
#				done);

#		anWindowIdList=(`xdotool search --pid $pidBanshee 2>>/dev/null`)
#		for nWindowId in ${anWindowIdList[@]};do
#			if strMusicNew="`xdotool getwindowname $nWindowId |grep -v "^Banshee"`";then
#				break
#			fi
#		done
		
#		strMusicNew=$(gdbus call -e -d org.bansheeproject.Banshee -o /org/bansheeproject/Banshee/PlayerEngine -m org.bansheeproject.Banshee.PlayerEngine.GetCurrentTrack |sed -r "s@.* 'artist': <.([^>]*).>, .* 'name': <.([^>]*).>, .*@\2 by \1 - Banshee Media Player@")&&:
		strDbusCurrentTrack=$(gdbus call -e -d org.bansheeproject.Banshee -o /org/bansheeproject/Banshee/PlayerEngine -m org.bansheeproject.Banshee.PlayerEngine.GetCurrentTrack)
		strArtist=$(echo "$strDbusCurrentTrack" |grep "'artist': <" |sed -r "s@.* 'artist': <.([^>]*).>, .*@\1@")&&:
		strName=$(  echo "$strDbusCurrentTrack" |sed -r "s@.* 'name': <.([^>]*).>, .*@\1@")&&:
		strMusicNew="$strName by $strArtist - Banshee Media Player"
		
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
			strLyricsFile="`echo "$strMusic" |sed -r "s'^(.*) by (.*) - Banshee Media Player$'\2\t\1.lyrics'"`"
			strLyricsFile="`echo "$strLyricsFile" |tr "_${strTabChar}-" " _ "`" # replaces "-" "_" by spaces, from names, and converts "\t" to _
			export strLyricsFile="$strPathLyrics/$strLyricsFile";
			#echoc -w 60
			
			if $bUseMozrepl;then
				for nIndex in "${!aLyricsSiteAndStrings[@]}";do
					if FUNConlineLyrics --mozrepl-only $nIndex "$strLyricsFile";then
						break
					fi
				done
			fi
			
			if [[ -f "$strLyricsFile" ]];then
				if ! $bUseMozrepl;then
					if $bGraphicalDialog;then
						#cat "$strLyricsFile" >"$strFileLyricsTmp"
						ln -sf "$strLyricsFile" "$strFileLyricsTmp"
						SECFUNCexecA -ce enscript -f "Times-Roman14" "`readlink -f "$strFileLyricsTmp"`" -p "${strFileLyricsTmp}.pdf"
					else
						cat "$strLyricsFile" |less & pidLess="$!"
					fi
				fi
			else
				echoc --alert "File not found!"
				echoc --info "strLyricsFile='$strLyricsFile'"
				for nIndex in "${!aLyricsSiteAndStrings[@]}";do
					if FUNConlineLyrics $nIndex "$strLyricsFile";then
						bJustDownloadedLyrics=true
						break
					fi
				done
				if ! $bJustDownloadedLyrics;then
					echo "Lyrics for '`basename "${strLyricsFile%.lyrics}"`' is Missing..." \
						|enscript -f "Times-Roman14" -p "${strFileLyricsTmp}.pdf"
				fi
			fi
			#pidLess="$(sh -c 'cat "$strLyricsFile" |less & echo ${!}')" #less wont work this way
		fi;
		
		if $bGraphicalDialog;then
			if $bCloseWithWindow;then
				if ! ps -p $pidGfxReader 2>&1 >/dev/null;then
					echoc --info "lyrics window closed"
					break;
				fi
			fi
		fi
	fi
	
	pidGfxReader=""
	bSlept=false
	nSleepDelay=3
	if ! $bUseMozrepl;then
		if $bGraphicalDialog;then
			#yad --title "$SECstrScriptSelfName" --text-info --listen --filename="$strFileLyricsTmp"&
	
			if ! $bCloseWithWindow;then
				if pgrep "^banshee$" >/dev/null;then
					bOpenNow=false
					if ! pgrep -fx "evince ${strFileLyricsTmp}.pdf" >/dev/null;then
						if $bOpenOnce;then
							bOpenNow=true
							bOpenOnce=false
						else
#							if echoc -t $nSleepDelay -q "open evince (lyrics pdf viewer) now?";then
#							if echoc -t 60 -q "open evince (lyrics pdf viewer) now?";then
#								bOpenNow=true
#								bSlept=true
#							fi
							echoc -Q "Lyrics@O_view/_edit"&&:;case "`secascii $?`" in 
								v)echo "viewing..."
									bOpenNow=true
									bSlept=true
									;; 
								e)gedit "$strLyricsFile";; 
							esac
						fi
						if $bOpenNow;then
							evince "${strFileLyricsTmp}.pdf" 2>/dev/null &
						fi
					fi
				fi
			fi
		fi
	fi
	
	if SECFUNCdelay daemonHold --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	if ! $bSlept;then
		sleep $nSleepDelay;
	fi
done

