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

bPlaySample=true
bPlayBeep=true
nSecondsLimit=1
nFreqReduction=0
nSampleDelay=5
nSampleRateRequired=1000 #beep max frequency is 1Khz so 1000

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		echoc --alert "STILL NOT WORKING!!!"
		SECFUNCshowHelp --colorize "..."
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--nobeep" || "$1" == "-B" ]];then #help just to make quiet tests..
		bPlayBeep=false
	elif [[ "$1" == "--seconds" || "$1" == "-s" ]];then #help <nSecondsLimit> limit to this amount of time
		shift
		nSecondsLimit="${1-}"
	elif [[ "$1" == "--freqreduction" || "$1" == "-r" ]];then #help <nFreqReduction> reduce this value from all frequencies
		shift
		nFreqReduction="${1-}"
	elif [[ "$1" == "--samplerate" || "$1" == "-s" ]];then #help <nSampleRateRequired> the sample rate used on the output files
		shift
		nSampleRateRequired="${1-}"
#	elif [[ "$1" == "--examplecfg" || "$1" == "-c" ]];then #help [CFGstrTest]
#		if ! ${2+false} && [[ "${2:0:1}" != "-" ]];then #check if next param is not an option (this would fail for a negative numerical value)
#			shift
#			CFGstrTest="$1"
#		fi
#		
#		bCfgTest=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options, and stored at astrRemainingParams
		shift #astrRemainingParams=("$@")
		while ! ${1+false};do	# checks if param is set
			astrRemainingParams+=("$1")
			shift #will consume all remaining params
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
SECFUNCcfgAutoWriteAllVars #this will also show all config vars


strInputFile="${1-}"

if [[ -z "$strInputFile" ]];then
	echoc -p "missing strInputFile='$strInputFile'"
	exit 1
fi

strOutputFile="${strInputFile%.???}-Mono${nSampleRateRequired}hz"
if $bPlaySample;then
	SECFUNCexecA -ce sox "$strInputFile" -c 1 -r $nSampleRateRequired "${strOutputFile}.wav"
	(
		mplayer "${strOutputFile}.wav" >>/dev/null 2>&1 &
		nPlayPid=$!
		sleep $nSampleDelay
		kill -SIGKILL $nPlayPid
	)&
fi
SECFUNCexecA -ce sox "$strInputFile" -c 1 -r $nSampleRateRequired "${strOutputFile}.dat"

ls -l "${strOutputFile}.dat"

nSampleRate="`head -n 1 "${strOutputFile}.dat" |tr -d '\r' |sed -r 's"; Sample Rate ([[:digit:]]*)"\1"'`"
echo "file nSampleRate='$nSampleRate'"
if((nSampleRateRequired<nSampleRate));then
	echoc -p "invalid nSampleRate='$nSampleRate' > nSampleRateRequired='$nSampleRateRequired'"
	exit 1
fi

nLength=$((nSampleRate))

nPrecision=5 # frequency will be limited by it
# beep frequency is from 0 to 19999
# sox dat frequency is from -1.0 to 1.0
strAwkCalc="{ \
	n=+\$1; \
	n=(10000*n)+10000; \
	n=(n>=20000 ? 19999 : n); \
	n-=$nFreqReduction; \
	n=(n<0 ? 0 : n); \
	printf \"%.${nPrecision}f\n\", n; }"
# each sox dat line has two values (1st value is the time, 2nd is the frequency)
astrFrequencies=(`head -n $((nSecondsLimit*500)) "${strOutputFile}.dat" \
	|tr -d '\r' \
	|egrep -v "^;.*" \
	|sed -r "s' *([^ ]*) *([^ ]*)'\2'" \
	|gawk "$strAwkCalc" 
`)
#	|sed -r "s' *([^ ]*) *([^ ]*)'\1\n\2'" \
#	|sed -r "s'.*'(10000*&)+9999'" #|bc -l
echo "MinFreq:`echo "${astrFrequencies[@]}" |tr ' ' '\n' |sort -n |head -n 1`"
echo "MaxFreq:`echo "${astrFrequencies[@]}" |tr ' ' '\n' |sort -n |tail -n 1`"
astrBeepParams=(`echo "${astrFrequencies[@]}" |tr ' ' '\n' |sed -r "s'.*'-n -l 1 -f &'"`)

echo -e "beep ${astrBeepParams[@]:0:100}" |sed 's"-n"\n"g';echo
echo "(First 100 sample) beep ${astrBeepParams[@]:0:100}"

#echo "beeps count: `bc <<< "${#astrBeepParams[@]}/5"`"
echo "beeps count: ${#astrFrequencies[@]}"
if $bPlayBeep;then
	SECFUNCdelay astrBeepParams --init
	beep "${astrBeepParams[@]}"
	echoc --info "delay `SECFUNCdelay astrBeepParams`s"
fi

exit 0

