#!/bin/bash
# Copyright (C) 2019 by Henrique Abdalla
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

source <(secinit)

function FUNCcodingGuide(){
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
		@y2      @wMisuse of shell builtins (according to Bash documentation) (but seems to be only returned by bash builtins...)
		@r126    @wCommand invoked cannot execute
		@r127    @wcommand not found
		@r128+n  @wFatal error signal n
		@r130    @wScript terminated by Ctrl-C
		@r255*   @wExit status out of range
		@wSo basically you can safely go from @g0 @wto @g125@w!
		"
	SECFUNCdrawLine "`echoc " @{ly}<@{-ty}---@{lw}<< @{lb}CODING GUIDE LINES@w "`" "~"
	echo
}

# initializations and functions
function FUNCexample() { #help function help text is here! MISSING DESCRIPTION
	SECFUNCdbgFuncInA;
	# var init here
	local lstrExample="DefaultValue"
  local lbExample=false
	local lastrRemainingParams=()
	local lastrAllParams=("${@-}") # this may be useful
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
		#SECFUNCsingleLetterOptionsA; #this may be encumbersome on some functions?
		if [[ "$1" == "--help" ]];then #FUNCexample_help show this help
			SECFUNCshowHelp $FUNCNAME
			SECFUNCdbgFuncOutA;return 0
		elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #FUNCexample_help <lstrExample> MISSING DESCRIPTION
			shift;lstrExample="${1-}"
    elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #FUNCexample_help MISSING DESCRIPTION
      lbExample=true
		elif [[ "$1" == "--" ]];then #FUNCexample_help params after this are ignored as being these options, and stored at lastrRemainingParams. TODO explain how it will be used
			shift #lastrRemainingParams=("$@")
			while ! ${1+false};do	# checks if param is set
				lastrRemainingParams+=("$1")
				shift&&: #will consume all remaining params
			done
		else
			SECFUNCechoErrA "invalid option '$1'"
			$FUNCNAME --help
			SECFUNCdbgFuncOutA;return 1
#		else #USE THIS INSTEAD, ON PRIVATE FUNCTIONS
#			SECFUNCechoErrA "invalid option '$1'"
#			_SECFUNCcriticalForceExit #private functions can only be fixed by developer, so errors on using it are critical
		fi
		shift&&:
	done
	
	#validate params here
	
	# work here
  if((`SECFUNCarraySize lastrRemainingParams`>0));then :;fi
	
	SECFUNCdbgFuncOutA;return 0 # important to have this default return value in case some non problematic command fails before returning
}

declare -p SECstrUserScriptCfgPath
strExample="DefaultValue"
bExample=false
bExitAfterConfig=false
CFGstrTest="Test"
CFGstrSomeCfgValue=""
astrRemainingParams=()
astrAllParams=("${@-}") # this may be useful

SECFUNCcfgReadDB ########### AFTER!!! default variables value setup above, and BEFORE the skippable ones!!!

: ${bWriteCfgVars:=true} #help false to speedup if writing them is unnecessary
: ${strEnvVarUserCanModify:="test"}
export strEnvVarUserCanModify #help this variable will be accepted if modified by user before calling this script
export strEnvVarUserCanModify2 #help test

while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "\t#MISSING DESCRIPTION script main help text goes here"
		SECFUNCshowHelp --colorize "\tConfig file: '`SECFUNCcfgFileName --get`'"
		echo
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "-c" || "$1" == "--configoption" ]];then #help <CFGstrSomeCfgValue> MISSING DESCRIPTION
		shift;CFGstrSomeCfgValue="${1-}"
		bExitAfterConfig=true
	elif [[ "$1" == "-e" || "$1" == "--exampleoption" ]];then #help <strExample> MISSING DESCRIPTION
		shift;strExample="${1-}"
	elif [[ "$1" == "-s" || "$1" == "--simpleoption" ]];then #help MISSING DESCRIPTION
		bExample=true
	elif [[ "$1" == "-v" || "$1" == "--verbose" ]];then #help shows more useful messages
		SECbExecVerboseEchoAllowed=true #this is specific for SECFUNCexec, and may be reused too.
	elif [[ "$1" == "--cfg" ]];then #help <strCfgVarVal>... Configure and store a variable at the configuration file with SECFUNCcfgWriteVar, and exit. Use "help" as param to show all vars related info. Usage ex.: CFGstrTest="a b c" CFGnTst=123 help
		shift
		pSECFUNCcfgOptSet "$@";exit 0;
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams. TODO explain how it will be used
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift&&: #will consume all remaining params
		done
	else
		echoc -p "invalid option '$1'"
		#"$SECstrScriptSelfName" --help
		$0 --help #$0 considers ./, works best anyway..
		exit 1
	fi
	shift&&:
done
# IMPORTANT validate CFG vars here before writing them all...
if $bWriteCfgVars;then SECFUNCcfgAutoWriteAllVars;fi #this will also show all config vars
if $bExitAfterConfig;then exit 0;fi

### collect required named params
# strParam1="$1";shift
# strParam2="$1";shift

# Main code
if SECFUNCarrayCheck -n astrRemainingParams;then :;fi

SECFUNCexec -ce FUNCcodingGuide
SECFUNCexec -ce FUNCexample --help

# SECFUNCuniqueLock --waitbecomedaemon # if a daemon or to prevent simultaneously running it

exit 0 # important to have this default exit value in case some non problematic command fails before exiting

