#!/bin/bash
# Copyright (C) 2004-2013 by Henrique Abdalla
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

#trap 'SECFUNCvarReadDB;SECFUNCvarWriteDBwithLock;exit 2;' INT

# THIS TRAP IS BUGGING NORMAL EXECUTION, IMPROVE IT! to simulate the problem, uncomment it and: eval `echoc --libs-init`; while true; do echoc -w -t 10; done #now try to hit ctrl+c ...
#trap '
#	SEC_DEBUG=false;
#	SECFUNCvarReadDB;
#	SECFUNCvarWriteDBwithLock;
#	kill -SIGINT $$;
#	' INT

# Fix in case it is empty or something else, make it sure it is true or false.
# The comparison must be inverse to default value!
# This way, it can be inherited from parent!
if [[ "$SEC_DEBUG" != "true" ]]; then
	export SEC_DEBUG=false # of course, np if already "false"
fi
if [[ "$SEC_DEBUG_WAIT" != "true" ]]; then
	export SEC_DEBUG_WAIT=false # of course, np if already "false"
fi
if [[ "$SEC_DEBUG_SHOWDB" != "true" ]]; then
	export SEC_DEBUG_SHOWDB=false
fi
if [[ "$SECvarOptWriteAlways" != "false" ]]; then
	export SECvarOptWriteAlways=true
fi
#if [[ "$SECvarOptWriteDBUseFullEnv" != "false" ]]; then
#	export SECvarOptWriteDBUseFullEnv=true # EXPERIMENTAL!!!!
#fi
#@@@R if [[ "$SECvarInitialized" != "true" ]]; then
#@@@R 	export SECvarInitialized=false #initialized at SECFUNCvarInit
#@@@R fi
### !!!!!!!!! UPDATE l_allVars at SECFUNCvarWriteDB() !!!!!!!!!!!!!

function SECFUNCvarClearTmpFiles() { #help: remove tmp files that have no related pid\n\tOptions:\n\t--verbose shows what is happening
	local l_verbose=""
	local l_output="/dev/null"
	if [[ "$1" == "--verbose" ]]; then
		l_verbose=" -v "
		l_output="/dev/stdout"
	fi
	
	local l_printfTypeAndFullName='%y=%p\n'
	local l_sedAllThatIsSymlinkBecomes0='s"^l="0="' # to sort!
	local l_sedAllThatIsNotSymlinkBecomes1='s"^[^l]="1="' # to sort!
	local l_sedRemoveHeadingSortDigits='s"^[[:digit:]]=""'
	local l_sedAddQuotesToLine='s/.*/"&"/' # to eval work right when creating item in the list
	eval "local l_listFiles=(`\
		find /tmp -maxdepth 1 -name "SEC.*.vars.tmp" -printf "$l_printfTypeAndFullName" \
			|sed -e "$l_sedAllThatIsNotSymlinkBecomes1" -e "$l_sedAllThatIsSymlinkBecomes0" \
			|sort \
			|sed -e "$l_sedRemoveHeadingSortDigits" -e "$l_sedAddQuotesToLine"\
	`)"
	local l_file
	for l_file in "${l_listFiles[@]}"; do echo "found: $l_file" >>$l_output;done
	
	#@@@R eval "local l_listFiles=(`find /tmp -name "SEC.*.vars.tmp" -exec echo '"{}"' \;`)"
	local l_tot=${#l_listFiles[*]}
	for((i=0;i<l_tot;i++));do
		echo "check[$i]: ${l_listFiles[i]}" >>$l_output
		local l_file=${l_listFiles[i]}
		if [[ -z "$l_file" ]];then continue;fi # ignores unset item
		
		# get pid from filename
		local l_sedGetPidFromFilename='s"^.*/SEC[.].*[.]\([[:digit:]]*\)[.]vars[.]tmp$"\1"'
		local l_pid=`echo "$l_file" |sed "$l_sedGetPidFromFilename"`;
		if [[ -n `echo "$l_pid" |tr -d "[:digit:]"` ]]; then 
			echo "SECERROR: l_pid [$l_pid] must be only digits..." >>$l_output
			return 1; # if fail, tmp files will remain but script wont break... good?
		fi; 
		
		#local l_bHasPid=$(($?==0?true:false))
		local l_bHasPid=`if ps -p $l_pid >>/dev/null; then echo "true"; else echo "false";fi`
		#@@@R echo ">>>$l_bHasPid" >>$l_output
		
		# excludes from check list valid files (with related pid)
		if $l_bHasPid; then
			if [[ -h "$l_file" ]]; then
				# find linked file in the list
				for((i2=0;i2<l_tot;i2++));do
					if((i==i2));then continue; fi
					if [[ "`readlink "$l_file"`" == "${l_listFiles[i2]}" ]]; then
						echo "keep: ${l_listFiles[i2]}" >>$l_output
						unset l_listFiles[i2] # when reached at main loop (i), will be ignored!
						break;
					fi
				done
			fi
			echo "keep: ${l_listFiles[i]}" >>$l_output
			unset l_listFiles[i] # will be ignored (dummy as already being worked..)
			continue
		fi
		
		# remove real files for missing pids
		if ! $l_bHasPid; then 
			rm $l_verbose "$l_file" >>$l_output
		fi 
	done
	
	#@@@R find /tmp -name "SEC.*.vars.tmp" -exec bash -c 'FUNCgetPidFromFileName "{}"' ";" >$l_output 2>&1
}
function SECFUNCvarInit() { #help: generic vars initializer
	#@@@R if ! $SECvarInitialized; then
		SECFUNCvarClearTmpFiles
		SECFUNCvarSetFileName
		SECFUNCvarReadDB #important to update vars on parent shell when using eval `echoc --libs-init`
	#@@@R 	SECvarInitialized=true
	#@@@R fi
}
function SECFUNCvarEnd() { #help: generic vars finalizer
	SECFUNCvarEraseDB
}
function SECFUNCvarIsArray() {
	#local l_strTmp=`declare |grep "^$1=("`; #declare is a bit slower than export
	eval "export $1"
	local l_strTmp=`export |grep "^declare -ax $1='("`;
	
 	#if(($?==0));then
 	if [[ -n "$l_strTmp" ]]; then
 		return 0;
 	fi;
 	return 1;
#  local l_arrayCount=`eval 'echo ${#'$1'[*]}'`
#  if((l_arrayCount>1));then
#  	return 0;
# 	fi
# 	return 1
}
function SECFUNCvarGet() { #help: <varname> [arrayIndex] if var is an array, you can use a 2nd param as index in the array (none to return the full array)
  if `SECFUNCvarIsArray $1`;then
  	if [[ -n "$2" ]]; then
  		eval 'echo "${'$1'['$2']}"'
  	else
	  	#declare |grep "^$1=(" |sed 's"^'$1'=""'
	  	declare -p $1 |sed -r -e "s;^declare -[^ ]* $1=;;" -e "s;^'(.*)'$;\1;"
#			local l_value=""
#			#for val in `eval 'echo "${'$1'[@]}"'`; do
#			local l_tot=`eval 'echo "${#'$1'[*]}"'`
#			for((i=0;i<l_tot;i++)); do
#				local l_separator=`if((i==0));then echo "";else echo " ";fi`
#				#l_value="$l_value '$val'"
#				local l_val=`eval 'echo "${'$1'['$i']}"'`
#				l_val="`SECFUNCfixPliq "$l_val"`"
#				l_value="$l_value$l_separator\"$l_val\""
#			done
#			l_value="($l_value)"
#			echo "$l_value";
  	fi
  else
		#@@@R local varWithCurrencySign=`echo '$'$1`
		#@@@R eval 'echo "'$varWithCurrencySign'"'
		eval 'echo "$'$1'"'
	fi
}
function SECFUNCfixPliq() { #internal:
		#echo "$1"
  	#echo "$1" |sed -e 's/"/\\"/g' -e 's"\"\\"g'
  	echo "$1" |sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}
function SECFUNCvarShowSimple() { #help: (see SECFUNCvarShow)
  SECFUNCvarShow "$1"
}
function SECFUNCvarShow() { #help: show var, opt --towritedb
	local l_prefix="" #"export "
	if [[ "$1" == "--towritedb" ]]; then
		#l_prefix="SECFUNCvarSet --nowrite " # --nowrite because it will be used at read db
		l_prefix="export "
		shift
	fi
	
  if `SECFUNCvarIsArray $1`;then
  	#@@@ todo, support to "'"
		#echo "${l_prefix}$1=`SECFUNCvarGet $1`;";
		
		# IMPORTANT: arrays set inside functions cannot have export or they will be ignored!
		echo "$1=`SECFUNCvarGet $1`;";
  else
  	local l_value="`SECFUNCvarGet $1`"
  	l_value=`SECFUNCfixPliq "$l_value"`
		echo "${l_prefix}$1=\"$l_value\";";
		
		#echo "${l_prefix}$1='`SECFUNCvarGet $1`';";
		#echo "${l_prefix}$1=\"`SECFUNCvarGet $1`\";";
		
  	#local l_value="`SECFUNCvarGet $1`"
  	#l_value=`SECFUNCfixPliq "$l_value"`
		#echo "${l_prefix}$1=\"$l_value\";";
  fi
}
function SECFUNCvarShowDbg() { #help: only show var and value if SEC_DEBUG is set true
  if $SEC_DEBUG; then
    SECFUNCvarShow "$@"
  fi
}
function SECFUNCvarSet() { #help: [options] <<var> <value>|<var>=<value>> :\n\tOptions:\n\t--show will show always var and value;\n\t--showdbg will show only if SEC_DEBUG is set;\n\t--write (this is the default now) will also write value promptly to DB;\n\t--nowrite prevent promptly writing value to DB;\n\t--default will only set if variable is not set yet (like being initialized only ONCE);\n\t--array (auto detection) arrays must be set outside here, this param is just to indicate that the array must be registered, but it cannot (yet?) be set thru this function...;
	SECFUNCvarReadDB
	
	local l_bShow=false
	local l_bShowDbg=false
	#local l_bWrite=false
	local l_bWrite=$SECvarOptWriteAlways
	local l_bDefault=false
	local l_bArray=false
	while true; do
		if [[ "$1" == "--show" ]]; then
			l_bShow=true
			shift
		elif [[ "$1" == "--showdbg" ]]; then
			l_bShowDbg=true
			shift
		elif [[ "$1" == "--write" ]]; then
			l_bWrite=true
			shift
		elif [[ "$1" == "--array" ]]; then
			l_bArray=true
			shift
		elif [[ "$1" == "--nowrite" ]]; then
			l_bWrite=false
			shift
		elif [[ "$1" == "--default" ]]; then
			l_bDefault=true
			shift
		else
			break
		fi
	done
	
	local l_varPleaseDontUseThisVarNamePlease="$1"
	local l_value="$2"

	#if [[ -z "$l_value" ]]; then
	if echo "$l_varPleaseDontUseThisVarNamePlease" |grep -q "="; then
		sedVar='s"\(.*\)=.*"\1"'
		sedValue='s".*=\(.*\)"\1"'
		l_varPleaseDontUseThisVarNamePlease=`echo "$1" |sed "$sedVar"`
		l_value=`echo "$1" |sed "$sedValue"`
	fi
	
	if `SECFUNCvarIsArray $l_varPleaseDontUseThisVarNamePlease`; then
		l_bArray=true
		l_value=""
	fi
	
  SECFUNCvarRegisterWithLock $l_varPleaseDontUseThisVarNamePlease #must register before writing
  
	if ! $l_bArray; then
		local l_bSetVarValue=false
		if $l_bDefault; then
			# info: substitution: with "-" VAR has priority; with "+" ALTERNATE has priority
			#  [ -n "${VAR+ALTERNATE}" ] # Fails if VAR is unset
			#  [ -n "${VAR:+ALTERNATE}" ] # Fails if VAR is unset or empty
			#  [ -n "${VAR-ALTERNATE}" ] # Succeeds if VAR is unset
			#  [ -n "${VAR:-ALTERNATE}" ] # Succeeds if VAR is unset or empty
			#  ${VAR:=newValue} #assign newValue to VAR in case it is unset or empty, and substitute it
			#  ${VAR:?errorMessage} #if VAR is unset or empty, terminate shell script with errorMessage
		
			# set default value if variable is not set yet
			if ! eval "[[ -n \${$l_varPleaseDontUseThisVarNamePlease+someVarName} ]]"; then 
				l_bSetVarValue=true
			fi
		else
			l_bSetVarValue=true
		fi
		if $l_bSetVarValue; then
			eval "export $l_varPleaseDontUseThisVarNamePlease=\"`SECFUNCfixPliq "$l_value"`\""
			#eval "export $l_varPleaseDontUseThisVarNamePlease=\"$l_value\""
		fi
  fi

	if $l_bArray || $l_bSetVarValue; then
		if $l_bWrite; then
			SECFUNCvarWriteDBwithLock
		fi
	fi
  
  if $l_bShow; then # priority over show only in debug mode
	  SECFUNCvarShow $l_varPleaseDontUseThisVarNamePlease
  elif $l_bShowDbg; then
	  SECFUNCvarShowDbg $l_varPleaseDontUseThisVarNamePlease
	fi
}
function SECFUNCvarIsRegistered() { #help: check if var is registered
	#echo "${SECvars[*]}" |grep -q $1
	local l_var
	for l_var in ${SECvars[*]}; do
		if [[ "$1" == "$l_var" ]]; then
			return 0  # found = 0 = true
		fi
	done
	return 1
}
function SECFUNCvarIsSet() { #help: equal to: SECFUNCvarIsRegistered
	SECFUNCvarIsRegistered $1
	return $?
}
function SECFUNCdebugMsg() {
	echo "SEC_DEBUG(`basename "$0"`:$LINENO): $@" >>/dev/stderr
}
function SECFUNCdebugMsgWaitAkey() {
	if $SEC_DEBUG_WAIT;then
		SECFUNCdebugMsg "press a key to continue..."
		read -n 1
	fi
}
function SECFUNCvarWaitValue() { #help: [--not] <var> <value> [delay=1]: wait until var has specified value. Also get the var. --not if the value differs from specified.
	local l_bNot=false
	while true; do
		if [[ "$1" == "--not" ]]; then
			l_bNot=true
			shift
		else
			break
		fi
	done
	
	local l_var=$1
	local l_valueCheck="$2"
	local l_delay=$3
	if [[ -z "$l_delay" ]]; then
		l_delay=1
	fi
	
	while true; do
		SECFUNCvarReadDB $l_var
		local l_value=`SECFUNCvarGet $l_var`;
		local l_bOk=false;
		
		if $l_bNot; then
			if [[ "$l_value" != "$l_valueCheck" ]]; then
				l_bOk=true;
			fi
		else
			if [[ "$l_value" == "$l_valueCheck" ]]; then
				l_bOk=true;
			fi
		fi
		if $l_bOk; then
			SECFUNCvarGet $l_var #this is to also create the variable on caller
			break;
		fi
		if ! sleep $l_delay; then kill -SIGINT $$; fi
		#read -t $l_delay #bash will crash!
	done
}
function SECFUNCvarWaitRegister() { #help: <var> [delay=1]: wait var be stored. Loop check delay can be float. Also get the var.
	local l_delay=$2
	if [[ -z "$l_delay" ]]; then
		l_delay=1
	fi
	
	while true; do
		SECFUNCvarReadDB $1
		if $SEC_DEBUG;then local l_value=`SECFUNCvarGet $1`;SECFUNCdebugMsg "$1=$l_value";fi
		if SECFUNCvarIsSet $1; then
			SECFUNCvarGet $1 #this is to also create the variable on caller
			break;
		fi
		if ! sleep $l_delay; then kill -SIGINT $$; fi
		#read -t $l_delay #bash will crash!
	done
}
function SECFUNCvarRestoreVarsArray() { #private: 
	# if SECvarsTmp is set, recover its value to array
	if [[ -n ${SECvarsTmp+dummy} ]]; then
		eval 'SECvars='$SECvarsTmp #do not put export here! this is just to transform the string back into a valid array. Arrays cant currently be exported by bash.
	fi
}
function SECFUNCvarPrepareVarsArrayToExport() { #private: 
	if((${#SECvars[*]}==0));then
		export SECvars=()
	else
		# just prepare to be shown with `declare` below
		export SECvars
	fi
	# collect exportable array in string mode
	l_export=`declare -p SECvars |sed 's"^declare -ax SECvars"export SECvarsTmp"'`
	# creates SECvarsTmp to be restored as array at SECFUNCvarRestoreVarsArray (on a child shell)
	eval "$l_export"
}

function SECFUNCvarRegisterWithLock() { #private: 
	if ! SECFUNCvarIsRegistered $1; then
		# var is registered at child shell
		flock -x "$SECvarFile" bash -c "SECFUNCvarRegister $1"
		
		# udpate this shell with registered var
		SECFUNCvarReadDB SECvars
	fi
}
function SECFUNCvarRegister() { #private: 
	SECFUNCvarReadDB SECvars
	#SECFUNCvarLoadMissingVars
	#SECFUNCvarReadDB
	
	# wont work as: export SECvars #because bash cant export arrays...
	SECvars+=($1)
	SECFUNCvarPrepareVarsArrayToExport # so SECvars is always ready when SECFUNCvarRestoreVarsArray is used at child shell
	
	SECFUNCvarWriteDB SECvars
}

function SECFUNCvarWriteDBwithLock() { #help: write variables to the temporary file with exclusive lock
	#SECFUNCvarPrepareVarsArrayToExport #redundant?
	#flock -x "$SECvarFile" bash -c "SECFUNCvarRestoreVarsArray;SECFUNCvarWriteDB"
	#flock -x "$SECvarFile" bash -c "SECFUNCvarWriteDBwithLockHelper"
	flock -x "$SECvarFile" bash -c "SECFUNCvarLoadMissingVars;SECFUNCvarWriteDB"
	
	##### TEST CASE (concurrent write DB test):
  # SEC_DEBUG=true
  # function FUNCdoIt() { SECFUNCvarSet varTst$1=$1;echo $1; };
  # for((i=0;i<10;i++));do FUNCdoIt $i& done
  # cat $SECvarFile 	
  #####
}
function SECFUNCvarLoadMissingVars() { #private: 
	# load new vars list
	SECFUNCvarReadDB SECvars;
	
	# load only variables that are missing, to prevent overwritting old variables values
	local l_varsMissing=()
	for l_varNew in ${SECvars[@]};do
		if ! declare -p $l_varNew >/dev/null 2>&1;then
			SECFUNCvarReadDB $l_varNew;
			l_varsMissing+=($l_varNew)
		fi
	done
#	echo "SECvars=${SECvars[@]}" >/dev/stderr
#	echo "MisVars=${l_varsMissing[@]}" >/dev/stderr
#	cat $SECvarFile |grep varTst |grep -v SECvars >/dev/stderr
}
#function SECFUNCvarWriteDBwithLockHelper() { #private: 
#	SECFUNCvarLoadMissingVars
#	
#	# ready to write the DB!
#	SECFUNCvarWriteDB;
#}
function SECFUNCvarWriteDB() { #private: 
	if $SEC_DEBUG; then SECFUNCdebugMsg "writing DB file: $SECvarFile"; fi
	
	local l_filter=$1; #l_filter="" #@@@TODO FIX FILTER FUNCTIONALITY THAT IS STILL BUGGED!
	local l_allVars=()
	
#  if $SECvarOptWriteDBUseFullEnv;then
  	#declare >"$SECvarFile" #I believe was not too safe
  	
	if [[ -n "$l_filter" ]];then
		l_allVars=($l_filter)
		#TODO for some reason this sed is breaking the db file data; without it the new var value will be appended and the next db read will ensure the last var value be the right one (what a mess..)
		#sed -i "/^$l_filter=/d" "$SECvarFile" #remove the line with the var
	else
		# do not save these (to prevent them being changed at read db):
		#SEC_DEBUG
		#SEC_DEBUG_SHOWDB
		# this seems safe!  	
		l_allVars=(
			SECvars
			SECvarFile
			SECvarOptWriteAlways
		)
		l_allVars+=(${SECvars[@]})
		if $SEC_DEBUG; then SECFUNCdebugMsg "l_allVars=(${l_allVars[@]})"; fi
		#declare |grep "^`echo ${l_allVars[@]} |sed 's" "=\\\|^"g'`" >"$SECvarFile"
		#if((${#SECvars[*]}==0));then SECvars=();fi
		echo -n >"$SECvarFile" #clean db file
	fi
	
	local l_sedRemoveArrayPliqs="s;(^.*=)'(\(.*)'$;\1\2;"
	declare -p ${l_allVars[@]} 2>/dev/null |sed -r -e 's"^declare -[^ ]* ""' -e "$l_sedRemoveArrayPliqs" >>"$SECvarFile"
#  else
#	  echo >"$SECvarFile" #clean
#	  
#		# register vars to speed up read db
#		echo "export SECvars=(${SECvars[@]});" >>"$SECvarFile"
#		 
#		local l_var
#		for l_var in ${SECvars[*]}; do
#		  SECFUNCvarShow --towritedb $l_var >>"$SECvarFile"
#		done
#  fi
  
	if $SEC_DEBUG && $SEC_DEBUG_SHOWDB; then 
		SECFUNCdebugMsg "Show DB $SECvarFile"
		cat "$SECvarFile" >>/dev/stderr
		SECFUNCdebugMsgWaitAkey
	fi
}

function SECFUNCvarReadDB() { #help: [varName] filter to load only one variable value
	local l_filter
	if [[ -n "$1" ]];then
		l_filter=$1
	fi
	
	if $SEC_DEBUG; then 
		SECFUNCdebugMsg "reading DB file: $SECvarFile"; 
		if $SEC_DEBUG_SHOWDB;then
			cat "$SECvarFile" >>/dev/stderr
		fi
	fi
	
	if [[ -n "$l_filter" ]];then
	  #eval "`cat "$SECvarFile" |grep "^${l_filter}="`" >/dev/null 2>&1
	  eval "`grep "^${l_filter}=" "$SECvarFile"`" >/dev/null 2>&1
	else
	  eval "`cat "$SECvarFile"`" >/dev/null 2>&1
	fi
	SECFUNCvarPrepareVarsArrayToExport #makes SECvars work again
}
function SECFUNCvarEraseDB() { #help: 
  rm "$SECvarFile"
}
function SECFUNCvarSetFileName() { #help: [pid] tmp file is automatic
	local l_pid="$1"
	
	# if pid info is not set, get current script pid
	if [[ -z "$l_pid" ]]; then
		l_pid=$$
	fi
	
	# if file vars is already set, prevent doing it again! so nested/child scripts will stay with the same file!!!
	local l_varFile="/tmp/SEC.`basename "$0"`.$l_pid.vars.tmp"
	if [[ ! -n "${SECvarFile+x}" ]]; then
	  export SECvarFile="$l_varFile"
	  #@@@R SECFUNCvarWriteDBwithLock #initially empty
	fi
	
	# make sure file exists
	if [[ ! -f "$SECvarFile" ]];then
	  SECFUNCvarWriteDBwithLock #initially empty
	fi
	
	# if there is already a file, create a symlink to it to SECFUNCvarClearTmpFiles know not to rm in case parent pid dies
	if [[ "$l_varFile" != "$SECvarFile" ]]; then
		ln -sf "$SECvarFile" "$l_varFile"
	fi
}
function SECFUNCvarUnitTest() {
	echo "Test to set and get values:"
	local l_values=(
		"123"
		"a b c" 
		"a'b" 
		"a' b" 
		"a'b'" 
		"a '  b' c" 
		"1.2.3" 
		"123.4" 
		"a\"b" 
		"a\"b\"c" 
		"a\"b \"c" 
		"a\"b\" c"
		"a\\//\\\"b\" c"
	)
	for((i=0;i<${#l_values[@]};i++));do
		local l_var
		SECFUNCvarSet l_var="${l_values[i]}"
		if [[ "`SECFUNCvarGet l_var`" != "${l_values[i]}" ]]; then
			echo "FAIL to: ${l_values[i]}"
		else
			echo "OK to: ${l_values[i]}"
		fi
	done
	#SECFUNCvarSet --array l_values
	SECFUNCvarSet l_values
	SECFUNCvarShow l_values
}

