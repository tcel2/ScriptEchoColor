#!/bin/bash
# Copyright (C) 2018 by Henrique Abdalla
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

# this is actually just a simple/single way to use a chosen terminal in the whole project

source <(secinit)

SECFUNCshowHelp --colorize "\tRun this like you would xterm or mrxvt, so to exec something requires -e param."

# Main code
astrParms=( "$@" )
#~ if((`SECFUNCarraySize astrParms`==0));then
  #~ astrParms+=(bash)
#~ fi

astrCmd=()

#~ function FUNCrun238746478() {
  #~ source <(secinit)
  
  #~ declare -p astrCmd
  #~ echo "SECTERMrun: ${astrParms[@]}"
  
  #~ "${astrParms[@]}";nRet=$?

  #~ if((nRet!=0));then
    #~ declare -p nRet
    #~ if SECFUNCisShellInteractive;then
      #~ echoc -p -t 60 "exit error $nRet"
    #~ fi
  #~ fi
#~ };export -f FUNCrun238746478

if which mrxvt >/dev/null 2>&1;then
  # mrxvt chosen because of: 
  #  low memory usage; 
  #  `xdotool getwindowpid` works on it;
  #  TODO rxvt does not kill some child proccesses when it is closed, if so, which ones?
  #  anyway none will kill(or hup) if the child was started with sudo!
  strConcatParms="${astrParms[@]-}"
  astrCmd+=(mrxvt -sl 1000 -aht +showmenu)
  if [[ -n "$strConcatParms" ]];then
    astrCmd+=(-title "`SECFUNCfixId --justfix -- "$strConcatParms"`" "${astrParms[@]}")
  fi
  #astrCmd+=(mrxvt -aht +showmenu -title "`SECFUNCfixId --justfix -- "$strConcatParms"`" bash -c "FUNCrun238746478")
else
  #astrCmd+=(xterm -e bash -c "FUNCrun238746478") # fallback
  astrCmd+=(xterm "${astrParms[@]}-") # fallback
fi

#"${astrCmd[@]}"
declare -p astrCmd
echo "SECTERMrun: ${astrCmd[@]}"

SECFUNCarraysExport #important for exported arrays before calling/reaching this script
"${astrCmd[@]}";nRet=$?
 
if((nRet!=0));then
  declare -p nRet
  source <(secinit)
  if SECFUNCisShellInteractive;then
    echoc -p -t 60 "exit error $nRet"
  fi
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting
