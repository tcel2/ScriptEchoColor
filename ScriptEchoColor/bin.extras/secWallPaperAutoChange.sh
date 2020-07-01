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

: ${CFGbZoom:=false};
export CFGbZoom #help set initial zoom mode toggle

: ${CFGstrFilter:=".*"}
export CFGstrFilter #help

strExample="DefaultValue"
CFGstrTest="Test"
strBaseTmpFileName=".KEEP_ORIGINAL.secWallPaperChanger-TMP.jpg"
strWallPPath="$HOME/Pictures/Wallpapers/"
: ${strTmpPath:="/dev/shm"} #help
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful
export CFGastrFileList=()
bDaemon=false
nChangeInterval=3600
nChHueFastModeTimes=10
nRandomHueInterval=$((nChangeInterval/nChHueFastModeTimes))
strWallPPath="$HOME/Pictures/Wallpapers/"
strFindRegex=".*[.]\(jpg\|jpeg\|png\|webp\)"
declare -p strFindRegex
nChangeFast=5
nChangeHue=7
bFlip=false;
bFlop=false;
bWriteFilename=true;
strScreenSize="`xrandr |egrep " connected primary " |sed -r 's".* ([[:digit:]]*x[[:digit:]]*)[+].*"\1"'`"
fResRatio="`FUNCratio $strScreenSize`"
declare -p strScreenSize fResRatio
SECFUNCcfgReadDB #after default variables value setup above
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
	elif [[ "$1" == "--resize" ]];then #help <strScreenSize> override default based on primary monitor 
    shift;strScreenSize="$1"
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


fResRatio="`FUNCratio $strScreenSize`"
eval `echo "$strScreenSize" |sed -r 's@([0-9]*)x([0-9]*)@nResW=\1;nResH=\2;@'`
declare -p strScreenSize fResRatio

: ${nPercTo2xBRZScale:=60} #help below this perc relatively to screen size, xBRZ will be used
bOldMode=false
if $bOldMode;then
  #TODO explain this better... and what 5p6 meant again? :P
  nResW5p6=$((nResW-`SECFUNCbcPrettyCalcA --scale 0 "${nResW}/12"`)) # /12 is for 16:9 monitor #TODO other monitor's ratios
  nResH5p6=$((nResH-`SECFUNCbcPrettyCalcA --scale 0 "${nResH}/6"`)) # good top/bottom blurred margin is 1/12 each (sum = 1/6) of the total requested height
else
  nResW5p6=$((nResW*nPercTo2xBRZScale/100))
  nResH5p6=$((nResH*nPercTo2xBRZScale/100))
fi
declare -p nResW5p6 nResH5p6

function FUNCconvert() {
  #~ (
    #~ local lnStart=$SECONDS
    #~ local lnPid
    #~ while ! lnPid=`pgrep convert`;do 
      #~ echo "`date` waiting convert to start...";
      #~ sleep 0.25;
      #~ if(( (SECONDS-lnStart) > 10));then
        #~ exit 0 # timedout
      #~ fi
    #~ done;
    #~ SECFUNCexecA -cE cpulimit -c 1 -l 50 -p $lnPid &&:
  #~ )&
  (SECFUNCCcpulimit -r "convert.*${strBaseTmpFileName}" -t 1 -l 25)&&:
  SECFUNCexecA -cE nice -n 19 convert "$@"
  return 0
}

nDelayMsg=3
nTotFiles=0
: ${CFGbShowHidden:=false}
function FUNCchkUpdateFileList() { #[--refill]
	nTotFiles=${#CFGastrFileList[@]}
	if((nTotFiles==0)) || [[ "${1-}" == "--refill" ]];then
    # ignores hidden (even at hidden folders) and the tmp files
    grepIgnore="/[.]"
    if $CFGbShowHidden;then #never DISABLED ones tho
      grepIgnore="/[.]DISABLED[.]"
    fi
		IFS=$'\n' read -d '' -r -a CFGastrFileList < <(
      find -iregex "$strFindRegex" \
        |egrep -v "${grepIgnore}" \
        |grep -v "$strBaseTmpFileName" \
        |egrep "$CFGstrFilter" \
        |sort \
    ) &&: # re-fill
		if [[ -z "${1-}" ]];then
			FUNCchkUpdateFileList --noNest #dummy recognition param, but works. This call will update tot files var
			if((nTotFiles==0));then
				if echoc -w -t $nDelayMsg -p "no files found at '`pwd`', reset filter CFGstrFilter='$CFGstrFilter'?";then CFGstrFilter=".*";fi
				return 1
			else
				echoc -w -t $nDelayMsg "updated files list"
			fi
		fi
	else
		CFGastrFileList=("${CFGastrFileList[@]}") # this will update the indexes
	fi
	
	return 0
}

function FUNCsetPicURI() {
  if $CFGbShowHidden;then
    declare -g strTmpFile="$strTmpPath/$strBaseTmpFileName"
  else
    declare -g strTmpFile="$strWallPPath/$strBaseTmpFileName"
  fi
  strPicURI="file://$strTmpFile"
  SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "$strPicURI";
}
FUNCsetPicURI

trap 'if $CFGbShowHidden;then gsettings set org.gnome.desktop.background picture-uri "";fi' EXIT # to help before reboot

if $bDaemon;then
  SECFUNCuniqueLock --daemonwait
	nTotFiles=0
	bFastMode=false
	nSleep=$nChangeInterval
  nCurrChIntvl=$nChangeInterval
  nSumSleep=0
  bChangeImage=true
  nChHueFastModeCount=0
  bFlipKeep=false;
  bFlopKeep=false;
  nSetIndex=-1
  nChosen=0
  bPlay=true
  bRandomColoring=true
  bOptDisableCurrent=false
  bOptAllowCurrentOnLockScreen=false
  bWasHidden=false;
  bResetCounters=false;
  bXBRZ=true;
  bTargetZoomAtMouse=false
  : ${CFGstrCurrentFile:=""}
  
  FUNChiddenToggle() {
    SECFUNCtoggleBoolean CFGbShowHidden
    SECFUNCcfgWriteVar CFGbShowHidden
    FUNCsetPicURI
    FUNCchkUpdateFileList --refill
    bChangeImage=true
    bResetCounters=true
  }      
  
  if $CFGbShowHidden;then 
    gsettings set org.gnome.desktop.background picture-uri ""; # to help just after starting
    echoc --say "wall paper auto changer starting in 10 minutes" # :)
    if echoc -q -t 600 "disable hidden now?";then 
      FUNChiddenToggle;
      gsettings set org.gnome.desktop.background picture-uri ""
    fi
  fi
  
  FUNCsetPicURI
  
	while true;do 
		if ! FUNCchkUpdateFileList;then continue;fi
		
    if [[ ! -f "$CFGstrCurrentFile" ]];then
      bChangeImage=true;
      
      # cleanups options that wont work
      bOptDisableCurrent=false;
      bOptAllowCurrentOnLockScreen=false;
    else
      if $bOptDisableCurrent;then
        SECFUNCexecA -ce mv -v "$CFGstrCurrentFile" "`dirname "$CFGstrCurrentFile"`/.DISABLED.`basename "$CFGstrCurrentFile"`" &&:
        bOptDisableCurrent=false
        continue
      elif $bOptAllowCurrentOnLockScreen;then
        if ! [[ "$CFGstrCurrentFile" =~ .*LOCKSCREEN[.].* ]];then
          strNewName="`dirname "$CFGstrCurrentFile"`/LOCKSCREEN.`basename "$CFGstrCurrentFile"`"
          SECFUNCexecA -ce mv -v "$CFGstrCurrentFile" "$strNewName" &&:
          CFGstrCurrentFile="$strNewName"
        fi
        bOptAllowCurrentOnLockScreen=false
        continue
      fi
    fi
    
    if $bChangeImage;then
      #~ CFGbZoom=false
      
      if((nSetIndex>-1));then
        nChosen=$nSetIndex
      else
        nChosen=$((RANDOM%nTotFiles));
      fi
      SECFUNCarrayShow CFGastrFileList
      declare -p nChosen nTotFiles
      
      strFlRelative="${CFGastrFileList[$nChosen]-}"
      CFGstrCurrentFile="`pwd`/$strFlRelative";
      declare -p CFGstrCurrentFile
      bInvalidFile=false
      strMsgWarn=""
      
      unset CFGastrFileList[$nChosen] #excluding current from shuffle list to always have a new one
      SECFUNCcfgWriteVar CFGastrFileList
      
      if [[ -z "$CFGstrCurrentFile" ]];then
        strMsgWarn="empty"
        bInvalidFile=true
      fi
      if [[ ! -f "$CFGstrCurrentFile" ]];then
        strMsgWarn="missing"
        bInvalidFile=true
      fi
      if $bInvalidFile;then
        declare -p nChosen
        echo "list size = ${#CFGastrFileList[@]}" >&2 &&:
        echoc -p "failed selecting $strMsgWarn CFGstrCurrentFile='$CFGstrCurrentFile'"
        if((nSetIndex>-1));then
          echoc --info "fixing invalid nSetIndex='$nSetIndex'"
          nSetIndex=-1 #reset
        #~ else
          #~ echoc --alert "unable to auto-fix!@-n #TODO Developer!"
        fi
        echoc -w -t 3 #$nSleep
        continue
      fi
      
      bWasHidden=false;if [[ "$strFlRelative" =~ .*/[.].* ]];then bWasHidden=true;fi # full path may contain "/./" that would break this check
      
      #TODO auto download wallpapers one new per loop
      
      SECFUNCcfgWriteVar CFGstrCurrentFile
      nSetIndex=-1 # because as it was already changed, CFGstrCurrentFile will remain the same, and this grants the next auto-change will be random/suffle again!
    fi
		
    #declare -p CFGstrCurrentFile >&2
    #bWasHidden=false;if [[ "$CFGstrCurrentFile" =~ .*/[.].* ]];then bWasHidden=true;fi
    #declare -p bWasHidden >&2
    
    strTmpFilePreparing="${strTmpFile}.TMP" #this is important because the file may be incomplete when the OS tried to apply the new one
    SECFUNCexecA -cE cp -v "$CFGstrCurrentFile" "${strTmpFilePreparing}"
    
    function FUNCprepGeomInfo() { # <lstrFile>
      local lstrFile="$1"
      strOrigSize="`identify "$lstrFile" |sed -r 's".* ([[:digit:]]*x[[:digit:]]*) .*"\1"'`"
      fOrigRatio="`FUNCratio $strOrigSize`"
      #nOrigW="`echo "$strOrigSize" |sed -r 's@([[:digit:]]*)x.*@\1@'`"
      eval `echo "$strOrigSize" |sed -r 's@([0-9]*)x([0-9]*)@nOrigW=\1;nOrigH=\2;@'`
    }
    FUNCprepGeomInfo "$CFGstrCurrentFile"
    
    # grants size preventing automatic from desktop manager using a lot (?) of CPU
    strSzOrEq="="
    strFixSz=""
    strFixSzTxt=""
    strXbrz=""
    strOrigSzTxt="$strOrigSize"
    bAllowZoom=false
    strTxtZoom=""
    if [[ "$strOrigSize" != "$strScreenSize" ]];then
      if((nOrigW>nResW || nOrigH>nResH));then # b4 xbrz for quality zoom
        bAllowZoom=true
      fi
      
      ##########
      ## xBRZ ##
      ##########
      if $SECbExecVerboseEchoAllowed;then declare -p LINENO nOrigW nOrigH nResW nResH;fi
#      if((nOrigW<nResW || nOrigH<nResH)) && which xbrzscale >/dev/null;then
      if $bXBRZ && ((nOrigW<nResW5p6 || nOrigH<nResH5p6)) && which xbrzscale >/dev/null;then
        nXBRZ=2 # more than 2 is not good for most pics
  #      if [[ -f "$HOME/.cache/${SECstrScriptSelfName}/${CFGstrCurrentFile}.resizeTo${nResW}x${nResH}" ]];then
        strXBRZcache="$HOME/.cache/${SECstrScriptSelfName}/`basename "${CFGstrCurrentFile}"`-${nXBRZ}xBRZ.webp"
        strXbrz=",${nXBRZ}xBRZ"
        if [[ -f "$strXBRZcache" ]];then
          #SECFUNCexecA -cE cp -vf "${strXBRZcache}" "${strTmpFilePreparing}"
          SECFUNCexecA -cE dwebp "${strXBRZcache}" -o "${strTmpFilePreparing}"
        else
          SECFUNCexecA -cE nice -n 19 xbrzscale $nXBRZ "${strTmpFilePreparing}" "${strTmpFilePreparing}2"
          #~ SECFUNCexecA -cE nice -n 19 xbrzscale 2 "${strTmpFilePreparing}" "${strTmpFilePreparing}.png"
          #~ FUNCconvert "${strTmpFilePreparing}.png" "${strTmpFilePreparing}2"
          SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          
          FUNCconvert -sharpen 20x20 "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2"
          SECFUNCexecA -cE mv -vf "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          
          mkdir -p "`dirname "$strXBRZcache"`/"
          #SECFUNCexecA -cE cp -vf "${strTmpFilePreparing}" "${strXBRZcache}"
          SECFUNCexecA -cE cwebp -q 90 "${strTmpFilePreparing}" -o "${strXBRZcache}"
        fi
        
        FUNCprepGeomInfo "${strTmpFilePreparing}" # !!!!!!! WATCHOUT CHANGES ORIG VARS !!!!!!!!!!!!!!!!!!!!!
        strOrigSzTxt+="($strOrigSize)"
      fi # xBRZ
      
      if((nOrigW>nResW));then
        # This only considers too wide images and will cut out left and right edges
        fMaxRatio="`SECFUNCbcPrettyCalcA "(1+(1/8)) * $fResRatio"`" #where top/bottom borders are not annoying
        if SECFUNCbcPrettyCalcA --cmpquiet "$fOrigRatio > $fMaxRatio";then 
          # if the image is too wide and the blurred borders will have too much height (and be annoying)
          if((nOrigH>=nResH5p6));then
            # this will cut more from the left/right edges
            nFixW=$nResW
          else
            # this will cut less from the left/right edges, and the image will be shrinked a bit
            fDiff="`SECFUNCbcPrettyCalcA "$fOrigRatio - $fMaxRatio"`"
            fSub="`SECFUNCbcPrettyCalcA "$fDiff/4"`"
            fFixRatio="`SECFUNCbcPrettyCalcA "1 - $fSub"`"
            #fFixRatio=0.75
            #fFixRatio=0.85
            nFixW="`SECFUNCbcPrettyCalcA --scale 0 "${nOrigW}*${fFixRatio}"`"
            if $SECbExecVerboseEchoAllowed;then declare -p LINENO fDiff fSub fFixRatio;fi
          fi
          strFixSz="${nFixW}x${nOrigH}"
          nLeftMargin=$(( (nOrigW-nFixW)/2 ))
          if $SECbExecVerboseEchoAllowed;then declare -p LINENO nOrigW nOrigH nResW nResH nFixW fMaxRatio fOrigRatio fResRatio nLeftMargin;fi
          FUNCconvert -extent "${strFixSz}+${nLeftMargin}+0" "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2"
          strFixSzTxt=",fixE:${strFixSz}"
          SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          
          FUNCprepGeomInfo "${strTmpFilePreparing}" # !!!!!!! WATCHOUT CHANGES ORIG VARS !!!!!!!!!!!!!!!!!!!!!
        fi
      fi
      
      if $bAllowZoom;then
        bDoZoomNow=false
        if $CFGbZoom && ((RANDOM%4>0));then # 25% chance of not zooming once
          bDoZoomNow=true
        fi
        if $bTargetZoomAtMouse;then
          bDoZoomNow=true
        fi
        if $bDoZoomNow;then
          if $bTargetZoomAtMouse;then
            nLeftMargin=0;
            if((nOrigW>nResW));then 
              eval "$(xdotool getmouselocation --shell|egrep "^(X|Y)"|sed -r -e "s'X'nMouseX'" -e "s'Y'nMouseY'")"
              
              nPercX=$((nMouseX*100/nResW))
              if $bFlopKeep;then nPercX=$((100-nPercX));fi
              
              nPercY=$((nMouseY*100/nResH))
              if $bFlipKeep;then nPercY=$((100-nPercY));fi
              
              declare -p nMouseX nMouseY nPercX nPercY >&2
              
              nLeftMargin=$(( (nOrigW-nResW)*nPercX/100 ));
              nTopMargin=$((  (nOrigH-nResH)*nPercY/100 ));
            fi
          else
            nLeftMargin=0;if((nOrigW>nResW));then nLeftMargin=$(( RANDOM%(nOrigW-nResW) ));fi
            nTopMargin=0 ;if((nOrigH>nResH));then nTopMargin=$((  RANDOM%(nOrigH-nResH) ));fi
          fi
          declare -p nLeftMargin nTopMargin nOrigW nOrigH nResW nResH >&2
          #~ nLeftMargin=0;if((nOrigW>nResW));then nLeftMargin=$(( (nOrigW-nResW)/2 ));fi
          #~ nTopMargin=0 ;if((nOrigH>nResH));then nTopMargin=$((  (nOrigH-nResH)/2 ));fi
          FUNCconvert -extent "${strScreenSize}+${nLeftMargin}+${nTopMargin}" "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2"
          SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
          strTxtZoom=",ZOOM"
        fi
      fi
      
      if [[ "$CFGstrCurrentFile" =~ .*[wW][eE][bB][pP]$ ]];then
        FUNCconvert "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}.jpg" # jpg type must be forced or will fail sometimes
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}.jpg" "${strTmpFilePreparing}2" #duhhh
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      fi
      
      strResizeFinal="$strScreenSize"
      astrCmdFrame=()
      nBorder=10
      nBorderX2=$((nBorder*2))
      #~ sedIntegerPart='s"^([[:digit:]]*).*"\1"'
      #~ nBorderIn="` bc <<< "${nBorder}*0.3" |sed -r "${sedIntegerPart}"`"
      #~ nBorderOut="`bc <<< "${nBorder}*0.6" |sed -r "${sedIntegerPart}"`"
      nBorderIn="` SECFUNCbcPrettyCalcA --scale 0 "${nBorder}*0.3"`"
      nBorderOut="`SECFUNCbcPrettyCalcA --scale 0 "${nBorder}*0.6"`"
      if $SECbExecVerboseEchoAllowed;then declare -p LINENO nOrigW nOrigH nResW nResH nBorder nBorderX2 nBorderIn nBorderOut;fi
      #if((nOrigW<(nResW-nBorderX2) && nOrigH<(nResH-nBorderX2)));then
      if((nOrigW<(nResW-nBorderX2) && nOrigH<(nResH-nBorderX2)));then
        # creates a frame border on the small image
        strResizeFinal="$strOrigSize"
        FUNCconvert -mattecolor black -compose Copy -frame "${nBorder}x${nBorder}+${nBorderOut}+${nBorderIn}" "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2"
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      fi
      
      strSzOrEq=""
      astrCmd=()
      astrCmd+=( FUNCconvert "${strTmpFilePreparing}" )
      astrCmd+=( \( -clone 0 -blur 0x5 -resize $strScreenSize\! -fill black -colorize 25% \) )
      #~ if((`SECFUNCarraySize astrCmdFrame`>0));then
        #~ astrCmd+=( "${astrCmdFrame[@]}" )
      #~ fi
      astrCmd+=( \( -clone 0 -resize $strResizeFinal \) )
      #astrCmd+=( -crop  ${strScreenSize}+10+10 )
      astrCmd+=( -delete 0 -gravity center -composite "jpeg:${strTmpFilePreparing}2" )
      if ! "${astrCmd[@]}";then
        echoc -p "Failed to process CFGstrCurrentFile='$CFGstrCurrentFile'"
        bChangeImage=true;
        continue;
      fi
      if $SECbExecVerboseEchoAllowed;then declare -p LINENO strOrigSize strScreenSize strResizeFinal;fi
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    if $bChangeImage;then
      bFlipKeep=false; bFlopKeep=false;
      if $bFlip && ((RANDOM%2==0));then bFlipKeep=true;fi
      if $bFlop && ((RANDOM%2==0));then bFlopKeep=true;fi
    fi
  
    if $bRandomColoring && ((nChangeHue!=0));then #TODO to not use hue to let everything else work... :P
      nAddR=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddG=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddB=$((RANDOM%(nChangeHue*2)-nChangeHue))
      if $SECbExecVerboseEchoAllowed;then declare -p nAddR nAddG nAddB;fi
      
      FUNCconvert "${strTmpFilePreparing}" \
        -colorspace HSL \
                   -channel R -evaluate add ${nAddR}% \
          +channel -channel G -evaluate add ${nAddG}% \
          +channel -channel B -evaluate add ${nAddB}% \
          +channel -set colorspace HSL -colorspace sRGB "jpeg:${strTmpFilePreparing}2"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    strFlipTxt=""
    if $bFlipKeep;then 
      FUNCconvert -flip "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2";
      strFlipTxt=",flip"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    strFlopTxt=""
    if $bFlopKeep;then
      FUNCconvert -flop "${strTmpFilePreparing}" "jpeg:${strTmpFilePreparing}2";
      strFlopTxt=",flop"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    if $bWriteFilename;then
      nFontSize=15
      strTxHid="";if $bWasHidden;then strTxHid="[HID]";fi
      strTxt="oSz:${strOrigSzTxt}${strFixSzTxt}${strFlipTxt}${strFlopTxt}${strXbrz}${strTxtZoom}(RGB:$nAddR,$nAddG,$nAddB)${strTxHid}"
      
      # if filename is too big, trunc it
      nColsLim=150 #TODO calc based on average font width and nResW with 15% error margin to less
      strBNCurrent=",`basename "$CFGstrCurrentFile"`"
      strBNCurrent="${strBNCurrent:0:$((150-${#strTxt}))}"
      strTxt+="$strBNCurrent"
      
      # pseudo outline at 4 corners
      astrOutlineColors=(red green blue purple) # dark outline colors
      #light readable color #if $CFGbShowHidden;then strTxtColor="red";fi
      strTxtColor="white";if $CFGbShowHidden;then strTxtColor="yellow";fi
        #strTxtColor="yellow";
        ##astrOutlineColors=(red red red red);
        ##if $bWasHidden;then
          ##strTxtColor="yellow";
          ##astrOutlineColors=(purple purple purple purple);
        ##else
          ##strTxtColor="yellow"; astrOutlineColors=(red red red red);
        ##fi
      #fi
      astrCmdWrTx=(
        -pointsize $nFontSize
        -fill ${astrOutlineColors[0]} -annotate +0+2 "$strTxt" # outline top left
        -fill ${astrOutlineColors[1]} -annotate +2+0 "$strTxt" # outline bottom right
        -fill ${astrOutlineColors[2]} -annotate +0+0 "$strTxt" # outline bottom left
        -fill ${astrOutlineColors[3]} -annotate +2+2 "$strTxt" # outline top right
        -fill $strTxtColor  -annotate +1+1 "$strTxt" # final text
      )
      astrCmdWriteTxt=(
        FUNCconvert "${strTmpFilePreparing}" 
          -gravity South "${astrCmdWrTx[@]}"
          -gravity North "${astrCmdWrTx[@]}"
      )
      #~ if $CFGbShowHidden;then
        #~ astrCmdWriteTxt+=( -fill red -annotate +0+0 "$strTxt" )
      #~ fi
      astrCmdWriteTxt+=( "jpeg:${strTmpFilePreparing}2" )
      "${astrCmdWriteTxt[@]}"
      SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
    fi
    
    # final step
    SECFUNCexecA -cE mv -f "${strTmpFilePreparing}" "$strTmpFile"
    
    if [[ "$CFGstrCurrentFile" =~ .*LOCKSCREEN[.].* ]];then
      strLockS="$strWallPPath/LOCKSCREEN.IMAGE"
      SECFUNCexecA -cE cp -vf "$strTmpFile" "$strLockS"
      SECFUNCexecA -ce gsettings set org.gnome.desktop.screensaver picture-uri "file://$strLockS";
    fi
    
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
      #~ SECFUNCexecA -cE cp -f "$CFGstrCurrentFile" "$strTmpFile"
    #~ fi
    
		#~ SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "file://$CFGstrCurrentFile";
    nWeek=$((3600*24*7))
    if ! $bPlay;then nSleep=$nWeek;fi #a week trick
    echoc --info "CFGstrCurrentFile='$CFGstrCurrentFile'"
    #strOptZoom="";if $bAllowZoom;then strOptZoom="toggle _zoom if possible (is `SECFUNCternary $CFGbZoom ? echo ON : echo OFF`)\n";fi
    astrOpt=(
      "toggle _auto play mode to conserve CPU (`SECFUNCternary --onoff $bPlay`)"
      "toggle x_BRZ oil paint zoom (`SECFUNCternary --onoff $bXBRZ`)"
      "_change image now"
      "toggle _fast mode (`SECFUNCternary --onoff $bFastMode`)"
      "_disable current"
      "show _hidden toggle (`SECFUNCternary --onoff $CFGbShowHidden`)"
      "toggle fl_ip (`SECFUNCternary --onoff $bFlipKeep`)"
      "allow current on loc_k screen"
      "fi_lter(@s@y$CFGstrFilter@S)"
      "toggle ra_ndom coloring (`SECFUNCternary --onoff $bRandomColoring`)"
      "toggle fl_op (`SECFUNCternary --onoff $bFlopKeep`)"
      "_reset timeout counter ($nSumSleep/$nChangeInterval)"
      "_set image index (`SECFUNCternary test $nSetIndex = -1 ? echo "disabled" : echo "nSetIndex=$nSetIndex"`)"
      "_target zoom at cursor (`SECFUNCternary --onoff $bTargetZoomAtMouse`)"
      "_verbose commands (to debug: `SECFUNCternary --onoff $SECbExecVerboseEchoAllowed`)"
      "fi_x wallpaper pic URI" # lets you set wallpaper outside here while not fixed
      "toggle _zoom if possible (is `SECFUNCternary --onoff $CFGbZoom`)" #"$strOptZoom"
    )
    #~ strOpts="`for strOpt in "${astrOpt[@]}";do echo -n "${strOpt}\n";done`"
    echoc -t $nSleep -Q "@O\n\t`SECFUNCarrayJoin "\n\t" "${astrOpt[@]}"`\n"&&:; nRet=$?; case "`secascii $nRet`" in 
      a)
        SECFUNCtoggleBoolean bPlay
        ;;
      b)
        SECFUNCtoggleBoolean bXBRZ
        ;;
      c)
        bChangeImage=true
        bResetCounters=true
        ;;
      d)
        bOptDisableCurrent=true;
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
      h)
        FUNChiddenToggle
        ;;
      i)
        SECFUNCtoggleBoolean bFlipKeep
        bResetCounters=true
        ;; 
      k)
        bOptAllowCurrentOnLockScreen=true
        ;;
      l)
        FUNCchkUpdateFileList --refill
        SECFUNCarrayShow CFGastrFileList
        declare -p CFGstrFilter
        #TODO for some inexplicable (?) reason, while 's' option will collect text and work fine many times, after this option is selected nothing will output anymore on text prompts `echoc -S`... scary... 8-( ), could be cuz of the @D default option? or even the '(' ')' test more later...
        CFGstrFilter="`echoc -S "Type a regex filter (can be a subfolder name)@D${CFGstrFilter}"`"
        declare -p CFGstrFilter
        FUNCchkUpdateFileList --refill
        if((`SECFUNCarraySize CFGastrFileList`>0));then
          SECFUNCarrayShow CFGastrFileList
          bChangeImage=true;
          bResetCounters=true
          SECFUNCcfgWriteVar CFGstrFilter
        else
          echoc -p "invalid filter, no matches"
          CFGstrFilter=".*"
          FUNCchkUpdateFileList --refill
        fi
        ;;
      n)
        SECFUNCtoggleBoolean bRandomColoring
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
        SECFUNCarrayShow -v CFGastrFileList
        nSetIndex="`echoc -S "set image index"`"
        if SECFUNCisNumber -dn "$nSetIndex" && ((nSetIndex<nTotFiles));then
          bChangeImage=true;
          bResetCounters=true
        else
          echoc -p "invalid nSetIndex='$nSetIndex'"
          nSetIndex=-1
        fi
        ;;
      t)
        SECFUNCtoggleBoolean --show bTargetZoomAtMouse
        ;;
      v)
        SECFUNCtoggleBoolean SECbExecVerboseEchoAllowed
        ;;
      x)
        FUNCsetPicURI
        ;;
      z)
        SECFUNCtoggleBoolean --show CFGbZoom
        SECFUNCcfgWriteVar CFGbZoom
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
