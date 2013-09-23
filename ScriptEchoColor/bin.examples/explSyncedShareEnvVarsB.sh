#!/bin/bash

eval `secLibsInit.sh` #auto creates the DB based on script pid

pidOtherScript=`ps -A -o pid,command |grep "explSyncedShareEnvVarsA.sh" |grep -v grep |sed -r 's"^[ ]*([[:digit:]]*) .*"\1"'`
varsetdb $pidOtherScript #changes the auto created DB to be the other script DB

#varset varA=10; #do not set it here; Script A is the main one.
#varset varPid=$$ #do not set it here; Script A is the main one.

while true; do 
	varsyncwrdb; 
	if(($$==varPid));then
		pidThatSet="SELF"
	else
		pidThatSet=$varPid
	fi
	echo "[`SECFUNCdtTimePrettyNow`] this pid is $$ (exec count ${SECmultiThreadEvenPids[$$]}); $varA was set by pid $pidThatSet; next varA=$((++varA)) set by SELF.";
	varPid=$$;
done

