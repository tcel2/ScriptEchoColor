#!/bin/bash

eval `secLibsInit.sh` #auto create DB based on pid

pidOtherScript=`ps -A -o pid,command |grep explShareEnvVarsA.sh |grep -v grep |sed -r 's"^[ ]*([[:digit:]]*) .*"\1"'`
vsetdb $pidOtherScript #changes the auto created DB to be the other script DB

while true; do
	vset var1=`echoc -S "type new value"`
done

