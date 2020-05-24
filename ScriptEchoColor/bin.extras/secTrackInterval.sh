#!/bin/bash
# Copyright (C) 2020-2020 by Henrique Abdalla
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

source <(secinit)

echo "WARN: This is still a scratch code..." >&2

egrep "[#]help" $0

strDT="${1-}" #help []

bSetNow=$(SECFUNCternary --tf test -n "$strDT")

function FUNCupdDT() {
	strDT="`SECFUNCdtFmt --pretty --nonano --nodate "${1-}"`"
}

SECFUNCcfgReadDB

if [[ -z "$strDT" ]] && [[ -n "$CFGnLastAteAt" ]];then 
	FUNCupdDT "${CFGnLastAteAt}";
fi

FUNCupdDT "$strDT"
SECFUNCdelay --initset "$strDT"
#if [[ -n "$strDT" ]];then
	#_dtSECFUNCdelayArray[SECFUNCdelay]="`date --date="$strDT" +%s`" #TODO SECFUNCdelay --initset "$strDT"
##	SECFUNCdelay --getpretty;
#fi

declare -p CFGnLastAteAt strDT bSetNow&&:

while true;do 
	if [[ -z "$strDT" ]];then
		bSetNow=$(SECFUNCternary --tf echoc -t $((60*10)) -q "ate now?")
		if $bSetNow;then
			FUNCupdDT
			SECFUNCdelay --init;
		fi
	fi
	
	if [[ -n "$strDT" ]];then
		echoc --info "ate at: @s@{LYb} $strDT @S"
		if $bSetNow;then
#			SECFUNCcfgWriteVar CFGnLastAteAt="`date +%s`"
			SECFUNCcfgWriteVar CFGnLastAteAt="$strDT"
		fi
	fi
	
	strDelay="`SECFUNCdelay --getsec`"
	declare -p strDelay
	strNotify="Ate at `SECFUNCdtFmt --alt --nonano --nodate "${strDT}"`,"
	strNotify+="interval of `SECFUNCdtFmt --delay --alt --nonano --nodate "${strDelay}"`"
	if secAutoScreenLock.sh --gnome --islocked;then #TODO implement --autodetect instead of --gnome
		secNotifyOnLockToo.py "$strNotify"
	else
		echo "$strNotify"
	fi
	
	strDT="";
done
