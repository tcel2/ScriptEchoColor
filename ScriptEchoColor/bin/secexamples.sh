#!/bin/bash
# Copyright (C) 2004-2012 by Henrique Abdalla
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


ScriptEchoColor -c 
echo `ScriptEchoColor --version`" Examples"
echo "(also helps to test and find bugs)"
echo 

nInitial=1
nIniC=$nInitial
n=$nIniC;desc[n]="Color Format";cmd[n]='ScriptEchoColor "dim:        @{dr}red @ggreen @bblue @ccyan @mmagenta @yyellow @kblack @wwhite"'
((n++)) ;desc[n]="Color Format";cmd[n]='ScriptEchoColor    "normal:     @rred @ggreen @bblue @ccyan @mmagenta @yyellow @kblack @wwhite"'
((n++)) ;desc[n]="Color Format";cmd[n]='ScriptEchoColor  "light:      @l@rred @ggreen @bblue @ccyan @mmagenta @yyellow @kblack @wwhite"'
((n++)) ;desc[n]="Color Format";cmd[n]='ScriptEchoColor  "bold:       @o@rred @ggreen @bblue @ccyan @mmagenta @yyellow @kblack @wwhite"'
((n++)) ;desc[n]="Color Format";cmd[n]='ScriptEchoColor    "BACKGROUND: @RRED @GGREEN @BBLUE @CCYAN @MMAGENTA @YYELLOW @KBLACK @WWHITE"'
((n++)) ;desc[n]="Color Format";cmd[n]='ScriptEchoColor  "B.LIGHT:    @L@RRED @GGREEN @BBLUE @CCYAN @MMAGENTA @YYELLOW @KBLACK @WWHITE"'
((n++)) ;desc[n]="Type Format" ;cmd[n]='ScriptEchoColor "more types: @uunderline@-t @estrike@-t @nblink"'
((n++)) ;nTotC=$n

nIniI=$nTotC
##n=$nIniE;desc[n]="Show Caller"                            ;cmd[n]='ScriptEchoColor -c'
n=$nIniI;desc[n]="Execute String as Command line:"        ;cmd[n]='ScriptEchoColor -x "pwd"'
((n++)) ;desc[n]="Execute String as Command line:"        ;cmd[n]='ScriptEchoColor -x "false"'
((n++)) ;desc[n]="Show problem message:"                  ;cmd[n]='ScriptEchoColor -p "example with BEEP sound!"'
((n++)) ;desc[n]="Timed Wait (5 seconds) for keypress:"   ;cmd[n]='ScriptEchoColor -w -t 5 "Your Message"'
((n++)) ;desc[n]="Wait for keypress:"                     ;cmd[n]='ScriptEchoColor -w "Your Message"'
((n++)) ;desc[n]="Question Mode:"                         ;cmd[n]='if ScriptEchoColor -q "Your Question"; then echo "Yes"; else echo "No"; fi'
((n++)) ;desc[n]="Extra Question Mode:"                   ;cmd[n]='ScriptEchoColor -Q "Your Question [press enter or space for default that is \"c\"] @O_box/_cube/c_one@Dc";nRet=$?;echo "return value $nRet = key \"`secascii $nRet`\""'
((n++)) ;desc[n]="Question Mode type answer text:"        ;cmd[n]='str=`ScriptEchoColor -S "Your Question"`;echo "You answered: $str"'
((n++)) ;desc[n]="Question Mode Timed type answer text, with default:"
                                                           cmd[n]='str=`ScriptEchoColor -S -t 5 "Your Question@Danswer"`;echo "You answered/default: $str"'
((n++)) ;desc[n]="Execute String as Command change environment:"
                                                           cmd[n]='str=`pwd`;pwd;`ScriptEchoColor -v "cd .."`;pwd;eval `ScriptEchoColor -v "cd \"$str\""`;pwd'
((n++)) ;desc[n]="Execute String as Command change environment and exit on error. \n\
                \r It won't be executed here as this command can make $0, \n\
                \r the caller, exit, so I will just show the colored output \n\
                \r to /dev/stderr and the command list output to /dev/stdout. \n\
                \r To make this command work as intended type: \n\
                \r    eval \`ScriptEchoColor -V \"pwd\"\` \n\
                \r Be warned though that if you run this at terminal command line, the \n\
                \r terminal may exit/logout in case of command error, it executes \n\
                \r \"exit N\" at end, so BEWARE; but if executed inside a script then \n\
                \r only the script exits:"
                                                           cmd[n]='ScriptEchoColor -V "pwd"'
((n++)) ;nTotI=$n
nTotal=$nTotI


bOptHelp=false
bOptDesc=true
bOptExec=true
bOptCmd=true
bOptScreenshot=false;
bOptColorType=false
bOptInteractive=false
nOptExample=0
# Command line options
strOpt="$1"
chOpt=""
strOptPROBLEM=""
if [[ -z "$strOpt" ]]; then bOptHelp=true; fi
while [[ "${strOpt:0:1}" == "-" ]]; do
  if [[ "${strOpt:1:1}" == "-" ]]; then
    case "${strOpt:2}" in  # long options ex.: --help
      #"") ;;  # option --
      #"exampleoptionaskingargument") shift; variable="$1";;
      "help"  ) bOptHelp=true ;;
      "nodesc") bOptDesc=false;;
      "noexec") bOptExec=false;;
      "nocmd" ) bOptCmd=false ;;
      "screenshot") bOptScreenshot=true; bOptDesc=false;;
      *) strOptPROBLEM="invalid option $strOpt"; break;;
    esac
  else
    chOptArg=""
    for((n=1;n<${#strOpt};n++)); do
      chOpt="${strOpt:n:1}"
      case "$chOpt" in # short options ex.: -a -bNk
        "a") bOptColorType=true; bOptInteractive=true;;
        "c") bOptColorType=true;;
        "i") bOptInteractive=true;;
        "n")  if [[ -n "$chOptArg" ]]; then 
                strOptPROBLEM="the option -$chOptArg already required an argument, invalid use of option -$chOpt";
                break;
              fi; 
              shift; strOptArg="$1"; 
              if [[ -z "$strOptArg" ]]; then 
                strOptPROBLEM="option -$chOpt requires an argument"; 
                break; 
              fi
              if [[ -n `echo "$strOptArg" |tr -d "[:digit:]"` ]]; then
                strOptPROBLEM="option -$chOpt requires a number as argument"; 
                break; 
              fi
              nOptExample="$strOptArg"; 
              if(( nOptExample < 1 || nOptExample > (nTotal-1) )); then
                strOptPROBLEM="option -$chOpt example number (you asked for $nOptExample) must be from 1 til $((nTotal-1))"; 
                break;
              fi
              chOptArg="$chOpt";;
        *) strOptPROBLEM="invalid option -$chOpt"; break;;
      esac 
    done
    if [[ -n "$strOptPROBLEM" ]]; then break; fi
  fi
  shift; strOpt="$1"
done
if $bOptHelp; then
  echo 
  echo "Options: "
  echo " required:"
  echo "  -a: show description/command and runs all examples"
  echo "  -c: show description/command and runs only color/types examples"
  echo "  -i: show description/command and runs only extra/interactive examples"
  echo "  -n <number>: show description/command and execute. Only one example number from 1 til $((nTotal-1))"
  echo " optional:" 
  echo "  --nodesc: hide descriptions"
  echo "  --nocmd:  hide commands"
  echo "  --noexec: don't execute the commands"
  echo "  --screenshot execute the way I prefer to prepare screenshots to the homepage :)"
  echo
  exit 0
fi
if [[ -n "$strOptPROBLEM" ]]; then
  echo -e "PROBLEM: $strOptPROBLEM\a" >&2
  exit 1
fi
if [[ -z "$chOpt" ]]; then
  echo -e "PROBLEM: missing one of the required options, see --help for details\a" >&2
  exit 1
fi

FUNCworkWithExample(){
  local nExample="$1"
  local strIndentCmd=""
  local strIndentExNum=""
  local strExShowNum=""
  
  # text adjustments
  if (( ${#nExample} == 1 )); then 
    strIndentExNum=" "; 
  fi
  
  if $bOptDesc; then 
    strIndentCmd="    "; 
  fi
  
  if $bOptCmd && ! $bOptDesc; then 
    strExShowNum=" $strIndentExNum$nExample"; 
  fi
  
  # show stuff
  if $bOptDesc; then
    echo -e "$strIndentExNum$nExample) ${desc[nExample]}"
  fi
    
  if $bOptCmd; then  
    echo "${strIndentCmd}CMD${strExShowNum}: ${cmd[nExample]}"
  fi
  
  if $bOptExec; then  
#    echo -n "$strIndentCmd"; 
    eval "${cmd[nExample]}"
  fi

  if ! $bOptScreenshot; then  
    echo
  fi
}

if((nOptExample==0));then
  if $bOptColorType && $bOptInteractive; then
    nIni=$nInitial
    nTot=$nTotal
  elif $bOptColorType; then
    nIni=$nIniC
    nTot=$nTotC
  elif $bOptInteractive; then
    nIni=$nIniI
    nTot=$nTotI
  fi
  
  for((n=nIni;n<nTot;n++));do
    FUNCworkWithExample $n
  done
else
  FUNCworkWithExample $nOptExample
fi

