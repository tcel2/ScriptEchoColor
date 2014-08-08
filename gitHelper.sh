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

eval `secinit -i`

SECFUNCuniqueLock --daemonwait

while true;do
	echoc --info "Git helper (hit ctrl+c to exit)"
	echoc -Q "git@O_commitWithGitGui/_diffLastTagFromMaster/_pushTagsToRemote/_browseWithGitk"&&:
	case "`secascii $?`" in 
		c) echoc -x "git gui";; 
		b) echoc -x "gitk";; 
		p) echoc -x "git push --tags";;
		d) echoc -x "git difftool -d \"`git tag |tail -n 1`..master\"";;
	esac
done

