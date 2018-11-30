#!/bin/bash
# Copyright (C) 2004-2018 by Henrique Abdalla
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

# initializations and functions

function FUNCratio() {
  local lstrSz="$1"
  local lstrCalc="$(echo "${lstrSz}" |tr "x" "/")"
  bc <<< "scale=2;$lstrCalc"
  return 0
}

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
strBaseTmpFileName="_WallPaperChanger-TMP.jpg"
strTmpFile="$HOME/Pictures/Wallpapers/$strBaseTmpFileName"
strPicURI="file://$strTmpFile"
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
SECFUNCcfgReadDB #after default variables value setup above
bDaemon=false
nChangeInterval=3600
nChHueFastModeTimes=10
nRandomHueInterval=$((nChangeInterval/nChHueFastModeTimes))
strWallPPath="$HOME/Pictures/Wallpapers/"
strFindRegex=".*[.]\(jpg\|png\)"
declare -p strFindRegex
nChangeFast=5
nChangeHue=7
bFlip=false;
bFlop=false;
bWriteFilename=true;
strResize="`xrandr |egrep " connected primary " |sed -r 's".* ([[:digit:]]*x[[:digit:]]*)[+].*"\1"'`"
fResRatio="`FUNCratio $strResize`"
eval `echo "$strResize" |sed -r 's@([0-9]*)x([0-9]*)@nResW=\1;nResH=\2;@'`
declare -p strResize fResRatio
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\tAuto changes wallpaper after delay."
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--daemon" || "$1" == "-d" ]];then #help
		bDaemon=true
	elif [[ "$1" == "--change" || "$1" == "-c" ]];then #help <nChangeInterval> change wallpaper interval in seconds
		shift;nChangeInterval=$1
	elif [[ "$1" == "--fast" || "$1" == "-f" ]];then #help <nChangeFast> fast change wallpaper interval in seconds
		shift;nChangeFast=$1
	elif [[ "$1" == "--flip" ]];then #help allows random flip (vertical)
		bFlip=true;
	elif [[ "$1" == "--flop" ]];then #help allows random flop (horizontal)
		bFlop=true;
	elif [[ "$1" == "--hue" || "$1" == "-h" ]];then #help <nChangeHue> <nRandomHueInterval> <nChHueFastModeTimes> play with hue values random +-nChangeHue%. The nRandomHueInterval only makes sense if less than nChangeInterval. The nChHueFastModeTimes determines how many times the image will not change to a new one, while just changing the hue of current one.
		shift;nChangeHue="$1";
    shift;nRandomHueInterval="$1";
	elif [[ "$1" == "--nohue" || "$1" == "-H" ]];then #help disable the hue mode (that is default)
    nChangeHue=0
	elif [[ "$1" == "--nowrite" ]];then #help do not write the filename and other info to the image
    bWriteFilename=false;
	elif [[ "$1" == "--path" || "$1" == "-p" ]];then #help <strWallPPath> wallpapers folder
		shift;strWallPPath="$1"
	elif [[ "$1" == "--resize" ]];then #help <strResize> prefer this size than default from primary monitor 
    shift;strResize="$1"
	elif [[ "$1" == "--find" ]];then #help <strFindRegex>
		shift;strFindRegex="$1"
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift;pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars
#yad --text "DEBUG:$0"

# Main code
cd $strWallPPath;

nDelayMsg=3
nTotFiles=0
strFilter=".*"
function FUNCchkUpdateFileList() { #[--refill]
	nTotFiles=${#astrFileList[@]}
	
	if((nTotFiles==0)) || [[ "${1-}" == "--refill" ]];then
    # ignores hidden (even at hidden folders) and the tmp files
		IFS=$'\n' read -d '' -r -a astrFileList < <(
      find -iregex "$strFindRegex" \
        |egrep -v "/[.]" \
        |grep -v "$strBaseTmpFileName" \
        |egrep "$strFilter" \
        |sort \
    ) &&: # re-fill
		if [[ -z "${1-}" ]];then
			FUNCchkUpdateFileList --noNest #dummy recognition param, but works. This call will update tot files var
			if((nTotFiles==0));then
				echoc -w -t $nDelayMsg -p "no files found at '`pwd`'"
				return 1
			else
				echoc -w -t $nDelayMsg "updated files list"
			fi
		fi
	else
		astrFileList=("${astrFileList[@]}") # this will update the indexes
	fi
	
	return 0
}

function FUNCsetPicURI() {
  SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "$strPicURI";
}

if $bDaemon;then
  SECFUNCuniqueLock --daemonwait
	nTotFiles=0
	astrFileList=()
	bFastMode=false
	nSleep=$nChangeInterval
  nCurrChIntvl=$nChangeInterval
  nSumSleep=0
  bChangeImage=true
  nChHueFastModeCount=0
  FUNCsetPicURI
  bFlipKeep=false;
  bFlopKeep=false;
  nSetIndex=-1
  nSelect=0
  bPlay=true
	while true;do 
		if ! FUNCchkUpdateFileList;then continue;fi
		
    if $bChangeImage;then
      if((nSetIndex>-1));then
        nSelect=$nSetIndex
      else
        nSelect=$((RANDOM%nTotFiles));
      fi
      declare -p astrFileList nSelect nTotFiles |tr '[' '\n'
      
      strFileBase="${astrFileList[$nSelect]-}"
      strFile="`pwd`/$strFileBase";
      declare -p strFile
      if [[ -z "$strFile" ]] || [[ ! -f "$strFile" ]];then
        declare -p nSelect
        echo "list size = ${#astrFileList[@]}" >&2 &&:
        echoc -p "failed selecting file"
        if((nSetIndex>-1));then
          echoc --info "fixing nSetIndex='$nSetIndex'"
          nSetIndex=-1 #reset
        else
          echoc --alert "unable to auto-fix!"
        fi
        echoc -w -t $nSleep
        continue
      fi
      
      #TODO auto download wallpapers one new per loop
      
      #excluding current from shuffle list to always have a new one
      unset astrFileList[$nSelect]
    fi
		
    strTmpFilePreparing="${strTmpFile}.TMP" #this is important because the file may be incomplete when the OS tried to apply the new one
    SECFUNCexecA -cE cp -v "$strFile" "${strTmpFilePreparing}"
    
    function FUNCprepGeomInfo() { # <lstrFile>
      local lstrFile="$1"
      strOrigSize="`identify "$lstrFile" |sed -r 's".* ([[:digit:]]*x[[:digit:]]*) .*"\1"'`"
      fOrigRatio="`FUNCratio $strOrigSize`"
      #nOrigW="`echo "$strOrigSize" |sed -r 's@([[:digit:]]*)x.*@\1@'`"
      eval `echo "$strOrigSize" |sed -r 's@([0-9]*)x([0-9]*)@nOrigW=\1;nOrigH=\2;@'`
    }
    FUNCprepGeomInfo "$strFile"
    
    # grants size preventing automatic from desktop manager using a lot (?) of CPU
    strSzOrEq="="
    strFixSz=""
    strFixSzTxt=""
    strXbrz=""
    strOrigSzTxt="$strOrigSize"
    if [[ "$strOrigSize" != "$strResize" ]];then
      if((nOrigW<nResW || nOrigH<nResH)) && which xbrzscale >/dev/null;then
        nXBRZ=2 # more than 2 is not good for most pics
  #      if [[ -f "$HOME/.cache/${SECstrScriptSelfName}/${strFile}.resizeTo${nResW}x${nResH}" ]];then
        strXBRZcache="$HOME/.cache/${SECstrScriptSelfName}/`basename "${strFile}"`-${nXBRZ}xBRZ.webp"
        strXbrz=",${nXBRZ}xBRZ"
        if [[ -f "$strXBRZcache" ]];then
          #SECFUNCexecA -cE cp -vf "${strXBRZcache}" "${strTmpFilePreparing}"
          SECFUNCexecA -cE dwebp "${strXBRZcache}" -o "${strTmpFilePreparing}"
        else
          SECFUNCexecA -cE nice -n 19 xbrzscale $nXBRZ "${strTmpFilePreparing}" "${strTmpFilePreparing}2"
          #~ SECFUNCexecA -cE nice -n 19 xbrzscale 2 "${strTmpFilePreparing}" "${strTmpFilePreparing}.png"
          #~ SECFUNCexecA -cE nice -n 19 convert "${strTmpFilePreparing}.png" "${strTmpFilePreparing}2"
          SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          
          SECFUNCexecA -cE nice -n 19 convert -sharpen 20x20 "${strTmpFilePreparing}" "${strTmpFilePreparing}2"
          SECFUNCexecA -cE mv -vf "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          
          mkdir -p "`dirname "$strXBRZcache"`/"
          #SECFUNCexecA -cE cp -vf "${strTmpFilePreparing}" "${strXBRZcache}"
          SECFUNCexecA -cE cwebp -q 90 "${strTmpFilePreparing}" -o "${strXBRZcache}"
        fi
        
        ################################################
        ### WATCHOUT CHANGES ORIG VARS! ###########
        ######################################
        FUNCprepGeomInfo "${strTmpFilePreparing}"
        strOrigSzTxt+="($strOrigSize)"
      fi
      
      strResizeFinal="$strResize"
      astrCmdFrame=()
      nBorder=20
      if((nOrigW<(nResW-nBorder) && nOrigH<(nResH-nBorder)));then
        # creates a frame border on the small image
        strResizeFinal="$strOrigSize"
        SECFUNCexecA -cE nice -n 19 convert -mattecolor black -compose Copy -frame "10x10+6+3" "${strTmpFilePreparing}" "${strTmpFilePreparing}2"
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      else
        # This only considers too wide images and will cut out left and right edges
        fMaxRatio="`SECFUNCbcPrettyCalcA "(1+(1/8)) * $fResRatio"`" #where top/bottom borders are not annoying
        if SECFUNCbcPrettyCalcA --cmpquiet "$fOrigRatio > $fMaxRatio";then #if the image it too wide and the blurred borders will have too much height (and annoying)
          fDiff="`SECFUNCbcPrettyCalcA "$fOrigRatio - $fMaxRatio"`"
          fSub="`SECFUNCbcPrettyCalcA "$fDiff/4"`"
          fFixRatio="`SECFUNCbcPrettyCalcA "1 - $fSub"`"
          #fFixRatio=0.75
          #fFixRatio=0.85
          nFixW="`SECFUNCbcPrettyCalcA --scale 0 "${nOrigW}*${fFixRatio}"`"
          SECFUNCexecA -cE declare -p nOrigW nOrigH nResW nResH nFixW fMaxRatio fOrigRatio fResRatio fDiff fFixRatio
          strFixSz="${nFixW}x${nOrigH}"
          SECFUNCexecA -cE nice -n 19 convert -extent "$strFixSz" "${strTmpFilePreparing}" "${strTmpFilePreparing}2"
          strFixSzTxt=",fix:${strFixSz}"
          SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
        fi
      fi
      
      strSzOrEq=""
      astrCmd=()
      astrCmd+=( convert "${strTmpFilePreparing}" )
      astrCmd+=( \( -clone 0 -blur 0x5 -resize $strResize\! -fill black -colorize 25% \) )
      #~ if((`SECFUNCarraySize astrCmdFrame`>0));then
        #~ astrCmd+=( "${astrCmdFrame[@]}" )
      #~ fi
      astrCmd+=( \( -clone 0 -resize $strResizeFinal \) )
      #astrCmd+=( -crop  ${strResize}+10+10 )
      astrCmd+=( -delete 0 -gravity center -composite "${strTmpFilePreparing}2" )
      SECFUNCexecA -cE nice -n 19 "${astrCmd[@]}"
      declare -p strOrigSize strResize strResizeFinal
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    if $bChangeImage;then
      bFlipKeep=false; bFlopKeep=false;
      if $bFlip && ((RANDOM%2==0));then bFlipKeep=true;fi
      if $bFlop && ((RANDOM%2==0));then bFlopKeep=true;fi
    fi
  
    if((nChangeHue!=0));then #TODO to not use hue to let everything else work... :P
      nAddR=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddG=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddB=$((RANDOM%(nChangeHue*2)-nChangeHue))
      declare -p nAddR nAddG nAddB
      
      SECFUNCexecA -cE nice -n 19 convert "${strTmpFilePreparing}" \
        -colorspace HSL \
                   -channel R -evaluate add ${nAddR}% \
          +channel -channel G -evaluate add ${nAddG}% \
          +channel -channel B -evaluate add ${nAddB}% \
          +channel -set colorspace HSL -colorspace sRGB "${strTmpFilePreparing}2"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    strFlipTxt=""
    if $bFlipKeep;then 
      SECFUNCexecA -cE nice -n 19 convert -flip "${strTmpFilePreparing}" "${strTmpFilePreparing}2";
      strFlipTxt=",flip"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    strFlopTxt=""
    if $bFlopKeep;then
      SECFUNCexecA -cE nice -n 19 convert -flop "${strTmpFilePreparing}" "${strTmpFilePreparing}2";
      strFlopTxt=",flop"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    if $bWriteFilename;then
      nFontSize=15
      strTxt="`basename "$strFile"`/orig:${strOrigSzTxt}${strFixSzTxt}${strFlipTxt}${strFlopTxt}${strXbrz}/RGB:$nAddR,$nAddG,$nAddB"
      # pseudo outline at 4 corners
      SECFUNCexecA -cE nice -n 19 convert "${strTmpFilePreparing}" -gravity South -pointsize $nFontSize \
        -fill red    -annotate +0+2 "$strTxt" \
        -fill green  -annotate +2+0 "$strTxt" \
        -fill blue   -annotate +0+0 "$strTxt" \
        -fill purple -annotate +2+2 "$strTxt" \
        -fill white  -annotate +1+1 "$strTxt" \
        "${strTmpFilePreparing}2"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    # final step
    SECFUNCexecA -cE mv -f "${strTmpFilePreparing}" "$strTmpFile"
    
    if $bFastMode;then
      if((nChHueFastModeCount<nChHueFastModeTimes));then
        ((nChHueFastModeCount++))&&:;
        bChangeImage=false;declare -p bChangeImage
      else
        nChHueFastModeCount=0;declare -p nChHueFastModeCount
        bChangeImage=true;declare -p bChangeImage
      fi
      declare -p nChHueFastModeCount nChHueFastModeTimes
    else
      if((nRandomHueInterval>0));then 
        nSleep=$nRandomHueInterval;declare -p nSleep
        declare -p nChangeInterval
        declare -p nSumSleep
        ((nSumSleep+=$nRandomHueInterval))&&:
        if((nSumSleep<nChangeInterval));then
          bChangeImage=false;declare -p bChangeImage
        else
          nSumSleep=0;declare -p nSumSleep
          bChangeImage=true;declare -p bChangeImage
        fi
      else
        bChangeImage=true;declare -p bChangeImage
      fi
    fi
    #~ else
      #~ SECFUNCexecA -cE cp -f "$strFile" "$strTmpFile"
    #~ fi
    
		#~ SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "file://$strFile";
    bResetCounters=false;
    nWeek=$((3600*24*7))
    if ! $bPlay;then nSleep=$nWeek;fi #a week trick
    astrOpt=(
      "toggle _auto play mode to conserve CPU\n"
      "_change image now\n"
      "toggle _fast mode\n"
      "fi_lter\n"
      "toggle fl_ip\n"
      "toggle fl_op\n"
      "_reset timeout counter\n"
      "_set image index\n"
      "_verbose commands (to debug)\n"
      "fi_x wallpaper pic URI\n"
    )
    echoc -t $nSleep -Q "@O\n ${astrOpt[*]}"&&:; nRet=$?; case "`secascii $nRet`" in 
      a)
        SECFUNCtoggleBoolean bPlay
        ;;
      c)
        bChangeImage=true
        bResetCounters=true
        ;;
      f)
        SECFUNCtoggleBoolean bFastMode
        if $bFastMode;then
          nSleep=$nChangeFast;declare -p nSleep
        else
          nSleep=$nChangeInterval;declare -p nSleep
        fi
        bResetCounters=true
        ;;
      l)
        FUNCchkUpdateFileList --refill
        declare -p astrFileList |tr '[' '\n'
        declare -p strFilter
        #TODO for some inexplicable (?) reason, while 's' option will collect text and work fine many times, after this option is selected nothing will output anymore on text prompts `echoc -S`... scary... 8-( ), could be cuz of the @D default option? or even the '(' ')' test more later...
        strFilter="`echoc -S "Type a regex filter (can be a subfolder name)@D${strFilter}"`"
        declare -p strFilter
        FUNCchkUpdateFileList --refill
        if((`SECFUNCarraySize astrFileList`>0));then
          declare -p astrFileList |tr '[' '\n'
          bChangeImage=true;
          bResetCounters=true
        else
          echoc -p "invalid filter, no matches"
          strFilter=".*"
          FUNCchkUpdateFileList --refill
        fi
        ;;
      i)
        SECFUNCtoggleBoolean bFlipKeep
        bResetCounters=true
        ;; 
      o)
        SECFUNCtoggleBoolean bFlopKeep
        bResetCounters=true
        ;; 
      r)
        bResetCounters=true
        ;; 
      s)
        FUNCchkUpdateFileList --refill
        declare -p astrFileList |tr '[' '\n'
        nSetIndex="`echoc -S "set image index"`"
        if SECFUNCisNumber -dn "$nSetIndex" && ((nSetIndex<nTotFiles));then
          bChangeImage=true;
          bResetCounters=true
        else
          echoc -p "invalid nSetIndex='$nSetIndex'"
          nSetIndex=-1
        fi
        ;; 
      v)
        SECFUNCtoggleBoolean SECbExecVerboseEchoAllowed
        ;;
      x)
        FUNCsetPicURI
        ;;
      *)if((nRet==1));then SECFUNCechoErrA "err=$nRet";exit 1;fi;;
    esac
#		if echoc -q -t $nSleep "bFastMode='$bFastMode', toggle?";then

    if $bResetCounters;then
      nSumSleep=0;declare -p nSumSleep
      nChHueFastModeCount=0;declare -p nChHueFastModeCount
    fi
    
	done
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
