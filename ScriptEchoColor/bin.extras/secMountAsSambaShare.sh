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

echoc --info "Params: <whatToMount> [whereToMount]"
echo "HELP: useful to write case insensitive files!!!"
echo "DEFAULTS: whereToMount will be automatic if empty."

if [[ "$1" == "--help" ]];then
	exit
fi

whatToMount="$1"
whereToMount="$2"

if [[ ! -d "$whatToMount" ]];then
	echoc -p "'$whatToMount' must be a directory"
	exit 1
fi

if [[ -z "$whereToMount" ]];then
	whereToMount="`dirname "$whatToMount"`/.`basename "$whatToMount"`.sambaMount"
fi

if [[ -a "$whereToMount" ]] && [[ ! -d "$whereToMount" ]];then
	echoc -p "'$whereToMount' must be a directory"
	exit 1
fi

if [[ "${whatToMount:0:1}" != "/" ]];then
	whatToMountFullPath="`pwd`/$whatToMount"
fi
if [[ "${whereToMount:0:1}" != "/" ]];then
	whereToMountFullPath="`pwd`/$whereToMount"
fi

#echoc -X "mount.smbfs --help >/dev/null"
echoc -X "mount.cifs --help >/dev/null"

mountName="SambaMounted`basename "$1"`"
description="$mountName samba mounted"
smbMounted=false
if mount |grep "localhost:/$mountName"; then
	smbMounted=true
fi
if ! $smbMounted; then
	echoc -X "net usershare add '$mountName' '$whatToMountFullPath' '$description' everyone:F guest_ok=n"
	echoc -X "net usershare info --long"
	
	echoc -X "mkdir -vp '$whereToMountFullPath'"
	echoc -X "chmod 0777 '$whereToMountFullPath'" #allow others to write
	echoc -X "ls -ld '$whereToMountFullPath'"
	echoc -x "du -b '$whereToMountFullPath'"
	#echoc -X "sudo mount -t smbfs 'localhost:/$mountName' '$whereToMountFullPath' -o username=`SECFUNCgetUserName`,nocase"
	while ! echoc -x "sudo -k mount -t cifs 'localhost:/$mountName' '$whereToMountFullPath' -o username=`SECFUNCgetUserName`,nocase @B#YOUR SAMBA PASSWORD WILL BE ASKED NEXT!";do
		echoc --info "fix your samba user account"
		echoc -X "sudo -k smbpasswd -a `SECFUNCgetUserName`"
	done
fi

if echoc -q "run nautilus at '$whereToMountFullPath'?";then
	nautilus "$whereToMountFullPath"
fi

while ! echoc -q "press 'y' to remove samba share"; do
	echo "wrong key..."
done

fuser -m "$whatToMountFullPath" #process using that folder, but didnt help much..
if ! echoc -x --retry "sudo -k umount -v '$whereToMountFullPath'"; then
	fuser -m "$whatToMountFullPath" #process using that folder, but didnt help much..
	if ! echoc -X --retry "sudo -k umount -l -v '$whereToMountFullPath'"; then #tries lazy mode
		fuser -m "$whatToMountFullPath" #process using that folder, but didnt help much..
		exit 1
	fi
fi

echoc -X "net usershare delete '$mountName'"

