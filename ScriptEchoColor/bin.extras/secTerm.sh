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

if which mrxvt >/dev/null 2>&1;then
  # mrxvt chosen because of: 
  #  low memory usage; 
  #  `xdotool getwindowpid` works on it;
  #  TODO rxvt does not kill some child proccesses when it is closed, if so, which ones?
  #  anyway none will kill(or hup) if the child was started with sudo!
  mrxvt -aht +showmenu "$@"
else
  xterm "$@" # fallback
fi
