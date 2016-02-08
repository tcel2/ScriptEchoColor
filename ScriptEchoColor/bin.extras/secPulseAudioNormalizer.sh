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

eval `secinit`

strExample="DefaultValue"
bCfgTest=false
CFGstrTest="Test"
astrRemainingParams=()
bEnable=true
SECFUNCcfgReadDB #after default variables value setup above
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do # checks if param is set
	SECFUNCsingleLetterOptionsA;
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Automatically configures pulseaudio ladspa normalizer."
		SECFUNCshowHelp --colorize "Implementation based on instructions from http://askubuntu.com/a/219921/46437, many thanks!"
		SECFUNCshowHelp
		exit 0
	elif [[ "$1" == "--remove" || "$1" == "-r" ]];then #help remove the sink from pulseaudio
		bEnable=false
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

strAudioOutput="`pacmd list-sinks |egrep "[[:blank:]]*name: " |sed -r 's".*<(.*)>"\1"'`";
strDriver="`ls /usr/lib/ladspa/dyson_compress_*.so`";
strDriver="`basename "$strDriver"`";
strDriver="${strDriver%.so}";

strPrefixName="ladspa_"
strSinkName="${strPrefixName}sink"
strNormSinkName="${strPrefixName}normalized"

if $bEnable;then
	if ! SECFUNCexecA -ce pacmd list-modules |grep "sink_name=${strPrefixName}";then
		SECFUNCexecA -ce \
			pacmd \
				load-module \
				module-ladspa-sink \
				sink_name="$strSinkName" \
				master="$strAudioOutput" \
				plugin="${strDriver}" \
				label=dysonCompress \
				control=0,1,0.5,0.99

		SECFUNCexecA -ce \
			pacmd \
				load-module \
				module-ladspa-sink \
				sink_name="$strNormSinkName" \
				master="$strSinkName" \
				plugin=fast_lookahead_limiter_1913 \
				label=fastLookaheadLimiter \
				control=10,0,0.8
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

