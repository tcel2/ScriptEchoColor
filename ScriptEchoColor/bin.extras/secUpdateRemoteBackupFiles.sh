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
source <(secinit);
#if [[ -L "$SECvarFile" ]];then	echoc --alert "warning $SECvarFile is for child pid";fi;
#ps -p $PPID
#echo "SECstrScriptSelfNameParent=$SECstrScriptSelfNameParent"
#echo "SECstrScriptSelfName=$SECstrScriptSelfName"

############### INTERNAL CFG
sedQuoteLines='s".*"\"&\""'
sedRemoveHomePath="s;^$HOME;.;"
#sedQuoteLinesForZenitySelection="s;.*;false \"&\";"
#sedEncloseLineOnPliqs="s;.*;'&';"
sedEncloseLineOnQuotes="s;.*;\"&\";"
#sedTrSeparatorToPliqs="s;[|];' ';g"
sedTrSeparatorToQuotes="s;[|];\" \";g"
sedEscapeQuotes='s;([^\])";\1\\";g' #ABSOLUTELY NO FILES should have quotes on its name... but...
addFileHist="$HOME/.`basename $0`.addFilesHistory.log"
fileGitIgnoreList="$HOME/.`basename $0`.gitIgnore"
sedUrlDecoder='s % \\\\x g' #example: strPath=`echo "$NAUTILUS_SCRIPT_CURRENT_URI" |sed -r 's"^file://(.*)"\1"' |sed "$sedUrlDecoder" |xargs printf`
#strUserScriptCfgPath="${SECstrUserHomeConfigPath}/${SECstrScriptSelfName}"

#
#if [[ "$bSkipNautilusCheckNow" != "true" ]]; then
#	bSkipNautilusCheckNow="false"
#fi

export bGoFastOnce=false
varset --default bInterruptAsk=false

############### USER CFG

export pathBackupsToRemote=""
export strCompressPasswd=""
SECFUNCcfgReadDB
#echo $SECcfgFileName

############### OPTIONS

function FUNCfileDoNotExist() { # [--nooutput] <fileAtCurPath> WILL WORK ONLY IF IT IS AT CURRENT PATH!
  SECFUNCdbgFuncInA;
  
  local lbOutput=true
  if [[ "$1" == "--nooutput" ]];then
    lbOutput=false
    shift
  fi
  local fileAtCurPath="`basename "$1"`";shift
  
	local relativeToHomePath=`pwd -L |sed -r "$sedRemoveHomePath"`
  
  local fileCheck="$pathBackupsToRemote/$relativeToHomePath/$fileAtCurPath";
  
  #declare -p fileAtCurPath relativeToHomePath fileCheck >&2
  
  if [[ ! -f "$fileCheck" ]];then
    if $lbOutput;then echo "$fileAtCurPath";fi
    return 0
  fi;
  
  SECFUNCdbgFuncOutA;return 1;
};export -f FUNCfileDoNotExist;

bAddFilesMode=false
bRmRBFfilesMode=false
varset --default bAutoSync=false
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
bForceMigrationToUnisonMode=false
bCompress=false
varset --default bUseAsBackup=true # use RBF as backup, so if real files are deleted they will be still at RBF
varset --default --allowuser bBackgroundWork=false
varset --default bAutoGit=false
varset --default bUseUnison=true
varset --default --allowuser nBackgroundSleep=1
while ! ${1+false} && [[ "${1:0:1}" == "-" ]]; do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]]; then #help show this help
		echo "Updates files at your Remote Backups folder if they already exist there, relatively to your home folder."
		#grep "#@help" "$0" |grep -v grep |sed -r 's".*\"[$]1\" == \"(--[[:alnum:]]*)\".*#@help:(.*)$"\t\1\t\2"'
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--daemon" ]]; then #help runs automatically forever
		bDaemon=true
declare -p bDaemon LINENO
		#bLookForChanges=true
	elif [[ "$1" == "--compress" || "$1" == "-c" ]]; then #help will backup a compressed file instead
		bCompress=true
	elif [[ "$1" == "--strCompressPasswd" ]]; then #help will ask for a global compress password to be used on all compressions (stored and used after `|sha1sum`, is just.. better then nothing..), and exit
		read -s -p "Type password to be stored:" strCompressPasswd
		if [[ -z "$strCompressPasswd" ]];then echoc -p "password is empty";exit 1;fi
		strCompressPasswd="`echo "$strCompressPasswd" |sha1sum |cut -d' ' -f1`"
		SECFUNCcfgWriteVar strCompressPasswd
		exit 0
	elif [[ "$1" == "--lookforchanges" ]]; then #help look for changes and update, is automatically set with --daemon option
		bLookForChanges=true
	elif [[ "$1" == "--purgemissingfiles" ]]; then #help will remove files at RBF that are missing on the real folders, only works with --lookforchanges 
		varset --show bUseAsBackup=false #varset because it is used on function called by find, so it will be easly exported this way also
	elif [[ "$1" == "--wait" ]]; then #help will wait a key press before exiting
		bWait=true
	elif [[ "$1" == "--skipnautilus" ]]; then #help 
		bSkipNautilusCheckNow=true
	elif [[ "$1" == "--addfiles" || "$1" == "-a" ]]; then #help <files...> add files to the remote backup folder! this is also default option if the param is a file, no need to put this option.
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
		shift;fileToIgnoreOnGitAdd="${1-}"
	elif [[ "$1" == "--autosync" ]]; then #help will automatically copy the changes without asking
		varset --show bAutoSync=true
	elif [[ "$1" == "--lsr" ]]; then #help will list what files, of current folder recursively, are at Remote Backup Folder!
		ls -lR "$pathBackupsToRemote/`pwd |sed "s'$HOME/''"`"
		exit 0
	elif [[ "$1" == "--lsnot" ]]; then #help will list files of current folder are NOT at Remote Backup Folder (use with --addfiles to show a dialog at X to select files to add!)
		bLsNot=true
	elif [[ "$1" == "-k" || "$1" == "--justcheck" ]]; then #help <strJustCheck> check if the specified file is configured already
		shift;strJustCheck="${1-}"
    if FUNCfileDoNotExist --nooutput "$strJustCheck";then exit 1;fi
    exit 0 # the file is configured
	elif [[ "$1" == "--lsmisshist" ]]; then #help will list missing files on Remote Backup Folder that are still on "history log" file (use with --addfiles to show a dialog at X to select files to re-add!)
		bLsMissHist=true
	elif [[ "$1" == "--recreatehist" ]]; then #help will recreate the history file based on what is at Remote Backup Folder..
		bRecreateHistory=true
	elif [[ "$1" == "--setbkpfolder" ]]; then #help this option should be run alone. This is a required setup of the folder that will be the target of remote backups, ex.: $HOME/Dropbox/Home
		shift
		pathBackupsToRemote="${1-}"
		SECFUNCcfgWriteVar pathBackupsToRemote
	elif [[ "$1" == "--forcemigrationtounisonmode" ]]; then #help revalidates the list of RBF files to sync with the symlinks at control dir
		bForceMigrationToUnisonMode=true
	elif [[ "$1" == "--secvarset" ]];then #help <var> <value> direct access to SEC vars; if <var> is "help", list SEC vars allowed to be set by user.
		shift;strSecVarId="${1-}"
		shift;strSecVarValue="${1-}"
			
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
declare -p bDaemon LINENO
SECFUNCvarReadDB #;SECFUNCexecA -ce cat $SECvarFile
declare -p bDaemon LINENO

varset --default bNextRunShowFullLog=false

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
	#source <(secinit)
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
			SECFUNCdrawLine --left " working with: $strFile "
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

sedCleanYadOutput="s'^TRUE[|](.*)[|]$'\1'" # sed cleans yad output to leave only one filename per line
function FUNCzenitySelectFiles() {
	local lstrTitle="$1"
	shift
	
  local lastrCmd=(yad --list --checklist --column="" --column="$lstrTitle" "$@")
  declare -p lastrCmd >&2
  echo "YAD-CMD: ${lastrCmd[@]}" >&2
	local listSelected="`"${lastrCmd[@]}"`"&&:
	
	if [[ -n "$listSelected" ]];then
		echoc --info "Selected files list:" >&2
		echo "$listSelected" >&2
#		local alistSelected=(`echo "$listSelected" |sed -r "$sedEscapeQuotes" |sed -r "$sedEncloseLineOnQuotes" |sed -r "$sedTrSeparatorToQuotes"`)
    echo "$listSelected" |sed -r "$sedCleanYadOutput" 
		#~ local lalistSelected;IFS=$'\n' read -d '' -r -a lalistSelected < <(echo "$listSelected" |sed -r "s'^TRUE[|](.*)[|]$'\1'")&&:
    #~ declare -p lalistSelected >&2
		#~ echo "${lalistSelected[@]}" >&2
		#~ echo "${lalistSelected[@]}"
	fi
};export -f FUNCzenitySelectFiles
function FUNCzenitySelectAndAddFiles() {
#	local lstrFilesToAdd="`FUNCzenitySelectFiles "file to add" "$@"`"
	local lastrFilesToAdd=();IFS=$'\n' read -d '' -r -a lastrFilesToAdd < <(FUNCzenitySelectFiles "file to add" "$@")&&:
	if [[ -n "${lastrFilesToAdd[@]-}" ]];then
		echoc --info "Adding requested files: ${lastrFilesToAdd[@]}"
		$0 --skipnautilus --addfiles "${lastrFilesToAdd[@]}"
	else
		echoc --info "no files selected"
	fi
};export -f FUNCzenitySelectAndAddFiles

function FUNCunison(){
	echoc --info "running unison"
	
#	( # if the unison command is going to use a zerobyte file (or a corrupt one, try to identify it with strace or `-debug verbose`?), remove all these invalid files before running it.
#		cd "$HOME/.unison";
#		while true; do 
#			strSmallestFile="`ls -S |tac |head -n 1`";
#			if((`stat -c %s "$strSmallestFile"`==0));then 
#				echoc --say "unison problem at `SECFUNCseparateInWords "$SECstrScriptSelfName"`"
#				if echoc -q "trash this strSmallestFile='$strSmallestFile' zero size file?";then 
#					SECFUNCexecA --echo -c trash "$strSmallestFile";
#				fi;
#			else 
#				break;
#			fi;
#		done
#	)
	
	# -ignorearchives will help on avoiding corrupted files
	strLastUnisonOutput="`SECFUNCexecA --echo -c unison \
		"$SECstrUserScriptCfgPath/Home" 									\
		"${pathBackupsToRemote}/" 												\
		-links false 																			\
		-fastcheck true 																	\
		-times -retry 2 																	\
		-follow "Regex .*" 																\
		-ignorearchives 																	\
		-force "$SECstrUserScriptCfgPath/Home" 						\
		-nodeletion "$SECstrUserScriptCfgPath/Home" 			\
		-nodeletion "${pathBackupsToRemote}/" 						\
		-batch 																						\
		-ui text 2>&1`"&&: #TODO return 1 but works, why? because there were skipped files?
	
	if $bNextRunShowFullLog;then
		echo "$strLastUnisonOutput"
	else
		#####
		# this removes all lines with 'missing' or 'absent' errors 
		# (like when there are missing mounts) (obs.: \r may happen before \n, so sed 'g' option is necessary)
		# also removes all that were skipped
		#####
		local lstrErrMatch="( error |\[ERROR\] Skipping )";
#		echo "$strLastUnisonOutput" \
#			|sed -r \
#				-e "/${lstrErrMatch}/ {N;s'[\r\n]' 'g}" \
#				-e "/.* <=[?]=> .*/ {N;s'[\r\n]' 'g;N;s'[\r\n]' 'g}" \
#			|egrep -v "${lstrErrMatch}.* is marked 'follow' but its target is missing| <=[?]=> file .* absent "
		echo "$strLastUnisonOutput" \
			|sed -r \
				-e "/${lstrErrMatch}/ {N;s'[\r\n]' 'g}" \
				-e "/.* <=[?]=> .*/ {N;s'[\r\n]' 'g;N;s'[\r\n]' 'g}" \
			|egrep -v "${lstrErrMatch}.* is marked 'follow' but its target is missing" \
			|egrep -v " <=[?]=> file .* absent " \
			|egrep -v " skipped: " \
			|egrep -v "\[CONFLICT\] Skipping "
	fi
		
	return 0
};export -f FUNCunison

function FUNClsNot() { #synchronize like
	#relativeToHome=`pwd -L |sed -r "$sedRemoveHomePath"`
	#echo "relativeToHome=$relativeToHome"
	#pwd -L
	
	#listOfFiles=`find ./ -maxdepth 1 -type f -not -iname "*~" -exec bash -c "FUNCfileDoNotExist \"$relativeToHome\" \"{}\"" \; |sort`
	#listOfFiles=`find ./ -maxdepth 1 -type f -not -iname "*~" |while read lstrFileFound;do FUNCfileDoNotExist "$relativeToHome" "$lstrFileFound";done |LC_COLLATE=C sort -f`
#  IFS=$'\n' read -d '' -r -a astrFileList < <(find ./ -maxdepth 1 -type f -not -iname "*~" |while read lstrFileFound;do FUNCfileDoNotExist "$relativeToHome" "$lstrFileFound";done |sort -f)&&:
  IFS=$'\n' read -d '' -r -a astrFileList < <(find ./ -maxdepth 1 \( -type f -or \( -type l -and -xtype f \) \) -not -iname "*~" |while read lstrFileFound;do FUNCfileDoNotExist "$lstrFileFound"&&:;done |sort -f)&&:
	if SECFUNCarrayCheck -n astrFileList;then
		echoc --info "File list that are not at Remote Backup Folder:"
    SECFUNCexecA -ce ls -ltr "${astrFileList[@]}"
    #for strFile in "${astrFileList[@]}";do echo "$strFile";done
		
		if ! $bAddFilesMode && echoc -t 60 -q "select what files you want to add?";then
			bAddFilesMode=true
		fi
		
		if $bAddFilesMode;then
      IFS=$'\n' read -d '' -r -a astrFileList < <(for strFile in "${astrFileList[@]}";do echo "$strFile" |sed -r "$sedEscapeQuotes";done)&&: #escape quotes
      IFS=$'\n' read -d '' -r -a astrFileList < <(for strFile in "${astrFileList[@]}";do echo false; echo "$strFile";done)&&: #prepare to be used by yad ex.: false "filename" (that is per entry, false is the checkbox state)
			#eval alistOfFiles=(`echo "$listOfFiles" |sed -r "$sedEscapeQuotes" |sed -r  "$sedQuoteLinesForZenitySelection"`)
			#FUNCzenitySelectAndAddFiles "${alistOfFiles[@]}"
      FUNCzenitySelectAndAddFiles "${astrFileList[@]}"
		fi
	else
		echoc --info "All files are at Remote Backup Folder! "
	fi
};export -f FUNClsNot

_SECFUNCcheckCmdDep 7z
strSufixCompressedFile="$SECstrScriptSelfName.7z"
function FUNCcompressFile() {
	local lstrFileCompressed="${1}.$strSufixCompressedFile"
	(
		local lstrPassOpt=""
		if [[ -n "$strCompressPasswd" ]];then
			lstrPassOpt="-p${strCompressPasswd}"
		fi
		echoc --info "compressing '$lstrFileCompressed'"
		if [[ -f "$lstrFileCompressed" ]];then
			SECFUNCexecA -c --echo trash -vf "$lstrFileCompressed"
		fi
		7z a $lstrPassOpt "$lstrFileCompressed" "$1" #to not echo the password
		SECFUNCexecA -c --echo touch -r "$1" "$lstrFileCompressed"
	) 1>&2
	echo "$lstrFileCompressed"
}
function FUNCcheckUpdateAllCompressedFiles() {
	cd "$pathBackupsToRemote"
	
	# relative paths
	IFS=$'\n' read -d '' -r -a lastrCompressedFilesList < <( \
		find ./ \( -not -name "." -not -name ".." \) \
			-and \( -iname "*.$strSufixCompressedFile" \) \
			-and \( -not -path "./.git/*" \) \
			-and \( -type f -or -type l \) \
			-and \( -not -type d \) \
			-and \( -not -xtype d \) \
	)&&: #TODO it works but returns 1, why?
	
	if [[ -n "${lastrCompressedFilesList[@]-}" ]];then
		if((`SECFUNCarraySize lastrCompressedFilesList`>0));then
			for lstrCompressedFile in "${lastrCompressedFilesList[@]}";do
				local lstrCompressedFile="$HOME/$lstrCompressedFile"
		
				echo "Found: lstrCompressedFile='$lstrCompressedFile'"
		
				local lstrUncompressedFile="${lstrCompressedFile%.$strSufixCompressedFile}"
		
				if [[ -f "$lstrUncompressedFile" ]];then
					echo "Found: lstrUncompressedFile='$lstrUncompressedFile'"
			
					if test "$lstrUncompressedFile" -nt "$lstrCompressedFile";then
						FUNCcompressFile "$lstrUncompressedFile"
					fi
				else
					echo "MISSING: lstrUncompressedFile='$lstrUncompressedFile'"
				fi
			done
		fi
	fi
}

################### MAIN CODES ######################################

declare -p bDaemon LINENO
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
#		echoc -w -t 5 "daemons sleep too..."
		
		#if SECFUNCdelay daemonHold --checkorinit 5;then
		if ! $bUseUnison;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		fi
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

if [[ ! -d "$SECstrUserScriptCfgPath/Home" ]] || $bForceMigrationToUnisonMode;then

	nSleepStep=600
	if $bForceMigrationToUnisonMode;then
		nSleepStep=0.1
	fi

	if ! $bForceMigrationToUnisonMode;then
		echoc --alert "new sync method uses unison, migration (from old method) is required"
	fi
	
	echoc -w -t $nSleepStep "recreating directory structure of old method into new one"
	# create all directories
	find "${pathBackupsToRemote}/" -type d \
		|sed -r "s'^${pathBackupsToRemote}/'${SECstrUserScriptCfgPath}/Home/'" \
		|while read strPath;do 
			if ! mkdir -vp "$strPath";then exit 1;fi;
		done
	
	echoc -w -t $nSleepStep "creating symlinks to all real files for new method"
#	find "${pathBackupsToRemote}/" -type f \
#		|sed -r "s'^${pathBackupsToRemote}/''" \
#		|while read strFile;do
	astrMissingTargetList=()
	IFS=$'\n' read -d '' -r -a astrFilesAtBTR < <(\
		find "${pathBackupsToRemote}/" -type f \
			|sed -r "s'^${pathBackupsToRemote}/''" )&&: #TODO returns 1 but works, why?
	for strFileAtBTR in "${astrFilesAtBTR[@]}";do
		if [[ ! -f "${HOME}/${strFileAtBTR}" ]];then
			astrMissingTargetList+=("${HOME}/${strFileAtBTR}")
		else
			if [[ ! -L "${SECstrUserScriptCfgPath}/Home/${strFileAtBTR}" ]];then
				if ! ln -vsfT "${HOME}/${strFileAtBTR}" "${SECstrUserScriptCfgPath}/Home/${strFileAtBTR}"&&:;then
	#					echo "ERROR: '$nRet'"
					echo "OldMethodFile: '${pathBackupsToRemote}/$strFileAtBTR'"
					echo "strFileAtBTR='$strFileAtBTR'"
					echo "TARGET: '${HOME}/${strFileAtBTR}'"
					echo "HARDLINKFILE: '${SECstrUserScriptCfgPath}/Home/${strFileAtBTR}'"
					break;
				fi
			fi
		fi
	done
	
	if ! $bForceMigrationToUnisonMode;then
		echoc --info "List of missing target/real files:"
		for strMissingTarget in "${astrMissingTargetList[@]}";do
			echo " '$strMissingTarget'"
		done
	
		FUNCunison
	fi
fi

strSkipGitFilesPrefix="$HOME/.git/"
if $bLsNot;then
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
	IFS=$'\n'; #this way, spaces on filenames will be ignored when creating the array
	
	echoc --info "Add files history: '$addFileHist'"
	aAllFiles=(`cat "$addFileHist"`);
	aMissingFilesAtRBFonly=();
	aFileOnRBFbutNotOnReal=();
	count=0
	echo
	echoc --info "Missing Files At\n\t[Real means file is missing at '$HOME']\n\t[RBF means file missing too at '$pathBackupsToRemote']:"
	echo
	for fileReal in "${aAllFiles[@]}";do
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
				aMissingFilesAtRBFonly+=("false") #yad checkbox initial state
				aMissingFilesAtRBFonly+=(`echo "$fileReal"`)
			fi
			if $bMissingReal && ! $bMissingRBF;then
				aFileOnRBFbutNotOnReal+=("false") #yad checkbox initial state
				aFileOnRBFbutNotOnReal+=(`echo "$fileAtRBF"`)
			fi
		fi;
	done;
	
	if $bRmRBFfilesMode && ((${#aFileOnRBFbutNotOnReal[@]}>0));then
#		strRBFfilesToTrash=`FUNCzenitySelectFiles "file to remove" "${aFileOnRBFbutNotOnReal[@]}"`
  	astrRBFfilesToTrash=();IFS=$'\n' read -d '' -r -a astrRBFfilesToTrash < <(FUNCzenitySelectFiles "file to remove" "${aFileOnRBFbutNotOnReal[@]}")&&:
		echoc --info "Trashing RBF requested files."
		if SECFUNCtrash "${astrRBFfilesToTrash[@]}";then
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
		
		SECFUNCdrawLine --left " working with: $strFile "
		
		if [[ "${strFile:0:${#pathBackupsToRemote}}" == "${pathBackupsToRemote}" ]]; then
			echoc -p "can only work with files outside of Remote Backup Folder!!!"
			continue
		fi		
		
		if [[ "${strFile:0:${#HOME}}" != "${HOME}" ]]; then
			echoc -p "can only work with files at $HOME"
			continue;
		fi
		
		if $bCompress;then
			strFile="`FUNCcompressFile "$strFile"`" #updates filename
		fi
		
		# copy the file
		strRelativeFile="${strFile:${#HOME}}"
		strAbsFileTarget="${pathBackupsToRemote}/$strRelativeFile"
		mkdir -vp "`dirname "$strAbsFileTarget"`"
		cp -vp "$strFile" "$strAbsFileTarget"
		$0 --skipnautilus --forcemigrationtounisonmode
		
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
		SECFUNCvarReadDB #;SECFUNCexecA -ce cat $SECvarFile
	
		if $bDoItConfirmed || $bConfirmAlways; then
			bDoIt=true
		fi
		
		FUNCcheckUpdateAllCompressedFiles
		
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
		if $bUseUnison;then
			FUNCunison
		else
			IFS=$'\n' read -d '' -r -a astrFullFilesList < <( \
				find ./ \( -not -name "." -not -name ".." \) \
					-and \( -not -path "./.git/*" \) \
					-and \( -type f -or -type l \) \
					-and \( -not -type d \) \
					-and \( -not -xtype d \) \
			)&&: #TODO it works but returns 1, why?
			nFilesTot="${#astrFullFilesList[@]}"
			#echo "#astrFullFilesList[@]=${#astrFullFilesList[@]}" >&2
			for strFileBTR in "${astrFullFilesList[@]}";do
				FUNCcopy $bDoIt "$strFileBTR";
			done
		fi
		
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
#		SECFUNCvarReadDB #TODO why it is only read here!?!? should be just after the begin of the loop.
		
		echoc --info " Changed=$nFilesChangedCount / total=$nFilesCount "
		
		if $bConfirmAlways;then
			#echoc -w -t $nWaitDelay "ended at `SECFUNCdtFmt --pretty`, sleeping..."
			echoc --info "ended at `SECFUNCdtFmt --pretty`"
			if echoc -q -t $nWaitDelay "run next showing full log?";then
				varset bNextRunShowFullLog=true
			else
				varset bNextRunShowFullLog=false
			fi
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

