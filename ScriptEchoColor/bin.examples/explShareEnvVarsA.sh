#!/bin/bash

eval `secLibsInit.sh` #auto creates the DB based on script pid
varsetdb -f #force independant DB (in case parent shell has it set)

varset var1=10
while true; do
	varreaddb
	echo $var1
	sleep 1
done

