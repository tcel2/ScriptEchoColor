#!/bin/bash

strSelfName="ScriptEchoColor"

installPath=`which "$strSelfName"`
if [[ -h "$installPath" ]]; then
	installPath=`readlink "$installPath"`
fi

installPath=`dirname "$installPath"` #remove the file name

if [[ "`basename "$installPath"`" != "bin" ]];then
	echo "$strSelfName should be at a '.../bin/' path!"
	exit 1
fi
installPath=`dirname "$installPath"` #remove the bin path

echo "$installPath"

