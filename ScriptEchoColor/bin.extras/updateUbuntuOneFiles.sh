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

function FUNCtrap() {
	trap 'echo "(ctrl+c pressed, exiting...)";exit 2' INT
	#TODO `find` exits if ctrl+c is pressed, why? #trap 'echo "ctrl+c pressed...";varset bInterruptAsk=true;' INT
};export -f FUNCtrap
FUNCtrap
eval `secinit`

############### INTERNAL CFG
export pathUbuntuOne="$HOME/Ubuntu One"
sedQuoteLines='s".*"\"&\""'
sedRemoveHomePath="s;^$HOME;.;"
sedQuoteLinesForZenitySelection="s;.*;false '&';"
sedEncloseLineOnPliqs="s;.*;'&';"
sedTrSeparatorToPliqs="s;[|];' ';g"
addFileHist="$HOME/.`basename $0`.addFilesHistory.log"
sedUrlDecoder='s % \\\\x g' #example: strPath=`echo "$NAUTILUS_SCRIPT_CURRENT_URI" |sed -r 's"^file://(.*)"\1"' |sed "$sedUrlDecoder" |xargs printf`

#
#if [[ "$bSkipNautilusCheckNow" != "true" ]]; then
#	bSkipNautilusCheckNow="false"
#fi

export bGoFastOnce=false
varset --default bInterruptAsk=false

############### OPTIONS

bAddFilesMode=false
SECFUNCvarSet --default --show bAutoSync=false
bDaemon=false
export bCmpData=false
bSkipNautilusCheckNow=false
bWait=false
bLookForChanges=false
bLsNot=false
bLsMissHist=false
bRecreateHistory=false
bConfirmAlways=false
export bBackgroundWork=false
varset --default --show bAutoGit=false
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	if [[ "$1" == "--help" ]]; then #help: show this help
		echo "Updates files at Ubuntu One folder if they already exist there, relatively to your home folder."
		#grep "#@help" "$0" |grep -v grep |sed -r 's".*\"[$]1\" == \"(--[[:alnum:]]*)\".*#@help:(.*)$"\t\1\t\2"'
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--daemon" ]]; then #help: runs automatically forever
		bDaemon=true
		#bLookForChanges=true
	elif [[ "$1" == "--lookforchanges" ]]; then #help: look for changes and update, is automatically set with --daemon option
		bLookForChanges=true
	elif [[ "$1" == "--wait" ]]; then #help: will wait a key press before exiting
		bWait=true
	elif [[ "$1" == "--skipnautilus" ]]; then #help: 
		bSkipNautilusCheckNow=true
	elif [[ "$1" == "--addfiles" ]]; then #help: <files...> add files to ubuntu one! this is also default option if the param is a file, no need to put this option.
		bAddFilesMode=true
	elif [[ "$1" == "--cmpdata" ]]; then #help: if size and time are equal, compare data for differences
		bCmpData=true
	elif [[ "$1" == "--confirmalways" ]]; then #help: will always accept to update the changes on the first check loop
		bConfirmAlways=true
	elif [[ "$1" == "--background" ]]; then #help: between each copy will be added a delay
		bBackgroundWork=true
	elif [[ "$1" == "--autogit" ]]; then #help: all files at Ubuntu One will be versioned (with history)
		bAutoGit=true
	elif [[ "$1" == "--autosync" ]]; then #help: will automatically copy the changes without asking
		SECFUNCvarSet --show bAutoSync=true
	elif [[ "$1" == "--lsr" ]]; then #help: will list what files, of current folder recursively, are at ubuntu one!
		ls -lR "$HOME/Ubuntu One/`pwd |sed "s'$HOME/''"`"
		exit 0
	elif [[ "$1" == "--lsnot" ]]; then #help: will list files of current folder are NOT at ubuntu one (use with --addfiles to show a dialog at X to select files to add!)
		bLsNot=true
	elif [[ "$1" == "--lsmisshist" ]]; then #help: will list missing files on ubuntu one folder that are still on "history log" file (use with --addfiles to show a dialog at X to select files to re-add!)
		bLsMissHist=true
	elif [[ "$1" == "--recreatehist" ]]; then #help: will recreate the history file based on what is at Ubuntu One folder..
		bRecreateHistory=true
	else	
		echoc -p "invalid option $1"
		exit 1
	fi
	
	shift
done

############### OPTIONS NAUTILUS WAY

if ! $bSkipNautilusCheckNow && set |grep -q "NAUTILUS_SCRIPT"; then #set causes broken pipe but works?
	#ex.: NAUTILUS_SCRIPT_SELECTED_FILE_PATHS=$'/file/one\n/file/two\n'
	sedEscapeSpaces='s"[ ]"\ "g'
	#eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed "$sedEscapeSpaces" |sed "$sedQuoteLines"`)
	eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed "$sedQuoteLines"`)
	
	#printf "%q " "${astrFiles[@]}"
	#echoc -w;exit 0
	
	#bash does not export arrays...
	#export strFiles="${astrFiles[@]}"
	
	echoc --info "nautilus way"
	set |grep "NAUTILUS_SCRIPT"
	
	#export bSkipNautilusCheckNow=true
	#function FUNCnautilusWay() { $0 $strFiles; }; export -f FUNCnautilusWay;
	#xterm -e bash -c "FUNCnautilusWay"
	#printf "%q " "${astrFiles[@]}"
	#xterm -e "$0 --skipnautilus `printf "%q " "${astrFiles[@]}"`"
	strFiles=`printf "%q " "${astrFiles[@]}"`
	eval "$0 --skipnautilus --addfiles --wait $strFiles"
	exit 0
fi
if $bSkipNautilusCheckNow; then #nautilus way
	set |grep "NAUTILUS_SCRIPT"
fi

################## FUNCTIONS 

function FUNCinterruptAsk() {
	if $bInterruptAsk;then
		echoc -Q "ctrl+c pressed@O_go fast once/_exit@Dg";case "`secascii $?`" in 
			g)bGoFastOnce=true;; 
			e)exit;; 
		esac
	fi
	varset bInterruptAsk=false
};export -f FUNCinterruptAsk

function FUNCcopy() {
	#FUNCtrap
	#eval `secinit`
	#SECFUNCvarReadDB
	
	SECFUNCdelay $FUNCNAME --init
	
	local bDoIt=$1
	local strFile="$2"
	local bChanged=false
	
	realFile="$HOME/$strFile"
	while [[ -L "$realFile" ]];do
		realFile=`readlink "$realFile"`
	done
	
	#echo "bCmpData=$bCmpData"
	if [[ -f "$realFile" ]];then
		if((`stat -c%s "$realFile"`!=`stat -c%s "$pathUbuntuOne/$strFile"`));then
			# check by size
			#echo "size changed `stat -c%s "$HOME/$strFile"`!=`stat -c%s "$pathUbuntuOne/$strFile"`"
			bChanged=true;
		elif((`stat -c%Y "$realFile"`!=`stat -c%Y "$pathUbuntuOne/$strFile"`));then
			# check by last modification
			#echo "modification time changed `stat -c%Y "$HOME/$strFile"`!=`stat -c%Y "$pathUbuntuOne/$strFile"`"
			bChanged=true;
	#	elif((`stat -c%Z "$realFile"`!=`stat -c%Z "$pathUbuntuOne/$strFile"`));then
	#		# check by last change (same as modification)
	#		bChanged=true;
		elif $bCmpData && ! cmp -s "$HOME/$strFile" "$pathUbuntuOne/$strFile"; then
	#		echo "data changed"
			bChanged=true;
		fi
	else
		bChanged=true;
	fi
	
	# do not allow symlinks on ubuntu one, must be real dada files
	#ls -l "$pathUbuntuOne/$strFile"
	if [[ -L "$pathUbuntuOne/$strFile" ]]; then
		bChanged=true;
	fi
	
	if $bChanged; then
		SECFUNCvarSet --showdbg nFilesChangedCount=$((++nFilesChangedCount))
		
		# this will remove from Ubuntu One, real files that are also missing at $HOME, so will sync properly (so wont work as backup)
		cmdRm="trash -vf \"$pathUbuntuOne/$strFile\""
		
		cmdCopy="cp -vfLp \"$HOME/$strFile\" \"$pathUbuntuOne/$strFile\""
		if $bDoIt; then
			echoc --info "working with: $strFile"
			eval "$cmdRm"
			eval "$cmdCopy"
		else
			echo "Changed: $HOME/$strFile"
			#echo "$cmdRm"
			#echo "$cmdCopy"
		fi
	fi
	
	SECFUNCvarSet --showdbg nFilesCount=$((++nFilesCount))
	
	# `find` calling this can be very time consuming... so daemon control goes here too...
	if SECFUNCdelay ListOfFuncCopy --checkorinit 5;then
		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
	fi
	
	FUNCinterruptAsk #can set bGoFastOnce to true
	if ! $bGoFastOnce;then
		if $bBackgroundWork;then
			read -s -n 1 -t 1 -p "" #sleep 1
		fi
	fi
	
	echo -en "\r$nFilesCount,delay=`SECFUNCdelay $FUNCNAME`\r"
};export -f FUNCcopy

function FUNCzenitySelectAndAddFilesUbuOne() {
	local listSelected=`zenity --list --checklist --column="" --column="file to add" "$@"`
	#local listSelected="$1"
	
	if [[ -n "$listSelected" ]];then
		echoc --info "Selected files list:"
		echo "$listSelected"
		local alistSelected=(`echo "$listSelected" |sed "$sedEncloseLineOnPliqs" |sed "$sedTrSeparatorToPliqs"`)
		echo "${alistSelected[@]}"
		eval $0 --skipnautilus --addfiles "${alistSelected[@]}"
	fi
};export -f FUNCzenitySelectAndAddFilesUbuOne

function FUNClsNot() { #synchronize like
	function FUNCfileCheck() { 
		#echo "look for: $1"
		local relativePath="$1"
		local fileAtCurPath="$2"
		local fileCheck="$HOME/Ubuntu One/$relativePath/$fileAtCurPath"; 
		if [[ ! -f "$fileCheck" ]];then 
			echo "$fileAtCurPath";
		fi; 
	};export -f FUNCfileCheck;
	relativeToHome=`pwd -L |sed -r "$sedRemoveHomePath"`
	#echo "relativeToHome=$relativeToHome"
	#pwd -L
	
	listOfFiles=`find ./ -maxdepth 1 -type f -not -iname "*~" -exec bash -c "FUNCfileCheck \"$relativeToHome\" \"{}\"" \; |sort`
	if [[ -n "$listOfFiles" ]];then
		echoc --info "File list that are not at Ubuntu One:"
		echo "$listOfFiles"
	
		if $bAddFilesMode;then
			#eval "alistOfFiles=(`echo "$listOfFiles" |sed "$sedQuoteLinesForZenitySelection"`)"
			#eval alistOfFiles=(`echo "$listOfFiles" |sed "$sedRemoveHomePath" |sed "$sedQuoteLinesForZenitySelection"`)
			eval alistOfFiles=(`echo "$listOfFiles" |sed "$sedQuoteLinesForZenitySelection"`)
	
			#listSelected=`zenity --list --checklist --column="" --column="file to add" "${alistOfFiles[@]}"`
			
			#FUNCzenitySelectAndAddFilesUbuOne "$listSelected"
			FUNCzenitySelectAndAddFilesUbuOne "${alistOfFiles[@]}"
#			if [[ -n "$listSelected" ]];then
#				echoc --info "Selected files list:"
#				echo "$listSelected"
#				#echo "$listSelected" |sed "$sedQuoteLines" |sed 's"[|]"\" \""g'
#				#eval "alistSelected=(`echo "$listSelected" |sed "$sedQuoteLines" |sed 's"[|]"\" \""g'`)"
#				alistSelected=(`echo "$listSelected" |sed "$sedEncloseLineOnPliqs" |sed "$sedTrSeparatorToPliqs"`)
#				echo "${alistSelected[@]}"
#				eval $0 --skipnautilus --addfiles "${alistSelected[@]}"
#			fi

		fi
	else
		echoc --info "All files are at Ubuntu One! "
	fi
};export -f FUNClsNot

################### MAIN CODES ######################################

if $bDaemon;then
	SECFUNCuniqueLock --daemonwait
	
	strBkgWrkopt=""
	if $bCmpData;then
		strBkgWrkopt="--background"
	fi
	
	while true; do
		nice -n 19 $0 --lookforchanges --confirmalways $strBkgWrkopt
		echoc -w -t 5 "daemons sleep too..."
		
		if SECFUNCdelay daemonHold --checkorinit 5;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		fi
		
		#if ! sleep 5; then exit 1; fi
	done
	exit 0
fi

# default is to add a file if it is a param.
if [[ -f "${1-}" ]]; then
	bAddFilesMode=true
fi

#while [[ -f "$1" ]]; do
#	echoc --info "$1"
#	shift
#done
#echoc -w "test"
#exit

if $bLsNot;then
	FUNClsNot
elif $bRecreateHistory;then
	mv -vf "$addFileHist" "${addFileHist}.old"
	find "$pathUbuntuOne" -type f |sed -r "s'$pathUbuntuOne'$HOME'" |sort >"$addFileHist"
	#cat "$addFileHist"
	meld "$addFileHist" "${addFileHist}.old"
elif $bLsMissHist; then
	bkpIFS="$IFS"; #default is: " \t\n", hexa: 0x20,0x9,0xA, octa: 040,011,012
	IFS=$'\n';
	
	aAllFiles=(`cat "$addFileHist"`);
	count=0
	echo "Missing Files:"
	for file in ${aAllFiles[@]};do
		prefix=""
		bMissingReal=false
		bMissingUbu1=false
		if [[ ! -e "$file" ]];then
			prefix="${prefix}Real:"
			bMissingReal=true
		fi
		if [[ ! -e "`echo "$file" |sed -r "s'^$HOME'$pathUbuntuOne'"`" ]];then
			prefix="${prefix}Ubu1:"
			bMissingUbu1=true
		fi
		if $bMissingReal || $bMissingUbu1;then
			echo "$prefix $file";
			if ! $bMissingReal && $bMissingUbu1;then
				aMissingFiles[$count]="false"
				#aMissingFiles[$((count+1))]=`echo "$file" |sed "$sedRemoveHomePath"`
				aMissingFiles[$((count+1))]=`echo "$file"`
				((count+=2))
			fi
		fi;
	done;
	
	if $bAddFilesMode && ((count>0));then
		#echoc --info "missing files to zenity"
		#echo "${aMissingFiles[@]}"
		#eval aMissingFiles=(`echo "${aMissingFiles[@]}"`)
		#listSelected=`zenity --list --checklist --column="" --column="file to add" "${aMissingFiles[@]}"`
		
		#FUNCzenitySelectAndAddFilesUbuOne "$listSelected"
		FUNCzenitySelectAndAddFilesUbuOne "${aMissingFiles[@]}"
#		if [[ -n "$listSelected" ]];then
#			echoc --info "Selected files list:"
#			echo "$listSelected"
#			alistSelected=(`echo "$listSelected" |sed "$sedEncloseLineOnPliqs" |sed "$sedTrSeparatorToPliqs"`)
#			echo "${alistSelected[@]}"
#			#eval $0 --skipnautilus --addfiles "${alistSelected[@]}"
#		fi
	fi
	
	IFS="$bkpIFS"
elif $bAddFilesMode; then
	while [[ -n "${1-}" ]]; do
		strFile="$1"
		
		# if it is relative path
		if [[ "${strFile:0:1}" != "/" ]]; then
			strFile="`pwd`/$strFile"
		fi
		
		echoc --info "working with: $strFile"
		
		if [[ "${strFile:0:${#pathUbuntuOne}}" == "${pathUbuntuOne}" ]]; then
			echoc -p "can only work with files outside of ubuntu one folder!!!"
			continue
		fi		
		
		if [[ "${strFile:0:${#HOME}}" != "${HOME}" ]]; then
			echoc -p "can only work with files at $HOME"
			continue;
		fi
		
		# copy the file
		strFileTarget="${pathUbuntuOne}/${strFile:${#HOME}}"
		mkdir -vp "`dirname "$strFileTarget"`"
		cp -vp "$strFile" "$strFileTarget"
		
		# history of added files
		if ! grep "$strFile" "$addFileHist"; then
			echo "$strFile" >>"$addFileHist"
			sort -u "$addFileHist" -o "$addFileHist"
		fi
		
		shift
	done
	
elif $bLookForChanges;then
	bDoItConfirmed=false
	bDoIt=false
	cd "$pathUbuntuOne"
	echoc --info "Udpates Ubuntu One files if they exist there already."
	nWaitDelay=$((60*30))
	SECFUNCvarSet --default --show saidChangedAt=0
	delayMinBetweenSays=10
	while true; do
		if $bDoItConfirmed || $bConfirmAlways; then
			bDoIt=true
		fi
		
		# list what will be done 1st
		cd "$pathUbuntuOne"
		SECFUNCvarSet nFilesCount=0
		SECFUNCvarSet nFilesChangedCount=0
		SECFUNCdelay --init
		
		SECFUNCdelay ListOfFuncCopy --init
		strCmdFuncCopyList=`
		find ./ \( -not -name "." -not -name ".." \) \
			-and \( -not -path "./.git/*" \) \
			-and \( -type f -or -type l \) \
			-and \( -not -type d \) \
			-and \( -not -xtype d \) |sed -r "s'.*'FUNCcopy $bDoIt \"&\";'"`
		#echo $strCmdFuncCopyList;
		eval $strCmdFuncCopyList
#		find ./ \
#			\( -not -name "." -not -name ".." \) \
#			-and \
#			\( -not -path "./.git/*" \) \
#			-and \
#			\( -type f -or -type l \) \
#			-and \
#			\( -not -type d \) \
#			-and \
#			\( -not -xtype d \) \
#			-exec bash -c "FUNCcopy $bDoIt '{}'" \;
		#echo "bAutoGit=$bAutoGit "
		if $bAutoGit;then
			echoc -x "git init" #no problem as I read
			echoc -x "git add --all" #add missing files on git
			echoc -x "git commit -m \"`SECFUNCdtTimePrettyNow`\""
		fi
		
		bGoFastOnce=false #controlled by FUNCinterruptAsk
		echo `SECFUNCdelay --getpretty`
		SECFUNCvarReadDB
		
		echoc --info " Changed=$nFilesChangedCount / total=$nFilesCount "
		
		if $bConfirmAlways;then
			echoc -w -t $nWaitDelay "sleeping..."
			exit 0
		else
			if $bDoItConfirmed; then
				exit
			fi
			
			#SECFUNCvarShow bAutoSync
			if 	! $bAutoSync && 
					((nFilesChangedCount>0)) && 
					(((`date +"%s"`-saidChangedAt)>(60*delayMinBetweenSays)));
			then
				echoc --info --say "Ubuntu One Changed $nFilesChangedCount files."
				SECFUNCvarSet --show saidChangedAt=`date +"%s"`
			fi
			
			if((nFilesChangedCount==0));then
				echoc -w -t $nWaitDelay "nothing to be updated..."
				exit 0
			fi
			
			if $bAutoSync || echoc -t $nWaitDelay -q "confirm updates"; then
				bDoItConfirmed=true
			else
				exit
			fi
		fi
	done
fi

if $bWait; then
	echoc -t 60 -w "LINENO=$LINENO"
fi

