#!/bin/bash
# Copyright (C) 2016 by Henrique Abdalla
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

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
bEnable=true

strDriver="`ls /usr/lib/ladspa/dyson_compress_*.so`";
strDriver="`basename "$strDriver"`";
strDriver="${strDriver%.so}";
echo "strDriver='$strDriver'"
strDriverOpt="0,1,0.5,0.99"

strDriverFLL="`ls /usr/lib/ladspa/fast_lookahead_limiter_*.so`"
strDriverFLL="`basename "$strDriverFLL"`"
strDriverFLL="${strDriverFLL%.so}"
echo "strDriverFLL='$strDriverFLL'"
strDriverFLLOpt="10,0,0.8"

bFix=false

SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Automatically configures pulseaudio ladspa normalizer."
		SECFUNCshowHelp --colorize "Implementation based on instructions from http://askubuntu.com/a/219921/46437, many thanks!"
		SECFUNCshowHelp
		exit 0
#	elif [[ "$1" == "--fix" ]];then #help try to fix pulseaudio if it is not working
#		bFix=true
	elif [[ "$1" == "--remove" || "$1" == "-r" ]];then #help remove the sink from pulseaudio
		bEnable=false
	elif [[ "$1" == "--driveropt" ]];then #help <strDriverOpt> options for strDriver
		shift
		strDriverOpt="${1-}"
	elif [[ "$1" == "--driverfllopt" ]];then #help <strDriverFLLOpt> options for strDriverFLL
		shift
		strDriverFLLOpt="${1-}"
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

# the best way to workaround pulseaudio problems is to completely stop it and fallback to alsa, in the current session (or just reboot)
#if $bFix;then
#	SECFUNCexecA -ce pulseaudio --cleanup-shm
#	echoc -w "ctrl+c if it is working"
#	SECFUNCexecA -ce sudo -k service pulseaudio stop
#	SECFUNCexecA -ce pulseaudio --cleanup-shm
#	echoc -w -t 10
#	SECFUNCexecA -ce pulseaudio -D
#fi

#strAudioOutput="`pacmd list-sinks |egrep "[[:blank:]]*name: " |sed -r 's".*<(.*)>"\1"'`";
strDefaultAudioOutput="`pacmd list-sinks |grep "* index" -A 1 |grep name |sed -r 's".*<(.*)>"\1"'`";
declare -p strDefaultAudioOutput 

strPrefixName="ladspa_"
strSinkName="${strPrefixName}sink"
strNormSinkName="${strPrefixName}normalized"

SECFUNCuniqueLock --waitbecomedaemon

if $bEnable;then
	if ! SECFUNCexecA -ce pacmd list-modules |grep "sink_name=${strPrefixName}";then
		SECFUNCexecA -ce \
			pacmd \
				load-module \
				module-ladspa-sink \
				sink_name="$strSinkName" \
				master="$strDefaultAudioOutput" \
				plugin="${strDriver}" \
				label=dysonCompress \
				control="$strDriverOpt"

		SECFUNCexecA -ce \
			pacmd \
				load-module \
				module-ladspa-sink \
				sink_name="$strNormSinkName" \
				master="$strSinkName" \
				plugin="$strDriverFLL" \
				label=fastLookaheadLimiter \
				control="$strDriverFLLOpt"
	else
		echoc --info "already setup"
	fi
	
	SECFUNCexecA -ce pacmd set-default-sink "$strNormSinkName"
else
#	SECFUNCexecA -ce pacmd unload-module module-ladspa-sink sink_name="$strSinkName"
#	SECFUNCexecA -ce pacmd unload-module module-ladspa-sink sink_name="$strNormSinkName"
	SECFUNCexecA -ce pacmd unload-module module-ladspa-sink
fi

exit 0

