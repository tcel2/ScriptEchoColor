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

trap '' HUP # this is required to --say work with terminals that close too fast (secSayStack.sh)

# RECOGNIZED EXPORTED ENVIRONMENT VARIABLES (see --help-extended):
#  SEC_BEEP
#  SEC_IGNORE_LIMITATIONS
#  SEC_DEBUG
#  SEC_HEADEREXEC
#  SEC_FORCESTDERR
#  SEC_CASESENS
#  SEC_SAYALWAYS
#  SEC_SAYVOL
#  SEC_NICE

# !!! THIS LINE BELOW IS COLLECTED AT CREATEPACKAGE
g_nVersion=1.15

##set -u #enforces strong coding
##SECinstallPath=`FUNCgetInstallPath`
#SECinstallPath=`secGetInstallPath.sh`

strMyEmail="teike@users.sourceforge.net"
strSelfName="ScriptEchoColor"
strClrKeyBufMsg="[clrkeybuf1s]"
nClrKeyBufDelay=0.1
strCfgHeader="# $strSelfName $g_nVersion [internal Version Control line]"

: ${SECbAllowUseLastFmt:=false}
if [[ "$SECbAllowUseLastFmt" != "true" ]]; then #compare to inverse of default value
	export SECbAllowUseLastFmt=false # of course, np if already "false"
fi

#TODO look at `man -7 ascii` may be useful

#nStartTime=`date -d "\`ps --pid $$ -o lstart |head -n 2 |tail -n 1\`" +"%s"`
nStartTime=`date +"%s%N"`

# Must be alias because of LINENO
#stdout=" >>/dev/stdout"
stdout=" >&1"
stderr=" >&2"
eval 'tput sc' $stderr # Save current cursor position in case there is line repositioning. It will be restored in the end.
strRestorePos=""

shopt -s expand_aliases
alias _hw='echo -ne "WARNING $strSelfName ${FUNCNAME-}() ln$LINENO: " '$stderr # warning header
alias _he='echo -ne "ERROR(send a bug report) $strSelfName ${FUNCNAME-}() ln$LINENO: " '$stderr # error header
##alias _hi='echo -n  "INFO $strSelfName ${FUNCNAME-}() ln$LINENO: " '$stderr # info header

alias _hi='FUNCmsg "INFO" "${FUNCNAME-}" "$LINENO"'

strUnkownPossibleTermEmuList=""
astrKnownTermEmulators=("gnome-terminal" "konsole" "login" "rxvt")

# test command exit value and show error exit message same way as -x does
strCommandAppendExitTest=';'\
'SEC_nRet=\$?;'\
'if((SEC_nRet!=0)); then '\
' $strSelfName -Rb "\"$strColorProblem [exit \$SEC_nRet] \\\`${strCommandLine-}\\\` \"";'\
' exit \$SEC_nRet;'\
'fi'

# fix invalid environment variables setup
##nHeaderExecSize=7 #default=7 is usefull for ex.: scriptname.sh -> "[scr*.sh]"
##strShortNameComma="shortname,"
##strPidShortNameComma="pidshortname,"
##nSNCSize=${#strShortNameComma}
##nPSNCSize=${#strPidShortNameComma}
##strSopt=""
##if [[ "${SEC_HEADEREXEC:0:nSNCSize}" == "$strShortNameComma" ]]; then
##  strSopt="shortname"
##  nSoptSize=$nSNCSize
##elif [[ "${SEC_HEADEREXEC:0:nPSNCSize}" == "$strPidShortNameComma" ]]; then
##  strSopt="pidshortname"
##  nSoptSize=$nPSNCSize
##fi
##if [[ -n "$strSopt" ]]; then
##  n="${SEC_HEADEREXEC:nSoptSize}"
##  SEC_HEADEREXEC="$strSopt"
##  # if only digits then after comma is a valid integer
##  if [[ -z `echo "$n" |tr -d "[:digit:]"` ]]; then
##    nHeaderExecSize=$(($n))
##  fi
##fi

# Fix wrong values to defaults
case "${SEC_BEEP-}"        in mute | single | extra);; *)SEC_BEEP="single"      ;; esac
case "${SEC_LOG_AVOID-}"   in true | false         );; *)SEC_LOG_AVOID=false    ;; esac
case "${SEC_FORCESTDERR-}" in true | false         );; *)SEC_FORCESTDERR="false";; esac
case "${SEC_CASESENS-}"    in true | false         );; *)SEC_CASESENS="false"   ;; esac
case "${SEC_IGNORE_LIMITATIONS-}" in true | false  );; *)SEC_IGNORE_LIMITATIONS="true";; esac
case "${SEC_SAYALWAYS-}"   in true | false         );; *)SEC_SAYALWAYS="false"   ;; esac
#if((SEC_SAYVOL<0 || SEC_SAYVOL>100)) | [[ -z "$SEC_SAYVOL" ]];then SEC_SAYVOL=100;fi
#if [[ -z "${SEC_SAYVOL-}" ]] || ((SEC_SAYVOL<0));then SEC_SAYVOL=100;fi
if [[ -z "${SEC_NICE-}" ]] || ((SEC_NICE<0)) || ((SEC_NICE>19));then SEC_NICE=0;fi

renice -n $SEC_NICE -p $$ >/dev/null 2>&1

# this fails, why?
#function FUNCps() {
#	echo "DEBUG: ps $@" >&2
#	eval "ps $@"
#};export -f FUNCps;alias ps='FUNCps'

##case "$SEC_HEADEREXEC" in pid  | name   | shortname | pidshortname);; *)SEC_HEADEREXEC=""  ;; esac

# SPEEDUP
#if [[ -z "${SEC_TmpFolder-}" ]];then
#	SECvarCheckScriptSelfNameParentChange=false
#	source <(secinit --core)
#fi
source <(secinit --fast) #secinit is already optimized to be very fast in case it is already initialized properly (with all aliases active)
#set |grep "^SECastr" >&2

strSpeedupFile="$SEC_TmpFolder/.SEC.ScriptEchoColor.Colorizing.SpeedUp.cfg"
if [[   -f "$strSpeedupFile" ]]; then
	if [[ `head -n 1 "$strSpeedupFile"` != "$strCfgHeader" ]]; then
#    mv -v "$strSpeedupFile" "$SEC_TmpFolder/speedup-"`date +%Y%m%d-%H%M%S`".old" 
#    if [[ -f "$strSpeedupFile" ]]; then
#      _he;echo -e "Could not move file '$strSpeedupFile', exiting...\a" >&2
#      exit 1
#    fi
    echo "WARN: $strSelfName: removing old version file." >&2
		rm -vf "$strSpeedupFile"
	fi
fi
if [[ ! -f "$strSpeedupFile" ]]; then
    secPrepareSpeedUp.sh "$strCfgHeader" "$strSpeedupFile"
		#echo "$strCfgHeader" >>"$strSpeedupFile"
		#echo "# DONT change below here, internal config to speed up script execution!" >>"$strSpeedupFile"
		
		###str=`tput sgr0`;if [[ -z "$str" ]]; then str="\033[0m"; fi
		#echo "cmdOff=\""`      echo -e "\E[0m"`"\"" >>"$strSpeedupFile" #`tput sgr0`
		#echo "cmdBold=\""`     echo -e "\E[1m"`"\"" >>"$strSpeedupFile" #`tput bold`
		#echo "cmdDim=\""`      echo -e "\E[2m"`"\"" >>"$strSpeedupFile"
		#echo "cmdUnderline=\""`echo -e "\E[4m"`"\"" >>"$strSpeedupFile" #`tput smul` tput rmul
		#echo "cmdBlink=\""`    echo -e "\E[5m"`"\"" >>"$strSpeedupFile" #`tput blink`
		#echo "cmdReverse=\""`  echo -e "\E[7m"`"\"" >>"$strSpeedupFile"
		#echo "cmdStrike=\""`   echo -e "\E[9m"`"\"" >>"$strSpeedupFile"
 
		##cmdFgBlack=`  tput setaf 0`
		#echo "cmdFgBlack=\""`  echo -e "\E[39m"`"\"" >>"$strSpeedupFile" # 30/39 works better. If used with Bold, black gets gray!
		#echo "cmdFgRed=\""`    echo -e "\E[31m"`"\"" >>"$strSpeedupFile" #`tput setaf 1` setaf (ANSI) instead of setf (bg too), works with "linux" terminal also
		#echo "cmdFgGreen=\""`  echo -e "\E[32m"`"\"" >>"$strSpeedupFile" #`tput setaf 2`
		#echo "cmdFgYellow=\""` echo -e "\E[33m"`"\"" >>"$strSpeedupFile" #`tput setaf 3`
		###str=`tput setaf 4`;if [[ -z "$str" ]]; then str=`echo -e "\033[34m"`; fi
		#echo "cmdFgBlue=\""`   echo -e "\E[34m"`"\"" >>"$strSpeedupFile" #`tput setaf 4`
		#echo "cmdFgMagenta=\""`echo -e "\E[35m"`"\"" >>"$strSpeedupFile" #`tput setaf 5`
		#echo "cmdFgCyan=\""`   echo -e "\E[36m"`"\"" >>"$strSpeedupFile" #`tput setaf 6`
		#echo "cmdFgWhite=\""`  echo -e "\E[37m"`"\"" >>"$strSpeedupFile" #`tput setaf 7`

		#echo "cmdBgBlack=\""`  echo -e "\E[40m"`"\"" >>"$strSpeedupFile" #`tput setab 0`
		#echo "cmdBgRed=\""`    echo -e "\E[41m"`"\"" >>"$strSpeedupFile" #`tput setab 1`
		#echo "cmdBgGreen=\""`  echo -e "\E[42m"`"\"" >>"$strSpeedupFile" #`tput setab 2`
		#echo "cmdBgYellow=\""` echo -e "\E[43m"`"\"" >>"$strSpeedupFile" #`tput setab 3`
		#echo "cmdBgBlue=\""`   echo -e "\E[44m"`"\"" >>"$strSpeedupFile" #`tput setab 4`
		#echo "cmdBgMagenta=\""`echo -e "\E[45m"`"\"" >>"$strSpeedupFile" #`tput setab 5`
		#echo "cmdBgCyan=\""`   echo -e "\E[46m"`"\"" >>"$strSpeedupFile" #`tput setab 6`
		#echo "cmdBgWhite=\""`  echo -e "\E[47m"`"\"" >>"$strSpeedupFile" #`tput setab 7`
 
		#echo "cmdFgLtBlack=\""`  echo -e "\E[90m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtRed=\""`    echo -e "\E[91m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtGreen=\""`  echo -e "\E[92m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtYellow=\""` echo -e "\E[93m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtBlue=\""`   echo -e "\E[94m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtMagenta=\""`echo -e "\E[95m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtCyan=\""`   echo -e "\E[96m"`"\"" >>"$strSpeedupFile"
		#echo "cmdFgLtWhite=\""`  echo -e "\E[97m"`"\"" >>"$strSpeedupFile"
	
		#echo "cmdBgLtBlack=\""`  echo -e "\E[100m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtRed=\""`    echo -e "\E[101m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtGreen=\""`  echo -e "\E[102m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtYellow=\""` echo -e "\E[103m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtBlue=\""`   echo -e "\E[104m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtMagenta=\""`echo -e "\E[105m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtCyan=\""`   echo -e "\E[106m"`"\"" >>"$strSpeedupFile"
		#echo "cmdBgLtWhite=\""`  echo -e "\E[107m"`"\"" >>"$strSpeedupFile"
		
		##GFX tables Hexa/Translation char
		#strTempCharTable=" a  A  b  B  c  C  d  D  e  E  f  F  g  G  h  H  i  I  j  J  k"
		#echo "gfxHexaTable=("`echo "80 81 82 83 8C 8F 90 93 94 97 98 9B 9C A3 A4 AB AC B3 B4 BB BC"`")" >>"$strSpeedupFile"
		#echo "gfxCharTable=("`echo "$strTempCharTable"`")" >>"$strSpeedupFile" #better if unique chars (no repeating)
		#echo "fmtCharTable=("`echo "r g b c m y k w R G B C M Y K W o u d n e l L : a s A S -f -b -l -L -o -u -d -n -e -t -: -a +p"`")" >>"$strSpeedupFile"
		#echo "fmtExtdTable=("`echo "red green blue cyan magenta yellow black white RED GREEN BLUE CYAN MAGENTA YELLOW BLACK WHITE bold underline dim blink strike light LIGHT graphic SaveAll SaveTypeColor RestoreAll RestoreTypeColor -foreground -background -light -LIGHT -bold -underline -dim -blink -strike -types -graphic -ResetAllSettings +RestorePosBkp"`")" >>"$strSpeedupFile"
		#echo "strGfxCharTable=\""`echo "$strTempCharTable" |tr -d " "`"\"" >>"$strSpeedupFile" #to speed up searches
		
		#chmod -w "$strSpeedupFile"
fi
source "$strSpeedupFile"

FUNCmsg(){
	local strHead="$1"
	local strFunc="$2"
	local nLine="$3"
	local strMsg="$4"
	local optEcho="${5-}"
	
	if [[ -z "$strMsg" ]]; then
		strMsg="Debug"
	fi
	
	if [[ -n "$strFunc" ]]; then
		strFunc="$strFunc() "
	fi
	
	if [[ "$strHead" == "INFO" ]]; then
		echo $optEcho "$strHead: $strMsg" >&2
	else
		echo $optEcho "$strHead $strSelfName $strFunc$nLine: $strMsg" >&2
	fi
	
	#SECFUNCechoDbgA "$strHead $strSelfName $strFunc$nLine: $strMsg"
}

#FUNCsetLogFile(){
#    local b=false
#    if [[ "$1" == "--justreturnfilename" ]]; then
#      b=true
#      shift
#    fi
#    
#    local bAuto=true
#    if [[ -z "$strUnformattedFileNameLog" ]] && [[ -n "$1" ]]; then
#      strUnformattedFileNameLog="$1"
#      bAuto=false
#    fi
#    if [[ -z "$strUnformattedFileNameLog" ]] && [[ -n "$SEC_LOG_FILE" ]]; then
#      strUnformattedFileNameLog="$SEC_LOG_FILE"
#      bAuto=false
#    fi
#    if [[ -z "$strUnformattedFileNameLog" ]]; then
#      # automatic log filename creation
#      strUnformattedFileNameLog=`ps -p $PPID -o comm |tail -n 1`".seclog"
#    fi
#    
#    if $b; then
#      echo "$strUnformattedFileNameLog"
#      return 0
#    fi
#    
#    if ! $SEC_LOG_AVOID; then
#      if [[ ! -f "$strUnformattedFileNameLog" ]]; then # inform user the log file is being created
#        local str=`if $bAuto; then echo -n "Automatically c"; else echo -n "C"; fi`
#        _hi "${str}reating log file '$strUnformattedFileNameLog'"
#      fi
#      
#      if ! echo -n >>"$strUnformattedFileNameLog"; then
#        _hw;eval 'echo -e "cannot log to file \"$strUnformattedFileNameLog\". $strCommandWasMsg"' $stderr
#        exit 1
#      fi
#    fi
#}
FUNCshortOptReqArgCheck(){
	local strPreviousOption="$1"
	local strOption="$2"
	local strNextArgument="$2"
	
	if [[ -n "$strPreviousOption" ]]; then
		echo "the option -$strPreviousOption already required an argument, invalid use of option -$strOption"
		return 1
	fi
	
	if [[ -z "$strNextArgument" ]]; then
		echo "option -$strOption requires an argument"
		return 1
	fi
	
	return 0
}
function FUNCifBC () {
	local l_ret=`echo "$1" |bc`; 
	return $((l_ret==0?1:0));
}
optAlert="--alert"
optDebug="--debug"
optEscapedChars="--escapedchars"
optExecuteRetry="--retry"
optGfxE294char="--gfx-E294char"
optGfxMostreliable="--gfx-mostreliable"
optGfxTputmacs="--gfx-tputmacs"
optGuessTermEmulator="--guesstermemulator"
optHelpExtended="--help-extended"
optHelpExtendedInfo="--help-extended-info"
optHelp="--help"
optHelpLGE="$optHelp-list${optGfxE294char:1}"
optHelpLGM="$optHelp-list${optGfxMostreliable:1}"
optHelpLGT="$optHelp-list${optGfxTputmacs:1}"
optHelpLibs="--help-libs"
optHelpListEscape="$optHelp-list-escape"
optHelpListExtdFmt="$optHelp-list-extended-format"
optIdea="--idea"
optInfo="--info"
optInstallPath="--getinstallpath"
optNotify="--notify"
#optLogFileName="--logfilename"
optParentPidList="--parentpidlist"
optRecreateConfigFile="--recreateconfigfile"
optSay="--say"
optWaitSay="--waitsay"
optTest="--test"
#optThereCanOnlyBeOne="--tcobo"
optVersionCheck="--versioncheck"
optVersion="--version"

# Ideas
astrIdea[0]='str="opqrsrqpopqrsrqpopqrsrqpo"; for((n=0;n<${#str};n++));do '"$strSelfName"' '"$optGfxTputmacs"' -ne "@{10:Ryo}a${str:n:1}a\r"; done'
astrIdea[1]='strATempColor=(r g b c m y w);strATempLight=(k d "" l o l "" d);echo;for((nC=0;nC<${#strATempColor[*]};nC++));do for((n=0;n<${#strATempLight[*]};n++));do '"$strSelfName"' -ne "@{40K${strATempColor[nC]}${strATempLight[n]}} @uGO"'"'!'"'"@-u \r"; done; done; echo'
astrIdea[2]="$strSelfName"' "@{10.5Bgo:s}caaaaaad\nb@{-:w}Ready?@{:S}b\neaaaaaaf"'

# options variables
strOptPrecedence="cpqQSwxXvV"
strGfxMode=$optGfxMostreliable

bOptAlert=false
bOptDebug=false
bOptEscapedChars=false
bOptGuessTermEmulator=false
bOptHelp=false
bOptHelpExtended=false
bOptHelpExtendedInfo=false
bOptHelpLGE=false
bOptHelpLGM=false
bOptHelpLGT=false
bOptHelpLibs=false
bOptHelpListEscape=false
bOptHelpListExtdFmt=false

bOptIdea=false
nOptIdea=0

bOptInfo=false
bOptInstallPath=false

bOptNotify=false

#bOptLogFileName=false
bOptParentPidList=false
bOptRecreateConfigFile=false
bOptTest=false
#bOptThereCanOnlyBeOne=false

bOptVersion=false
bOptVersionCheck=false
nOptVersionCheck=0

#strOptThereCanOnlyBeOneCmdPart=""

bAddYesNoQuestion=false
bExecuteAsCommandLine=false
bExecuteRetry=false
bExtendedQuestionMode=false
bForceStdout=false
bKeepColorSettings=false
bKeepPCS=true
bKeepPosition=false
bKillCallerOnExecError=false
bLogDef=false
bLogForce=false
bNormalEchoInterpretEscapeChars=true ##false
bNoWARNBEEP=false
bParentEnvironmentChangeEchoHelper=false
bProblem=false
bSay=false
bWaitSay=false
bShowCaller=false
bStringQuestion=false
bGfxModeOn=false

bUnformatted=false
strUnformatted=""
strUnformattedFileNameLog=""

bWaitAKey=false

bWaitTimeGet=false
fWaitTime=0
nWaitTime=0
strNWaitTime=""

bWARNBEEP=false

output="$stdout"

strEchoNormalOption="e" # Default is to interpret escape characters
strResetAtEnd="$cmdOff"
strString=""

if $SEC_SAYALWAYS; then
	bSay=true
fi
if $SEC_FORCESTDERR; then
	output="$stderr"
fi
#if [[ "${SEC_LOG_DEFAULT-}" == "LOG" ]]; then
#  bLogDef=true
#  FUNCsetLogFile ## "$SEC_LOG_FILE"
#fi
# Command line options
strOpt="${1-}"
chOpt=""
strOptPROBLEM=""
#if [[ -z "$strOpt" ]]; then bOptHelp=true; fi
while [[ "${strOpt:0:1}" == "-" ]]; do
	if [[ "${strOpt:1:1}" == "-" ]]; then
		case "${strOpt:2}" in  # long options ex.: --help
			"") shift # option -- must be skipped before exiting while loop
					break # option -- means here end of options, next arguments taken as normal text
					;;
			"${optIdea:2}")
					shift; nOptIdea="$1"
					if [[ -n `echo "$nOptIdea" |tr -d "[:digit:]"` ]] || ((nOptIdea < 1)) || ((nOptIdea > ${#astrIdea[*]})); then
						strOptPROBLEM="invalid idea '$nOptIdea' index (valid from 1 til ${#astrIdea[*]})"
						break
					fi
					bOptIdea=true
					;;
			"${optInstallPath:2}")
					bOptInstallPath=true
					;;
			"${optTest:2}")
					bOptTest=true
					;;
#      "${optLogFileName:2}")
#          bOptLogFileName=true
#          ;;
			"${optParentPidList:2}")
					bOptParentPidList=true
					;;
			"${optGuessTermEmulator:2}")
					bOptGuessTermEmulator=true
					;;
			"${optEscapedChars:2}")
					bOptEscapedChars=true
					;;
			"${optRecreateConfigFile:2}")
					bOptRecreateConfigFile=true
					;;
			"${optVersion:2}")
					bOptVersion=true
					;;
			"${optVersionCheck:2}")
					shift; nOptVersionCheck="$1"
					if [[ -n `echo "$nOptVersionCheck" |tr -d "[:digit:]."` ]]; then
						strOptPROBLEM="invalid version to check '$nOptVersionCheck'"
						break
					fi
					bOptVersionCheck=true
					;;
			"${optGfxTputmacs:2}")
					strGfxMode="$optGfxTputmacs"
					;;
			"${optGfxE294char:2}")
					strGfxMode="$optGfxE294char"
					;;
			"${optGfxMostreliable:2}")
					strGfxMode="$optGfxMostreliable"
					;;
			"${optHelpLGT:2}")
					bOptHelpLGT=true
					;;
			"${optHelpLGE:2}")
					bOptHelpLGE=true
					;;
			"${optHelpLGM:2}")
					bOptHelpLGM=true
					;;
			"${optHelpListEscape:2}")
					bOptHelpListEscape=true
					;;
			"${optHelpListExtdFmt:2}")
					bOptHelpListExtdFmt=true
					;;
			"${optHelpExtended:2}") 
					bOptHelpExtended=true
					;;
			"${optHelpExtendedInfo:2}") 
					bOptHelpExtendedInfo=true
					;;
			"${optInfo:2}") 
					bOptInfo=true
					;;
			"${optAlert:2}") 
					bOptAlert=true
					;;
			"${optDebug:2}") 
					bOptDebug=true
					;;
			"${optHelpLibs:2}") 
					bOptHelpLibs=true
					;;
			"${optHelp:2}") 
					bOptHelp=true 
					;;
      "${optNotify:2}")
          bOptNotify=true
          ;;
#      "${optThereCanOnlyBeOne:2}")
##          shift; nOptThereCanOnlyBeOnePidSkip=$1
##          if ! ps -p "$nOptThereCanOnlyBeOnePidSkip" >/dev/null 2>&1; then
##            strOptPROBLEM="invalid pid, $nOptThereCanOnlyBeOnePidSkip is not running!"
##            break
##          fi
#          shift; strOptThereCanOnlyBeOneCmdPart="$1"
##          if ! ps -A |grep -q "$strOptThereCanOnlyBeOneCmdPart" \
##             || \
##             [[ -z "$strOptThereCanOnlyBeOneCmdPart" ]]; \
##          then
##            strOptPROBLEM="invalid cmdPart, '$strOptThereCanOnlyBeOneCmdPart' no process has it!"
##            break
##          fi
#          if [[ -z "$strOptThereCanOnlyBeOneCmdPart" ]]; then
#            strOptPROBLEM="requires cmdPart to be searched on proccesses command!"
#            break
#          fi
#          bOptThereCanOnlyBeOne=true
#          ;;
			"${optSay:2}")
					bSay=true
					;;
			"${optWaitSay:2}")
					bSay=true
					bWaitSay=true
					;;
			"${optExecuteRetry:2}")
					bExecuteRetry=true
					;;
			*) strOptPROBLEM="invalid option $strOpt"; break;;
		esac
	else
		chOptReqArg=""
		for((n=1;n<${#strOpt};n++)); do
			chOpt="${strOpt:n:1}"
			case "$chOpt" in # short options ex.: -a -bNk
				"q")  bAddYesNoQuestion=true
							;;
				"Q")  bExtendedQuestionMode=true
							;;
				"S")  bStringQuestion=true
							output="$stderr"
							;;
				"w")  bWaitAKey=true
							;;
				"x")  bExecuteAsCommandLine=true
							;;
				"X")  bExecuteAsCommandLine=true
							bKillCallerOnExecError=true
							;;
				"v")  bParentEnvironmentChangeEchoHelper=true
							output="$stderr"
							;;
				"V")  bParentEnvironmentChangeEchoHelper=true
							bKillCallerOnExecError=true
							output="$stderr"
							;;
				"O")  bForceStdout=true
							output="$stdout"
							;;
				"R")  output="$stderr"
							;;
				"b")  bWARNBEEP=true
							;;
				"i")  trap 'tput sgr0; echo "Interrupted by user (Ctrl+c)"; exit 2' INT
							;;
				"I")  trap 'tput sgr0; echo "Interrupted by user (Ctrl+c), Killing ParentPID ($PPID)!"; ps -p $PPID; kill -SIGKILL $PPID' INT
							;;
				"c")  bShowCaller=true
							;;
				"r")  bKeepPCS=false
							;;
				"u")  bUnformatted=true
							;;
#        "L")  if ! $bLogForce; then
#                if $bLogDef; then # turn off
#                  strUnformattedFileNameLog=""
#                else
#                  FUNCsetLogFile ## "$SEC_LOG_FILE"
#                fi
#              fi
#              ;;
				"k")  strResetAtEnd=""
							bKeepPosition=true
							bKeepColorSettings=true
							;;
				"m")  bNoWARNBEEP=true
							;;
				"n")  strEchoNormalOption=$strEchoNormalOption$chOpt
							;;
				"e")  strEchoNormalOption=$strEchoNormalOption$chOpt
							bNormalEchoInterpretEscapeChars=true
							;;
				"E")  strEchoNormalOption=$strEchoNormalOption$chOpt
							;;
				"p")  bProblem=true
							;;
#	      "l")  shift;strOptArg="$1"
#              strOptPROBLEM=`FUNCshortOptReqArgCheck "$chOptReqArg" "$chOpt" "$strOptArg"`;nRet=$?
#              if(($nRet!=0));then break; fi
#              chOptReqArg="$chOpt"
#              
#              bLogForce=true
#              FUNCsetLogFile "$strOptArg"
#              ;;
				"t")  shift;strOptArg="$1"
							strOptPROBLEM=`FUNCshortOptReqArgCheck "$chOptReqArg" "$chOpt" "$strOptArg"`;nRet=$?
							if(($nRet!=0));then break; fi
							chOptReqArg="$chOpt"
							
							strTest=`echo "$strOptArg" |tr -d "."`
							if (( ${#strTest} < (${#strOptArg}-1) )); then
								strOptPROBLEM="invalid wait time: '$strOptArg', cannot have more than one point '.'"
								break
							fi
							strTest=`echo "$strOptArg" |tr -d ".[:digit:]"` 
							if (( ${#strTest} != 0 )); then 
								strOptPROBLEM="invalid wait time: '$strOptArg', can only contain numbers and one point '.'"
								break
							fi
							
							bWaitTime=true
							fWaitTime="$strOptArg"
							#@@@R nWaitTime=`printf %.0f $fWaitTime`
							#@@@R nWaitTime=`printf %f $fWaitTime` #new bash allows floating point!
							nWaitTime=$fWaitTime #new bash allows floating point!
							#@@@R if ((nWaitTime <= 0)); then
							if FUNCifBC "$nWaitTime <= 0"; then
								strOptPROBLEM="wait time argument to bash read function should be greater than 0"
								break
							fi
							strNWaitTime=" -t $nWaitTime "
							;;
				*) strOptPROBLEM="invalid option -$chOpt"; break;;
			esac
		done
		if [[ -n "$strOptPROBLEM" ]]; then break; fi
	fi
	shift; strOpt="${1-}"
done
# Take care of options problems
if ! $bOptHelp && ! $bOptHelpExtended && ! $bOptHelpExtendedInfo; then
	strBeep="\a"
	if [[ "$SEC_BEEP" == "mute" ]]; then
		strBeep=""
	fi
	if [[ -n "$strOptPROBLEM" ]]; then
		echo -e "$strSelfName ${FUNCNAME-}() ln$LINENO Options PROBLEM: $strOptPROBLEM$strBeep" >&2
		exit 1
	fi
fi

#would require interactivity? anyway not being used...
#nTermCols=`tput cols`
#nTermLines=`tput lines`

FUNCboolFromStrMatch(){
	local str="$1"
	local strCompareTo="$2"
	if [[ "$str" == "$strCompareTo" ]]; then 
		echo "true"
	else
		echo "false"
	fi
}

FUNCexecName(){
	# Find out the executable name from 'ps' command with column 'cmd' only ex.: 
	#  "/bin/bash script.sh" will return "bash"
	local nPid="$1"
	local strLine="${2-}"
	if [[ -z "$strLine" ]]; then
		strLine=`ps -p $nPid -o cmd |tail -n 1`
	fi
	# for each line finds the 1st space and removes the remaining characters, this beggining is the executable :)
	local nPos=`expr index "$strLine" " "`
	if((nPos!=0));then
		strLine="${strLine:0:nPos-1}"
	fi
	basename "$strLine"
}

FUNCscriptName(){
	local nPid="$1"
	local strLine=`ps -p $nPid -o cmd |tail -n 1`
	local strBash="/bin/bash "
	
	#ex.: '/bin/bash ./script.sh -opt1' will result in './script.sh -opt1'
	if [[ "${strLine:0:${#strBash}}" == "$strBash" ]]; then
		strLine="${strLine:${#strBash}}"
	fi
	
	FUNCexecName "" "$strLine"
}

FUNCppidList(){ #TODO add these functionalities to SECFUNCppidList
	local bShowColumnNames=true
	local bOneLineResult=false
##  local bOnlyCommand=false
##  local bOnlyFullCmd=false
	local bOnlyExecName=false
	while [[ -n "${1-}" ]]; do
		case "$1" in
			"hidecolumnnames") bShowColumnNames=false;;
			"onelineresult"  ) bOneLineResult=true;;
##      "onlycommand"    ) bOnlyCommand=true;;
##      "onlyfullcmd"    ) bOnlyFullCmd=true;;
			"onlyexecname"   ) bOnlyExecName=true;;
			*)_hw;echo -e "invalid option \"$1\"" >&2;;
		esac
		shift
	done
	
	local nPPID=$PPID
	local nCount=0
	local strOut=""
	local strProc=""
	local strColumns="pid,ppid,comm,cmd"
##  if   $bOnlyCommand; then
##    strColumns="comm"
##  el
##  if $bOnlyFullCmd; then
##    strColumns="cmd"
##  fi
##  if $bOnlyExecName; then
##    strColumns="cmd"
##  fi
	while ((nPPID != 0)); do
		if $bOnlyExecName; then
			strProc=`FUNCexecName "$nPPID"`
		else
			if((nCount == 0)) && $bShowColumnNames; then  # columns names
				strOut=`ps -o $strColumns |head -n 1`"\n"
			fi
			strProc=`ps -o $strColumns -p $nPPID --no-headers`
		fi
		
		# ATTENTION: above here is using PREVIOUS nPPID
		nPPID=`ps -o ppid -p $nPPID --no-headers`
		
		if((nPPID != 0));then
			strProc="$strProc\n"
		fi
		if $bOneLineResult; then
			strProc="[$strProc] "
		fi
		strOut="$strOut$strProc"
		((nCount++))
	done
	
	if $bOneLineResult; then
		strOut=`echo -e "$strOut"` # convert \n to newline
		echo -n $strOut # remove newlines :D
	else
		echo -e "$strOut"
	fi
}

FUNCguessTermEmulator(){
	# IMPORTANT: this func returns or "termemu" or an array "(\"termemus...\" \"unknown termemus...\")"
	# USAGE ex.: eval 'astr='`FUNCguessTermEmulator`
	# FAILURE TEST: if((${#astr[*]}==2))
	
	local strNL="\n"
	if [[ "${1-}" == "usecomma" ]]; then
		strNL=", "
	fi

	# guess terminal executables
	local strPPIDList=`FUNCppidList onlyexecname`
		
	# remove known ppids that are not terminal emulators
	local strTermEmuList=`echo "$strPPIDList" |grep "\<bash\>|\<init\>|\<mc\>|\<sh\>" -Ev` # with 'sh' a file.sh is also ignored :)
	local nLines=`echo "$strTermEmuList" |wc -l`
	local strLine=""
	local strTermEmu=""
	local strUnkownPossibleTermEmuList=""
	local nValidCount=0
	local n=0
	local n1=0
	local bValid=false
	local strValidList=""

	for((n1=1;n1<=nLines;n1++));do
		# validate
		strLine=`echo "$strTermEmuList" |head -n $n1 |tail -n 1`
		strTermEmu="$strLine"
#  if [[ -z "$strTermEmu" ]]; then # ?
#    echo -n
#    return 1
#  fi
		
		for((n=0;n<${#astrKnownTermEmulators[*]};n++));do
			if [[ "$strTermEmu" == "${astrKnownTermEmulators[n]}" ]]; then
				bValid=true
				((nValidCount++))
				break;
			fi
		done
		
		if $bValid; then
			if((nValidCount > 1)); then
				strValidList="$strValidList$strNL"
			fi
			strValidList="$strValidList$strTermEmu"
			# successfull! return the 1st matching known term emu
			if((n1 == 1)); then
				break
			fi
		else
			if((n1>1)); then
				strUnkownPossibleTermEmuList="$strUnkownPossibleTermEmuList$strNL"
			fi
			strUnkownPossibleTermEmuList="$strUnkownPossibleTermEmuList$strTermEmu"
		fi
		bValid=false
	done

	if [[ -n "$strUnkownPossibleTermEmuList" ]]; then
		echo "(\"$strValidList\" \"$strUnkownPossibleTermEmuList\")"
	else
		echo "($strValidList)"
	fi
}

# last fmt before this execution
strLastFmt=""

FUNCkillSelf(){
	if(($1!=0)); then
		kill -SIGKILL $$
	fi
}
strArgPrefix="_SEC_ARG_PID_"
FUNCargget(){
	source <(secinit --vars)
	local strVar="${1-}"
	if [[ -z "$strVar" ]]; then
		strVar="${strArgPrefix}$PPID"
	fi
	#$SECinstallPath/bin/secargget "$strLastFmtFile" "$strVar" -q #it echoes to stdout
	SECFUNCvarGet "$strVar"
	FUNCkillSelf $?
}
FUNCargset(){ # [varId] <value> #only one parameter means there is only the value
	source <(secinit --vars)
	if [[ -z "${2-}" ]];then
		strVar="${strArgPrefix}$PPID"
		strValue="$1"
	else
		strVar="$1"
		strValue="$2"
	fi
	SECFUNCvarSet "$strVar" "$strValue"
	FUNCkillSelf $?
}
FUNCargclr(){
	source <(secinit --vars)
	local strVar="$1"
	if [[ -z "$strVar" ]]; then
		strVar="${strArgPrefix}$PPID"
	fi
	#$SECinstallPath/bin/secargclr "$strLastFmtFile" "$strVar"
	SECFUNCvarUnset "$strVar"
	FUNCkillSelf $?
}

# Clean invalid (dead) pid's information from arg file
# minimum delay is 60 seconds (1 minute)
nCurrentTime=`date +%s`

#strTermEmulator=""
strPreviousLastFmt=""
if $SECbAllowUseLastFmt;then
	#strTermEmulator=`expr "$(FUNCargget)" : "\(.*\);"` # faster than FUNCguessTermEmulator below..
	strPreviousLastFmt=$(expr "$(FUNCargget)" : ".*;\(.*\)")
fi

# Limitations to Prevents some problems
bLimitColor=false # a
bLimitLight=false # b
bLimitBlink=false # c
bLimitDim=false   # d
bLimitStrike=false # e
bLimitUnderline=false # f
bLimitBold=false  # g
bLimitUseAutoFgBlue=false
# Limitations based on $TERM (dont limit here the matching terminal emulators limitations,
#                             just after these, in case of same name ex.: rxvt)
if [[ "$SEC_IGNORE_LIMITATIONS" == "false" ]]; then
	case "$TERM" in
		"linux") bLimitBold=true;   bLimitDim=true;   bLimitLight=true; 
						 bLimitStrike=true; bLimitUnderline=true;;
#    "rxvt")  bLimitBlink=true;  bLimitDim=true;   bLimitStrike=true; #@@@ limit graphical chars also...
	esac
fi
bCheckForExtraLimitations=false
if $bCheckForExtraLimitations;then #TODO rework this to speed up
	# Extra limitations based on terminal emulator executable
	if [[ -z "$strTermEmulator" ]]; then
		eval 'astr='`FUNCguessTermEmulator usecomma`
		if((${#astr[*]}==1));then
		strTermEmulator="${astr[0]}"
		fi
		if [[ -z "$strTermEmulator" ]]; then
		strTermEmulator="[${astr[1]}]"
		SECFUNCechoWarnA "Unknown term emulator \"$strTermEmulator\", PPIDlist=("`FUNCppidList onelineresult`")"
		fi
	fi
	if [[ "$SEC_IGNORE_LIMITATIONS" == "false" ]]; then
		case "$strTermEmulator" in
		"konsole") bLimitDim=true; bLimitStrike=true; bLimitUseAutoFgBlue=true;;
		"gnome-terminal") bLimitBlink=true;;
		"rxvt")  bLimitBlink=true;  bLimitDim=true;   bLimitStrike=true;; #@@@ limit graphical chars also...
		esac
	fi
fi

strCommandWasMsg=`basename $0`" $@"

FUNCread() {
	#source <(secinit --core) #for SECFUNCisShellInteractive
	#read requires interactiveness.
	if ! SECFUNCisShellInteractive;then
		SECFUNCechoErrA "Shell is NOT interactive! ";
		sleep 60 # this prevents bloated error logs in ex. question mode (-q) and prevents cpu load too TODO explain how
		exit 1 # it is `exit` (and not `return`) on this function because interactivity is critical!
	fi;
	
	if read "$@";then
		return 0
	else
    local lnRet=$?
    if((lnRet<=128));then
      SECFUNCfdReport
      echo "SECERR: 'read' returned error $lnRet" >&2
      exit 1
    fi
		return $lnRet # Exit Status for `read` command: The return code is zero, unless end-of-file is encountered, read times out (in which case it's greater than 128), a variable assignment error occurs, or an invalid file descriptor is supplied as the argument to -u.
	fi
}

FUNCtestIgnore(){
	local strTestIgnore=""
	if $bLimitColor    ; then strTestIgnore="$strTestIgnore""a"; fi
	if $bLimitLight    ; then strTestIgnore="$strTestIgnore""b"; fi
	if $bLimitBlink    ; then strTestIgnore="$strTestIgnore""c"; fi
	if $bLimitDim      ; then strTestIgnore="$strTestIgnore""d"; fi
	if $bLimitStrike   ; then strTestIgnore="$strTestIgnore""e"; fi
	if $bLimitUnderline; then strTestIgnore="$strTestIgnore""f"; fi
	if $bLimitBold     ; then strTestIgnore="$strTestIgnore""g"; fi
	
	if [[ -n "$strTestIgnore" ]] && $strSelfName -Rq "Ignore known limitations tests '$strTestIgnore'@Dy"; then
		echo -n "$strTestIgnore"
	else
		echo -n
	fi
}

# "include" files

# USER CONFIG
strUserCfgFile="$SECstrUserHomeConfigPath/User.cfg"
if $bOptRecreateConfigFile; then
		mv "$strUserCfgFile" "$strUserCfgFile.bkp"
fi
strUserCfgFilePreviousVersion=""
if [[ -f "$strUserCfgFile" ]]; then
	if [[ "`head -n 1 "$strUserCfgFile"`" != "$strCfgHeader" ]]; then
		strUserCfgFilePreviousVersion="$SECstrUserHomeConfigPath/User-"`date +%Y%m%d-%H%M%S`".old" 
		mv -v "$strUserCfgFile" "$strUserCfgFilePreviousVersion"
		if [[ -f "$strUserCfgFile" ]]; then
			_he;echo -e "Could not move file '$strUserCfgFile', exiting...\a" >&2
			exit 1
		fi
    
    echo "WARN: $strSelfName: importing old user config file: $strUserCfgFilePreviousVersion" >&2
		#~ # Ask user to do the import
		#~ _hi "Version does not match, IMPORT old '$strUserCfgFilePreviousVersion' configuration file (yes/...)?" -n
		#~ FUNCread -n 1 strResp&&:;echo >&2; #`echo` to append a new line as read wont do that after we type a key
		#~ if [[ "${strResp-}" != "y" ]]; then
			#~ _hi "Creating '$strUserCfgFile' with default values."
			#~ strUserCfgFilePreviousVersion=""
		#~ fi
	fi
fi
if [[ ! -f "$strUserCfgFile" ]]; then
		astrVariable[ 0]="strColorAddYesNoQuestion"                 ;
		astrValue[    0]="@{LBow} "                
		astrVariable[ 1]="strColorAddYesNoQuestionProblem"          ;
		astrValue[    1]="@{oyR}"           
		astrVariable[ 2]="strColorWaitAKey"                         ;
		astrValue[    2]="@{B} "                            
		astrVariable[ 3]="strColorProblem"                          ;
		astrValue[    3]="@{oyR}"                           
		astrVariable[ 4]="strColorExecuteAsCommandLine"             ;
		astrValue[    4]="@{Cow}"              
		astrVariable[ 5]="strColorParentEnvironmentChangeEchoHelper";
		astrValue[    5]="@{Coy}" 
		astrVariable[ 6]="strHeadProblem"                           ;
		astrValue[    6]="PROBLEM: "                         
		astrVariable[ 7]="strHeadShowCaller"                        ;
		astrValue[    7]="@{owK} @uEXECUTING:@-a@{ogK} "  
		astrVariable[ 8]="strColorOptionKey"                        ;
		astrValue[    8]="@{ug}"                          
		astrVariable[ 9]="strColorOptionKeyDefault"                 ;
		astrValue[    9]="@{uy}"                   
		astrVariable[10]="strColorDefaultStringAnswer"              ;
		astrValue[   10]="@g"                  
		astrVariable[11]="strColorOptionHighlight"                  ;
		astrValue[   11]="@{bYL}"                   
		astrVariable[12]="strColorOptionInfo"                       ;
		astrValue[   12]="@{bW}"                   
		astrVariable[13]="strColorOptionAlert"                      ;
		astrValue[   13]="@{LYnr}"                   

		if ! echo "$strCfgHeader" >"$strUserCfgFile"; then
			_he;echo -e "Cannot create file '$strUserCfgFile', exiting..." >&2
			exit 1
		fi
		echo "# Beware! this file is loaded like a include source file at $strSelfName" >>"$strUserCfgFile"
		echo "# Only change inside the \"\", and test before keeping the settings!" >>"$strUserCfgFile"
		echo "# To restore defaults, just delete this file."        >>"$strUserCfgFile"
		if [[ -n "$strUserCfgFilePreviousVersion" ]]; then
			_hi "Importing your user configuration from previous version file: $strUserCfgFilePreviousVersion"
		fi    
		for((n=0;n<${#astrVariable[*]};n++));do
			strValueDefault="${astrValue[n]}"
			strValue="$strValueDefault"
			
			# importing from previous version
			if [[ -n "$strUserCfgFilePreviousVersion" ]]; then
				strLine=`grep "${astrVariable[n]}=\".*\"" -x "$strUserCfgFilePreviousVersion"`
				if [[ -n "$strLine" ]]; then
					strValuePreviousVersion=`expr "$strLine" : "${astrVariable[n]}=\"\(.*\)\""`;nRet=$?
					if((nRet==0 || nRet==1));then # see exit values for 'expr': info expr
						if((nRet==1)) && [[ -n "$strValuePreviousVersion" ]]; then
							_hi "ERROR using default as found a not expected value to variable: ${astrVariable[n]}=\"$strValuePreviousVersion\""
							strValuePreviousVersion="$strValueDefault"
						fi
						strValue="$strValuePreviousVersion"
						if [[ "$strValue" == "$strValueDefault" ]]; then
							_hi "using default: ${astrVariable[n]}=\"$strValue\""
						else
							_hi "importing different (default is \"$strValueDefault\"): ${astrVariable[n]}=\"$strValue\""
						fi
					else
						_hi "ERROR while executing 'expr' to collect variable value (LINE: \"$strLine\")."
					fi
				else
					_hi "not found, using default: ${astrVariable[n]}=\"$strValue\""
				fi
			fi
			
			echo "${astrVariable[n]}=\"$strValue\"" >>"$strUserCfgFile"
		done
		
		echo >>"$strUserCfgFile"
fi
source "$strUserCfgFile"

FUNCgfxTranslateChar(){
	if (( ${#1} != 1 )); then
		_hw;echo "parameter size must be 1 \"$1\"" >&2
	fi
	if [[ "$1" == ' ' ]]; then 
		echo -n " "
		return
	fi
	local n=`expr index "$strGfxCharTable" "[$1]"` #;local nRet=$?
	((n--))
	if ((n>=0)); then
		echo -en "\xE2\x94\x${gfxHexaTable[n]}"
		return
	fi
	# All other chars are not translated
	echo -n "$1"
}

FUNCgfxTranslateCharE294(){
	if [[ "$1" == ' ' ]]; then 
		echo -n " "
		return
	fi
	if [[ ${1:0:1} == 'x' ]] && 
		 ((`expr "${1:1:1}" : "[0-9a-fA-F]"` != 0)) && 
		 ((`expr "${1:2:1}" : "[0-9a-fA-F]"` != 0)) ; then
		echo -en "\xE2\x94\\$1"
		return
	else
		_hw;echo "invalid Hexa string 0$1" >&2
	fi
	echo -n
}

FUNCtransExtdFmt(){ #translate
	for((n=0;n<${#fmtExtdTable[*]};n++));do
		if [[ "$1" == "${fmtExtdTable[n]}" ]]; then
			echo -n "${fmtCharTable[n]}"
			return
		fi
	done
	_hw;echo "undefined extended format \"/$1\""'!!!' >&2
}

FUNCtranslateColor(){
	local strParam1="$1"

	local fgbg=""
	if   [[ "$2" == "foreground" ]]; then 
		fgbg="Fg"
	elif [[ "$2" == "background" ]]; then 
		fgbg="Bg"
	else 
		echo -n; return;
	fi

	local lt=""
	if [[ "${strParam1:0:5}" == "light" ]]; then
		if ! $bLimitLight; then 
			lt="Lt"
		fi
		strParam1="${strParam1:5}"
	fi

	local param1stupper=`echo -n "${strParam1:0:1}" |tr '[:lower:]' '[:upper:]'`
#	echo "cmd,${fgbg},${lt},${param1stupper},${strParam1}" >&2
	eval echo -n "\$cmd${fgbg}${lt}${param1stupper}${strParam1:1}"
#  case "$strParam1" in
#  	"black")  eval echo -n "\$cmd${fgbg}${lt}Black"  ;return;;
#	  "red")    eval echo -n "\$cmd${fgbg}${lt}Red"    ;return;;
#  	"green")  eval echo -n "\$cmd${fgbg}${lt}Green"  ;return;;
#	  "yellow") eval echo -n "\$cmd${fgbg}${lt}Yellow" ;return;;
#  	"blue")   eval echo -n "\$cmd${fgbg}${lt}Blue"   ;return;;
#	  "magenta")eval echo -n "\$cmd${fgbg}${lt}Magenta";return;;
#  	"cyan")   eval echo -n "\$cmd${fgbg}${lt}Cyan"   ;return;;
#	  "white")  eval echo -n "\$cmd${fgbg}${lt}White"  ;return;;
#  	*)_hw;echo "invalid color name $strParam1" >&2;;
#  esac
}

# HEADER EXEC
strHeaderExec=""
FUNCheaderExecOpt(){
	local strOpt="$1"
	
	local strSep=""
	local strScriptName=""
	local nSize=0
	local nHESHalfSize=0
	local nImpar=0
	local nHeaderExecSize=7 #default=7 is usefull for ex.: scriptname.sh -> "[scr*.sh]"
	if [[ -n "$strHeaderExec" ]]; then 
		strSep="$strHeaderExec:"
	else
		strSep=""
	fi
	
	local strShortNameEqual="shortname="
	local nSNESize=${#strShortNameEqual}
	local n=0
	if [[ "${strOpt:0:nSNESize}" == "$strShortNameEqual" ]]; then
		n="${strOpt:nSNESize}"
		strOpt="shortname"
		# if only digits then after comma is a valid integer
		if [[ -z `echo "$n" |tr -d "[:digit:]"` ]]; then
			nHeaderExecSize=$(($n))
		fi
		if((nHeaderExecSize < 1));then
			nHeaderExecSize=1
		fi
	fi
	
	case "$strOpt" in
		pid      )strHeaderExec="$strSep$PPID";;
		name     )strHeaderExec="$strSep"`FUNCscriptName $PPID`;;
		shortname)
			strScriptName=`FUNCscriptName $PPID`
			nSize=${#strScriptName}
			nHESHalfSize=$((nHeaderExecSize/2))
			nImpar=$(( $((nHeaderExecSize%2)) ?0:1)) #if remainder=0, nImpar=1; if r=1, nImpar=0
##      if((nHESHalfSize==0));then nHESHalfSize=1;fi #minimum size is 1
			if((nHeaderExecSize<=2));then # show just 1st 2 chars
				strScriptName="${strScriptName:0:nHeaderExecSize}"
			else
				if((nSize>nHeaderExecSize));then
					strScriptName="${strScriptName:0:nHESHalfSize}*${strScriptName:nSize-nHESHalfSize+nImpar}"  # nImpar is 0 or 1, and stands for '*' size skip also
				fi
			fi
			strHeaderExec="$strSep$strScriptName"
			;;
	esac
}
if [[ -n "${SEC_HEADEREXEC-}" ]]; then
	strOpt=""
	for((nCount=0;nCount<${#SEC_HEADEREXEC};nCount++));do
		char="${SEC_HEADEREXEC:nCount:1}"
		if [[ "$char" == "," ]]; then
			FUNCheaderExecOpt "$strOpt"
			strOpt=""
		else
			strOpt="$strOpt$char"
		fi
	done
	FUNCheaderExecOpt "$strOpt"
	strHeaderExec="[$strHeaderExec]"
fi
##  case "$SEC_HEADEREXEC" in
##    pid      )strHeaderExec="[$PPID]";;
##    name     )strHeaderExec="["`FUNCscriptName $PPID`"]";;
##    shortname)
##      str=`FUNCscriptName $PPID`
##      nSize=${#str}
##      nHESHalfSize=$((nHeaderExecSize/2))
##      nImpar=$(( $((nHeaderExecSize%2)) ?0:1)) #if remainder=0, nImpar=1; if r=1, nImpar=0
##      if((nHESHalfSize==0));then nHESHalfSize=1;fi
##      if((nSize>nHeaderExecSize));then
##        str="${str:0:nHESHalfSize}*${str:nSize-nHESHalfSize+nImpar}"  # nImpar is 0 or 1, and stands for '*' size skip also
##      fi
##      strHeaderExec="[$str]"
##      ;;
##  esac
##fi

# Fill up user text string
n=0
while [[ -n "${1-}" ]]; do
##  if((n == 0)); then
##    strString="$strHeaderExec$strString"
##  fi
	if((n > 0)); then
		strString="${strString} "
	fi
	strString="${strString}${1}"
	#echo "n=$((n++))" >&2
	((n++))&&: #when n=0, this returns error!!!! :o 
	shift
done

if [[ -n "$strEchoNormalOption" ]]; then
		strEchoNormalOption='-'"$strEchoNormalOption"
fi
bEmptyString=false
if [[ -z "$strString" ]]; then
	bEmptyString=true
fi

# Take care of Options
if $bOptVersion; then
	echo "$strSelfName $g_nVersion"
	exit 0
fi 

if $bOptVersionCheck; then
	nRet=`echo "$g_nVersion >= $nOptVersionCheck" |bc -l`
	if [[ "$nRet" == "1" ]]; then  # to 'bc -l' 1 is 'true' while at script exit code 0 is 'true'
		exit 0
	else
		exit 1
	fi
fi 

if $bOptParentPidList; then
	FUNCppidList
	exit 0
fi

if $bOptGuessTermEmulator; then
	eval 'astr='`FUNCguessTermEmulator` ##'; nRet=$?'
	if((${#astr[*]}==2));then
		$strSelfName "@{yoB}List of unknown possible terminal emulator executables:"
		echo -e "${astr[1]}"
		if [[ -n "${astr[0]}" ]]; then
			echo
			$strSelfName "@{og}Known though:"
			echo -e "${astr[0]}"
		fi
		echo
		$strSelfName "@{ob}Parent Pid list:"
		FUNCppidList
	else
		echo "${astr[0]}" # working as non array here
	fi
	exit $nRet
fi

if $bOptInstallPath; then
	#FUNCgetInstallPath;
	secGetInstallPath.sh
	exit 0
fi

if $bOptTest; then
	strBugReportFile=`$strSelfName -S "Type filename to bug report@D\`pwd\`/ScriptEchoColorBugReport.txt"`
	if [[ -a "$strBugReportFile" ]]; then
		$strSelfName -Q "File @s@g'$strBugReportFile'@S already exists@O_overwrite/_backup@Db";nRet=$?
		if ((nRet==0)); then
			exit 1
		fi
		if [[ `secascii $nRet` == "b" ]]; then
			$strSelfName -x "mv \"$strBugReportFile\" \"$strBugReportFile.bkp\""
		fi
	fi
	if echo -n >"$strBugReportFile"; then
		strTestIgnore=`FUNCtestIgnore`
		astrTests=(a b c d e f g h)
		echo
		if [[ -n "$strTestIgnore" ]]; then
			echo "TESTS (some ignored because already known/reported '$strTestIgnore'):"
		else
			echo "TESTS:"
		fi
		for((n=0;n<${#astrTests[*]};n++));do
			case `echo -n "${astrTests[n]}" |tr -d "$strTestIgnore"` in 
				a)  echo  " (a) COLORS foreground green, background blue"
						$strSelfName "     @{gB}test"
						echo;;
				b)  echo  " (b) COLORS foreground light green, background light blue (if equal to test 'a' then this was unsuccessfull)"
						$strSelfName "     @{lgLB}test"
						echo;;
				c)  echo  " (c) TYPE blink"
						$strSelfName "     normal @ntest"
						echo;;
				d)  echo  " (d) TYPE dim"
						$strSelfName "     normal @dtest"
						echo;;
				e)  echo  " (e) TYPE strike"
						$strSelfName "     normal @etest"
						echo;;
				f)  echo  " (f) TYPE underline"
						$strSelfName "     normal @utest"
						echo;;
				g)  echo  " (g) TYPE bold"
						$strSelfName "     normal @otest"
            echo;;
        h)  echo  " (h) ALL COLORS"
            aColorList=(r g b c m y k w R G B C M Y K W);
						$strSelfName -n "     "
            for strColor in "${aColorList[@]}";do 
              $strSelfName -n "@{${strColor}}$strColor";
              $strSelfName -n "@{${strColor}o}$strColor";
              $strSelfName -n "@{${strColor}d}$strColor";
              $strSelfName -n "@{${strColor}lL}$strColor";
            done
            echo;;
			esac
		done
		echo
		strTestLetter=`$strSelfName -S "Type the letters of the unsuccessfull tests to this terminal"`
		
		if [[ -n "$strTestLetter" ]]; then
			# prepare bug report file
			echo "$strCfgHeader"                                >>"$strBugReportFile"
#      echo "DateTimeZone=\""`date "+%Y/%m/%d %H:%M:%S %z %Z"`"\"" >>"$strBugReportFile"
			echo "EnvTERM=\"$TERM\""                            >>"$strBugReportFile"
			echo "TermLongname=\""`tput longname`"\""           >>"$strBugReportFile"
			echo "Unsuccessfull=\"$strTestLetter\""             >>"$strBugReportFile"
			
			echo "# results below based on $strSelfName $optGuessTermEmulator" >>"$strBugReportFile"
			eval 'astr='`FUNCguessTermEmulator usecomma`
			if((${#astr[*]}==2)); then
				echo "UnknownPossibleTermEmulatorExecutables=\"${astr[1]}\"" >>"$strBugReportFile"
			fi
			echo "KnownTermEmulatorExecutables=\"${astr[0]}\""             >>"$strBugReportFile"
		
			$strSelfName -x "cat \"$strBugReportFile\""
			echo
			$strSelfName "@bPlease email the file @g'$strBugReportFile'@b to @g'"`gawk '{gsub(/@/,"@@",$0);print $0}' <<<"$strMyEmail"`"'@b, thanks."
		fi
	fi
##  shift #?
	exit 0
fi

strExtraQModeExmpl="$strSelfName "'-Q "question@O_one/_two/answer__t_hree@Dt"&&:; nRet=$?; case "`secascii $nRet`" in o)echo 1;; t)echo 2;; h)echo 3;; *)if((nRet==1));then SECFUNCechoErrA "err=$nRet";exit 1;fi;; esac' #TODO this is too much, if pressing an F-key like F7 should not be an error, just return normally: *)if((nRet<0x20||nRet>0x7E));then SECFUNCechoErrA "invalid `secasciicode --hexa "$nRet"`";exit 1;fi;; esac' 
if $bOptHelp; then
		echo "$strSelfName version $g_nVersion"
		echo "usage: $strSelfName [-<c|x|X|v|V|q|Q|S|w|p><pmORbrktulLiI>] [-enE] [\"string\""]
		echo
		echo "Main options:"
		echo " -c show caller"
		echo " -x execute string as command line"
		echo " -X execute string as command line and kill ParentPID on error (BEWARE)"
		echo " -v echo and help change environment (see $optHelpExtended) ex.: \"cd ..\""
		echo " -V echo and help change environment, with exit command BEWARE (see $optHelpExtended)"
		echo " -q question mode"
		echo " -Q extra question mode ex.: ${strExtraQModeExmpl}"
		echo " -S question mode where you can type a String"
		echo " -w wait mode"
		echo " -p problem mode"
		echo " (do not use toguether, but auto choice precedence is: $strOptPrecedence)"
		echo
		echo "Options that can be combined with main options:"
		echo " -p problem mode, can only be combined with main options -q or -w"
		echo " -n -e -E bash echo options, see 'help echo'"
		echo " -m Mute beep"
		echo " -O ensure output to /dev/stdout"
		echo " -R send output to /dev/stderr"
		echo " -b Beep (see also SEC_BEEP)"
		echo " -r reset previous settings"
		echo " -k keep settings after end (color settings and position) (requires: export SECbAllowUseLastFmt=true;)"
		echo " -t <value> time to wait before continuing"
		echo " -u output Unformatted"
#    echo " -l <logfile>: append unformatted text to logfile file"
#    echo " -L: append unformatted text to logfile file at SEC_LOG_FILE (or default)"
		echo " -i trap SIGINT"
		echo " -I trap SIGINT and kill ParentPID (BEWARE)"
		echo " -- arguments after this are taken as normal text"
		echo
		echo "Extra Options:"
    strExpand="expand --tabs=30"
		echo -e " $optHelp\tthis \"short\" help" |$strExpand
		echo -e " $optHelpListEscape\techo escape functionalities" |$strExpand
		echo -e " $optHelpLGM\tcommon? chars between most terminal types" |$strExpand
		echo -e " $optHelpLGT\tall macs chars" |$strExpand
		echo -e " $optHelpLGE\tall escaped \\\\xE2\\\\x94\\\\xHEXA chars" |$strExpand
		echo -e " $optHelpListExtdFmt\textended format list" |$strExpand
		echo -e " $optHelpLibs\tshow help info about libs functions" |$strExpand
		echo -e " $optHelpExtended\textended help/usage information and examples!" |$strExpand
		echo -e " $optHelpExtendedInfo\tsame as extended help but shown with \`| less -R\`" |$strExpand
		echo -e " $optInfo\teasy info coloring" |$strExpand
		echo -e " $optAlert\teasy alert coloring" |$strExpand
		echo -e " $optTest\ttest terminal capabilities and helps to bug report" |$strExpand
		echo -e " $optInstallPath\tusefull to source libs on your scripts" |$strExpand
		echo -e " $optParentPidList\tshow a list of the parent pids (parent of parent of...)" |$strExpand
		echo -e " $optGuessTermEmulator\tshow the parent executable name guessed as terminal emulator that is running $strSelfName" |$strExpand
		echo -e " $optEscapedChars\tshow what you would use with 'echo -e'" |$strExpand
		echo -e " $optVersion\tshow just \"$strSelfName $g_nVersion\" then exits" |$strExpand
		echo -e " $optVersionCheck\t<Version> return '0' on 'current version' >= required 'Version', otherwise return '1'" |$strExpand
		echo -e " $optIdea\t<Index> executes one of the available usage ideas (1 til ${#astrIdea[*]})" |$strExpand
#    echo -e " $optLogFileName show the log file name being used (also automatic one)"
		echo -e " ${optGfxMostreliable}\t(it is the default) use most realiable gfx chars trans. table" |$strExpand
		echo -e " ${optGfxTputmacs}\tuse tput smacs/rmacs gfx chars mode" |$strExpand
		echo -e " ${optGfxE294char}\tuse full gfx translation table" |$strExpand
		echo -e " ${optRecreateConfigFile}\twill remove $strUserCfgFile to be recreated with defaults" |$strExpand
#    echo -e " ${optThereCanOnlyBeOne} <cmdPart>: 'There Can Only Be One' looks for another proccess having cmdPart (ex.: \"\`basename \$0\`\") on its command; skips this caller recursive parents pids; usage: call from a script to prevent it from running if another instance of it is already running."
		echo -e " ${optSay}\tuse festival to say the text!" |$strExpand
		echo -e " ${optWaitSay}\tlike ${optSay} but wait until speech ends before exiting." |$strExpand
		echo -e " ${optNotify}\tuse the notification system." |$strExpand
		echo -e " ${optExecuteRetry}\tin conjunction with -x or -X, will ask if you want to retry the failed command." |$strExpand
		echo 
		echo "String format summary (@/@{}):"
		echo " @{:}     \"graphics\" mode"
		echo " @{asAS}  save RESTORE settings"
		echo " @{0123456789.0123456789} absolute terminal position @{column.line}"
		echo " @{rgbcmykwRGBCMYKW}      foreground BACKGROUND colors"
		echo " @{oudnelL} bold/underline/dim/blink/strike/light/BACKGROUNDLIGHT types"
		echo " @{-f-b-l-L-o-u-d-n-e-t-:-a} cancel modes"
		echo " @{--} begin ignoring all formatting"
		echo " @++ (must be used this way: '@++') end ignoring all formatting"
		echo " @{+p} restore backup position"
		echo " @{/.../...} extended formatting (see the list with option $optHelpListExtdFmt), must come as the end of commands within @{}"
		echo 
		echo "Observation: the default is to interpret escape characters, to disable it use -E"
		exit 0
fi

if $bOptHelpExtendedInfo;then
	$strSelfName $optHelpExtended |less -R
	exit 0
fi

if $bOptHelpExtended; then
		$strSelfName "@{Gow} Script @kEcho @rC@go@bl@co@yr @w(echoc) $g_nVersion Extended Help "
		echo
		echo "Simple symbolic link name \"echoc -> $strSelfName\""
		echo
		echo "The default color/type behavior is to next argument inherit previous settings."
		echo "Warning and error messages are sent to /dev/stderr so there will be no problems"
		echo "at collecting $strSelfName normal output."
		echo
		echo "Color formatting was chosen to not conflict with script and printf rules:"
		echo " by using '@{.}'  instead of %<;> \${,} #(*) etc."
		echo
		$strSelfName "@{ou}$strSelfName Main Parameters (Cannot be Combined):"
		echo " If background color is chosen but foreground color is not, "
		echo " foreground color it will default to black or light white based on best contrast."
		echo " -c Caller: Show Parent caller command line based on \"ps\" output to parent PID."
		echo "    added to beggining of string parameter"
		echo -n "    ex.: ";$strSelfName -c
		echo
		echo " -x Execute Mode: will echo and execute the resulting string as command line!!! "
		echo "    will use color blue as foreground"
		echo "    string will be executed with bash \"eval\" "
		echo "    exit with exit value of executed 'string'"
		echo "    will show exit value as: \"string [exit 0]\""
		echo "    at script capture it like:"
		echo "     if $strSelfName -x \"ps -p $PPID\"; then ...; fi"
		echo
		echo " -X same as -x"
		echo "    and will issue command \"kill -SIGKILL \$PPID\" so BEWARE"
		echo "    as this kills the parent process."
		echo
		echo " -v echo and help change environment (color set is same of -x)"
		echo "    usage ex.:"
		strCmdLine="cd .."    
		echo "      \`$strSelfName -v \"$strCmdLine\"\`"
		echo "    outputs to $stderr the formatted text"
		echo "    outputs to $stdout the unformatted text that will be executed "
		echo "      at parent environment"
		echo "    obs.2: some specific commands and multiple commands require \"eval\" ex.:"
		echo "      eval \`$strSelfName -v \"$strCmdLine;ls\"\`"
		echo "    obs.3: if there is more than one space as value on the command, to avoid"
		echo "     the multiple spaces being shrank to one space, you must prepare the"
		echo "     command this way ex.:"
		echo "      eval \"\`$strSelfName -v 'str=\"abc    def\"'\`\""
		echo "     or"
		echo '      eval "`'$strSelfName' -v \"str=\\\"abc    def\\\"\"`"'
		echo "     or in case of ex. str2='a  b  c':"
		echo "      eval \"\`$strSelfName -v 'str=\"'\"\$str2\"'\"'\`\""
		echo
		echo " -V same as -v but"
		echo "    Echo and help change environment, with 'exit' command."
		echo "    It allows parent exit on error but without killing it, anyway BEWARE."
		echo "    usage ex.:"
		echo "      eval \`$strSelfName -V \"$strCmdLine\"\`"
		echo "    this option always require \"eval\" because exit test is appended to your"
		echo "      \"command\", so the output to $stdout becomes:"
		eval echo "\"      \\\"$strCmdLine$strCommandAppendExitTest\"\\\""
		echo "    this may be an advantage over -X option as your script will exit with"
		echo "      the exit value of the executed \"command\"."
		echo
		echo " -q Question Mode: will add \" (y/...)?\" to the end of the string and"
		echo "    exit 0 case y and 1 otherwise, at script capture it like:"
		echo "     if $strSelfName -q \"Ready\"; then ..."
		echo "    will also begin with @{lbu} underlined light blue"
		echo "    You can use arrow keys (up/down/left/right) to access options, "
		echo "     then press Enter/Esc. Only good if one line question."
		echo '    @Dy: at end, sets the "y" option as the default one, even on space/enter press'
		echo
		echo " -Q Extended Question Mode:"
		echo "    These tokens are at the end of the string."
		echo "    @O: put after this the option words"
		echo "    _: the character after this is considered as an option key"
		echo '    "@@O" and "__" expands to "@O" and "_"'
		echo "    @D: the character after this will be the default key"
		echo "     it is optional and must be at the very end of the string"
		echo '    Use this command `secascii $?` just after '"$strSelfName call"
		echo "    Options must be unique (do not repeat keys)"
		echo "    OBS.: Invalid keys will return 0 (true) in oposition to normal options that return non 0 (false)"'!!!'
		echo "    example:"
    echo "    ${strExtraQModeExmpl}"
		echo
		echo " -S Question mode where you can type a string"
		echo "    @D: begins ending string part with default answer string"
		echo "    its normal output will be sent to /dev/stderr"
		echo "    and the typed string will be sent to /dev/stdout"
		echo "    so the typed text can be assingned to a variable ex.:"
		echo '    strName=`'"$strSelfName"' -S "Type the name@DName"`; echo "$strName"'
		echo " Obs.: to question modes, will be shown this $strClrKeyBufMsg that tells to "
		echo "       user to wait $nClrKeyBufDelay second to keyboard buffer be cleared before begin"
		echo "       typing the answer."
		echo
		echo " -p Problem Mode: this will add "
		echo "    \"@{lyR}PROBLEM: \" to beggining of string (light yellow on Red background)"
		echo "    and will execute a warn beep"
		echo "    its output will go to /dev/stderr"
		echo "    to force output to default (/dev/stdout) use option -f"
		echo "    OBS.: this option can mix with -q OR -w"
		echo -n "    ex.: ";$strSelfName -pm "example!"
		echo
		echo " -w Wait: for any key press before continue normal execution (also beeps)"
		echo "    it adds \", press any key to continue...\" to the end of string"
		echo "    fg is black and bg is green"
		echo
		echo " -n -e -E: like bash echo options, see at bash 'help echo'"
		echo
		$strSelfName "@{ou}$strSelfName Extra Parameters (Can be combined with Main or Extra parameters):"
		echo " -m Mute: any preset beep modes"
		echo
		echo " -b Beep: execute a warn beep (see SEC_BEEP)"
		echo
		echo " -O Force output to default (/dev/stdout) even in case of -p Problem message mode"
		echo
		echo " -R Force output to /dev/stderr"
		echo
		echo " -r Reset: color setting previously to set any new one"
		str="$strSelfName -r \"@{gKuo}A@bB\""
		echo "    ex.: $str"; echo "         "`eval "$str"`
		echo
		echo " -k Keeps: last color/type/position settings after execution of $strSelfName"
		echo
		echo " -t <value>: sleep for <value> time before exiting. It can be a floating"
		echo "    point but must be integer if combined with -q."
		echo
		echo " -u Unformatted: print plain text without any color and type formats, usefull like:"
		echo "    str=\"@{Bows} processing file @y\$1 @Swith @g\$2 \""
		echo "    $strSelfName \"\$str\""
		echo "    $strSelfName -u \"\$str\" >application.log"
		echo
#    echo " -l <logfile>: output normal formatted text (unless you also use -u) and append "
#    echo "    unformatted to logfile file (create it if not exist)"
#    echo "    this option has priority over -L"
#    echo
#    echo " -L Log: output normal formatted (unless you also use -u) text and append "
#    echo "    unformatted to logfile SEC_LOG_FILE (create it if not exist)."
#    echo "    If SEC_LOG_FILE is not set, a default is created with parent pid name:"
#    echo "     \`ps -p \$PPID -o comm |tail -n 1\`\".seclog\""
#    echo "     to work properly, the parent pid script must begin with '#!/bin/bash'"
#    echo "    It also works AGAINST default behavior (OFF), let me explain:"
#    echo "     if you want all calls to $strSelfName to be logged to file,"
#    echo "     set the environment variable SEC_LOG_DEFAULT (see next help session),"
#    echo "     this way you won't need to add the option -L to all $strSelfName calls"
#    echo "     and when you do, that call won't be logged."
#    echo
		echo " -i trap interrupt: kill signal INT (SIGINT), so Ctrl+c will show message,"
		echo "    but wont exit from caller script."
		echo
		echo " -I trap Interrupt: kill signal INT (SIGINT), so Ctrl+c will show message,"
		echo "    and will issue command \"kill -SIGKILL \$PPID\" so BEWARE as this kills"
		echo "    the parent process."
		echo "    OBS.: if not used -i and -I, Ctrl+c will SIGINT parent normally."
		echo
		echo " -- consider next arguments as normal text ex.:"
		str="$strSelfName -- -x -b are some of $strSelfName options"
		echo "    $str"; echo "         "`eval "$str"`
		echo
		$strSelfName "@{ou}Recognized environment variables (use with 'export'):"
#    echo "    Logfile is setup at exported environment variable at your script ex.:"
#    echo "     export SEC_LOG_FILE=\"$HOME/temp/messages.log\""
#    echo
#    echo "    Log default is to NOT log. To turn it on do this:"
#    echo "     export SEC_LOG_DEFAULT=\"LOG\""
#    echo "     to turn off again just set it empty (\"\")"
#    echo
#    echo "    To avoid all logs, set this:"
#    echo "     export SEC_LOG_AVOID=\"true\""
#    echo "     to turn off again just set it empty (\"\")"
#    echo
		echo "    Beep mode:"
		echo "     export SEC_BEEP=\"mute\"  "
		echo "     export SEC_BEEP=\"single\"  (this is the default)"
		echo "     export SEC_BEEP=\"extra\" "
		echo
		echo "    Show at beggining of each output of $strSelfName, a header:"
		echo "    (Usefull for scripts inside other scripts)"
		echo "    (default shortname=7 ex.: scriptname.sh -> \"[scr*.sh]\")"
		echo "     export SEC_HEADEREXEC=\"pid\" "
		echo "     export SEC_HEADEREXEC=\"name\" "
		echo "     export SEC_HEADEREXEC=\"shortname\" "
		echo "     export SEC_HEADEREXEC=\"shortname=10\" "
		echo "     export SEC_HEADEREXEC=\"pid,shortname\" (this one looks good)"
		echo
		echo "    Ignore Color Limitations by TERM type and emulator:"
		echo "     export SEC_IGNORE_LIMITATIONS=\"true\""
		echo
#    echo "    Debug mode will fill up (no limits) the file \"$strFileDebug\""
#    echo "     export SEC_DEBUG=\"true\""
#    echo
		echo "    Enforce all output of $strSelfName to go to /dev/stderr."
		echo "    (usefull to collect your script normal output, just 'echo', as data, "
		echo "    while all calls to $strSelfName shall output to /dev/stderr)"
		echo "     export SEC_FORCESTDERR=\"true\""
		echo
		echo "    Case sensitive to question modes -q -Q"
		echo "     export SEC_CASESENS=\"true\""
		echo "     obs.: if 'false' with -Q, returned letters are in lower case"
		echo
		echo "    Say text always:"
		echo "     export SEC_SAYALWAYS=\"true\""
		echo
		echo "    Say text, see: secSayStack.sh --help"
		echo
		echo "    Default nice:"
		echo "     export SEC_NICE=0 #from 0 to 19"
		echo
		$strSelfName "@{ou}Color Functionality:"
		echo " If using multiple arguments mode @{...}, last option will overhide "
		echo " previous ones ex.: @{ywbRGK} will result blue fg on black bg"
		echo "  s/S = will save/restore color and type settings"'!'
		echo "  a/A = will save/restore all settings (=sS + gfx mode + position)"'!'
		echo "  rgbcmywk = red grren blue cyan magenta yellow white black"
		echo "  RGBCMYWK = (background colors)"
		echo "  oudnelL = underline bold(it is also light mode) dim blink(linux console) strike lightForeground LightBackground"
		echo "  -o = cancel bold"
		echo "  -u = cancel underline"
		echo "  -d = cancel dim"
		echo "  -n = cancel blink"
		echo "  -e = cancel strike"
		echo "  -t = cancel all types (equal to '-o-u-d-n-e')"
		echo "  -f = cancel foreground"
		echo "  -b = cancel background"
		echo "  -l = cancel light to foreground"
		echo "  -L = cancel light to background"
		echo "  -a = cancel everything (it is '-t-f-b-:' and some more internal things)"
		echo "  +p = restore only backup position (last sucessfully configured position)"
		echo "  -- = begin ignoring all formatting"
		echo "  ++ = (must be used this way: '@++') end ignoring all formatting"
		echo "  @@ or \@ expands to '@', skipping color formatting functionality"
		echo "  /... = extended format mode (instead of 'o' type /bold etc...)"
		echo "         must come after short format mode, or alone @{go/underline/BLUE}"
		echo "         see also $optHelpListExtdFmt"
		echo
		echo " EXAMPLES:"
		str="$strSelfName \"ABC @gDEF@-a GHI\""
		echo "  $str"; echo "         "`eval "$str"`
		str="$strSelfName \"ABC @{ogBu}DEF@-a GHI\""
		echo "  $str"; echo "         "`eval "$str"`
		str="$strSelfName \"ABC @@ \@ DEF\""
		echo "  $str"; echo "         "`eval "$str"`
		str="$strSelfName \"@GA @{ro}B @uC @-tD @-fE @-bF\""
		echo "  $str"; echo "         "`eval "$str"`
		str="$strSelfName \"@{oguKs}abc@{-aB} def @Sghi\""
		echo "  $str"; echo "         "`eval "$str"`
		str="$strSelfName \"@{o/green/BLACK/underline/SaveTypeColor}abc@{/-ResetAllSettings/BLUE} def @{/RestoreTypeColor}ghi\""
		echo "  $str"; echo "         "`eval "$str"`
		echo "  Lets simulate a flag:"
		str="$strSelfName \"@{yoG}<@bo@y>\""
		echo "  $str"; echo "         "`eval "$str"`
		echo
		$strSelfName "@{ou}Graphic Chars Functionality:"
		echo " after @ use : to begin and -: to end"
		str="$strSelfName \"@:"`echo "${gfxCharTable[*]}" |tr -d " "`"\""
		echo " $str"; echo "                    "`eval "$str"`
		str="$strSelfName ${optGfxTputmacs} \"@:ajklmnopqrstuvwx@-:\""
		echo " $str"; echo "$(printf %${#optGfxTputmacs}s)                     "`eval "$str"`
		echo " see also options:" 
		echo "  $optHelpLGM"
		echo "  $optHelpLGT"
		echo "  $optHelpLGE"
		echo
		$strSelfName "@{ou}Position Funcionality:"
		echo " n1 = column (good for indentation)"
		echo ' n1.n2 = column.line (good for mini application development)'
		echo " ex.: "
		echo "  $strSelfName \"@{7r}abc\"    will print, in red, abc at absolute column 7 of current line"
		echo "  $strSelfName \"@{10.3r}abc\" will print, in red, abc at absolute column 10 line 3"
		echo "  $strSelfName \"@{.5r}abc\"   will print, in red, abc at absolute column 0 line 5"
		echo ' obs.: if you set a column and use "\n" within string, next line will start at last set column!'
		echo
		$strSelfName "@{ou}Tips:"
		echo " To make tags easy to read, prefer using always @{...} instead of @..."
		echo " While learning, at beggining, use extended format mode. Later on, change to short mode."
		echo 
		$strSelfName "@{ou}Ideas:@-t Run and Watch (some may fail..) "
		for((n=0;n<${#astrIdea[*]};n++));do
			echo -ne "\t$((n+1))) "; echo "${astrIdea[n]}"
		done
		$strSelfName "\t@{ou}Obs.:@-u 3rd idea will create a box using graphic chars!"
		echo
		exit 0
fi

if $bOptHelpListEscape; then
	$strSelfName -E '@gecho -e "\033[${n}mTEXT\033[0m"'
	for((n=0;n<=255;n++));do 
		echo -en `printf "%3d" $n`"=(\033[${n}mAb\033[0m)\t"
		if((n%5==0)); then 
			echo
		fi
	done
	echo
	exit 0
fi

if $bOptHelpLGM; then
		$strSelfName "@gHexa: $strGfxHexaMostRealiable"
		nGfx=${#gfxHexaTable[*]}
		echo "Translation Table \"Hexa = (Translate Char) = Gfx\" (Total $nGfx):"
		echo "Lower case stands for single line and upper to double lines."
		echo "This is the most realiable because you will see the same results at xterm and linux terminals."
		echo "${optGfxMostreliable} is the default setting"'!'
		for((n=0;n<nGfx;n++));do
	echo -e "${gfxHexaTable[n]} = (${gfxCharTable[n]}) = \xE2\x94\x${gfxHexaTable[n]}"
		done
		echo
		exit 0
fi

if $bOptHelpLGT; then
		$strSelfName "@bDecimal=Octal=NormalChar=(macsChar)"
		$strSelfName "@gTo access Octal, use as: $strSelfName -e \"@@.\0260\""
		echo " it uses \`tput smacs\` and \`tput rmacs\`"
		for((n=0;n<256;n++)); do 
	nO=`printf %o $n`
				echo -ne "$n=0$nO=\\$nO"$cmdOff"=("`tput smacs`"\\$nO"`tput rmacs`")\t"
	if((n%5==0));then 
			echo $cmdOff
	fi
		done
		echo $cmdOff
		exit 0
fi

if $bOptHelpLGE; then
		$strSelfName -E '@gecho \xE2\x94\xHEXA'
		$strSelfName "@gDecimal=Hexadecimal=(resulting char)"
		for((n=0;n<=255;n++));do 
	echo -en `printf %3d=%3X $n $n`"=(\xE2\x94\x"`printf "%X" $n`")\t\033[0m"
	if((n%5==0)); then 
			echo
	fi
		done
		echo
		exit 0
fi

if $bOptHelpListExtdFmt; then
		$strSelfName "@gShortFormat = /LongFormat"
		for((n=0;n<${#fmtCharTable[*]};n++));do
      str=`printf %2s "${fmtCharTable[n]}"`
      echo -e "$str\t= /${fmtExtdTable[n]}"
		done
		echo
		exit 0
fi

if $bOptIdea; then
	$strSelfName "@dIdea $nOptIdea"
	n=$((nOptIdea-1))
	
	$strSelfName -k -n "@b";echo -n "${astrIdea[n]}";$strSelfName
	eval "${astrIdea[n]}"
	echo
	
	exit 0
fi

if $bOptHelpLibs; then
	#strInfo="(all functions are prefixed with: \"SECFUNC\", ex.: SECFUNCshowVar())"
	echo "HELP on Libs functions:"
	echo
	#echo "$strInfo"
	echo "at: $SECinstallPath/lib/$strSelfName"
	
	cd "$SECinstallPath/lib/$strSelfName"
	
	#function FUNCechoPipe() {
	#	FUNCread str
	#	echo -en "$str"
	#};export -f FUNCechoPipe
	function FUNCtoFind() { 
		echo "File: ${1:2}"; #remove heading "./"
		sedGatherHelpText='s"function \(SECFUNC[[:alnum:]].*()\).*#help: \(.*\)"  \1\t\2"';
		sedTranslateNewLine='s"[\]n"\n"g'
		sedTranslateTab='s"[\]t"\t"g'
		#grep "function SECFUNC.*#help:" "$1" |sed "$sedGatherHelpText" |FUNCechoPipe;
		grep "function SECFUNC.*#help:" "$1" |sed "$sedGatherHelpText" |sed "$sedTranslateNewLine" |sed "$sedTranslateTab";
	};export -f FUNCtoFind
	find ./ -iname "*.sh" -exec bash -c 'FUNCtoFind "{}"' \;
	 
	#echo "$strInfo"
	
	exit 0
fi

#FUNCthereCanOnlyBeOne(){
#  # tcobo, good it be a function so all var names are kept local!
#  
#  local pidToSkip=$$ # begin skiping $$ that is this proccess! and so who called it and so on...
#  local runCommandToCheck="$1"
#  # not fail safe...
#  #local runCommandToCheck=`ps -o command -p $pidToSkip |tail -n 1`
#  #runCommandToCheck="`basename \"$runCommandToCheck\"`"
#  
#  local pid=$pidToSkip
#  local ppidListToSkip="$pidToSkip"
#  local sedTrimDigits='s"[ ]*\([[:digit:]]*\).*"\1"'
#  
#  while true; do
#    local ppid=`ps -o ppid -p $pid 2>&1 |tail -n 1 |sed "$sedTrimDigits"`
#    if((ppid==0));then 
#      break; 
#    fi
#    ppidListToSkip="$ppidListToSkip\|$ppid"
#    pid=$ppid
#  done
#  
#  #egrep does not work with more than 2 ors
#  local sedClearPPidListToSkipLines='s"^[ ]*\('"$ppidListToSkip"'\) .*""'
#  #echo "$sedClearPPidListToSkipLines" "$runCommandToCheck" >&2 #@@@ comment out
#  if ps -A -o pid,command \
#     |grep -v grep \
#     |sed "$sedClearPPidListToSkipLines" \
#     |grep -q "$runCommandToCheck"; \
#  then
#    return 1 # exit value of failure if someone else is found
#  fi
#  
#  return 0 # success if no one else if found
#}
#if $bOptThereCanOnlyBeOne; then
#  FUNCthereCanOnlyBeOne "$strOptThereCanOnlyBeOneCmdPart"
#  nRet=$?
#  if((nRet!=0));then
#    $strSelfName -p "'$strOptThereCanOnlyBeOneCmdPart' is already running..."
#  fi
#  exit $nRet
#fi

FUNCturnOff(){
		eval "b=\$$1"
		if $b; then
	_hw;echo "precedence is [$strOptPrecedence] turning off option $1" >&2
		fi
		eval "$1=false"
}
if $bShowCaller; then
	FUNCturnOff bProblem
	FUNCturnOff bAddYesNoQuestion
	FUNCturnOff bExtendedQuestionMode
	FUNCturnOff bStringQuestion
	FUNCturnOff bWaitAKey
	FUNCturnOff bExecuteAsCommandLine
	FUNCturnOff bParentEnvironmentChangeEchoHelper
elif $bProblem || 
		 $bAddYesNoQuestion || $bExtendedQuestionMode || $bStringQuestion ||
		 $bWaitAKey; then
	FUNCturnOff bExecuteAsCommandLine
	FUNCturnOff bParentEnvironmentChangeEchoHelper
		
	if   $bAddYesNoQuestion; then
		FUNCturnOff bExtendedQuestionMode
		FUNCturnOff bStringQuestion
		FUNCturnOff bWaitAKey
	elif $bExtendedQuestionMode; then
		FUNCturnOff bStringQuestion
		FUNCturnOff bWaitAKey
	elif $bStringQuestion; then
		FUNCturnOff bWaitAKey
	fi
	
	if $bProblem; then
		strString="$strHeadProblem$strString"
		SECFUNCechoErrA --logonly "'$strString' at BASH_SOURCE[@]='${BASH_SOURCE[@]-}'" #no error happened here.. just to log the problem mode!
	
		if   $bAddYesNoQuestion || $bExtendedQuestionMode || $bStringQuestion; then
			if $bStringQuestion && ((fWaitTime > 0)); then
				strString="$strString" # color format will be of option -q #TODO why this useless line?
			else
				strString="$strColorAddYesNoQuestionProblem$strString"
			fi
		elif $bWaitAKey; then
			strString="$strColorWaitAKey$strString"
		else
			strString="$strColorProblem$strString"
		fi
	
		if ! $bForceStdout; then
			output="$stderr"
		fi
		
		bWARNBEEP=true
	elif $bAddYesNoQuestion || $bExtendedQuestionMode || $bStringQuestion; then
		if $bStringQuestion && ((fWaitTime > 0)); then
			strString="$strString" # color format will be of option -q #TODO why this useless line?
		else
			strString="$strColorAddYesNoQuestion$strString"
		fi
	elif $bWaitAKey; then
		strString="$strColorWaitAKey$strString"
	fi
elif $bExecuteAsCommandLine; then
		strString="$strColorExecuteAsCommandLine$strString"
elif $bParentEnvironmentChangeEchoHelper; then
		strString="$strColorParentEnvironmentChangeEchoHelper$strString"
fi

if $bNoWARNBEEP; then
		bWARNBEEP=false
fi

if $bOptInfo; then
	strString="$strColorOptionInfo$strString"
fi

if $bOptAlert; then
	strString="$strColorOptionAlert$strString"
fi

if $bAddYesNoQuestion; then
	n=${#strString}
	str="${strString:n-4}"
	if [[ "$str" != "@@Dy" ]] && [[ "${str:1}" == "@Dy" ]]; then
		strString="${strString:0:n-3}"
		str="@Dy"
	else
		str=""
	fi
	strString="$strString@O_yes$str"
fi

if [[ -n "$strPreviousLastFmt" ]]; then
	strString='@{'"$strPreviousLastFmt"'}'"$strString"
fi

# Do all @... color translations
strForeground=""
strBackground=""
strTypeO=""
strTypeU=""
strTypeD=""
strTypeN=""
strTypeE=""
strTypeFgL=""
strTypeBgL=""
bFgAutoSet=false
strGfxTputmacs=""
bGfxTransTab=false
bGfxE294=false
nLine=""
nColumn=""

bSave=false

strSaveFg=""
strSaveBg=""
strSaveTpO=""
strSaveTpU=""
strSaveTpD=""
strSaveTpN=""
strSaveTpE=""
bSaveFgAutoSet=false
strSaveGfxTm=""
bSaveGfxTT=false
bSaveGfxE=false
nSaveLine=""
nSaveColumn=""

strCommandLine=""
bLineMove=false
nUnrecognizedCharCount=0
bIgnore=false

nColumnBkp=""
nLineBkp=""

FUNCformatColor(){
	strFUNCformatColor=""

	local strString="$1"
	local strStringOK="" #$cmdOff

	local bRemoveFormat=false
	if [[ "${2-}" == "RemoveFormat" ]]; then
		bRemoveFormat=true
	elif [[ -n "${2-}" ]]; then
		_he;eval echo "invalid parameter 2 value: $2" $stderr
	fi

	local bCMDIn=false
	local bCMDMulti=false
	local strCMD=""
	local bGfxTransTab=false
	local bGfxE294=false
	local strE294Temp=""
	local bSetKeepColumn=false

	local char=""
	local charPrev=""

	local bExtendedFormat=false
	local strExtdFmt=""
	
	local lbEscapeToken=false
	
	local bGfxCharIsEscaped=false
	for (( nCount=0; nCount<${#strString}; nCount++ )); do
		charPrev="$char"
		char="${strString:nCount:1}"
		
		if $bIgnore;then # bIgnore=true is set by '@--'
			if [[ "${strString:nCount:3}" == '@++' ]];then
				if [[ "$charPrev" == '@' ]];then
					continue # to skip @ of @++
				else
					bIgnore=false
					((nCount+=2)) # and +1 of nCount++ for loop
					charPrev=""
					char=""
				fi
			else
				strStringOK+="$char"
			fi
			continue
		fi
		
		if $lbEscapeToken;then
			lbEscapeToken=false
			continue
		fi
		
		if ! $bCMDIn; then
			if [[ "$char" == '\' ]] && [[ "${strString:nCount+1:1}" == "@" ]];then
				strStringOK+="@"
				if $bExecuteAsCommandLine || $bParentEnvironmentChangeEchoHelper;then
					strCommandLine+="@"
				fi
				lbEscapeToken=true
				continue
			fi
			
			if [[ $char == "@" ]]; then
				bCMDIn=true
				bCMDMulti=false
				strCMD=""
				bExtendedFormat=false
				if [[ -n "$strE294Temp" ]]; then
					_hw;echo "strE294Temp has trash = \"$strE294Temp\"" >&2
				fi
				strE294Temp="" #prevent previous trash
			else
				charGfxTrans=""
				if $bGfxE294; then
					strE294Temp="$strE294Temp$char"
					if ((${#strE294Temp}==3)) || [[ "$strE294Temp" == ' ' ]];then
						charGfxTrans=`FUNCgfxTranslateCharE294 "$strE294Temp"`
						strE294Temp=""
					fi
				else
					if $bGfxTransTab; then
						if [[ "$char" == '\' ]]; then
							charGfxTrans="$char"
							bGfxCharIsEscaped=true
						elif $bGfxCharIsEscaped; then
							charGfxTrans="$char"
							bGfxCharIsEscaped=false
						else
							charGfxTrans=`FUNCgfxTranslateChar "$char"`
						fi
					else
						charGfxTrans="$char"
					fi
					if $bNormalEchoInterpretEscapeChars && [[ "$charPrev$char" == '\n' ]]; then
						if [[ -n $nLine     ]]; then ((nLine++    )); fi
						if [[ -n $nLineBkp  ]]; then ((nLineBkp++ )); fi
						if [[ -n $nSaveLine ]]; then ((nSaveLine++)); fi
						bSetKeepColumn=true
					fi
				fi
				charEscape=""
				if [[ "$char" == '"' || "$char" == '`' || "$char" == '\' ]]; then  # allow " within string
					charEscape="\\"
				fi
				strStringOK="$strStringOK$charEscape$charGfxTrans"
				if $bSetKeepColumn; then
					strStringOK="$strStringOK${cmdLastColumnSet-}" # !!! insertion of cmd here!
					bSetKeepColumn=false
				fi
	#      strUnformatted="$strUnformatted$charGfxTrans"
				if $bExecuteAsCommandLine || $bParentEnvironmentChangeEchoHelper; then #for performance
	##		    strCommandLine="$strCommandLine$charEscape$charGfxTrans" 
					strCommandLine+="$charGfxTrans" 
				fi
			fi
		else
			bSet=false
			if ! $bCMDMulti && [[ "$char" == '@' ]]; then
				strStringOK+="@"
	#      strUnformatted="$strUnformatted@"
				if $bExecuteAsCommandLine || $bParentEnvironmentChangeEchoHelper; then #for performance
					strCommandLine+="@"
				fi
				bCMDIn=false
			elif   $bCMDMulti && [[ "$char" == '/' ]]; then
				if $bExtendedFormat; then
					strCMD="$strCMD"`FUNCtransExtdFmt "$strExtdFmt"`
					strExtdFmt=""
				else
					bExtendedFormat=true
				fi
			elif [[ "$char" != '{' && "$char" != '}' ]]; then
				if $bExtendedFormat; then
					strExtdFmt="$strExtdFmt$char"
				else
					strCMD="$strCMD$char"
					if ! $bCMDMulti; then
						if	[[ "$char"     != '-' && "$char"     != '+' ]] ||
								[[ "$charPrev" == '-' || "$charPrev" == '+' ]]; then
							bSet=true
						fi
					fi
				fi
			elif [[ "$char" == '{' ]]; then
				bCMDMulti=true
			elif [[ "$char" == '}' ]] || ! $bCMDMulti; then
				if $bExtendedFormat; then
					strCMD="$strCMD"`FUNCtransExtdFmt "$strExtdFmt"`
					strExtdFmt=""
				fi
				bSet=true
			fi
			
			if $bSet; then
				if ! $bRemoveFormat; then
					FUNCColorCMD "$strCMD"
					strStringOK+="${strFUNCColorCMD}"
				fi
				bCMDIn=false
			fi
		fi
	done
	strFUNCformatColor="$strStringOK"

	# Store last fmts to be used in next call to this script in case -k was used as command line option
	strLastFmt="$nColumn.$nLine"\
`FUNCLastFmtAdd "strForeground" lesslight`\
`FUNCLastFmtAdd "strBackground" lesslight uppercase`\
`FUNCLastFmtAdd "strTypeO"`\
`FUNCLastFmtAdd "strTypeU"`\
`FUNCLastFmtAdd "strTypeD"`\
`FUNCLastFmtAdd "strTypeN"`\
`FUNCLastFmtAdd "strTypeE"`\
`FUNCLastFmtAdd "strTypeFgL"`\
`FUNCLastFmtAdd "strTypeBgL" uppercase`
	if ${bGfxModeOn}; then
		strLastFmt="$strLastFmt/graphic"
	fi

}

FUNCLastFmtAdd(){
	eval "str=\$${1}"
	shift
	while [[ -n "${1-}" ]]; do
		if [[ "$1" == "lesslight" ]]; then
			if [[ "${str:0:5}" == "light" ]]; then
				str="${str:5}"
			fi
		fi
		if [[ "$1" == "uppercase" ]]; then
			str=`echo $str |tr "[:lower:]" "[:upper:]"`
		fi
		shift
	done
	if [[ -n "$str" ]]; then
		echo "/$str"
	fi
}

# Extended Question mode ending String!
FUNCEQMArrayAdd(){
	local n
	for((n=0;n<${#1};n++));do
		local char="${1:n:1}"
		if [[ "$char" == '/' ]]; then
			((nEQMArray++))
		else
			strEQMArray[$((nEQMArray-1))]="${strEQMArray[$((nEQMArray-1))]-}$char"
		fi
	done
}

FUNCprepareEQM(){
	if $bAddYesNoQuestion || $bExtendedQuestionMode; then
		local nHighlight=-1 # -1 is out of index!
		local n
		local str="("
		local strEQMCurrent=""
		if [[ -n "$1" ]]; then
			nHighlight=$(($1))
		fi
		for((n=0;n<nEQMArray;n++));do
			strEQMCurrent=${strEQMArray[n]}
			if((n==nHighlight));then
				strEQMCurrent="@s${strColorOptionHighlight}${strEQMArrayUnformatted[n]}@S"
			fi
			str="$str$strEQMCurrent"
			if((n<nEQMArray-1));then
				str="$str/"
			fi
		done
		str="${str})? "
		echo -n "$str"
	else
		echo -n
	fi
}

FUNCEQMArrayUnformattedPrepare(){
	local n
	local strTemp="$strCommandLine"
	for((n=0;n<nEQMArray;n++));do
		FUNCformatColor "${strEQMArray[n]}" RemoveFormat
		strEQMArrayUnformatted[$n]="$strFUNCformatColor"
	done
	strCommandLine="$strTemp"
}  

strEQMArray=""
strEQMArrayUnformatted=""
nEQMArray=0
strEQMTemp=""
strEQMDTemp=""
strEQMList=""
strStringAnswerDefault=""
strStringAnswerDefaultToShow=""
bDefKeyFound=false
bDefKey=false
if $bAddYesNoQuestion || $bExtendedQuestionMode; then
	nEQMArray=1 # Always will have at least one option
	for((n=0;n<${#strString};n++));do
		char2="${strString:n:2}"
		if [[ "$char2" == "@@" ]]; then ((n+=1)); continue; fi # with n++ will be a total of +2
		if [[ "$char2" == "@O"  ]]; then 
			strEQMDTemp=${strString:n+2}
			strString=${strString:0:n}
			break
		fi
	done
	strEQMTemp="$strEQMDTemp"
	for((n=0;n<${#strEQMDTemp};n++));do
		char2="${strEQMDTemp:n:2}"
		if [[ "$char2" == "@@" ]]; then ((n+=1)); continue; fi # with n++ will be a total of +2
		if [[ "$char2" == "@D"  ]]; then 
			strEQMTemp=${strEQMDTemp:0:n}
			strStringAnswerDefault=${strEQMDTemp:n+2:1} # only one char
			bDefKey=true
			break
		fi
	done
	if [[ -n "$strEQMTemp" ]]; then
		bClose=false
		for((n=0;n<${#strEQMTemp};n++));do
			if [[ "${strEQMTemp:n:2}" == '__' ]]; then
				FUNCEQMArrayAdd "_"
				((n+=1)) # will be +2 with n++
				continue
			fi
			char="${strEQMTemp:n:1}"
			if [[ "$char" == '_' ]]; then
				FUNCEQMArrayAdd "@s$strColorOptionKey"
				bClose=true
				continue
			fi
			if $bClose && [[ "$char" == "$strStringAnswerDefault" ]]; then
				bDefKeyFound=true
				FUNCEQMArrayAdd "$strColorOptionKeyDefault"
			fi
			FUNCEQMArrayAdd "$char"
			if $bClose; then
        #declare -p strEQMList char >&2
				if ((`expr index "$strEQMList" "$char"&&:` == 0)); then
					strEQMList="$strEQMList$char"
				else
					_hw;echo "this option key was already defined: $char" >&2
				fi
				FUNCEQMArrayAdd "@S"
				bClose=false
			fi
		done
	fi
	FUNCEQMArrayAdd "/@s@r...@S"
	FUNCEQMArrayUnformattedPrepare
	if [[ -z "$strEQMList" ]]; then
		_hw;eval echo "you must define option keys like @O_option1/o_ption2 etc..." $stderr
	fi
	if $bDefKey && ! $bDefKeyFound; then
		_hw;eval echo "@D should have defined a valid key, one that exists at options @O" $stderr
	fi
elif $bStringQuestion; then
	for((n=0;n<${#strString};n++));do
		if [[ "${strString:n:3}" == "@@D" ]]; then ((n+=2)); continue; fi # with n++ will be a total of +3
		if [[ "${strString:n:2}" == "@D"  ]]; then 
			strStringAnswerDefault=${strString:n+2}
			strStringAnswerDefaultToShow=" [@s$strColorDefaultStringAnswer$strStringAnswerDefault@S]"
			strString=${strString:0:n}
			break
		fi
	done
fi

bHideStringQuestion=false
bCollectAnswerTimedMode=false
strWaitTime=""
#@@@R if ((nWaitTime>0));then 
if FUNCifBC "$nWaitTime>0"; then
	strWaitTime=" (${nWaitTime}s)"
fi
if   $bAddYesNoQuestion || $bExtendedQuestionMode; then
		strString="$strString$strWaitTime " #`FUNCprepareEQM`
elif $bStringQuestion; then
		if [[ -n "$strWaitTime" ]]; then
			bHideStringQuestion=true
			strEmptyDefault=""
			if [[ -z "$strStringAnswerDefaultToShow" ]]; then
				strEmptyDefault=" []"
			fi
			
			strLogOption=""
			if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
				strLogOption=" -l \"$strUnformattedFileNameLog\" "
			fi
			if ! eval $strSelfName $strLogOption -qt $nWaitTime "\"$strString$strStringAnswerDefaultToShow$strEmptyDefault, accept@Dy\"" $stderr; then
				bCollectAnswerTimedMode=true
			fi
		fi
		if ! $bHideStringQuestion; then # usefull to speedup
			strString="$strString$strStringAnswerDefaultToShow: "
		fi
elif $bWaitAKey; then
		strComma="Press"
		if ! $bEmptyString; then
			strComma=", press"
		fi
		strString="$strString$strComma any key to continue$strWaitTime... "
else
		if [[ "$fWaitTime" != "0" ]];then strWaitTime=" (${fWaitTime}s)"; fi
		strString="$strString$strWaitTime"
fi

# Translate each COLOR/Type instruction @...
function FUNCColorCMD(){
	local strParam1="$1"
	local nRecognizedCharCount=0
	local nAllChars=$(( ${#1} ))
	strFUNCColorCMD="$cmdOff" # as settings, like underline, cant be undone, everithing must be reset then setup again!
	if [[ -n "$strParam1" ]]; then
		# prevent previous underline setting (@@@ may prevent bold or light etc also, need more tests)
		if ! $bKeepPCS; then
			strParam1="-a$strParam1"
		fi
	
		# take care of formats
		local nCol=""
		local nLin=""
		local bGetLineNum=false
		local n
		local nSize
		local str=""
		local char=""
		local charPrev=""
		local bRestorePos=false
		local bRecognized=false
		local bTwoChar=false
    local strUnrecognizedWarn=""
		for((n=0;n<${#strParam1};n++));do
			if $bRecognized; then
				charPrev=""
			else
				charPrev="$char"
			fi
			bRecognized=false
			char="${strParam1:n:1}"
			str="$str$char"
			strTwoChar="$charPrev$char"

			if [[ "$strTwoChar" == '-' || "$strTwoChar" == '+' ]]; then
				continue
			fi
				
			# restore settings, but may be overriden by new settings after it
			if [[ "$char" == 'A' || "$char" == 'S' ]]; then #-n `expr "$strParam1" : ".*\([AS]\)"` ]]; then
				if $bSave; then #restore
					strForeground="$strSaveFg"
					strBackground="$strSaveBg"
					strTypeO="$strSaveTpO"
					strTypeU="$strSaveTpU"
					strTypeD="$strSaveTpD"
					strTypeN="$strSaveTpN"
					strTypeE="$strSaveTpE"
					strTypeFgL="$strSaveTpFgL"
					strTypeBgL="$strSaveTpBgL"
					bFgAutoSet=$bSaveFgAutoSet
					if [[ "$char" == 'A' ]]; then # -n `expr "$strParam1" : ".*\(A\)"` ]]; then
						strGfxTputmacs=$strSaveGfxTm
						bGfxTransTab=$bSaveGfxTT
						bGfxE294=$bSaveGfxE
						bRestorePos=true
					fi
				fi
			
				nSize=$(( ${#str} -1 ));str="${str:0:nSize}";((nRecognizedCharCount++))&&:
				bRecognized=true
				continue
			fi
				
			# cancel graphic, type, fore and background by choice
			case "$strTwoChar" in
				"-f")bRecognized=true;strForeground="";;
				"-b")bRecognized=true;strBackground="";;
				"-o")bRecognized=true;strTypeO="";;
				"-u")bRecognized=true;strTypeU="";;
				"-d")bRecognized=true;strTypeD="";;
				"-n")bRecognized=true;strTypeN="";;
				"-e")bRecognized=true;strTypeE="";;
				"-l")bRecognized=true;strTypeFgL="";;
				"-L")bRecognized=true;strTypeBgL="";;
				"-t")bRecognized=true;strParam1="${strParam1:0:n+1}-o-u-d-n-e-l-L${strParam1:n+1}";;
				"+p")bRecognized=true;strParam1="${strParam1:0:n+1}$nColumnBkp.$nLineBkp${strParam1:n+1}";;
				"-:")bRecognized=true
					if [[ "$strGfxMode" == "$optGfxTputmacs"     ]]; then strGfxTputmacs=`tput rmacs`; fi
					if [[ "$strGfxMode" == "$optGfxMostreliable" ]]; then bGfxTransTab=false; fi
					if [[ "$strGfxMode" == "$optGfxE294char"     ]]; then bGfxE294=false; fi
					;;
				"-a")bRecognized=true; # reset everything
					strParam1="${strParam1:0:n+1}-:-f-b-t${strParam1:n+1}"
					bFgAutoSet=false
					strFUNCColorCMD=$cmdOff;;
				"--")bRecognized=true;bIgnore=true;; # bIgnore is at main loop: Do all @... color translations
				"++")bRecognized=true;bIgnore=false;; 
				"-"?|"+"?)
					_hw;echo "unrecognized '$strTwoChar'" >&2
					nSize=$(( ${#str} -2 ))
					str="${str:0:nSize}"
					continue;; #; strUnrecognizedChar="$strUnrecognizedChar-$charCC";;
			esac
			if $bRecognized; then
				nSize=$(( ${#str} -2 ))
				str="${str:0:nSize}"
				((nRecognizedCharCount+=2))&&:
				continue
			fi
				
			# init graphic
			bGfxModeOn=false
			if [[ "$char" == ':' ]]; then #-n `expr "$strParam1" : ".*\([:]\)"` ]]; then
				if [[ "$strGfxMode" == "$optGfxTputmacs"     ]]; then strGfxTputmacs=`tput smacs`; fi
				if [[ "$strGfxMode" == "$optGfxMostreliable" ]]; then bGfxTransTab=true; fi
				if [[ "$strGfxMode" == "$optGfxE294char"     ]]; then bGfxE294=true; fi
				bGfxModeOn=true
				
				nSize=$(( ${#str} -1 ));str="${str:0:nSize}";((nRecognizedCharCount++))&&:
				bRecognized=true
				continue
			fi

			# position column.line find
			if [[ -n `expr "0123456789" : ".*\([$char]\)"` ]]; then
				if ! $bGetLineNum; then
					nCol="$nCol$char"
				else
					nLin="$nLin$char"
				fi
				nSize=$(( ${#str} -1 ));str="${str:0:nSize}";((nRecognizedCharCount++))&&:
				bRecognized=true
				continue
			elif [[ "$char" == '.' ]]; then
				bGetLineNum=true
			
				nSize=$(( ${#str} -1 ));str="${str:0:nSize}";((nRecognizedCharCount++))&&:
				bRecognized=true
				continue
			fi

      local lbSkip=false
			case "$char" in
				# foreground
				r) bRecognized=true;bFgAutoSet=false;strForeground="red"    ;;
				g) bRecognized=true;bFgAutoSet=false;strForeground="green"  ;;
				b) bRecognized=true;bFgAutoSet=false;strForeground="blue"   ;;
				c) bRecognized=true;bFgAutoSet=false;strForeground="cyan"   ;;
				m) bRecognized=true;bFgAutoSet=false;strForeground="magenta";;
				y) bRecognized=true;bFgAutoSet=false;strForeground="yellow" ;;
				w) bRecognized=true;bFgAutoSet=false;strForeground="white"  ;;
				k) bRecognized=true;bFgAutoSet=false;strForeground="black"  ;;
				# background
				R) bRecognized=true;strBackground="red"    ;;
				G) bRecognized=true;strBackground="green"  ;;
				B) bRecognized=true;strBackground="blue"   ;;
				C) bRecognized=true;strBackground="cyan"   ;;
				M) bRecognized=true;strBackground="magenta";;
				Y) bRecognized=true;strBackground="yellow" ;;
				W) bRecognized=true;strBackground="white"  ;;
				K) bRecognized=true;strBackground="black"  ;;
				# type
				o) bRecognized=true;strTypeO="bold"   ;;
				u) bRecognized=true;strTypeU="underline";;
				d) bRecognized=true;strTypeD="dim"    ;;
				n) bRecognized=true;strTypeN="blink"  ;;
				e) bRecognized=true;strTypeE="strike" ;;
				l) bRecognized=true;strTypeFgL="light";;
				L) bRecognized=true;strTypeBgL="light";;
        # skippers just to not generate the warning
        s|S|a|A)lbSkip=true;;
			esac
			
      if $bRecognized; then
				nSize=$(( ${#str} -1 ));str="${str:0:nSize}";((nRecognizedCharCount++))&&:
				continue
      fi
      
      if $lbSkip;then continue;fi
      
      #(echo "all params: $@";declare -p char str strTwoChar strParam1) >&2 #DEBUGGING 
      strUnrecognizedWarn+="$char"
		done
		nAllChars=$(( ${#strParam1} ))
		strParam1="$str"

		# position column.line SET
		if $bRestorePos; then
				# Must be here to be after nCol/nLin fill attempt, at loop 'for' above
			if [[ -z $nCol ]]; then nCol=$nSaveColumn; fi
			if [[ -z $nLin ]]; then nLin=$nSaveLine  ; fi
		fi
		
		nColumn=""
		nLine=""
		if [[ -n "$nCol" ]]; then
			nColumn=$nCol
		fi
		if [[ -n "$nLin" ]]; then
			nLine=$nLin
		fi

		strPosition=""
		if [[ -n "$nColumn" ]]; then
			nColumnBkp=$nColumn
			cmdLastColumnSet=`tput hpa $nColumn`
			strPosition="$cmdLastColumnSet"
		fi
		if [[ -n "$nLine" ]]; then
			nLineBkp=$nLine
			strPosition="$strPosition"`tput vpa $nLine`
			bLineMove=true
			strRestorePos=`tput rc`
		fi
		#TIP: strPosition=`tput cup $nLine $nColumn`
			
		# SET type
		strTypes=""
		if [[ -n "$strTypeO" ]] && ! $bLimitBold; then
			strTypes=$strTypes$cmdBold
		fi
		if [[ -n "$strTypeU" ]] && ! $bLimitUnderline; then
			strTypes=$strTypes$cmdUnderline
		fi
		if [[ -n "$strTypeD" ]] && ! $bLimitDim; then
			strTypes=$strTypes$cmdDim
		fi
		if [[ -n "$strTypeN" ]] && ! $bLimitBlink; then
			strTypes=$strTypes$cmdBlink
		fi
		if [[ -n "$strTypeE" ]] && ! $bLimitStrike; then
			strTypes=$strTypes$cmdStrike
		fi
		if [[ -n "$strForeground" ]]; then
			bLightFg=false
			if [[ "light" == "${strForeground:0:5}" ]]; then
				bLightFg=true
			fi
			if [[ -n "$strTypeFgL" ]]; then
				if ! $bLightFg; then
					strForeground="light$strForeground"
				fi
			else
				if $bLightFg; then
					strForeground="${strForeground:5}"
				fi
			fi
		fi
		if [[ -n "$strBackground" ]]; then
			bLightBg=false
			if [[ "light" == "${strBackground:0:5}" ]]; then
				bLightBg=true
			fi
			if [[ -n "$strTypeBgL" ]]; then
				if ! $bLightBg; then
					strBackground="light$strBackground"
				fi
			else
				if $bLightBg; then
					strBackground="${strBackground:5}"
				fi
			fi
		fi
		
		# setup fore and back ground
		if ( $bFgAutoSet || [[ -z "$strForeground" ]] ) && [[ -n "$strBackground" ]]; then
			bFgAutoSet=true
			if [[ -z "$strTypeBgL" ]]; then
				if   [[ `echo "black red yellow blue magenta" |grep "$strBackground" -w` ]]; then
					strForeground="lightwhite"
				elif [[ `echo "green cyan white"              |grep "$strBackground" -w` ]]; then
					if $bLimitUseAutoFgBlue; then
						strForeground="blue"
					else
						strForeground="black"
					fi
				fi
			else
				if   [[ `echo "blue black"                          |grep "${strBackground:5}" -w` ]]; then
					strForeground="lightwhite"
				elif [[ `echo "green red cyan magenta white yellow" |grep "${strBackground:5}" -w` ]]; then
					if $bLimitUseAutoFgBlue; then
						strForeground="blue"
					else
						strForeground="black"
					fi
				fi
			fi
		fi
		strFgBg=""
		if [[ -n "$strForeground" ]]; then
			strFgBg=$strFgBg`FUNCtranslateColor $strForeground foreground`
		fi
		if [[ -n "$strBackground" ]]; then
			strFgBg=$strFgBg`FUNCtranslateColor $strBackground background`
		fi
		
		# save settings
    if [[ "$strParam1" =~ .*[s|a].* ]];then
      bSave=true
      
      strSaveFg="$strForeground"
      strSaveBg="$strBackground"
      strSaveTpO="$strTypeO"
      strSaveTpU="$strTypeU"
      strSaveTpD="$strTypeD"
      strSaveTpN="$strTypeN"
      strSaveTpE="$strTypeE"
      strSaveTpFgL="$strTypeFgL"
      strSaveTpBgL="$strTypeBgL"
      bSaveFgAutoSet=$bFgAutoSet
      if [[ "$strParam1" =~ .*a.* ]];then
        strSaveGfxTm=$strGfxTputmacs
        bSaveGfxTT=$bGfxTransTab
        bSaveGfxE=$bGfxE294
        nSaveLine=$nLine
        nSaveColumn=$nColumn
      fi
      ((nRecognizedCharCount++))&&:
    fi

		strFUNCColorCMD=${strPosition}${strFUNCColorCMD}${strFgBg}${strTypes}${strGfxTputmacs}
	fi
	
	(( nUnrecognizedCharCount += nAllChars -nRecognizedCharCount ))&&:
	
  if [[ -n "$strUnrecognizedWarn" ]];then
    _hw;echo "UNRECOGNIZED(s) '$strUnrecognizedWarn'" >&2
  fi
  
	return 0 # means all went ok
}

# prevent undesired formatting
if $bShowCaller; then
		strString="$strHeadShowCaller@--"`ps -p $PPID --format=cmd |tail -n 1`"@++ @-a$strString"
		bKeepPCS=true
fi    

#echo "nUnrecognizedCharCount=$nUnrecognizedCharCount"
if ((nUnrecognizedCharCount!=0));then
		_hw;echo "total unrecognized characters count = $nUnrecognizedCharCount " >&2 #\"$strUnrecognizedChar\"
fi

if $bWARNBEEP && [[ $SEC_BEEP != "mute" ]]; then 
	if [[ $SEC_BEEP == "single" ]]; then
		eval echo -en '"\a"' $stderr
	elif [[ $SEC_BEEP == "extra" ]]; then
		eval echo -en '"\a"' $stderr; sleep .1
		eval echo -en '"\a"' $stderr; sleep .1
		eval echo -en '"\a"' $stderr; sleep .1
		eval echo -en '"\a"' $stderr; sleep .1
		eval echo -en '"\a"' $stderr; sleep .1
	fi
fi

FUNCclearInputBufferGetLastChar(){ # waits .1 seconds before collecting last pressed key, and outputs progress info
	echo -n "$strClrKeyBufMsg" >&2 # tells user that its clearing keyboard buffer and waiting 1 second
	local char=""
	local nKeyPressed=1 # false
	declare -a aProgress=("\|" "/" "-" '\\\\')
	local nCount=0
	while FUNCread -s -n 1 -t $nClrKeyBufDelay -p "" char; do 
		echo -ne "${aProgress[$((nCount++ % 4))]}\b" >&2
		nKeyPressed=0 # true
	done 
	local str=`echo -ne "$strClrKeyBufMsg" |tr "[:graph:]" " "`
	echo -ne "\r$str \r" >&2 # the space after str is in case clear key progress was shown
	echo -n "$char" # this should go to who called this function, and not to normal stdout
	return $nKeyPressed
}

FUNCdoTheEcho(){
	local strGoToBeginOfLine=""
	if [[ "${1-}" == "GoToBeginOfLine" ]]; then
		strGoToBeginOfLine=`echo -ne "\r"`
	elif [[ -n "${1-}" ]]; then
		_he;eval echo "invalid parameter 1 value: $1" $stderr
	fi
	
	local str="$strString"`FUNCprepareEQM $nEQMCurrent`

	local strUnformatted=""
	FUNCformatColor "$str" "RemoveFormat"
	strUnformatted="$strFUNCformatColor"
	strCommandLine="" # it was filled by FUNCformatColor, so clean it up
	
	#@@@r # LOG
	#@@@R if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
	#@@@R  strCommandLine="" # don't let it be filled now
	#@@@R fi
	
	#@@@R if $bUnformatted; then
	#@@@R   FUNCformatColor "$str" "RemoveFormat"
	#@@@R   strUnformatted="$strFUNCformatColor"
	#@@@R else
	if ! $bUnformatted; then
		FUNCformatColor "$str"
	fi
	
	if $bKeepColorSettings && [[ -n "$strLastFmt" ]]; then
#    FUNCargset "$strTermEmulator;$strLastFmt"
		FUNCargset "$strLastFmt"
#  else
#    FUNCargset "$strTermEmulator;"
	fi
	
	#local strFmted=`FUNCtranslateFormatColor "$str"`
	if $bUnformatted;then
		eval echo $strEchoNormalOption $strNL "\"${strGoToBeginOfLine}${strHeaderExec}${strUnformatted}\"" $output
	else
		eval echo $strEchoNormalOption $strNL "\"${strGoToBeginOfLine}${strHeaderExec}${strFUNCformatColor}${strResetAtEnd}\"" $output
	fi
	
	if $bOptEscapedChars; then
		echo
		echo "echo -e \"${strFUNCformatColor}${strResetAtEnd}\"" |sed 's"\d27"\\E"g'
	fi
	
	if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
		eval echo $strEchoNormalOption $strNL "\"${strGoToBeginOfLine}${strHeaderExec}${strUnformatted}\"" >>"$strUnformattedFileNameLog"
	fi
	
	if $bSay; then
		#@@@R FUNCformatColor "$str" "RemoveFormat"
		#@@@R strUnformatted="$strFUNCformatColor"
		
		#echo "$strUnformatted" |festival --tts
		
		#echo "(SayText \"$strUnformatted\")" |festival --pipe
		
		strOptWaitSay=""
		if $bWaitSay; then
			strOptWaitSay="--waitsay"
		fi
#		nohup "$SECinstallPath/bin/secSayStack.sh" ${strOptWaitSay} --sayvol $SEC_SAYVOL "$strUnformatted" 2>/dev/null 1>/dev/null& #>/dev/null is required to prevent nohup creating nohup.out file...
		(
			source <(secinit) #TODO secSayStack.sh should output nothing other than CRITICAL errors! may be add --verboseless or --critmsgonly option? this way would not be necessary to redirect stderr!
			_SECFUNCcheckCmdDep ffmpeg
			_SECFUNCcheckCmdDep play
			_SECFUNCcheckCmdDep festival
			nohup "$SECinstallPath/bin/secSayStack.sh" ${strOptWaitSay} "$strUnformatted" 2>/dev/null 1>/dev/null& #>/dev/null is required to prevent nohup creating nohup.out file...
		)
		if $bWaitSay; then
			wait $!
		fi
		#sleep 5
		#while ! ps -p $!;do			sleep 0.1;		done
		#disown -h %1
		#("$SECinstallPath/bin/secSayStack.sh" --sayvol $SEC_SAYVOL "$strUnformatted")&
		#nohup "$SECinstallPath/bin/secSayStack.sh" --sayvol $SEC_SAYVOL "$strUnformatted"&
		#disown %1
		#local sayCmd="\"$SECinstallPath/bin/secSayStack.sh\" --sayvol $SEC_SAYVOL \"$strUnformatted\""
		#eval "$sayCmd"&
		#eval "disown '$sayCmd'"
		#("$SECinstallPath/bin/secSayStack.sh" --sayvol $SEC_SAYVOL "$strUnformatted"&)
	fi
  
  if $bOptNotify;then
    local lastrCmdNotif=(notify-send)
    if $bOptAlert;then
      lastrCmdNotif+=(-u critical)
      lastrCmdNotif+=(-t 10)
      local lstrPicAlert="`secGetInstallPath.sh`/share/pixmaps/ScriptEchoColor/Alert.png"
      if [[ -f "$lstrPicAlert" ]];then
        lastrCmdNotif+=(-i "$lstrPicAlert")
      fi
    fi
    lastrCmdNotif+=("$strUnformatted")
    "${lastrCmdNotif[@]}"
  fi
}

FUNCstrNL(){
	if [[ -n $strNL ]]; then
		eval echo $output
		if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
			echo >>"$strUnformattedFileNameLog"
		fi
	fi
}

strNL=""
if [[ ! `echo "${strEchoNormalOption:1}" |grep n` ]]; then
	strNL="-n"
fi

nEQMCurrent=-1
FUNCWalkEQM(){
	if((nEQMArray==0));then return; fi
	
	case "$1" in
		"-1")   ((--nEQMCurrent));;
		"+1")   ((++nEQMCurrent));;
		"begin")nEQMCurrent=0;;
		"end")  nEQMCurrent=$((nEQMArray-1));;
		*) return;;
	esac
	
	if((nEQMCurrent<0)); then
		nEQMCurrent=0;
	fi
	if((nEQMCurrent>=nEQMArray)); then
		nEQMCurrent=$((nEQMArray-1));
	fi
}

FUNCmatchStr(){
	local str1="$1"
	local str2="$2"
	
	if ! $SEC_CASESENS; then
		str1=`echo "$str1" |tr "[:upper:]" "[:lower:]"`
		str2=`echo "$str2" |tr "[:upper:]" "[:lower:]"`
	fi
	
	if [[ "$str1" == "$str2" ]]; then
		return 0
	else 
		return 1
	fi
}

FUNCcmdEscapedChars(){
	local str="$1"
	local strOut=""
	local char=""
	local n=0
##  local bInside=false
	for((n=0;n<${#str};n++));do
		char="${str:n:1}"
##    if [[ "$char" == '"' ]]; then
##      if $bInside; then
##        bInside=false
##      else
##        bInside=true
##      fi
##    fi
		if [[ "$char" == '"' || "$char" == '`' || "$char" == '\' ]]; then ##|| "$char" == ' ' ]]; then
##      if [[ "$char" == ' ' ]]; then
##        if $bInside; then
##          strOut="${strOut}\\"
##        fi
##      else
				strOut="${strOut}\\"
##      fi
		fi
		strOut="$strOut$char"
	done
	echo "$strOut"
}

if $bWaitAKey; then #WAIT A KEY MODE
	if SECFUNCisShellInteractive;then
		char="`FUNCclearInputBufferGetLastChar`"&&: #this outputs progress info
	fi
	FUNCdoTheEcho
	#source <(secinit --core) #for SECFUNCisShellInteractive
	if SECFUNCisShellInteractive;then
		FUNCread -s -n 1 $strNWaitTime -p ""&&: # -s and -p helps when hit ctrl+c to not bug into invisible typed characters
	else
		sleep $nWaitTime #if not interactive, and -t wasnt specified, it will sleep for 0s as no key can be pressed...
	fi
	FUNCstrNL
	if ! $bKeepPosition; then
		eval echo -n $strRestorePos $stderr
	fi
	exit 0
elif $bStringQuestion; then
	# Its expected that Enter is pressed at end of string typing
	if ! $bHideStringQuestion; then
		char=`FUNCclearInputBufferGetLastChar`&&:
		FUNCdoTheEcho
	fi
	
	strResp=""
	astrReadParams=()
	if [[ -n "$strStringAnswerDefault" ]];then
		astrReadParams+=(-e -i "$strStringAnswerDefault")
	fi
	astrReadParams+=(strResp)
	if $bCollectAnswerTimedMode; then
		strLogOption=""
		if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
			strLogOption=" -l \"$strUnformattedFileNameLog\" "
		fi
		eval $strSelfName -n $strLogOption "\"${strColorAddYesNoQuestion}Type your answer: \"" $stderr
		FUNCread "${astrReadParams[@]}"&&:
	elif ! $bHideStringQuestion; then
		FUNCread "${astrReadParams[@]}"&&:
	fi
	
	if ! $bKeepPosition; then
		eval echo -n $strRestorePos $stderr
	fi
		
	strAnswer=""
	if ! $bCollectAnswerTimedMode; then # this accepts empty answers
		if [[ -z "${strResp-}" ]]; then
			strResp="$strStringAnswerDefault"
			if $bHideStringQuestion; then
				strAnswer="ANSWER: "
			fi
		fi
	fi
	eval echo -n "\"${strResp-}\"" $stdout # send answer string to stdout to be grabbed by external application

	if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
		echo "$strAnswer${strResp-}" >>"$strUnformattedFileNameLog"
	fi
	
	exit 0
elif $bAddYesNoQuestion || $bExtendedQuestionMode; then #QUESTION MODE
	char=`FUNCclearInputBufferGetLastChar`&&:
	FUNCdoTheEcho
	while FUNCread -s -n 1 $strNWaitTime -p "" strResp; do
		strNWaitTime="" # to wait only the begin of typing
		
		if [[ -z "${strResp-}" ]]; then # Enter/Space
			break
		fi
		
		asciicode=`$SECinstallPath/bin/secasciicode ${strResp-}`
		if [[ $asciicode == '\47' ]]; then # backspace
			continue
		elif [[ $asciicode == '\33' ]]; then # escape chars
			if ! FUNCread -s -t 1 -n 2 -p "" strResp; then #esc key
				nEQMCurrent=$((-1))
			fi
			asciicode=`$SECinstallPath/bin/secasciicode ${strResp-}`
			if   [[ $asciicode == '\133\101' ]]; then # Up key
				FUNCWalkEQM begin
			elif [[ $asciicode == '\133\102' ]]; then # Down key
				FUNCWalkEQM end
			elif [[ $asciicode == '\133\104' ]]; then # Left key
				FUNCWalkEQM -1
			elif [[ $asciicode == '\133\103' ]]; then # Right key
				FUNCWalkEQM +1
			else # eliminates other escaped keys
				FUNCread -s -t 1 -p ""&&:
			fi
			FUNCdoTheEcho GoToBeginOfLine
		else
			eval echo -n "${strResp-}" $output
			break
		fi  
	done
	FUNCstrNL
	
	if ! $bKeepPosition; then
		eval echo -n $strRestorePos $stderr
	fi

	nRet=0
	if $bAddYesNoQuestion; then
		if [[ -z "${strResp-}" ]]; then # Enter/Space
			strResp="$strStringAnswerDefault"
		fi
	
		if FUNCmatchStr "${strResp-}" "y" || ((nEQMCurrent==0)); then
			nRet=0
##    	exit 0
		else
			nRet=1
##	    exit 1
		fi
	elif $bExtendedQuestionMode; then
		b=false
		if [[ -z "${strResp-}" ]]; then # enter/space/time out
			if((nEQMCurrent!=-1));then
				char=${strEQMList:nEQMCurrent:1} # List char index is equal to current option index
				if [[ -n "$char" ]]; then
					strResp="$char"
				fi
				b=true
			elif(( nEQMCurrent==(nEQMArray-1) ));then # final invalid option "..."
				nRet=0
##        exit 0
			elif [[ -z "$strStringAnswerDefault" ]]; then
				nRet=0
##        exit 0 # different exit mode, 0 is invalid, non zero is the answer
			else
				strResp=$strStringAnswerDefault
				b=true
			fi
		else
			b=true
		fi
		
		if $b; then
			if ! $SEC_CASESENS; then
				strResp=`echo    "${strResp-}"    |tr "[:upper:]" "[:lower:]"`
				strEQMList=`echo "$strEQMList" |tr "[:upper:]" "[:lower:]"`
			fi
			if ((`expr index "$strEQMList" "${strResp-}"&&:` != 0)); then
				strResp="'${strResp-}'"
				nRet=`printf "%d" "${strResp-}"`
##        exit `printf "%d" "${strResp-}"`
			else
				nRet=0
##        exit 0
			fi
		fi
	fi

	if ! $SEC_LOG_AVOID && [[ -n "$strUnformattedFileNameLog" ]]; then
		echo "ANSWER: ${strResp-}" >>"$strUnformattedFileNameLog"
	fi
	
	exit $nRet
else
	FUNCdoTheEcho
	FUNCstrNL
		
	if [[ "$fWaitTime" != "0" ]]; then
		if ! sleep "$fWaitTime"; then 
			exit 2;
		fi
	fi
	# EXEC AS COMMAND LINE
	nRet=0
	if $bExecuteAsCommandLine; then
		if [[ -z "$strCommandLine" ]]; then
			strErrCmdLineEmpty="strCommandLine is Empty"
			#_hw;eval echo "$strErrCmdLineEmpty" $stderr
			#SEC_WARN=true SECbBashSourceFilesForceShowOnce=true SECFUNCechoWarnA "'$strErrCmdLineEmpty' at BASH_SOURCE[@]='${BASH_SOURCE[@]}'"
			#export SEC_WARN=true;export SECbBashSourceFilesForceShowOnce=true;SECFUNCechoWarnA "'$strErrCmdLineEmpty'"
			SECFUNCechoErrA "'$strErrCmdLineEmpty'" #TODO was only a warning because user coded the strCommandLine?
			exit 1
		fi
		strCmd="`echo $strEchoNormalOption "$strCommandLine"`" #this way execution will also be formatted
##    strCmd=`FUNCcmdEscapedChars "$strCmd"`
##    eval "`echo $strEchoNormalOption "$strCommandLine"`" #this way execution will also be formatted
		while true; do
			nRet=0;if eval "$strCmd";then :;else nRet=$?;fi
			if ((nRet!=0)); then
				$strSelfName "$strColorAddYesNoQuestionProblem [exit $nRet] \`$strCmd\` "
				if $bExecuteRetry; then
					if $strSelfName -q "Retry"; then
						continue
					fi
				fi
	##	    $strSelfName "$strColorAddYesNoQuestionProblem [exit $nRet] \`$strCommandLine\` "
				if $bKillCallerOnExecError; then
					$strSelfName -Rnb # as program will be killed, send a error beep
					eval tput sgr0 $stderr
					eval echo "\"Killing ParentPID ($PPID)!\"" $stderr
					eval ps -p "\"$PPID\"" $stderr
					kill -SIGKILL $PPID # Execution interrupted here!!!
				fi
			fi
			break
		done
	elif $bParentEnvironmentChangeEchoHelper; then
		# formatted echo was already sent to /dev/stderr at FUNCdoTheEcho
		# now unformatted is sent to normal /dev/stdout so can be used by user as command
		str=""
		if $bKillCallerOnExecError; then
			str="$strCommandAppendExitTest"
		fi
		strCmd="`echo $strEchoNormalOption '$strCommandLine'`" #this way execution will also be formatted
		eval echo "\"$strCmd$str\"" $stdout
	fi

	if ! $bKeepPosition; then
		eval echo -n $strRestorePos $stderr
	fi
		
	exit $nRet
fi

