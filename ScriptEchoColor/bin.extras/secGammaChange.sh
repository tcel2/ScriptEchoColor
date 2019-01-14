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

source <(secinit)

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
  if [[ "$strMonitor" == "ALL" ]];then
    SECFUNCexecA -ce xgamma \
      -rgamma "`FUNCchkFixGammaComponent "$1"`" \
      -ggamma "`FUNCchkFixGammaComponent "$2"`"	\
      -bgamma "`FUNCchkFixGammaComponent "$3"`"
  else
    SECFUNCexecA -ce xrandr --output "$strMonitor" --gamma `FUNCchkFixGammaComponent "$1"`:`FUNCchkFixGammaComponent "$2"`:`FUNCchkFixGammaComponent "$3"`
  fi
}

strCfgByDisplay="`SECFUNCfixId -f -- "${SECstrScriptSelfName}_Display${DISPLAY}"`"
SECFUNCcfgFileName "$strCfgByDisplay"
#echo "SECcfgFileName='$SECcfgFileName'"
#SECFUNCcfgFileName --get
#SECFUNCcfgFileName --show
#exit 0

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
bManuallyAdjust=false
CFGstrNVidiaSettingsFile="$HOME/.Custom.nvidia-settings-rc"
bKeepNVidia=false
CFGnKeepDelay=30
CFGbRefreshKeepGammaNow=false
SECFUNCcfgFileName --get
SECFUNCcfgFileName --show
SECFUNCexecA -ce xgamma
bOnlyOverDesktop=false
afCurrentGamma=(`FUNCgetCurrentGammaRGB --force`);
astrConnectedMonitors=(`xrandr |grep connected -w |awk '{print $1}'`);declare -p astrConnectedMonitors
#strMonitor="${astrConnectedMonitors[0]}"
strMonitor="ALL"
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
	elif [[ "$1" == "--adjust" ]];then #help manually adjust TODO
		bManuallyAdjust=true
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
	elif [[ "$1" == "--keepnvidia" ]];then #help ~daemon (CFGstrNVidiaSettingsFile) a loop that keeps the last gamma setup made at nvidia setttings application,
		#help useful in case some application changes it when you do not want.
		#help incompatible with --random.
		bKeepNVidia=true
	elif [[ "$1" == "--monitor" ]];then #help [strMonitor] to change gamma at, see astrConnectedMonitors options
    shift&&:
    strMonitor="$1"
    if ! SECFUNCarrayContains astrConnectedMonitors "$strMonitor";then
      echoc -p "invalid monitor strMonitor='$strMonitor'"
    fi
	elif [[ "$1" == "--onlydesk" ]];then #help will be active only if mouse is over the desktop (no window under it)
    bOnlyOverDesktop=true
	elif [[ "$1" == "--random" ]];then #help ~last [nRgfStep] [nRgfDelay] [nRgfMin] [nRgfMax]
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
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
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

if $bKeepNVidia;then
	while true;do 
		if echoc -t $CFGnKeepDelay -q "run settings?";then 
			nvidia-settings --config="$CFGstrNVidiaSettingsFile";
		fi;
		SECFUNCexecA -ce nvidia-settings -l --config="$CFGstrNVidiaSettingsFile";
	done
fi

if $bManuallyAdjust;then #TODO
	bChanging=true
	while $bChanging;do
		echoc -Q "gamma@_r/_g/_b/_R/_G/_B/_set@Dt"&&:; case "`secascii $?`" in 
			r)echo 1;;
			g)echo 2;;
			b)echo 3;;
			R)echo 1;;
			G)echo 2;;
			B)echo 3;;
			s)bChanging=false;;
		esac
	done
	exit 0
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

#if $bKeep;then # Keep Daemon - PART1
#	SECFUNCuniqueLock --daemonwait --id "$strCfgByDisplay"
#	echo "SECcfgFileName='$SECcfgFileName'"
#fi

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
elif $bKeep;then  # Keep Daemon - PART2
	SECFUNCuniqueLock --daemonwait --id "$strCfgByDisplay"
	
#	strCfgByDisplay="${SECstrScriptSelfName}_DaemonKeep_Display${DISPLAY}"
#	
#	SECFUNCuniqueLock --daemonwait --id "$strCfgByDisplay"
##	if ! SECFUNCarrayCheck CFGafBaseGammaRGB;then
##		SECFUNCechoWarnA "setting required base"
##		SECFUNCexecA -ce $SECstrScriptSelfName --setbase
##	fi

##	CFGafModGammaRGB=(`FUNCgetCurrentGammaRGB`)
##	declare -p CFGafModGammaRGB
##	SECFUNCcfgWriteVar CFGafModGammaRGB
#	
#	SECFUNCcfgFileName "$strCfgByDisplay"
#	echo "SECcfgFileName='$SECcfgFileName'"
	while true;do
		SECFUNCcfgReadDB CFGafModGammaRGB
		#SECFUNCexecA -ce xgamma -rgamma ${CFGafModGammaRGB[0]} -ggamma ${CFGafModGammaRGB[1]} -bgamma ${CFGafModGammaRGB[2]}
		if declare -p CFGafModGammaRGB;then
			SECFUNCexecA -ce FUNCsetGamma "${CFGafModGammaRGB[@]}"
		else
			echoc -p "CFGafModGammaRGB is not set?"
		fi
		
		nDelayStep=3
		for((nDelayCurrent=0;nDelayCurrent<CFGnKeepDelay;nDelayCurrent+=nDelayStep));do
			SECFUNCcfgReadDB CFGbRefreshKeepGammaNow
			if $CFGbRefreshKeepGammaNow;then 
				echoc --info "refreshing now, CFGbRefreshKeepGammaNow='$CFGbRefreshKeepGammaNow'"
				SECFUNCcfgWriteVar CFGbRefreshKeepGammaNow=false
				break;
			fi
			
			if echoc -q -t $nDelayStep "refresh now?";then 
				break;
			fi
		done
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
	nMinLimit=10
  FUNCinitVars() { #reset also
    declare -g nR=100
    declare -g nG=100
    declare -g nB=100
    declare -g nRto=$nR
    declare -g nGto=$nG
    declare -g nBto=$nB
  }
  FUNCinitVars

  nFUNCto=0
	FUNCto() {
		local n=$1;n=$((10#$n))
		local nTo=$2;nTo=$((10#$nTo))
		#if((n==nTo));then
		if(( n>=(nTo-nRgfStep) && n<=(nTo+nRgfStep) ));then
		  ((nDelta=nRgfMax-nRgfMin))
		  nRandom=$RANDOM
		  nRandom=`echo "$nRandom%$nDelta" |bc`
		  nRandom=$((nRandom+nRgfMin))
		  if((nRandom<nRgfMin||nRandom>nRgfMax));then echo "BUG: out of min/max range $nRandom" >&2; fi
		  nTo=$nRandom
		  if((nTo<nMinLimit));then
		    nTo=$nMinLimit
		  fi
		fi
    nFUNCto=$nTo
		#echo $nTo
	}

  nFUNCwalk=0
	FUNCwalk() {
		local n=$1;n=$((10#$n))
		local nTo=$2;nTo=$((10#$nTo))
		if((n<nTo));then
		  n=$((n+nRgfStep))
		elif((n>nTo));then
		  n=$((n-nRgfStep))
		fi
    nFUNCwalk=$n
		#echo $n
	}

  fFUNCtoFloat=0.0
	FUNCtoFloat() {
		local n=$1;n=$((10#$n))
		if((n<nMinLimit||n>1000));then SECFUNCechoErrA "BUG: out of xgamma range $n" >&2; fi
		#KEEP SAFE CALC OLD CODE: echo "scale=2;$1/100" |bc
    fFUNCtoFloat="$((10#${n}/100)).$((10#${n}/10%10))$((10#${n}%10))"
    #echo "$((10#${n}/100)).$((10#${n}/10%10))$((10#${n}%10))"
	}

  strFUNCupDown=""
	FUNCupDown() {
		local n=$1;n=$((10#$n))
		local nTo=$2;nTo=$((10#$nTo))
		if((n<nTo));then
		  strFUNCupDown="^"
		else
		  strFUNCupDown="v"
		fi
    #echo "$strFUNCupDown"
	}

  function FUNCisOverDesktop() {
    local lnWId=0
    lnWId=`xdotool getmouselocation|grep -o "[[:digit:]]*$"`&&:
#    declare -p lnWId >&2
    if((lnWId==0)) || [[ -z "$lnWId" ]];then return 0;fi # when locked from metacity
    #declare -p lnWId;
    #xdotool getwindowname $lnWId;
    if xwininfo -id $lnWId |egrep -q "xwininfo: Window id:.*(the root window|Desktop|nux input window|gnome-screensaver|has no name)";then return 0;fi # when locked from compiz = "nux input window", locked from metacity = "has no name"
    return 1
  }
  
  astrOODMBkpGammaRGB=()
  bOODMplay=false
  nOODMSec=$SECONDS
  bOODMSmoothResetting=false
  function FUNConlyOverDesktopMode() {
    if ! $bOnlyOverDesktop;then return 0;fi # let it play normally
    
#    if SECFUNCdelay ${FUNCNAME[0]} --checkorinit1 3;then
    if(( SECONDS >= (nOODMSec+3) ));then # 2000x faster than SECFUNCdelay! :) #id="test$RANDOM";i=0;while true;do if SECFUNCdelay $id --checkorinit 3;then break;fi; echo $((i++));done #id="test$RANDOM";i=0;nSec=$SECONDS;while true;do if((SECONDS>=(nSec+3)));then break;fi; echo $((i++));done
      if FUNCisOverDesktop;then
        astrOODMBkpGammaRGB=(`FUNCgetCurrentGammaRGB --force`)
        bOODMplay=true
        return 0 # play if over desktop
      else
        nRto=100;nGto=100;nBto=100 # overrides random mode
        if((nR!=100 && nG!=100 && nB!=100));then
          bOODMSmoothResetting=true
          return 0 # smoothly resets gamma
        else
          if $bOODMplay;then
            echo "(gamma smooth reset completed at `date`!)"
            if((`SECFUNCarraySize astrOODMBkpGammaRGB`>0));then FUNCsetGamma "${astrOODMBkpGammaRGB[@]}";fi # restore gamma double granted
            bOODMplay=false
            bOODMSmoothResetting=false
          fi
          echo -en "(mouse cursor is not over desktop at `date`)\r"
          return 1 # suspend
        fi
        #~ if $bOODMplay;then
          #~ if((`SECFUNCarraySize astrOODMBkpGammaRGB`>0));then FUNCsetGamma "${astrOODMBkpGammaRGB[@]}";fi # restore gamma once only
          #~ FUNCinitVars #reset to avoid too many annoying gamma jumps
          #~ bOODMplay=false
        #~ fi
        #~ return 1 # suspend
      fi
    else
      if $bOODMplay;then return 0;else return 1;fi # keep playing/suspended til next check time even if over windows now to avoid using xdotool too much TODO is that still a problem?
    fi
    
    return 1 # fallback granted suspend
  }
  
  #tabs 2
  nSecPrev=0
  declare -p nMinLimit nRgfStep nRgfDelay nRgfMin nRgfMax
	while true; do
    if ! FUNConlyOverDesktopMode;then sleep 1;continue;fi
    
    if ! $bOODMSmoothResetting;then
      FUNCto $nR $nRto;nRto=$nFUNCto
      FUNCto $nG $nGto;nGto=$nFUNCto
      FUNCto $nB $nBto;nBto=$nFUNCto
    fi
		
    FUNCwalk $nR $nRto;nR=$nFUNCwalk
    FUNCwalk $nG $nGto;nG=$nFUNCwalk
    FUNCwalk $nB $nBto;nB=$nFUNCwalk
		
    FUNCtoFloat $nR;fR=$fFUNCtoFloat
    FUNCtoFloat $nG;fG=$fFUNCtoFloat
    FUNCtoFloat $nB;fB=$fFUNCtoFloat
    
    strFRGB="$fR:$fG:$fB"
    if [[ "$strMonitor" == "ALL" ]];then
      xgamma -quiet -rgamma $fR -ggamma $fG -bgamma $fB
    else
      xrandr --output "$strMonitor" --gamma "$strFRGB"
    fi
    
		sleep $nRgfDelay
		
		#### report ####
    
    FUNCupDown $nR $nRto;strR="$strFUNCupDown"
    FUNCupDown $nG $nGto;strG="$strFUNCupDown"
    FUNCupDown $nB $nBto;strB="$strFUNCupDown"
    
    printf -v strTo "%03d,%03d,%03d" $nRto $nGto $nBto
    if $SEC_DEBUG;then
      echo "$strFRGB `printf "%03d,%03d,%03d" $nR $nG $nB` to $strTo" >&2
    else
      if $bOODMSmoothResetting || ((SECONDS>nSecPrev));then # report once per second
  #      printf "RGB `FUNCupDown $nR $nRto`%03d,`FUNCupDown $nG $nGto`%03d,`FUNCupDown $nB $nBto`%03d to $strTo\r" $nR $nG $nB
        printf "RGB ${strR}%03d,${strG}%03d,${strB}%03d to $strTo\r" $nR $nG $nB
        nSecPrev=$SECONDS
      fi
    fi
    strToPrev="$strTo"
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
##			#echo "asdf" >&2
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

