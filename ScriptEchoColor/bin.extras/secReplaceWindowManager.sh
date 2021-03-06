#!/bin/bash
# Copyright (C) 2004-2016 by Henrique Abdalla
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

function FUNCcheckWM() { #help <which|pgrep> [lstrCheck]
	source <(secinit) #to restore arrays
	local astrAllParms=( "$@" )
	local lstrCmd="$1";shift&&:
	local lstrCheck="${1-}";shift&&:
	
	local lbFail=false
	local lstrFoundWM=""
	
	if [[ -n "$lstrCheck" ]];then
		if $lstrCmd "$lstrCheck" 2>&1 >>/dev/null;then
			lstrFoundWM="$lstrCheck"
		#~ else
			#~ lbFail=true
		else
			echoc -p "not available (${astrAllParms[@]})" #TODO add option for other WM replace cmds
			return 1
		fi
	else
		local lstrWM;
		for lstrWM in "${astrSupportedWM[@]}";do
			echo "try: $lstrCmd $lstrWM" >&2
			if $lstrCmd $lstrWM 2>&1 >>/dev/null;then
				lstrFoundWM="$lstrWM"
        declare -p lstrFoundWM >&2
				break;
			fi
		done
		
		if [[ -z "$lstrFoundWM" ]];then
			echoc -p "no WM available (${astrAllParms[@]})"
			return 1
		fi
	
		# default preference order
		#~ if   which compiz 2>&1 >>/dev/null;then
			#~ lstrFoundWM="compiz"
		#~ elif which metacity 2>&1 >>/dev/null;then
			#~ lstrFoundWM="metacity"
		#~ elif which xfwm4 2>&1 >>/dev/null;then
			#~ lstrFoundWM="xfwm4"
		#~ elif which kwin 2>&1 >>/dev/null;then
			#~ lstrFoundWM="kwin"
		#~ elif which mutter 2>&1 >>/dev/null;then
			#~ lstrFoundWM="mutter"
	#~ #	elif which jwm 2>&1 >>/dev/null;then
	#~ #		lstrFoundWM="jwm"
		#~ else
	fi
	
#	if [[ -z "$lstrFoundWM" ]];then
		#~ lbFail=true
	#~ fi
	
	#~ if $lbFail;then
#		if [[ -z "$lstrCheck" ]];then echoc -p "no WM available";fi
#		echoc -w "exiting"
#		return 1
#	fi
	
	echo "$lstrFoundWM"
	return 0
}


: ${CFGstrUseSafeFallBackAlways:="metacity"}
export CFGstrUseSafeFallBackAlways #help will force the use the specified one if installed in case there is no WM running, neither the last one used (as the current may have issues when starting it directly like wrong mouse positioning on compiz some times)

#TODO check if jwm has --replace like feature
astrSupportedWM=( # default preference order
	"metacity"
	"compiz"
	"xfwm4"
	"kwin"
	"mutter"
);export astrSupportedWM;SECFUNCarraysExport
strPreferedWM=""
#####
### this would disable current from being auto-preferred: strPreferedWM="${astrSupportedWM[0]}"
#####

bForceOnce=false
SECFUNCcfgReadDB
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Recovers window manager after it's crash, and helps easily replacing it."
		SECFUNCshowHelp --colorize "The default auto-recovery window manager option (if not set) is the last detected. If none is detected, prefers (if installed) in this order:"
		echo "WMs that support param '--replace':`SECFUNCarrayShow astrSupportedWM`"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-w" ]];then #help <strPreferedWM> force the default auto recovery option
		shift
		strPreferedWM="$1"
		
		echo "validating strPreferedWM='$strPreferedWM'"
		FUNCcheckWM which "${strPreferedWM}"
		if ! $strPreferedWM --help |grep "\--replace" -w;then
			echoc -p "strPreferedWM='$strPreferedWM' has no --replace option"
			exit 1
		fi
		
		bForceOnce=true
	#~ elif [[ "$1" == "--compiz" || "$1" == "-c" ]];then #help force compiz the default auto recovery option
		#~ strPreferedWM="compiz"
	#~ elif [[ "$1" == "--metacity" || "$1" == "-m" ]];then #help force metacity the default auto recovery option
		#~ strPreferedWM="metacity"
	#~ elif [[ "$1" == "--xfwm4" || "$1" == "-x" ]];then #help force xfwm4 the default auto recovery option
		#~ strPreferedWM="xfwm4"
	#~ elif [[ "$1" == "--kwin" || "$1" == "-k" ]];then #help force kwin the default auto recovery option
		#~ strPreferedWM="kwin"
	#~ elif [[ "$1" == "--mutter" || "$1" == "-u" ]];then #help force mutter the default auto recovery option
		#~ strPreferedWM="mutter"
#	elif [[ "$1" == "--jwm" || "$1" == "-j" ]];then #help force jwm the default auto recovery option
#		strPreferedWM="jwm"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift&&:
done
SECFUNCcfgAutoWriteAllVars

if [[ -n "$CFGstrUseSafeFallBackAlways" ]] && ! which "$CFGstrUseSafeFallBackAlways";then
  echoc -p "CFGstrUseSafeFallBackAlways='$CFGstrUseSafeFallBackAlways' not installed, cleaning it"
  CFGstrUseSafeFallBackAlways=""
fi

## if not set, will be the current
#strPreferedWM="`FUNCcheckWM which "$strPreferedWM"`"

SECFUNCuniqueLock --daemonwait

strCurrent=""
while true;do
	# check current
	strCurrent="`FUNCcheckWM pgrep`"&&: #can fail
	
	#~ if pgrep compiz 2>&1 >>/dev/null;then
		#~ strCurrent="compiz"
	#~ elif pgrep metacity 2>&1 >>/dev/null;then
		#~ strCurrent="metacity"
	#~ elif pgrep xfwm4 2>&1 >>/dev/null;then
		#~ strCurrent="xfwm4"
	#~ elif pgrep kwin 2>&1 >>/dev/null;then
		#~ strCurrent="kwin"
	#~ elif pgrep mutter 2>&1 >>/dev/null;then
		#~ strCurrent="mutter"
#~ #	elif pgrep jwm 2>&1 >>/dev/null;then
#~ #		strCurrent="jwm"
	#~ else
		#~ strCurrent=""
	#~ fi
	
  declare -p CFGstrUseSafeFallBackAlways >&2
  
	# set prefered window manager
	if [[ -z "$strPreferedWM" ]];then
		if [[ -n "$strCurrent" ]];then
			strPreferedWM="$strCurrent"
      echoc --info "defaulting preferred to current: strPreferedWM='$strPreferedWM'"
		else
      if [[ -n "$CFGstrUseSafeFallBackAlways" ]];then
        strPreferedWM="$CFGstrUseSafeFallBackAlways"
      else
        strPreferedWM="`FUNCcheckWM which`"
      fi
		fi
	fi
	
	echoc --info "strPreferedWM='$strPreferedWM'"
	
	if $bForceOnce;then
    #if ! pgrep $strPreferedWM;then
      SECFUNCexecA -ce secXtermDetached.sh $strPreferedWM --replace
    #fi
  else
    if [[ -z "$strCurrent" ]];then #mainly for crash recovery !!!CRITICAL RESCUE!!!
      if [[ -n "$CFGstrUseSafeFallBackAlways" ]];then
        strPreferedWM=""
        SECFUNCexecA -ce secXtermDetached.sh $CFGstrUseSafeFallBackAlways --replace
      else
        SECFUNCexecA -ce secXtermDetached.sh $strPreferedWM --replace
      fi
      echoc -w -t 3
      continue;
    fi
  fi
  
	#~ if $bForceOnce;then
		#~ if [[ "$strCurrent" != "$strPreferedWM" ]];then strCurrent="";fi
		#~ bForceOnce=false #just at 1st loop's iteration!
	#~ fi
	#~ if [[ -z "$strCurrent" ]];then #mainly for crash recovery !!!CRITICAL RESCUE!!!
#~ #		SECFUNCexecA -ce $strPreferedWM --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
    #~ declare -p CFGstrUseSafeFallBackAlways >&2
    #~ if ! $bForceOnce && [[ -n "$CFGstrUseSafeFallBackAlways" ]];then
      #~ SECFUNCexecA -ce secXtermDetached.sh $CFGstrUseSafeFallBackAlways --replace
    #~ else
      #~ SECFUNCexecA -ce secXtermDetached.sh $strPreferedWM --replace
    #~ fi
		#~ continue;
	#~ fi
  
	bForceOnce=false
	echoc -t 10 -Q "replace window manager@O
		_compiz/
		_metacity/
		_xfwm4/
		_kwin/
		m_utter/
		holdFor_60s"&&:;
	case "`secascii $?`" in 
		c)
			if [[ "$strCurrent" == "compiz" ]];then
				secFixWindow.sh --fixcompiz #this more safely replaces compiz!
			#~ else
				#~ SECFUNCexecA -ce secXtermDetached.sh compiz --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			fi
			strPreferedWM="compiz"
			bForceOnce=true
			;; 
		m)
			#~ SECFUNCexecA -ce secXtermDetached.sh metacity --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="metacity"
			bForceOnce=true
			;; 
		x)
			#~ SECFUNCexecA -ce secXtermDetached.sh xfwm4 --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="xfwm4"
			bForceOnce=true
			;; 
		k)
			#~ SECFUNCexecA -ce secXtermDetached.sh kwin --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="kwin"
			bForceOnce=true
			;; 
		u)
			#~ SECFUNCexecA -ce secXtermDetached.sh mutter --replace #>&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
			strPreferedWM="mutter"
			bForceOnce=true
			;; 
		6)
			echoc -w -t 60 "holding execution"
			;;
	esac
	
#	if [[ "$strCurrent" != "metacity" ]];then
#		if echoc -q -t 10 "replace with metacity?";then
#			SECFUNCexecA -ce metacity --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
#			strPreferedWM="metacity"
#			continue;
#		fi
#	fi

#	if [[ "$strCurrent" != "compiz" ]];then
#		if echoc -q -t 10 "replace with compiz?";then
#			SECFUNCexecA -ce compiz --replace >&2 & disown # stdout must be redirected or the terminal wont let it be disowned...
#			strPreferedWM="compiz"
#			continue;
#		fi
#	fi
	
	echoc -w -t 3 #TODO just for safety to prevent fastly replacing?
done

