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

eval `secinit`

echo
SECFUNCdrawLine "`echoc " @{lb}CODING GUIDE LINES@w @{lw}>>@{-ty}---@{ly}> "`" "~"
echoc "@{lw}Environment variables used as these types below, will begin with ->
  @cString\t@y->\t@g'str'
  @cDecimal\t@y->\t@g'n'
  @cFloating\t@y->\t@g'f'
  @cBoolean\t@y->\t@g'b'
  @cArray \t@y->\t@g'a' @{-tw}(prefix all other types with 'a' like 'astr' 'af' 'an' 'ab')
 @{lw}Aliases ends with @g'A'
 @wFunctions begins with @g'FUNC'
 
 @wWords on identifiers are captalized like: @gstrThisIsAnExampleAndATest
 @wThis helps with one or another piece of code that expects for this way of coding like @bSECFUNCseparateInWords@y()
 @wmaking it useful for ex.: @c\`echoc --say\`@w."
#SECFUNCexec --echo --colorize SECFUNCseparateInWords --notype strThisIsAnExampleAndATest
echoc -x "SECFUNCseparateInWords --notype strThisIsAnExampleAndATest"
echoc " @{lw}All publics coded at @{Bow} Script @{lk}Echo @rC@go@bl@co@yr @-b @ware prefixed with @g'SEC'

 @{wu}Coding Tips:@{-u}
  @wBecause of 'trap ERR', commands that can fail may simply end with '&&:' ex.: @gln -s a b&&:
  @wBecause of 'set -u', if a variable is not set, do set it up. Or use this: @g\${variable-} @{rn}#TODO <-- the missing example here requires a fix at scripteechocolor@{-n}
 
 @{wu}Exit/Return values shall not be these:@{-u}
	@y1      @wCatchall for general errors (this is actually ok for unspecified errors tho...)
	@r2      @wMisuse of shell builtins (according to Bash documentation)
	@r126    @wCommand invoked cannot execute
	@r127    @wcommand not found
	@r128+n  @wFatal error signal n
	@r130    @wScript terminated by Ctrl-C
	@r255*   @wExit status out of range
  "
SECFUNCdrawLine "`echoc " @{ly}<@{-ty}---@{lw}<< @{lb}CODING GUIDE LINES@w "`" "~"
echo

# initializations and functions
function FUNCexample() { #help function help text is here! MISSING DESCRIPTION
	# var init here
	
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then #FUNCexample_help
			SECFUNCshowHelp $FUNCNAME
			return 0
		elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #FUNCexample_help MISSING DESCRIPTION
			echo "#your code goes here"
		elif [[ "$1" == "--" ]];then #FUNCexample_help params after this are ignored as being these options
			shift
			break
		else
			SECFUNCechoErrA "invalid option '$1'"
			return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift
	done
	
	# code here
}

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--exampleoption" || "$1" == "-e" ]];then #help MISSING DESCRIPTION
		echo "#your code goes here"
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done

# Main code
SECFUNCexec -c --echo FUNCexample --help
SECFUNCexec -c --echo FUNCexample -e

exit 0

