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

#function FUNCchkSetBase() { # <index> <value>
#	local liIndex="$1"
#	local lfValue="$2"
#	if SECFUNCisNumber -n "$lfValue";then 
#		SECFUNCechoErrA "invalid floating number lfValue='$lfValue'"
#		exit 1;
#	fi;
#	CFGafBaseGammaRGB[$liIndex]=($lfValue)
#}

bChange=false
bUp=false
bDown=false
fStep=0.25
bReset=false
bRandom=false
nRgfStep=1 #DEF step between gama changes
nRgfDelay=0.1 #DEF gamma update delay, float seconds ex.: 0.2
nRgfMin=80 #DEF min gamma, integer where 100 = 1.0 gamma, 150 = 1.5 gamma, limit = 0.100 (10/100=0.1)
nRgfMax=170 #DEF max gamma, integer where 100 = 1.0 gamma, 150 = 1.5 gamma
bSetBase=false
#declare -a CFGafBaseGammaRGB
#SECFUNCcfgReadDB CFGafBaseGammaRGB
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Changes gamma from last setup value."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--setbase" ]];then #help the currently setup gamma components will be stored at default cofiguration file.
		bSetBase=true
#	elif [[ "$1" == "--setbase" ]];then #help <R> <G> <B> instead of 1.0 1.0 1.0. The specified base will be used at all calculations. Good to work with an old problematic CRT monitor...
#		shift
#		FUNCchkSetBase 0 "${1-}"
#		shift
#		FUNCchkSetBase 1 "${1-}"
#		shift
#		FUNCchkSetBase 2 "${1-}"
	elif [[ "$1" == "--up" ]];then #help
		bUp=true
		bChange=true
	elif [[ "$1" == "--down" ]];then #help
		bDown=true
		bChange=true
	elif [[ "$1" == "--step" ]];then #help the float step ammount when changing gamma
		shift
		fStep="${1-}"
	elif [[ "$1" == "--reset" ]];then #help gamma 1.0
		bReset=true
	elif [[ "$1" == "--random" ]];then #help [nRgfStep] [nRgfDelay] [nRgfMin] [nRgfMax] random gamma fade, fun effect
		shift&&:
		nRgfStep="${1-}"
		shift&&:
		nRgfDelay="${1-}"
		shift&&:
		nRgfMin="${1-}"
		shift&&:
		nRgfMax="${1-}"
		
		bRandom=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift&&:
done

if ! SECFUNCisNumber -n "${fStep}";then
	echoc -p "invalid fStep='$fStep'"
	exit 1
fi
if ! SECFUNCisNumber -dn "$nRgfStep"; then
	echoc -p "invalid nRgfStep='$nRgfStep'"
	exit 1
fi
if ! SECFUNCisNumber -n "$nRgfDelay"; then
	echoc -p "invalid nRgfDelay='$nRgfDelay'"
	exit 1
fi
if ! SECFUNCisNumber -dn "$nRgfMin"; then
	echoc -p "invalid nRgfMin='$nRgfMin'"
	exit 1
fi
if ! SECFUNCisNumber -dn "$nRgfMax"; then
	echoc -p "invalid nRgfMax='$nRgfMax'"
	exit 1
fi

if $bSetBase;then
	CFGafBaseGammaRGB=(`xgamma 2>&1 |sed -r 's"-> Red  (.*), Green  (.*), Blue  (.*)"\1 \2 \3"'`)
	declare -p CFGafBaseGammaRGB
	SECFUNCcfgWriteVar CFGafBaseGammaRGB
fi
SECFUNCcfgReadDB CFGafBaseGammaRGB

if $bReset;then
	if SECFUNCvarIsArray CFGafBaseGammaRGB;then
		SECFUNCexecA -ce xgamma -rgamma ${CFGafBaseGammaRGB[0]} -ggamma ${CFGafBaseGammaRGB[1]} -bgamma ${CFGafBaseGammaRGB[2]}
	else
		SECFUNCexecA -ce xgamma -gamma 1
	fi
	
	exit 0
elif $bRandom;then
	if $SECbRunLog;then
		echoc --alert "INT trap (to reset gamma to 1.0) wont work with SECbRunLog=true"
	fi
	trap '{ echo "(ctrl+c pressed, exiting...)";xgamma -gamma 1; exit 1; }' INT

	# params
	bReport=true
	
	###################################

	# internal variables
	nR=100
	nG=100
	nB=100
	nRto=$nR
	nGto=$nG
	nBto=$nB
	nMinLimit=10

	FUNCto() {
		n=$1
		nTo=$2
		#if((n==nTo));then
		if(( n>=(nTo-nRgfStep) && n<=(nTo+nRgfStep) ));then
		  ((nDelta=nRgfMax-nRgfMin))
		  nRandom=$RANDOM
		  nRandom=`echo "$nRandom%$nDelta" |bc`
	#@@@r    nAdjust=`echo "$nRandom%$nRgfStep"  |bc` #this grants nTo will always be reachable thru nRgfStep stepping!
	#@@@r    nRandom=$((nRandom-nAdjust))
	#@@@!!!bash-bug:    ((nRandon+=nRgfMin))
	#@@@!!!bash-bug:    ((nRandon=nRandom+nRgfMin))
		  nRandom=$((nRandom+nRgfMin))
		  if((nRandom<nRgfMin||nRandom>nRgfMax));then echo "BUG: out of min/max range $nRandom" >/dev/stderr; fi
	#@@@r    if((nRandom<nRgfMin)); then nRandom=$nRgfMin; fi 
		  nTo=$nRandom
		  if((nTo<nMinLimit));then
		    nTo=$nMinLimit
		  fi
		fi
		echo $nTo
	}

	FUNCwalk() {
		n=$1
		nTo=$2
		if((n<nTo));then
		  n=$((n+nRgfStep))
		elif((n>nTo));then
		  n=$((n-nRgfStep))
		fi
		echo $n
	}

	FUNCtoFloat() {
		n=$1
		if((n<nMinLimit||n>1000));then echo "BUG: out of xgamma range $n" >/dev/stderr; fi
		echo "scale=2;$1/100" |bc
	}

	FUNCupDown() {
		n=$1
		nTo=$2
		if((n<nTo));then
		  echo "^"
		else
		  echo "v"
		fi
	}

	while true; do
		nRto=`FUNCto $nR $nRto`
		nGto=`FUNCto $nG $nGto`
		nBto=`FUNCto $nB $nBto`
		
		nR=`FUNCwalk $nR $nRto`
		nG=`FUNCwalk $nG $nGto`
		nB=`FUNCwalk $nB $nBto`
		
		xgamma -quiet -rgamma `FUNCtoFloat $nR`
		xgamma -quiet -ggamma `FUNCtoFloat $nG`
		xgamma -quiet -bgamma `FUNCtoFloat $nB`
		
		sleep $nRgfDelay
		
		#report
		printf "RGB; current:`FUNCupDown $nR $nRto`%03d,\
	`FUNCupDown $nG $nGto`%03d,\
	`FUNCupDown $nB $nBto`%03d;\
	 to:%03d,%03d,%03d\r" $nR $nG $nB $nRto $nGto $nBto

	done	
	
	exit 0
elif $bChange;then
	fCurrentGamma="`xgamma 2>&1 |awk '{print $3}' |sed -r 's"(.*),"\1"'`";

	strOperation=""
	if $bUp;then
		strOperation="+"
	elif $bDown;then
		strOperation="-"
	fi

	fNewGamma="`SECFUNCbcPrettyCalcA "${fCurrentGamma}+(${strOperation}${fStep})"`"
	xgamma -gamma "$fNewGamma"
fi

