#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

strMountAt="$1"

function FUNCumount(){
	SECFUNCexecA -ce sudo -k umount "$strMountAt"
	SECFUNCexecA -ce trash -v "$strMountAt"
}

if [[ -a "$strMountAt" ]];then
	if ! [[ -d "$strMountAt" ]];then
		echoc -p "should be a directory strMountAt='$strMountAt', or should not exist..."
	elif mount |egrep "/${strMountAt} type aufs";then
		if echoc -q "umount and trash it?";then
			FUNCumount
		fi
	elif [[ -d "$strMountAt" ]];then
		SECFUNCexecA -ce ls -lR "$strMountAt/"
		echoc --info "the mount point strMountAt='$strMountAt' access would be overriden, and its files will not be accessible..."
		echoc -p "strMountAt='$strMountAt' should not exist..."
		
		if [[ -z "`ls -A "$strMountAt/"`" ]];then
			echoc --info "it is empty..."
			SECFUNCexecA -ce trash -v "$strMountAt"
		fi
	fi
	
	echoc --info "run it again..."
	exit 1
fi

# the layers override priority is from left (top override) to right
strLayerBranch="`ls -d "${strMountAt}.layer"* |sort -r |tr "\n" ":" |sed -r 's"(.*):"\1"'`"&&:
declare -p strLayerBranch

if [[ -z "$strLayerBranch" ]];then
	echoc --info "create layers like:"
	echo "${strMountAt}.layer0100.SomeDescription"
	echo "${strMountAt}.layer0200.SomeDescription2"
	echo "..."
	echoc --info "the high value layers will override lower value ones"
fi

########
### the leftmost layer will be the one receiving all writes made at the mounted folder, 
### even if it is a write on a file present in a lower layer (such file will remain the same,
### at such lower layer, as long it is modified at the mounted folder)!
########
strWriteLayer="${strMountAt}.writeLayer"
SECFUNCexecA -ce mkdir -vp "$strWriteLayer"

SECFUNCexecA -ce mkdir -vp "$strMountAt"
SECFUNCexecA -ce sudo -k mount -t aufs -o br="$strWriteLayer:$strLayerBranch" none "$strMountAt"

SECFUNCexecA -ce ls -d "${strMountAt}"*

echoc -w "to umount and remove"
FUNCumount


