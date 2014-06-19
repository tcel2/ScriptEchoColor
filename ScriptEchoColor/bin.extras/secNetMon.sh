#!/bin/bash
# Copyright (C) 2014-2014 by Henrique Abdalla
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

strSelfName="`basename "$0"`"

bDaemon=false
bRestart=false
nDelay=0
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	if [[ "$1" == "--help" ]];then #help show this help
		SECFUNCshowHelp --colorize "Using nethogs, reports a total of sent and received network data for each application."
		SECFUNCshowHelp 
		exit
	elif [[ "$1" == "--daemon" ]];then #help start the daemon
		bDaemon=true
	elif [[ "$1" == "--restart" ]];then #help restart the daemon
		bDaemon=true
		bRestart=true
	elif [[ "$1" == "--delay" ]];then #help delay between checks (works for daemon and for default monitoring)
		shift
		nDelay=${1-}
	else
		SECFUNCechoErrA "invalid option '$1'"
		exit 1
	fi
	shift
done

if ! SECFUNCisNumber "$nDelay";then
	SECFUNCechoErrA "invalid nDelay='$nDelay'"
	exit 1
fi
if((nDelay==0));then
	if $bDaemon;then
		nDelay=10
	else
		nDelay=600
	fi
fi

strNethogsMinVersion="0.8.1"
strNethogsVersion="`nethogs -V 2>&1 |sed -r 's"^[^[:digit:]]*([[:digit:]][[:digit:].]*).*"\1"'`"
if [[ "$strNethogsMinVersion" != "$strNethogsVersion" ]];then 
	strMinVersion="`echo -e "${strNethogsMinVersion}\n${strNethogsVersion}" |sort -V |head -n 1`"
	if [[ "$strMinVersion" != "$strNethogsMinVersion" ]];then
		SECFUNCechoErrA "strNethogsVersion='$strNethogsVersion' < strNethogsMinVersion='$strNethogsMinVersion', try installing nethogs from its CVS"
		exit 1
	fi
fi
SECFUNCechoDbgA "strNethogsVersion='$strNethogsVersion', strNethogsMinVersion='$strNethogsMinVersion'"

strNethogsLogFile="/tmp/.$strSelfName.nethogs.log"
if $bDaemon;then
	strCmdNetHogs="`which nethogs` -b -v 2"
	
	while true;do
		if $bRestart;then
			#echoc -x "pkill -fe '$strCmdNetHogs'" #without -x it will kill itself too...
			SECFUNCexecA --echo pkill -fe "$strCmdNetHogs"
		fi

		SECFUNCuniqueLock --setdbtodaemon

		if $SECbDaemonWasAlreadyRunning && ! $bRestart;then
			SECFUNCechoErrA "daemon already running..."
			exit 1
		fi
		
		if ! $SECbDaemonWasAlreadyRunning;then
			break;
		fi
		
		sleep 5
	done

	# shows sent and received in total of bytes
	if ! $strCmdNetHogs -d $nDelay >>"$strNethogsLogFile";then
		SECFUNCechoErrA "\`$strCmdNetHogs\` execution failed or was terminated..."
		exit 1
	fi
else
	charTab="`echo -en "\t"`"
	while true;do
		strEvaluateableCmds="`cat "$strNethogsLogFile" \
			|grep "$charTab" \
			|sed -r "s@^([^\t]*)/([[:digit:]]*)/([[:digit:]]*)\t([[:digit:]]*)\t([[:digit:]]*)@strCmd='\1';nPid='\2';nUser='\3';nSent='\4';nReceived='\5'@"`"
		
		anPids=(`echo "$strEvaluateableCmds" \
			|grep -o "nPid='[[:digit:]]*'" \
			|sed -r "s@nPid='([[:digit:]]*)'@\1@" |sort -un`)
		
		if((`SECFUNCarraySize anPids`>0));then
			echo -e "User\tPid\tSentTotal\tReceivedTotal\tCommand"
			for nPid in "${anPids[@]}";do
				strFullDataToPid="`echo "$strEvaluateableCmds" |grep ";nPid='$nPid';"`"
				strCmdToEval="`echo "$strFullDataToPid" |head -n 1`"
				if ! eval "$strCmdToEval";then
					SECFUNCechoErrA "eval '$strCmdToEval' failed..."
					echoc -w
					exit 1
				fi
				#echo "$strFullDataToPid" |tail -n 1
		
				function FUNCcalcTotal(){
					local lstrId="$1"
			
					local lnPrevious=0
					local lnTotal=0
					local lnCurrent=0
					local lanCurrent=(`echo "$strFullDataToPid" \
						|grep -o "${lstrId}='[[:digit:]]*'" \
						|sed -r "s@${lstrId}='([[:digit:]]*)'@\1@" \
						|gawk '!seen[$0]++'`)
		#				|while read lnCurrent;do
					for lnCurrent in ${lanCurrent[@]};do
		#				echo "1)lnCurrent='$lnCurrent',lnPrevious='$lnPrevious',lnTotal='$lnTotal'" >>/dev/stderr
						if((lnPrevious>lnCurrent));then
							SECFUNCechoDbgA "lnPrevious='$lnPrevious' > lnCurrent='$lnCurrent'"
							((lnTotal+=lnPrevious))
						fi
						lnPrevious="$lnCurrent"
					done
					SECFUNCechoDbgA "lnTotal='$lnTotal' += lnPrevious='$lnPrevious'"
					echo $((lnTotal+=lnPrevious))
		#			echo "1)lnCurrent='$lnCurrent',lnPrevious='$lnPrevious',lnTotal='$lnTotal'" >>/dev/stderr
				}
				nSentTotal="`FUNCcalcTotal nSent`"
				nReceivedTotal="`FUNCcalcTotal nReceived`"
				strUser="`getent passwd "$nUser" | cut -d: -f1`"
				echo -e "$strUser\t$nPid\t$nSentTotal\t$nReceivedTotal\t$strCmd"
				#echo "$strFullDataToPid" |grep -o "nReceived='[[:digit:]]*'" |gawk '!seen[$0]++'
			done
		fi
		
		echoc -w -t $nDelay
	done
fi

