#!/bin/bash
# Copyright (C) 2004-2020 by Henrique Abdalla
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

strCfgHeader="$1"
strSpeedupFile="$2"

echo "$strCfgHeader" >>"$strSpeedupFile"
echo "# DONT change below here, internal config to speed up script execution!" >>"$strSpeedupFile"

##str=`tput sgr0`;if [[ -z "$str" ]]; then str="\033[0m"; fi
echo "cmdOff=\""`      echo -e "\E[0m"`"\"" >>"$strSpeedupFile" #`tput sgr0`
echo "cmdBold=\""`     echo -e "\E[1m"`"\"" >>"$strSpeedupFile" #`tput bold`
echo "cmdDim=\""`      echo -e "\E[2m"`"\"" >>"$strSpeedupFile"
echo "cmdUnderline=\""`echo -e "\E[4m"`"\"" >>"$strSpeedupFile" #`tput smul` tput rmul
echo "cmdBlink=\""`    echo -e "\E[5m"`"\"" >>"$strSpeedupFile" #`tput blink`
echo "cmdReverse=\""`  echo -e "\E[7m"`"\"" >>"$strSpeedupFile"
echo "cmdStrike=\""`   echo -e "\E[9m"`"\"" >>"$strSpeedupFile"

#cmdFgBlack=`  tput setaf 0`
echo "cmdFgBlack=\""`  echo -e "\E[39m"`"\"" >>"$strSpeedupFile" # 30/39 works better. If used with Bold, black gets gray!
echo "cmdFgRed=\""`    echo -e "\E[31m"`"\"" >>"$strSpeedupFile" #`tput setaf 1` setaf (ANSI) instead of setf (bg too), works with "linux" terminal also
echo "cmdFgGreen=\""`  echo -e "\E[32m"`"\"" >>"$strSpeedupFile" #`tput setaf 2`
echo "cmdFgYellow=\""` echo -e "\E[33m"`"\"" >>"$strSpeedupFile" #`tput setaf 3`
##str=`tput setaf 4`;if [[ -z "$str" ]]; then str=`echo -e "\033[34m"`; fi
echo "cmdFgBlue=\""`   echo -e "\E[34m"`"\"" >>"$strSpeedupFile" #`tput setaf 4`
echo "cmdFgMagenta=\""`echo -e "\E[35m"`"\"" >>"$strSpeedupFile" #`tput setaf 5`
echo "cmdFgCyan=\""`   echo -e "\E[36m"`"\"" >>"$strSpeedupFile" #`tput setaf 6`
echo "cmdFgWhite=\""`  echo -e "\E[37m"`"\"" >>"$strSpeedupFile" #`tput setaf 7`

echo "cmdBgBlack=\""`  echo -e "\E[40m"`"\"" >>"$strSpeedupFile" #`tput setab 0`
echo "cmdBgRed=\""`    echo -e "\E[41m"`"\"" >>"$strSpeedupFile" #`tput setab 1`
echo "cmdBgGreen=\""`  echo -e "\E[42m"`"\"" >>"$strSpeedupFile" #`tput setab 2`
echo "cmdBgYellow=\""` echo -e "\E[43m"`"\"" >>"$strSpeedupFile" #`tput setab 3`
echo "cmdBgBlue=\""`   echo -e "\E[44m"`"\"" >>"$strSpeedupFile" #`tput setab 4`
echo "cmdBgMagenta=\""`echo -e "\E[45m"`"\"" >>"$strSpeedupFile" #`tput setab 5`
echo "cmdBgCyan=\""`   echo -e "\E[46m"`"\"" >>"$strSpeedupFile" #`tput setab 6`
echo "cmdBgWhite=\""`  echo -e "\E[47m"`"\"" >>"$strSpeedupFile" #`tput setab 7`

echo "cmdFgLtBlack=\""`  echo -e "\E[90m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtRed=\""`    echo -e "\E[91m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtGreen=\""`  echo -e "\E[92m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtYellow=\""` echo -e "\E[93m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtBlue=\""`   echo -e "\E[94m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtMagenta=\""`echo -e "\E[95m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtCyan=\""`   echo -e "\E[96m"`"\"" >>"$strSpeedupFile"
echo "cmdFgLtWhite=\""`  echo -e "\E[97m"`"\"" >>"$strSpeedupFile"

echo "cmdBgLtBlack=\""`  echo -e "\E[100m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtRed=\""`    echo -e "\E[101m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtGreen=\""`  echo -e "\E[102m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtYellow=\""` echo -e "\E[103m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtBlue=\""`   echo -e "\E[104m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtMagenta=\""`echo -e "\E[105m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtCyan=\""`   echo -e "\E[106m"`"\"" >>"$strSpeedupFile"
echo "cmdBgLtWhite=\""`  echo -e "\E[107m"`"\"" >>"$strSpeedupFile"

#GFX tables Hexa/Translation char
strTempCharTable=" a  A  b  B  c  C  d  D  e  E  f  F  g  G  h  H  i  I  j  J  k"
echo "gfxHexaTable=("`echo "80 81 82 83 8C 8F 90 93 94 97 98 9B 9C A3 A4 AB AC B3 B4 BB BC"`")" >>"$strSpeedupFile"
echo "gfxCharTable=("`echo "$strTempCharTable"`")" >>"$strSpeedupFile" #better if unique chars (no repeating)
echo "fmtCharTable=("`echo "r g b c m y k w R G B C M Y K W o u d n e l L : a s A S -f -b -l -L -o -u -d -n -e -t -: -a +p"`")" >>"$strSpeedupFile"
echo "fmtExtdTable=("`echo "red green blue cyan magenta yellow black white RED GREEN BLUE CYAN MAGENTA YELLOW BLACK WHITE bold underline dim blink strike light LIGHT graphic SaveAll SaveTypeColor RestoreAll RestoreTypeColor -foreground -background -light -LIGHT -bold -underline -dim -blink -strike -types -graphic -ResetAllSettings +RestorePosBkp"`")" >>"$strSpeedupFile"
echo "strGfxCharTable=\""`echo "$strTempCharTable" |tr -d " "`"\"" >>"$strSpeedupFile" #to speed up searches

chmod -w "$strSpeedupFile"
