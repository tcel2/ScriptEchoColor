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

function FUNCtrap() { #TODO this trap isnt working... even outside the function... why!??!
	trap 'echo "(ctrl+c pressed, exiting...)";exit 2' INT
	#trap 'echo "ctrl+c pressed...";varset bInterruptAsk=true;' INT
	#TODO `find` exits if ctrl+c is pressed, why? #trap 'echo "ctrl+c pressed...";varset bInterruptAsk=true;' INT
};export -f FUNCtrap
FUNCtrap

#echo "SECstrScriptSelfNameParent=$SECstrScriptSelfNameParent"
#echo "SECstrScriptSelfName=$SECstrScriptSelfName"
eval `secinit`;
#if [[ -L "$SECvarFile" ]];then	echoc --alert "warning $SECvarFile is for child pid";fi;
#ps -p $PPID
#echo "SECstrScriptSelfNameParent=$SECstrScriptSelfNameParent"
#echo "SECstrScriptSelfName=$SECstrScriptSelfName"

############### INTERNAL CFG
sedQuoteLines='s".*"\"&\""'
sedRemoveHomePath="s;^$HOME;.;"
sedQuoteLinesForZenitySelection="s;.*;false \"&\";"
#sedEncloseLineOnPliqs="s;.*;'&';"
sedEncloseLineOnQuotes="s;.*;\"&\";"
#sedTrSeparatorToPliqs="s;[|];' ';g"
sedTrSeparatorToQuotes="s;[|];\" \";g"
sedEscapeQuotes='s;([^\])";\1\\";g' #ABSOLUTELY NO FILES should have quotes on its name... but...
addFileHist="$HOME/.`basename $0`.addFilesHistory.log"
fileGitIgnoreList="$HOME/.`basename $0`.gitIgnore"
sedUrlDecoder='s % \\\\x g' #example: strPath=`echo "$NAUTILUS_SCRIPT_CURRENT_URI" |sed -r 's"^file://(.*)"\1"' |sed "$sedUrlDecoder" |xargs printf`
strUserScriptCfgPath="${SECstrUserHomeConfigPath}/${SECstrScriptSelfName}"

#
#if [[ "$bSkipNautilusCheckNow" != "true" ]]; then
#	bSkipNautilusCheckNow="false"
#fi

export bGoFastOnce=false
varset --default bInterruptAsk=false

############### USER CFG

export pathBackupsToRemote=""
SECFUNCcfgReadDB
echo $SECcfgFileName

############### OPTIONS

bAddFilesMode=false
bRmRBFfilesMode=false
varset --default --show bAutoSync=false
bDaemon=false
export bCmpData=false
bSkipNautilusCheckNow=false
bWait=false
bLookForChanges=false
bLsNot=false
bLsMissHist=false
bRecreateHistory=false
bConfirmAlways=false
fileToIgnoreOnGitAdd=""
varset --default --show bUseAsBackup=true # use RBF as backup, so if real files are deleted they will be still at RBF
varset --default --show --allowuser bBackgroundWork=false
varset --default --show bAutoGit=false
varset --default --show bUseUnison=false
varset --default --show --allowuser nBackgroundSleep=1
while ! ${1+false} && [[ "${1:0:2}" == "--" ]]; do
	if [[ "$1" == "--help" ]]; then #help show this help
		echo "Updates files at your Remote Backups folder if they already exist there, relatively to your home folder."
		#grep "#@help" "$0" |grep -v grep |sed -r 's".*\"[$]1\" == \"(--[[:alnum:]]*)\".*#@help:(.*)$"\t\1\t\2"'
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--daemon" ]]; then #help runs automatically forever
		bDaemon=true
		#bLookForChanges=true
	elif [[ "$1" == "--lookforchanges" ]]; then #help look for changes and update, is automatically set with --daemon option
		bLookForChanges=true
	elif [[ "$1" == "--purgemissingfiles" ]]; then #help will remove files at RBF that are missing on the real folders, only works with --lookforchanges 
		varset --show bUseAsBackup=false #varset because it is used on function called by find, so it will be easly exported this way also
	elif [[ "$1" == "--wait" ]]; then #help will wait a key press before exiting
		bWait=true
	elif [[ "$1" == "--skipnautilus" ]]; then #help 
		bSkipNautilusCheckNow=true
	elif [[ "$1" == "--addfiles" ]]; then #help <files...> add files to the remote backup folder! this is also default option if the param is a file, no need to put this option.
		bAddFilesMode=true
	elif [[ "$1" == "--rmRBFmissingFiles" ]]; then #help opens an interface to select what missing files on real home folder are to be removed from the remote backup folder. implies --lsmisshist 
		bRmRBFfilesMode=true
		bLsMissHist=true
	elif [[ "$1" == "--cmpdata" ]]; then #help if size and time are equal, compare data for differences
		bCmpData=true
	elif [[ "$1" == "--confirmalways" ]]; then #help will always accept to update the changes on the first check loop, is automatically set with --daemon option
		bConfirmAlways=true
	elif [[ "$1" == "--background" ]]; then #help between each copy will be added a delay
		varset --show bBackgroundWork=true
	elif [[ "$1" == "--backgroundsleep" ]]; then #help <nBackgroundSleep> the time, in seconds, to sleep when in background mode; this implies --background 
		shift
		varset --show nBackgroundSleep="${1-}"
		
		varset --show bBackgroundWork=true
	elif [[ "$1" == "--autogit" ]]; then #help all files at Remote Backup Folder will be versioned (with history)
		varset --show bAutoGit=true
	elif [[ "$1" == "--gitignore" ]];then #help <file> set the file to be ignored on automatic git add all
		shift
		fileToIgnoreOnGitAdd="$1"
	elif [[ "$1" == "--unison" ]];then #help synchronize with unison #TODO INCOMPLETE, IN DEVELOPMENT
		varset --show bUseUnison=true
	elif [[ "$1" == "--autosync" ]]; then #help will automatically copy the changes without asking
		varset --show bAutoSync=true
	elif [[ "$1" == "--lsr" ]]; then #help will list what files, of current folder recursively, are at Remote Backup Folder!
		ls -lR "$pathBackupsToRemote/`pwd |sed "s'$HOME/''"`"
		exit 0
	elif [[ "$1" == "--lsnot" ]]; then #help will list files of current folder are NOT at Remote Backup Folder (use with --addfiles to show a dialog at X to select files to add!)
		bLsNot=true
	elif [[ "$1" == "--lsmisshist" ]]; then #help will list missing files on Remote Backup Folder that are still on "history log" file (use with --addfiles to show a dialog at X to select files to re-add!)
		bLsMissHist=true
	elif [[ "$1" == "--recreatehist" ]]; then #help will recreate the history file based on what is at Remote Backup Folder..
		bRecreateHistory=true
	elif [[ "$1" == "--setbkpfolder" ]]; then #help this option should be run alone. This is a required setup of the folder that will be the target of remote backups, ex.: $HOME/Dropbox/Home
		shift
		pathBackupsToRemote="$1"
		SECFUNCcfgWriteVar pathBackupsToRemote
	elif [[ "$1" == "--secvarset" ]];then #help <var> <value> direct access to SEC vars; if <var> is "help", list SEC vars allowed to be set by user.
		shift
		strSecVarId="${1-}"
		shift
		strSecVarValue="${1-}"
			
		SECFUNCuniqueLock --setdbtodaemon #if daemon is running change its vars, if not, set to be used on current daemon
		if [[ "$strSecVarId" == "help" ]];then
			echoc --info "SEC vars allowed to be set by user:"
			echo "${SECvarsUserAllowed[@]}"
			exit
		else
#			if $SECbDaemonWasAlreadyRunning;then
				varset --checkuser --show -- "$strSecVarId" "$strSecVarValue"
#			else
#				echoc -p "daemon not running!"
#				exit 1
#			fi
		fi
	else	
		echoc -p "invalid option $1"
		exit 1
	fi
	
	shift
done

if ! SECFUNCisNumber -dn $nBackgroundSleep;then
	echoc -p "invalid nBackgroundSleep='$nBackgroundSleep'"
	exit 1
fi

if [[ -z "$pathBackupsToRemote" ]];then
	echoc -p "required setup with option: --setbkpfolder"
	exit 1
elif [[ ! -d "$pathBackupsToRemote" ]];then
	if [[ ! -a "$pathBackupsToRemote" ]];then
		echoc -p "missing folder pathBackupsToRemote='$pathBackupsToRemote'"
		if echoc -q "create folder '$pathBackupsToRemote'?";then
			if ! mkdir -v "$pathBackupsToRemote";then
				exit 1
			fi
		else
			exit
		fi
	else
		echoc -p "invalid folder pathBackupsToRemote='$pathBackupsToRemote'"
		ls -l "$pathBackupsToRemote"
		echoc -w
		exit 1
	fi
fi

echoc --info "pathBackupsToRemote='$pathBackupsToRemote'"

if [[ -n "$fileToIgnoreOnGitAdd" ]];then
	if [[ ! -f "$fileToIgnoreOnGitAdd" ]];then
		echoc -p "must be a file"
		exit 1
	fi
	
	if [[ "${fileToIgnoreOnGitAdd:0:2}" == "./" ]];then
		fileToIgnoreOnGitAdd="`pwd`/${fileToIgnoreOnGitAdd:2}"
	elif [[ "${fileToIgnoreOnGitAdd:0:1}" != "/" ]];then
		fileToIgnoreOnGitAdd="`pwd`/$fileToIgnoreOnGitAdd"
	fi
	
	echoc --info "git ignore: $fileToIgnoreOnGitAdd"
	
	if [[ "${fileToIgnoreOnGitAdd:0:${#pathBackupsToRemote}}" != "${pathBackupsToRemote}" ]];then
		echoc -p "file must be under '$pathBackupsToRemote'"
		exit 1
	fi
	
	fileToIgnoreOnGitAdd="${fileToIgnoreOnGitAdd:${#pathBackupsToRemote}+1}"
	echoc --info "git ignore: $fileToIgnoreOnGitAdd"
	
	if ! grep -q "$fileToIgnoreOnGitAdd" "$fileGitIgnoreList";then
		fileIgnoreBkpTmp="${fileToIgnoreOnGitAdd}.gitIgnore.tmp"
		pwdBkp="`pwd`"
		cd "${pathBackupsToRemote}"
		pwd
		echoc -x "mv -v \"$fileToIgnoreOnGitAdd\" \"$fileIgnoreBkpTmp\""
		echoc -x "git rm \"$fileToIgnoreOnGitAdd\""
		echoc -x "mv -v \"$fileIgnoreBkpTmp\" \"$fileToIgnoreOnGitAdd\""
		cd "$pwdBkp"
		echo "$fileToIgnoreOnGitAdd" >>"$fileGitIgnoreList"
	fi
	
	echoc -x "cat \"$fileGitIgnoreList\""
	exit 0
fi

############### OPTIONS NAUTILUS WAY

if ! $bSkipNautilusCheckNow && set |grep -q "NAUTILUS_SCRIPT"; then #set causes broken pipe but works?
	#ex.: NAUTILUS_SCRIPT_SELECTED_FILE_PATHS=$'/file/one\n/file/two\n'
	sedEscapeSpaces='s"[ ]"\ "g'
	#eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed "$sedEscapeSpaces" |sed "$sedQuoteLines"`)
	eval astrFiles=(`echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" |sed -r "$sedEscapeQuotes" |sed -r "$sedQuoteLines"`)
	
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
	set |grep "NAUTILUS_SCRIPT"&&:
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
	SECFUNCdbgFuncInA
	#FUNCtrap
	#eval `secinit`
	#SECFUNCvarReadDB
	
	SECFUNCdelay $FUNCNAME --init
	
	local bDoIt=$1
	local strFile="$2"
	local bChanged=false
	
	realFile="$HOME/$strFile"
	while [[ -L "$realFile" ]];do
		realFile=`readlink -f "$realFile"`
	done
	
	#echo "bCmpData=$bCmpData"
	if [[ -f "$realFile" ]];then
		if((`stat -c%s "$realFile"`!=`stat -c%s "$pathBackupsToRemote/$strFile"`));then
			# check by size
			#echo "size changed `stat -c%s "$HOME/$strFile"`!=`stat -c%s "$pathBackupsToRemote/$strFile"`"
			bChanged=true;
		elif((`stat -c%Y "$realFile"`!=`stat -c%Y "$pathBackupsToRemote/$strFile"`));then
			# check by last modification
			#echo "modification time changed `stat -c%Y "$HOME/$strFile"`!=`stat -c%Y "$pathBackupsToRemote/$strFile"`"
			bChanged=true;
	#	elif((`stat -c%Z "$realFile"`!=`stat -c%Z "$pathBackupsToRemote/$strFile"`));then
	#		# check by last change (same as modification)
	#		bChanged=true;
		elif $bCmpData && ! cmp -s "$HOME/$strFile" "$pathBackupsToRemote/$strFile"; then
	#		echo "data changed"
			bChanged=true;
		fi
	else
		if ! $bUseAsBackup;then
			echoc --info "Removing backup of missing file: '$realFile'"
			bChanged=true;
		else
			echoc --info "Keeping backup of missing file: '$realFile'"
		fi
	fi
	
	# do not allow symlinks on Remote Backup Folder, must be real dada files
	#ls -l "$pathBackupsToRemote/$strFile"
	if [[ -L "$pathBackupsToRemote/$strFile" ]]; then
		bChanged=true;
	fi
	
	if $bChanged; then
		SECFUNCvarSet --showdbg nFilesChangedCount=$((++nFilesChangedCount))
		
		# this will remove from Remote Backup Folder, real files that are also missing at $HOME, so will sync properly (so wont work as backup)
		cmdRm="trash -vf \"$pathBackupsToRemote/$strFile\""
		
		cmdCopy="cp -vfLp \"$HOME/$strFile\" \"$pathBackupsToRemote/$strFile\""
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
#	if SECFUNCdelay ListOfFuncCopy --checkorinit 5;then
#		SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
#	fi
	
	FUNCinterruptAsk #can set bGoFastOnce to true
	if ! $bGoFastOnce;then
		if $bBackgroundWork;then
			#read -s -n 1 -t 1 -p "" 
			#sleep $nBackgroundSleep&&:
			echo #just to not overwrite the previous line that had no \n
			if echoc -q -t $nBackgroundSleep "go fast (no background work) once?";then
				bGoFastOnce=true
			fi
		fi
	fi
	
	# Progress report
	#echo -en "\r$nFilesCount,delay=`SECFUNCdelay $FUNCNAME`,`basename "$strFile"`\r"
	SECFUNCdrawLine --stay --left "$nFilesCount/$nFilesTot,delay=`SECFUNCdelay $FUNCNAME`/`SECFUNCdelay ListOfFuncCopy`,`basename "$strFile"`" " "
	
	SECFUNCdbgFuncOutA
};export -f FUNCcopy


function FUNCzenitySelectFiles() {
	local lstrTitle="$1"
	shift
	
	local listSelected=`zenity --list --checklist --column="" --column="$lstrTitle" "$@"`
	
	if [[ -n "$listSelected" ]];then
		echoc --info "Selected files list:" >>/dev/stderr
		echo "$listSelected" >>/dev/stderr
		local alistSelected=(`echo "$listSelected" |sed -r "$sedEscapeQuotes" |sed -r "$sedEncloseLineOnQuotes" |sed -r "$sedTrSeparatorToQuotes"`)
		echo "${alistSelected[@]}" >>/dev/stderr
		echo "${alistSelected[@]}"
	fi
};export -f FUNCzenitySelectFiles
function FUNCzenitySelectAndAddFiles() {
	local lstrFilesToAdd=`FUNCzenitySelectFiles "file to add" "$@"`
	echoc --info "Adding requested files."
	#echo "lstrFilesToAdd='$lstrFilesToAdd'" >>/dev/stderr
	eval $0 --skipnautilus --addfiles $lstrFilesToAdd
};export -f FUNCzenitySelectAndAddFiles

function FUNClsNot() { #synchronize like
	function FUNCfileCheck() {
		#eval `secinit --base`
		SECFUNCdbgFuncInA; 
		#echo "look for: $1"
		local relativePath="$1"
		local fileAtCurPath="$2"
		local fileCheck="$pathBackupsToRemote/$relativePath/$fileAtCurPath"; 
		if [[ ! -f "$fileCheck" ]];then 
			echo "$fileAtCurPath";
		fi; 
		SECFUNCdbgFuncOutA;
	};export -f FUNCfileCheck;
	relativeToHome=`pwd -L |sed -r "$sedRemoveHomePath"`
	#echo "relativeToHome=$relativeToHome"
	#pwd -L
	
	#listOfFiles=`find ./ -maxdepth 1 -type f -not -iname "*~" -exec bash -c "FUNCfileCheck \"$relativeToHome\" \"{}\"" \; |sort`
	listOfFiles=`find ./ -maxdepth 1 -type f -not -iname "*~" |while read lstrFileFound;do FUNCfileCheck "$relativeToHome" "$lstrFileFound";done |LC_COLLATE=C sort -f`
	if [[ -n "$listOfFiles" ]];then
		echoc --info "File list that are not at Remote Backup Folder:"
		echo "$listOfFiles"
		
		if echoc -t 3 -q "select what files you want to add?";then
			bAddFilesMode=true
		fi
		
		if $bAddFilesMode;then
			eval alistOfFiles=(`echo "$listOfFiles" |sed -r "$sedEscapeQuotes" |sed -r  "$sedQuoteLinesForZenitySelection"`)
			FUNCzenitySelectAndAddFiles "${alistOfFiles[@]}"
		fi
	else
		echoc --info "All files are at Remote Backup Folder! "
	fi
};export -f FUNClsNot

################### MAIN CODES ######################################

if $bDaemon;then
	SECFUNCuniqueLock --daemonwait
	#secDaemonsControl.sh --register
	
#	strBkgWrkopt=""
#	if $bCmpData;then
#		strBkgWrkopt="--background"
#	fi
	
	while true; do
#		nice -n 19 $0 --lookforchanges --confirmalways $strBkgWrkopt
		nice -n 19 $0 --lookforchanges --confirmalways 
		echoc -w -t 5 "daemons sleep too..."
		
		#if SECFUNCdelay daemonHold --checkorinit 5;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		#fi
		
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

strSkipGitFilesPrefix="$HOME/.git/"
if $bUseUnison;then 
	# create all directories
	find "${pathBackupsToRemote}/" -type d \
		|sed -r "s'^${pathBackupsToRemote}/'${strUserScriptCfgPath}/Home'" \
		|while read strPath;do 
			if ! mkdir -vp "$strPath";then exit 1;fi;
		done
	# create all symlinks
	find "${pathBackupsToRemote}/" -type f \
		|sed -r "s'^${pathBackupsToRemote}/''" \
		|while read strFile;do
			if ! ln -vsf "${HOME}/${strFile}" "${strUserScriptCfgPath}/Home/${strFile}";then break;fi;
		done
elif $bLsNot;then
	FUNClsNot
elif $bRecreateHistory;then
	mv -vf "$addFileHist" "${addFileHist}.old"
#		|grep -v "^$pathBackupsToRemote/.git/" \
	find "$pathBackupsToRemote" -type f \
		|sed -r "s'$pathBackupsToRemote'$HOME'" \
		|grep -v "^$strSkipGitFilesPrefix" \
		|LC_COLLATE=C sort -f >"$addFileHist"
	#cat "$addFileHist"
	if echoc -t 3 -q "see differences on meld?";then
		#echoc -x "diff \"$addFileHist\" \"${addFileHist}.old\""
		meld "${addFileHist}.old" "$addFileHist"
	fi
elif $bLsMissHist; then
	bkpIFS="$IFS"; #internal field separator: default is: " \t\n", hexa: 0x20,0x9,0xA, octa: 040,011,012
	IFS=$'\n'; #TODO confirm if: this way, spaces on filenames will be ignored when creating the array
	
	echoc --info "Add files history: '$addFileHist'"
	aAllFiles=(`cat "$addFileHist"`);
	aMissingFilesAtRBFonly=();
	aFileOnRBFbutNotOnReal=();
	count=0
	echo
	echoc --info "Missing Files At\n\t[Real means file is missing at '$HOME']\n\t[RBF means file missing too at '$pathBackupsToRemote']:"
	echo
	for fileReal in ${aAllFiles[@]};do
		if [[ "${fileReal:0:${#strSkipGitFilesPrefix}}" == "$strSkipGitFilesPrefix" ]];then
			continue
		fi
		prefix=""
		bMissingReal=false
		bMissingRBF=false
		if [[ ! -e "$fileReal" ]];then
			prefix="${prefix}M.Real:"
			bMissingReal=true
		fi
		fileAtRBF="`echo "$fileReal" |sed -r "s'^$HOME'$pathBackupsToRemote'"`"
		if [[ ! -e "$fileAtRBF" ]];then
			prefix="${prefix}M.RBF:"
			bMissingRBF=true
		fi
		if $bMissingReal || $bMissingRBF;then
			echo "$prefix $fileReal";
			if ! $bMissingReal && $bMissingRBF;then
				aMissingFilesAtRBFonly+=("false") #zenity checkbox initial state
				aMissingFilesAtRBFonly+=(`echo "$fileReal"`)
			fi
			if $bMissingReal && ! $bMissingRBF;then
				aFileOnRBFbutNotOnReal+=("false") #zenity checkbox initial state
				aFileOnRBFbutNotOnReal+=(`echo "$fileAtRBF"`)
			fi
		fi;
	done;
	
	if $bRmRBFfilesMode && ((${#aFileOnRBFbutNotOnReal[@]}>0));then
		strRBFfilesToTrash=`FUNCzenitySelectFiles "file to remove" "${aFileOnRBFbutNotOnReal[@]}"`
		echoc --info "Trashing RBF requested files."
		if eval trash -v $strRBFfilesToTrash;then
			if echoc -q "recreate history file?";then
				$0 --recreatehist
			fi
		fi
	elif $bAddFilesMode && ((${#aMissingFilesAtRBFonly[@]}>0));then
		FUNCzenitySelectAndAddFiles "${aMissingFilesAtRBFonly[@]}"
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
		
		if [[ "${strFile:0:${#pathBackupsToRemote}}" == "${pathBackupsToRemote}" ]]; then
			echoc -p "can only work with files outside of Remote Backup Folder!!!"
			continue
		fi		
		
		if [[ "${strFile:0:${#HOME}}" != "${HOME}" ]]; then
			echoc -p "can only work with files at $HOME"
			continue;
		fi
		
		# copy the file
		strRelativeFile="${strFile:${#HOME}}"
		strAbsFileTarget="${pathBackupsToRemote}/$strRelativeFile"
		mkdir -vp "`dirname "$strAbsFileTarget"`"
		cp -vp "$strFile" "$strAbsFileTarget"
		
#		if $bUseUnison;then
#			# create a symlink #TODO to be used with unison #TODO code its removal
#			strSymlinkToUnison="$strUserScriptCfgPath/Home/$strRelativeFile"
#			mkdir -vp "`dirname "$strSymlinkToUnison"`"
#			ln -vsf "$strFile" "$strSymlinkToUnison"
#		fi
		
		# history of added files
		if ! grep -q "$strFile" "$addFileHist"; then
			echo "$strFile" >>"$addFileHist"
			LC_COLLATE=C sort -f -u "$addFileHist" -o "$addFileHist"
		fi
		
		shift
	done
	
elif $bLookForChanges;then
	bDoItConfirmed=false
	bDoIt=false
	cd "$pathBackupsToRemote"
	echoc --info "Udpates Remote Backup Folder files if they exist there already."
	nWaitDelay=$((60*30))
	SECFUNCvarSet --default --show saidChangedAt=0
	delayMinBetweenSays=10
	while true; do
		if $bDoItConfirmed || $bConfirmAlways; then
			bDoIt=true
		fi
		
		# list what will be done 1st
		cd "$pathBackupsToRemote"
		SECFUNCvarSet nFilesCount=0
		SECFUNCvarSet nFilesChangedCount=0
		SECFUNCdelay --init
		
		SECFUNCdelay ListOfFuncCopy --init
#		strCmdFuncCopyList=`
#		find ./ \( -not -name "." -not -name ".." \) \
#			-and \( -not -path "./.git/*" \) \
#			-and \( -type f -or -type l \) \
#			-and \( -not -type d \) \
#			-and \( -not -xtype d \) |sed -r "s'.*'FUNCcopy $bDoIt \"&\";'"`
#		#echo $strCmdFuncCopyList;
#		eval $strCmdFuncCopyList
#		find ./ \( -not -name "." -not -name ".." \) \
#			-and \( -not -path "./.git/*" \) \
#			-and \( -type f -or -type l \) \
#			-and \( -not -type d \) \
#			-and \( -not -xtype d \) \
#			|while read strFileBTR;do
#				FUNCcopy $bDoIt "$strFileBTR";
#			done
		IFS=$'\n' read -d '' -r -a astrFullFilesList < <( \
			find ./ \( -not -name "." -not -name ".." \) \
				-and \( -not -path "./.git/*" \) \
				-and \( -type f -or -type l \) \
				-and \( -not -type d \) \
				-and \( -not -xtype d \) \
		)&&: #TODO it works but returns 1, why?
		nFilesTot="${#astrFullFilesList[@]}"
		#echo "#astrFullFilesList[@]=${#astrFullFilesList[@]}" >>/dev/stderr
		for strFileBTR in "${astrFullFilesList[@]}";do
			FUNCcopy $bDoIt "$strFileBTR";
		done
		
		#echo "bAutoGit=$bAutoGit "
		if $bAutoGit;then
			echoc -x "git init" #no problem as I read
			git config core.excludesfile "$fileGitIgnoreList"
#			if [[ ! -a "$pathBackupsToRemote/.gitignore" ]];then
#				echo -n >"$pathBackupsToRemote/.gitignore"
#			fi
			echoc -x "git add -v --all" #add missing files on git
			echoc -x "git commit -m \"`SECFUNCdtFmt --pretty`\""
			
			nSizeBTR="`du -sb "$pathBackupsToRemote" |tr '[:blank:]' '\n' |head -n 1`"
			nSizeOnlyGit="`du -sb "$pathBackupsToRemote/.git" |tr '[:blank:]' '\n' |head -n 1`"
			nSizeOnlyBTR=$((nSizeBTR-nSizeOnlyGit))
			echo "nSizeOnlyBTR='$nSizeOnlyBTR', nSizeOnlyGit='$nSizeOnlyGit'"
			if(( nSizeOnlyGit > (nSizeOnlyBTR*2) ));then
				echoc --alert ".git ($nSizeOnlyGit) is getting much bigger than BTR ($nSizeOnlyBTR)"
			fi
		fi
		
		bGoFastOnce=false #controlled by FUNCinterruptAsk
		echo `SECFUNCdelay --getpretty`
		SECFUNCvarReadDB
		
		echoc --info " Changed=$nFilesChangedCount / total=$nFilesCount "
		
		if $bConfirmAlways;then
			echoc -w -t $nWaitDelay "ended at `SECFUNCdtFmt --pretty`, sleeping..."
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
				echoc --info --say "Remote Backup Folder Changed $nFilesChangedCount files."
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

