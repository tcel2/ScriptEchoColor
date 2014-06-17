#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

############ CFG and INIT

eval `secLibsInit`

canonicalSelfFileName="`readlink -f "$0"`"
selfName="`basename "$canonicalSelfFileName"`"
cfgPath="$HOME/.ScriptEchoColor/$selfName"
cfgManagedFiles="$cfgPath/managedFiles.cfg"
fastMedia="$cfgPath/.fastMedia"
cfgExt="AtFastMedia"

mkdir -p "$cfgPath"

SECFUNCuniqueLock --setdbtodaemon #--daemonwait will be set after, here is just to attach the same db of the daemon

########### INTERNAL VARIABLES

dtCfgManagedFiles=0
varset --default bForceDisableFastMedia=false

########### FUNCTIONS

function FUNCcheckFreeSpace() {
	local lfileFastMediaReal=`readlink "$fastMedia"`
	df -h "$lfileFastMediaReal" >>/dev/stderr
	
	local lsedDfAvailableSpace='s"^[^[:blank:]]*[[:blank:]]*[[:digit:]]*[[:blank:]]*[[:digit:]]*[[:blank:]]*([[:digit:]]*)[[:blank:]]*.*"\1"'
	local lnAvailableSpace=`df -B 1 "$lfileFastMediaReal" |tail -n 1 |sed -r "$lsedDfAvailableSpace"`
	echo "$lnAvailableSpace"
}

function FUNCcheckCfgChanged() {
	echoc --info "$FUNCNAME"
	local ldtCfgManagedFiles=`stat -c "%Y" "$cfgManagedFiles"`
	if((dtCfgManagedFiles!=ldtCfgManagedFiles));then
		dtCfgManagedFiles=$ldtCfgManagedFiles
		return 0
	fi
	return 1
}

function FUNCaddFile() {
	# HERE IS $1, to check the real parameter
	if [[ -L "$1" ]];then
		if [[ -f "${1}.${cfgExt}" ]];then
			echoc -x "grep \"`basename "$1"`\" \"$cfgManagedFiles\""
			echoc -x "ls -l \"${1}.${cfgExt}\""
			echoc --info "file '$1' seems to be already managed..."
			exit
		else
			echoc -p "file '$1' is a symlink, must be a real file"
			exit 1
		fi
	fi
	
	fileToAdd=`readlink -f "$1"` # canonical full path and filename
	
	echoc --info "working with '$fileToAdd'"
	
	if [[ ! -f "$fileToAdd" ]];then
		echoc -p "invalid file '$fileToAdd'"
		exit 1
	fi
	
	# this only happens if the fast media is offline/unmounted and files have been restored
	if grep -q "^${fileToAdd}$" $cfgManagedFiles;then
		echoc --info "file '$fileToAdd' already managed."
		exit
	fi
	
	local lnSize=`du -b "$fileToAdd" |grep -o "^[[:digit:]]*"`
	if((lnSize<`FUNCcheckFreeSpace`));then
		echo "$fileToAdd" >>"$cfgManagedFiles"
		if grep "$fileToAdd" "$cfgManagedFiles";then
			echoc --info "file added"
		else
			echoc -p "unable to add file (why?).."
			exit 1
		fi
	else
		echoc -p "file is too big '$lnSize', wont fit in the fast media.."
		exit 1
	fi
}

function FUNCprepareFileAtFastMedia() {
	echoc --info "$FUNCNAME '$1'"
	
	local lfileId="$1"
	if [[ -z "$lfileId" ]];then #ignore empty lines
		return 0
	fi
	
	local lpathDest=`dirname "$fastMedia/$lfileId"`
	
	if [[ ! -d "$lpathDest" ]];then
		mkdir -vp "$lpathDest"
	fi
	
	if [[ ! -f "${lfileId}.$cfgExt" ]];then
		if [[ -f "$lfileId" ]];then
			if ! echoc -x "mv -v \"$lfileId\" \"${lfileId}.$cfgExt\"";then
				echoc -p "renaming failed"
				return 1
			fi
		else
			echoc -p "missing real file '$lfileId'"
			return 1
		fi
	fi
	
	# check if was previously configured
	if [[ -f "${lfileId}.$cfgExt" ]];then
		# fix missing or different fast media file
		local lbFixMissing=false
		if [[ ! -f "$fastMedia/$lfileId" ]];then
			lbFixMissing=true
		else
			local lnSize=`stat -c "%s" "${lfileId}.$cfgExt"`
			local lnSizeAtFastMedia=`stat -c "%s" "$fastMedia/$lfileId"`
			if((lnSize!=lnSizeAtFastMedia));then
				echoc --alert "fixing because size differs $lnSize != $lnSizeAtFastMedia"
				rm -v "$fastMedia/$lfileId"
				lbFixMissing=true
			fi
		fi
		if $lbFixMissing;then
			secdelay delayToCopy --init
			if ! nice -n 19 echoc -x "cp -v \"${lfileId}.$cfgExt\" \"$fastMedia/$lfileId\"";then
				echoc -p "copying failed"
				return 1
			fi
			echo "Delay to copy: `secdelay delayToCopy --getpretty`"
		fi
		
		# fix missing symlink to fast media file
		if [[ ! -L "$lfileId" ]];then
			if [[ ! -a "$lfileId" ]];then
				#echoc --alert "fixing missing symlink"
				if ! echoc -x "ln -sv \"$fastMedia/$lfileId\" \"$lfileId\"";then
					echoc -p "symlinking failed"
					return 1
				else
					# make the symlink have the same timestamp of the real file
					touch -h -r "$fastMedia/$lfileId" "$lfileId"
				fi
			else
				ls -l "$lfileId"
				echoc -p "'$lfileId' should not exist"
				return 1
			fi
		fi
	fi
}

function FUNCrestoreFile() {
	echoc --info "$FUNCNAME '$1'"
	
	local lfileId="$1"
	
	# restore original files
	if [[ -f "${lfileId}.$cfgExt" ]];then
		if [[ -L "$lfileId" ]];then
			rm -v "$lfileId"
			if ! mv -v "${lfileId}.$cfgExt" "$lfileId";then
				echoc --alert "unable to restore file!"
			fi
		else
			echoc --alert "file '$lfileId' should be a symlink"
		fi
	fi
}

function FUNCsetFastMedia() {
	if [[ ! -d "$1" ]];then
		echoc -p "$LINENO: invalid directory"
		exit 1
	fi
	
	fastMediaRealPath="$1/.$selfName"
	echoc --info "setting fast media to '$fastMediaRealPath'"
	
	if [[ -a "$fastMedia" ]];then
		if [[ -d "$fastMedia" ]];then
			if ! echoc -q "Fast Media already set to '`readlink "$fastMedia"`', reconfigure it?";then
				exit 1
			fi
		else
			echoc -p "'$fastMediaRealPath' should be a directory"
			exit 1
		fi
	fi
	
	bOk=true
	if $bOk && ! mkdir -v "$fastMediaRealPath";then
		bOk=false
	fi
	if $bOk && ! ln -svf "$fastMediaRealPath" "$fastMedia";then
		bOk=false
	fi
#	if $bOk && ! SECFUNCdtTimePrettyNow >"$fastMediaRealPath/initialized.cfg";then
#		bOk=false
#	fi
	if ! $bOk;then
		echoc -p "unable to work with '$fastMediaRealPath'"
		exit 1
	fi
}

########### MAIN

bDaemon=false
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--daemon" ]];then #help checks if configured files exist in the setup fast media (memory/SSD/etc) and copies them there; otherwise if that midia is not available, removes all symlinks and renames the real files to their original names.
		bDaemon=true
	elif [[ "$1" == "--add" ]];then #help adds a file to be speed up
		shift
		FUNCaddFile "$1"
	elif [[ "$1" == "--setfastmedia" ]];then #help set fast media to copy files to
		shift
		FUNCsetFastMedia "$1"
#	elif [[ "$1" == "--disablefastmedia" ]];then #help disable fast media to restore original files (being real files and no more symlinks). This will keep the files copied at fast media.
#		mv -v "$fastMedia" "${fastMedia}.DISABLED"
#		varset bForceValidationOnce=true
#		if echoc -q "restore now"; then
#			mv -v "${fastMedia}.DISABLED" "$fastMedia"
#			varset bForceValidationOnce=true
#		fi
	elif [[ "$1" == "--disablefastmedia" ]];then #help restore original files (being real files and no more symlinks). This will keep the files copied at fast media tho.
		varset bForceDisableFastMedia=true
		varset bForceValidationOnce=true
		if echoc -q "re-enable fast media?"; then
			varset bForceDisableFastMedia=false
			varset bForceValidationOnce=true
		fi
	elif [[ "$1" == "--reenablefastmedia" ]];then #help restore fast media functionality
		varset bForceDisableFastMedia=false
		varset bForceValidationOnce=true
	elif [[ "$1" == "--help" ]];then #help
		echo "Helps on copying big files to a faster media like SSD or even RamDrive (/dev/shm), to significantly improve related applications read/load speed."
		SECFUNCshowHelp
		exit
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if $bDaemon;then
#	if $SECbDaemonWasAlreadyRunning;then
#		echoc -p "daemon already running"
#		echoc -w
#		exit 1
#	fi
	SECFUNCuniqueLock --daemonwait
	#secDaemonsControl.sh --register
	
#	while [[ ! -d "$fastMedia" ]];do
#		echoc -t 1 -w "configure fast media path"
#	done
	echoc --info "Fast Media set at: `readlink "$fastMedia"`"
	
	varset bForceValidationOnce=true #will be initially forced once
	while true; do
		SECFUNCvarReadDB
		
		if $bForceDisableFastMedia;then
			echoc --alert "Fast media disabled!"
		fi
		
		if SECFUNCdelay daemonHold --checkorinit 5;then
			SECFUNCdaemonCheckHold #secDaemonsControl.sh --checkhold
		fi
		
		if [[ ! -f "$cfgManagedFiles" ]];then
			echoc -t 1 -w "configure some files to be managed"
			continue
		fi
		
		if ! $bForceValidationOnce;then
			if ! FUNCcheckCfgChanged;then
				if echoc -t 60 -q "force validation?";then
					varset bForceValidationOnce=true
				fi
				continue
			fi
		fi
		
		bFastMediaAvailable=false
		if [[ -d "$fastMedia" ]];then
			bFastMediaAvailable=true
		else
			echoc -p "Fast Media '`readlink "$fastMedia"`' NOT available."
		fi
		
#		# update file list
#		fileList=()
#		while read strLine; do
#			fileList+=("$strLine")
#		done <"$cfgManagedFiles"
#		# check all files
#		for fileId in ${fileList[@]}; do
#			if $bFastMediaAvailable;then
#				if ! FUNCprepareFileAtFastMedia;then
#					break
#				fi
#			else
#				FUNCrestoreFile
#			fi
#		done
		# check all files
		while read strLine; do
			#echoc --info "working with '$strLine'"
			if ! $bForceDisableFastMedia && $bFastMediaAvailable;then
				if ! FUNCprepareFileAtFastMedia "$strLine";then
					break
				fi
			else
				FUNCrestoreFile "$strLine"
			fi
		done <"$cfgManagedFiles"
		
		#echoc -w -t 300
		varset bForceValidationOnce=false
	done
fi

