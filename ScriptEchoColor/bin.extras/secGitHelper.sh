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

strDpkgPackage=""
strDevPath=""
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--package" || "$1" == "-p" ]];then #help package name to be queried with dpkg
		shift
		strDpkgPackage="${1-}"
	elif [[ "$1" == "--devpath" || "$1" == "-d" ]];then #help development path where .git directory can be found into
		shift
		strDevPath="${1-}"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

if [[ ! -d "$strDevPath" ]];then
	echoc -p "invalid strDevPath='$strDevPath'"
	exit 1
fi
strDevPath="`readlink -f "$strDevPath"`"
if [[ ! -d "$strDevPath/.git" ]];then
	echoc -p "missing .git at strDevPath='$strDevPath'"
	exit 1
fi
ls -ld "$strDevPath/.git"

if ! dpkg -p "$strDpkgPackage";then
	echoc -p "invalid strDpkgPackage='$strDpkgPackage'"
	exit 1
fi

cd "$strDevPath"
echoc -x "pwd"

#strDevPath="`basename "$0"`";strDevPath="`readlink -f "$strDevPath"`";strDevPath="`dirname "$strDevPath"`"
##echo "(`pwd`)($strDevPath)"
#if [[ "$strDevPath" != "`pwd`" ]];then
#	pwd
#	echoc --alert "invalid run path, should be where '$0' is."
#	cd "$strDevPath"
#	pwd
#fi

while true;do
	#echoc --info "Git helper (hit ctrl+c to exit)"

	strSECInstalledVersion="`dpkg -p "$strDpkgPackage" |grep Version |grep "[[:digit:]]*-[[:digit:]]*$" -o`"
	strSECInstalledVersionFormatted="`echo "$strSECInstalledVersion" |sed -r "s'(....)(..)(..)-(..)(..)(..)'\1-\2-\3 \4:\5:\6'"`"
	echoc "strDpkgPackage='@r$strDpkgPackage@{-a}';"
	echoc "strSECInstalledVersion='@{c}$strSECInstalledVersion@{-a}';"
	echoc "strDevPath='@y$strDevPath';"
	
	#|sed -r "s'.* ([[:digit:]-]* [[:digit:]:]*) .*'\1'" |tr -d ':-' |tr ' ' '-' \
	strCommits="`git log --full-history --date=iso |grep Date |sed -r "s@.* ([[:digit:]-]*) ([[:digit:]:]*) .*@\1 \2@"`"
	strLastCommitBeforeInstall="`(echo "$strCommits";echo "$strSECInstalledVersionFormatted") |sort -r |grep "$strSECInstalledVersionFormatted" -A 1 |tail -n 1`"
#	nMaxShownCommits=20
#	echoc --info "last $nMaxShownCommits commits:"
	echoc --info "last commits (highlited the one previous to install):"
#	echo "$strCommits" |sed "s@.*@'&'@" |head -n $nMaxShownCommits |column
	nNewestCommitsLimit=1000 #just an "absurd?" number to make it easier to code...
	nTerminalWidth="`stty size 2>/dev/null |cut -d" " -f2`"
	echo "$strCommits" \
		|sed "s@.*@'&'@" \
		|grep "$strLastCommitBeforeInstall" -A 1 -B $nNewestCommitsLimit --color=always \
		|column -c $nTerminalWidth
	
#	echoc -Q "git@O\
#_commitWithGitGui/\
#_diffLastTagFromMaster/\
#diff_installedFromMaster/\
#diffToBeP_ushed/\
#_pushTagsToRemote/\
#_nautilusAtDevPath/\
#_terminalAtDevPath/\
#_browseWithGitk"&&:
	echoc -Q "git helper (hit ctrl+c to exit) @O\n\
\t_commit with 'git gui'/\n\
\t_diff last tag from master/\n\
\tdiff _installed from master/\n\
\tdiff to be p_ushed/\n\
\t_push tags to remote/\n\
\t_nautilus at dev path/\n\
\t_terminal at dev path/\n\
\t_browse with gitk"&&:
	case "`secascii $?`" in 
		b) echoc -x "gitk"&&: ;; 
		c) echoc -x "git gui"&&: ;; 
		d) echoc -x "git difftool -d \"`git tag |tail -n 1`..master\""&&: ;;
		i)	if [[ -z "$strSECInstalledVersion" ]];then
					echoc --alert "package scriptechocolor is not installed."
				else
					echoc -x "git difftool -d \"HEAD\@{$strLastCommitBeforeInstall}..master\""&&:
				fi
			;;
		n) echoc -x "nautilus ./"&&: ;;
		p) echoc -x "git push --tags"&&: ;;
		t) echoc -x "gnome-terminal"&&: ;;
		u) git difftool -d origin/master&&: ;;
	esac
	
done

