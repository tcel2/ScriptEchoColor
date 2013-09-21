#!/bin/bash

eval `secLibsInit.sh` #auto creates the DB based on script pid

vset varA=10;
vset varPid=$$

while true; do 
	vsyncwrdb; 
	if(($$==varPid));then
		pidThatSet="SELF"
	else
		pidThatSet=$varPid
	fi
	echo "[`SECFUNCdtTimePrettyNow`] this pid is $$; $varA was set by pid $pidThatSet; next varA=$((++varA)) set at SELF.";
	varPid=$$;
done

