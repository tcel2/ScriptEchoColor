#!/bin/bash

eval `secLibsInit.sh` #auto creates the DB based on script pid
varsetdb -f #force independant DB (in case parent shell has it set)

varset varA=10;
varset varPid=$$

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

