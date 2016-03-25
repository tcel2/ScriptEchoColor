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

function FUNCgetCurrentGammaRGB() {
	# var init here
	local lbForce=false
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #FUNCgetCurrentGammaRGB_help show this help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--force" || "$1" == "-f" ]];then #FUNCgetCurrentGammaRGB_help <lbForce> will use system current gamma componenets
			shift
			lbForce=true
		elif [[ "$1" == "--" ]];then #FUNCgetCurrentGammaRGB_help params after this are ignored as being these options
			shift
			break
#		else
#			SECFUNCechoErrA "invalid option '$1'"
#			SECFUNCshowHelp $FUNCNAME
#			return 1
		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
			SECFUNCechoErrA "invalid option '$1'"
			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	if ! $lbForce;then
		SECFUNCcfgReadDB CFGafModGammaRGB
		if ! ${CFGafModGammaRGB+false};then # is set
			if ! SECFUNCarrayCheck CFGafModGammaRGB;then
				SECFUNCechoErrA "CFGafModGammaRGB='`declare -p CFGafModGammaRGB`' should be an array."
				lbForce=true
			fi
		else # is not set
			lbForce=true
		fi
	fi
	
	if $lbForce;then
		xgamma 2>&1 |sed -r 's"-> Red[ ]*(.*), Green[ ]*(.*), Blue[ ]*(.*)"\1 \2 \3"'
	else
		echo "${CFGafModGammaRGB[@]}"
	fi
	
	return 0
}
function FUNCchkFixGammaComponent() {
	local lfGammaComp="$1"

	if   SECFUNCbcPrettyCalcA --cmpquiet "$lfGammaComp<0.1";then
		SECFUNCechoWarnA "gamma component lfGammaComp='$lfGammaComp' < 0.1, fixing"
		echo "0.1"
	elif SECFUNCbcPrettyCalcA --cmpquiet "$lfGammaComp>10.0";then
		SECFUNCechoWarnA "gamma component lfGammaComp='$lfGammaComp' > 10.0, fixing"
		echo "10.0"
	else
		echo "$lfGammaComp"
	fi

	return 0
}

function FUNCsetGamma() { #<fR> <fG> <fB>
	SECFUNCexecA -ce xgamma \
		-rgamma "`FUNCchkFixGammaComponent "$1"`" \
		-ggamma "`FUNCchkFixGammaComponent "$2"`"	\
		-bgamma "`FUNCchkFixGammaComponent "$3"`"
}

bChange=false
bChangeUp=false
bChangeDown=false
fStep=0.25
bReset=false
bRandom=false
nRgfStep=1 #DEF step between gama changes
nRgfDelay=0.1 #DEF gamma update delay, float seconds ex.: 0.2
nRgfMin=80 #DEF min gamma, integer where 100 = 1.0 gamma, 150 = 1.5 gamma, limit = 0.100 (10/100=0.1)
nRgfMax=170 #DEF max gamma, integer where 100 = 1.0 gamma, 150 = 1.5 gamma
bSetBase=false
bSetBaseAlt=false
bKeep=false
bSetCurrent=false
#declare -a CFGafBaseGammaRGB
#SECFUNCcfgReadDB CFGafBaseGammaRGB
afModGammaRGB=()
bSpeak=false
bGetc=false
astrRunParams=("$@")
bChangeWait=false
CFGnKeepDelay=30
SECFUNCcfgFileName --show
SECFUNCexecA -ce xgamma
afCurrentGamma=(`FUNCgetCurrentGammaRGB --force`);
echoc --info "TypeHelper: xgamma -rgamma ${afCurrentGamma[0]} -ggamma ${afCurrentGamma[1]} -bgamma ${afCurrentGamma[2]};secGammaChange.sh --setc;secGammaChange.sh --setbase"
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Controls gamma."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--getc" ]];then #help will show current gamma components values in a simple way
		bGetc=true
	elif [[ "$1" == "--set" ]];then #help <fR> <fG> <fB> will set and store the specified gamma componenets.
		bSetCurrent=true
		shift
		afModGammaRGB[0]="${1-}"
		shift
		afModGammaRGB[1]="${1-}"
		shift
		afModGammaRGB[2]="${1-}"
	elif [[ "$1" == "--setc" ]];then #help like --set, but will use current system gamma components
		bSetCurrent=true
		afModGammaRGB=(`FUNCgetCurrentGammaRGB --force`)
	elif [[ "$1" == "--setbase" ]];then #help the currently setup gamma components will be stored at default cofiguration file at CFGafBaseGammaRGB.
		bSetBase=true
	elif [[ "$1" == "--setbasealt" ]];then #help like --setbase but will be an alternative value
		bSetBaseAlt=true
# elif [[ "$1" == "--setbase" ]];then #help <R> <G> <B> instead of 1.0 1.0 1.0. The specified base will be used at all calculations. Good to work with an old problematic CRT monitor.
#		shift
#		FUNCchkSetBase 0 "${1-}"
#		shift
#		FUNCchkSetBase 1 "${1-}"
#		shift
#		FUNCchkSetBase 2 "${1-}"
	elif [[ "$1" == "--up" ]];then #help @UniqueLock lighten screen (uses --set)
		bChangeUp=true
		bChange=true
	elif [[ "$1" == "--down" ]];then #help @UniqueLock darken screen (uses --set)
		bChangeDown=true
		bChange=true
	elif [[ "$1" == "--wait" ]];then #help will wait for @UniqueLock and wont skip gamma change requests.
		#help If the requests stack is too big and slow, and --say option was used, it may be annoying.
		bChangeWait=true
	elif [[ "$1" == "--step" ]];then #help <fStep> the float step amount when changing gamma (below 1.0 gamma component, step is halved)
		shift
		fStep="${1-}"
	elif [[ "$1" == "--reset" ]];then #help will reset gamma to 1.0 or to CFGafBaseGammaRGB (if it was set) or CFGafAltBaseGammaRGB (if it was CFGafBaseGammaRGB).
		bReset=true
	elif [[ "$1" == "--say" ]];then #help will speak current gamma components
		bSpeak=true
#	elif [[ "$1" == "--speakc" ]];then #help will speak current gamma components
#		bSpeak=true
#		bSpeakCurrent=true
	elif [[ "$1" == "--keep" ]];then #help ~daemon (works with --set) a loop that keeps the last gamma setup here,
		#help useful in case some application changes it when you do not want.
		#help incompatible with --random.
		bKeep=true
	elif [[ "$1" == "--random" ]];then #help [nRgfStep] [nRgfDelay] [nRgfMin] [nRgfMax]
		#help ~daemon a loop that does random gamma fade, fun effect.
		#help will not modify configuration file.
		#help incompatible with --keep.
		shift&&:
		nRgfStep="${1-$nRgfStep}"
		shift&&:
		nRgfDelay="${1-$nRgfDelay}"
		shift&&:
		nRgfMin="${1-$nRgfMin}"
		shift&&:
		nRgfMax="${1-$nRgfMax}"
		
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
if $bSetCurrent;then
	if ! SECFUNCisNumber -n "${afModGammaRGB[0]}"; then
		echoc -p "invalid afModGammaRGB[0]='${afModGammaRGB[0]}'"
		exit 1
	fi
	if ! SECFUNCisNumber -n "${afModGammaRGB[1]}"; then
		echoc -p "invalid afModGammaRGB[1]='${afModGammaRGB[1]}'"
		exit 1
	fi
	if ! SECFUNCisNumber -n "${afModGammaRGB[2]}"; then
		echoc -p "invalid afModGammaRGB[2]='${afModGammaRGB[2]}'"
		exit 1
	fi
fi

if $bSetBase;then
	CFGafBaseGammaRGB=(`FUNCgetCurrentGammaRGB`)
	declare -p CFGafBaseGammaRGB
	SECFUNCcfgWriteVar CFGafBaseGammaRGB
fi
SECFUNCcfgReadDB CFGafBaseGammaRGB
if $bSetBaseAlt;then
	CFGafAltBaseGammaRGB=(`FUNCgetCurrentGammaRGB`)
	declare -p CFGafAltBaseGammaRGB
	SECFUNCcfgWriteVar CFGafAltBaseGammaRGB
fi
SECFUNCcfgReadDB CFGafAltBaseGammaRGB

if $bReset;then
	
	# toggle alt/default mode
	astrCurrentGammaRGB=(`FUNCgetCurrentGammaRGB --force`)
	declare -p astrCurrentGammaRGB
	bStillRequiresReset=true
	if SECFUNCarrayCheck CFGafAltBaseGammaRGB;then
		if   SECFUNCarrayCmp astrCurrentGammaRGB CFGafBaseGammaRGB;then
			echoc --info "ResetToggleAltMode:AltBase"
			SECFUNCexecA -ce $SECstrScriptSelfName --set "${CFGafAltBaseGammaRGB[@]}"
			bStillRequiresReset=false
		elif SECFUNCarrayCmp astrCurrentGammaRGB CFGafAltBaseGammaRGB;then
			echoc --info "ResetToggleAltMode:DefaultBase"
			SECFUNCexecA -ce $SECstrScriptSelfName --set "${CFGafBaseGammaRGB[@]}"
			bStillRequiresReset=false
		fi
	fi
	
	# simple reset to default
	if $bStillRequiresReset;then
		if SECFUNCarrayCheck CFGafBaseGammaRGB;then
			#SECFUNCexecA -ce xgamma -rgamma ${CFGafBaseGammaRGB[0]} -ggamma ${CFGafBaseGammaRGB[1]} -bgamma ${CFGafBaseGammaRGB[2]}
			SECFUNCexecA -ce $SECstrScriptSelfName --set "${CFGafBaseGammaRGB[@]}"
		else
			SECFUNCexecA -ce xgamma -gamma 1
		fi
	fi
	
	CFGafModGammaRGB=(`FUNCgetCurrentGammaRGB`)
	SECFUNCcfgWriteVar CFGafModGammaRGB
elif $bGetc;then
	FUNCgetCurrentGammaRGB --force
#elif $bSpeakCurrent;then
#	FUNCspeak
elif $bSetCurrent;then
	CFGafModGammaRGB=("${afModGammaRGB[@]}")
	#FUNCsetGamma "${afModGammaRGB[@]}"
	FUNCsetGamma "${CFGafModGammaRGB[@]}"
	
	#CFGafModGammaRGB=(`FUNCgetCurrentGammaRGB --force`)
	declare -p CFGafModGammaRGB
	SECFUNCcfgWriteVar CFGafModGammaRGB
elif $bKeep;then
	SECFUNCuniqueLock --daemonwait
#	if ! SECFUNCarrayCheck CFGafBaseGammaRGB;then
#		SECFUNCechoWarnA "setting required base"
#		SECFUNCexecA -ce $SECstrScriptSelfName --setbase
#	fi

#	CFGafModGammaRGB=(`FUNCgetCurrentGammaRGB`)
#	declare -p CFGafModGammaRGB
#	SECFUNCcfgWriteVar CFGafModGammaRGB
	
	while true;do
		SECFUNCcfgReadDB CFGafModGammaRGB
		#SECFUNCexecA -ce xgamma -rgamma ${CFGafModGammaRGB[0]} -ggamma ${CFGafModGammaRGB[1]} -bgamma ${CFGafModGammaRGB[2]}
		declare -p CFGafModGammaRGB
		SECFUNCexecA -ce FUNCsetGamma "${CFGafModGammaRGB[@]}"
		echoc -w -t $CFGnKeepDelay "keep gamma"
	done
elif $bRandom;then
	if $SECbRunLog;then
		echoc --alert "INT trap (to reset gamma to 1.0) wont work with SECbRunLog=true, restoring default outputs"
		SECFUNCexecA -ce SECFUNCcheckActivateRunLog --restoredefaultoutputs
#		echoc --info "re-running with SECbRunLog=false"
#		SECbRunLog=false SECFUNCexecA -ce $SECstrScriptSelfName "${astrRunParams[@]}"
#		exit 0
	fi
	
	SECFUNCuniqueLock --daemonwait
	
	trap '{ echo "(ctrl+c pressed, resetting gamma and exiting...)";$SECstrScriptSelfName --reset; exit 1; }' INT

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
	strLockChangeGammaId="${SECstrScriptSelfName}_bChange"
	strSECFUNCtrapErrCustomMsg="$strLockChangeGammaId"
	while ! SECFUNCuniqueLock --pid $$ --id "$strLockChangeGammaId";do
		if ! $bChangeWait;then
			echoc --info "skipping gamma change request..."
			exit 0
		fi
		echo "waiting strLockChangeGammaId='$strLockChangeGammaId' be released..."
		sleep 1
	done
	
	strOperation=""
	if $bChangeUp;then
		strOperation="+"
	elif $bChangeDown;then
		strOperation="-"
	fi

#	fCurrentGamma="`xgamma 2>&1 |awk '{print $3}' |sed -r 's"(.*),"\1"'`";
#	fNewGamma="`SECFUNCbcPrettyCalcA "${fCurrentGamma}+(${strOperation}${fStep})"`"
#	xgamma -gamma "$fNewGamma"
	afGammaRGBcurrent=(`FUNCgetCurrentGammaRGB`)
#	function _FUNCchkFixGammaComponent() {
#		local liIndex="$1"
#		local lfGammaComp="`SECFUNCbcPrettyCalcA "${afGammaRGBcurrent[$liIndex]}+(0${strOperation}${fStep})"`"
#		
#		FUNCchkFixGammaComponent "$lfGammaComp"
##		if   SECFUNCbcPrettyCalcA --cmpquiet "$lfGammaComp<0.1";then
##			#echo "asdf" >>/dev/stderr
##			echo "0.1"
##		elif SECFUNCbcPrettyCalcA --cmpquiet "$lfGammaComp>10.0";then
##			echo "10.0"
##		else
##			echo "$lfGammaComp"
##		fi
#	
#		return 0
#	}
	function _FUNCcalcComp() {
		local liIndex="$1"
		if SECFUNCbcPrettyCalcA --cmpquiet \
				"${afGammaRGBcurrent[$liIndex]} < 1.0 || ${afGammaRGBcurrent[$liIndex]}+(0${strOperation}${fStep}) < 1.0";then
			SECFUNCbcPrettyCalcA --scale 3 "${afGammaRGBcurrent[$liIndex]}+(0${strOperation}${fStep}/2.0)"
		else
			SECFUNCbcPrettyCalcA --scale 3 "${afGammaRGBcurrent[$liIndex]}+(0${strOperation}${fStep})"
		fi
		return 0
	}
#	SECFUNCexecA -ce xgamma \
#		-rgamma "`_FUNCchkFixGammaComponent 0`" \
#		-ggamma "`_FUNCchkFixGammaComponent 1`" \
#		-bgamma "`_FUNCchkFixGammaComponent 2`"
	#FUNCsetGamma "`_FUNCcalcComp 0`" "`_FUNCcalcComp 1`" "`_FUNCcalcComp 2`"
	SECFUNCexecA -ce $SECstrScriptSelfName --set "`_FUNCcalcComp 0`" "`_FUNCcalcComp 1`" "`_FUNCcalcComp 2`"

	SECFUNCuniqueLock --release --pid $$ --id "$strLockChangeGammaId"
fi

# independent of other options
if $bSpeak;then
	afGammaRGB=(`FUNCgetCurrentGammaRGB --force`)
	# sed to make it less tedious
	strSay="`echo "gamma red ${afGammaRGB[0]} green ${afGammaRGB[1]} blue ${afGammaRGB[2]} " \
		|sed -e "s'0 ' 'g" -e "s'0 ' 'g" -e "s'0 ' 'g" -e "s'[.] ' 'g"`"
	echoc --say "$strSay"
fi

exit 0

