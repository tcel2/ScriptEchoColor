#!/bin/bash

strMainAppName="ScriptEchoColor"

installPath=`which "$strMainAppName"`
if [[ -h "$installPath" ]]; then
	installPath=`readlink "$installPath"`
fi

installPath=`dirname "$installPath"` #remove the file name

if [[ "`basename "$installPath"`" != "bin" ]];then
	echo "$strMainAppName should be at a '.../bin/' path!"
	exit 1
fi
installPath=`dirname "$installPath"` #remove the bin path

echo "$installPath"

