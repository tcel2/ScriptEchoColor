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

: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test
strExample="DefaultValue"
CFGstrTest="Test"
strBaseTmpFileName="_WallPaperChanger-TMP.jpg"
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
	elif [[ "$1" == "--nowrite" ]];then #help do not write the filename to the image
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

# Main code
cd $strWallPPath;

nDelayMsg=3
nTotFiles=0
function FUNCchkUpdateFileList() { #[--refill]
	nTotFiles=${#astrFileList[@]}
	
	if((nTotFiles==0)) || [[ "${1-}" == "--refill" ]];then
		IFS=$'\n' read -d '' -r -a astrFileList < <(find -iregex "$strFindRegex" |grep -v "$strBaseTmpFileName") &&: # re-fill
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
  strTmpFile="$HOME/Pictures/Wallpapers/$strBaseTmpFileName"
  SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "file://$strTmpFile";
  bFlipKeep=false;
  bFlopKeep=false;
  nSetIndex=-1
  nSelect=0
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
        echoc -w -t $nSleep -p "failed selecting file"
        continue
      fi
      
      #TODO auto download wallpapers one new per loop
      
      #excluding current from shuffle list to always have a new one
      unset astrFileList[$nSelect]
    fi
		
    if((nChangeHue!=0));then
      nAddR=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddG=$((RANDOM%(nChangeHue*2)-nChangeHue))
      nAddB=$((RANDOM%(nChangeHue*2)-nChangeHue))
      declare -p nAddR nAddG nAddB
      
      strTmpFilePreparing="${strTmpFile}.TMP" #this is important because the file may be incomplete when the OS tried to apply the new one
      
      if $bChangeImage;then
        bFlipKeep=false; bFlopKeep=false;
        if $bFlip && ((RANDOM%2==0));then bFlipKeep=true;fi
        if $bFlop && ((RANDOM%2==0));then bFlopKeep=true;fi
      fi
    
      SECFUNCexecA -cE convert "$strFile" \
        -colorspace HSL \
                   -channel R -evaluate add ${nAddR}% \
          +channel -channel G -evaluate add ${nAddG}% \
          +channel -channel B -evaluate add ${nAddB}% \
          +channel -set colorspace HSL -colorspace sRGB "${strTmpFilePreparing}"
          
      if $bFlipKeep;then 
        SECFUNCexecA -cE convert -flip "${strTmpFilePreparing}" "${strTmpFilePreparing}2";
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      fi
      if $bFlopKeep;then
        SECFUNCexecA -cE convert -flop "${strTmpFilePreparing}" "${strTmpFilePreparing}2";
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      fi
      
      # grants size preventing automatic from desktop manager
      strOrigSize="`identify "$strFile" |sed -r 's".* ([[:digit:]]*x[[:digit:]]*) .*"\1"'`"
      if [[ "$strOrigSize" != "$strResize" ]];then
        SECFUNCexecA -cE convert "${strTmpFilePreparing}" \
          \( -clone 0 -blur 0x5 -resize $strResize\! -fill black -colorize 15% \) \
          \( -clone 0 -resize $strResize \) \
          -delete 0 -gravity center -composite "${strTmpFilePreparing}2"
        SECFUNCexecA -cE mv -f "${strTmpFilePreparing}2" "${strTmpFilePreparing}"
      fi
      
      if $bWriteFilename;then
        nFontSize=15
        strTxt="`basename "$strFile"` $strOrigSize"
        SECFUNCexecA -cE convert "${strTmpFilePreparing}" -gravity South -pointsize $nFontSize \
          -fill black -annotate +0+$nFontSize "$strTxt" \
          -fill white -annotate +0+0          "$strTxt" \
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
    else
      SECFUNCexecA -cE cp -f "$strFile" "$strTmpFile"
    fi
    
		#~ SECFUNCexecA -ce gsettings set org.gnome.desktop.background picture-uri "file://$strFile";
    bResetCounters=false;
    echoc -t $nSleep -Q "@Otoggle _fast mode/_reset timeout counter/_change image now/_set image index/toggle fl_ip/toggle fl_op"&&:; nRet=$?; case "`secascii $nRet`" in 
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
