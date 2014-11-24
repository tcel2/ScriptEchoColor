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

# these prevent continuing on errors...
trap 'exit 1' ERR
set -u 

if [[ ! -f "bin/ScriptEchoColor.sh" ]];then
	echo -e "\E[0m\E[31m\E[103m\E[5m '$0' must be run at '`dirname "$0"`/' like: './`basename "$0"`' \E[0m"
	read -n 1 -p "press a key to exit..."
	exit 1
fi
echo

############################ at ScriptEchoColor/
echo ">>---> removing local and updating from git... <---<<"
pwd
read -n 1 -p "continue? (ctrl+c to exit)"
#git pull origin
git reset --hard HEAD;
git clean -f -d;
git pull
echo

cd bin #################################### at ScriptEchoColor/bin/
echo ">>---> creating symlinks <---<<"
pwd
strSECbinInstPathGit="`pwd`"
ln -vs ../bin.extras/*   ./ 2>&1 |egrep -v ": File exists$"
ln -vs ../bin.examples/* ./ 2>&1 |egrep -v ": File exists$"
echo

echo ">>---> initialize ScriptEchoColor <---<<"
./echoc --info "ScriptEchoColor @nenabled!" #will initialize it
echo

echo ">>---> now add this '$strSECbinInstPathGit' to your PATH variable <---<<"
echo
