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

function FUNCarrayRestore() {
	local l_arrayName=$1
	local l_exportedArrayName=${l_arrayName}_exportedArray
	
	# if set, recover its value to array
	if eval '[[ -n ${'$l_exportedArrayName'+dummy} ]]'; then
		eval $l_arrayName'='`eval 'echo $'$l_exportedArrayName` #do not put export here!
	fi
}
export -f FUNCarrayRestore
	
function FUNCarrayFakeExport() {
	local l_arrayName=$1
	local l_exportedArrayName=${l_arrayName}_exportedArray
	
	# prepare to be shown with export -p
	eval 'export '$l_arrayName
	# collect exportable array in string mode
	local l_export=`export -p \
		|grep "^declare -ax $l_arrayName=" \
		|sed 's"^declare -ax '$l_arrayName'"export '$l_exportedArrayName'"'`
	# creates exportable non array variable (at child shell)
	eval "$l_export"
}
export -f FUNCarrayFakeExport

#example (works with bash 4.2.24):
# source exportArray.sh
# list=(a b c)
# FUNCarrayFakeExport list
# bash
# echo ${list[@]} #empty :(
# FUNCarrayRestore list
# echo ${list[@]} #profit! :D

