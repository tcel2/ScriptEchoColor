#!/bin/bash
# Copyright (C) 2015 by Henrique Abdalla
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

eval `secinit`

bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
strRegexMatch=""
strReplaceWith=""
strFileFilter="*.java"
bWrite=false
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "<strRegexMatch> <strReplaceWith> will replace the matching regex in all source files." 
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--filefilter" || "$1" == "-f" ]];then #help <strFileFilter> it is a `find` param
		shift
		strFileFilter="${1-}"
	elif [[ "$1" == "--write" ]];then #help this option will actually make `sed` write to files
		bWrite=true
	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
			shift
			CFGstrTest="$1"
		fi
		
		bCfgTest=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		$0 --help
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
SECFUNCcfgAutoWriteAllVars #this will also show all config vars

strRegexMatch="${1-}"
shift&&:
strReplaceWith="${1-}"
shift&&:

if [[ -z "$strRegexMatch" ]];then
	echoc -p "invalid strRegexMatch='$strRegexMatch'"
	exit 1
fi
if [[ -z "$strReplaceWith" ]];then
	echoc -p "invalid strReplaceWith='$strReplaceWith'"
	exit 1
fi

# Main code
IFS=$'\n' read -d '' -r -a astrFileList < <(find "src/" -iname "${strFileFilter}")&&:
for strFile in "${astrFileList[@]}";do
	if egrep -q "$strRegexMatch" "$strFile";then
		egrep -Hc "$strRegexMatch" "$strFile"
		if $bWrite;then
			SECFUNCexec -ce sed -i "s@${strRegexMatch}@${strReplaceWith}@g" "$strFile"
			SECFUNCexec -ce egrep --color=always "${strReplaceWith}" "$strFile"&&:
		else
			SECFUNCexec -ce sed "s@${strRegexMatch}@${strReplaceWith}@g" "$strFile" |egrep --color=always "${strReplaceWith}"&&:
		fi
	fi
done
if ! $bWrite;then
	echoc --alert "nothing was changed!"
fi

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

