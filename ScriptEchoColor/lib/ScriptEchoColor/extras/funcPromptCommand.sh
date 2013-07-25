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

function SECFUNCpromptCommand () { #help: to use as source at .bashrc
        history -a; # append to history at each command issued!!!
        local width=`tput cols`;
        local half=$((width/2))
        local dt="[EndAt:`date +"%Y/%m/%d-%H:%M:%S.%N"`]";
        local sizeDtHalf=$((${#dt}/2))
        #printf "%-${width}s" $dt |sed 's" "="g'; 
        printf "%*s%*s\n" $((half+sizeDtHalf)) "$dt" $((half-sizeDtHalf)) "" |sed 's" "="g';
}
export PROMPT_COMMAND=SECFUNCpromptCommand

