#!/bin/bash

eval `secLibsInit.sh` #auto creates the DB based on script pid

vset var1=10
while true; do
	vreaddb
	echo $var1
	sleep 1
done

