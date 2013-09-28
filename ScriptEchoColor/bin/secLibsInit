#!/bin/bash

SECinstallPath=`secGetInstallPath.sh`
while [[ "${1:0:2}" == "--" ]];do
	if [[ "$1" == "--help" ]];then
		echo "Initialize environment variables sharing between bash scripts."
		echo 'use like: eval `'`basename $0`'`'
		echo
		
		#strInfo="(all functions are prefixed with: \"SECFUNC\", ex.: SECFUNCshowVar())"
		echo "HELP on Libs functions:"
		echo
		#echo "$strInfo"
		echo "at: $SECinstallPath/lib/ScriptEchoColor"
	
		cd "$SECinstallPath/lib/ScriptEchoColor"
	
		#function FUNCechoPipe() {
		#	read str
		#	echo -en "$str"
		#};export -f FUNCechoPipe
		function FUNCtoFind() { 
			echo "File: ${1:2}"; #remove heading "./"
			sedGatherHelpText='s"function \(SECFUNC[[:alnum:]].*()\).*#help: \(.*\)"  \1\t\2"';
			sedTranslateNewLine='s"[\]n"\n"g'
			sedTranslateTab='s"[\]t"\t"g'
			#grep "function SECFUNC.*#help:" "$1" |sed "$sedGatherHelpText" |FUNCechoPipe;
			grep "function SECFUNC.*#help:" "$1" |sed "$sedGatherHelpText" |sed "$sedTranslateNewLine" |sed "$sedTranslateTab";
		};export -f FUNCtoFind
		find ./ -iname "*.sh" -exec bash -c 'FUNCtoFind "{}"' \;
		 
		#echo "$strInfo"
		exit
	else
		echoc -p "invalid option: $1"
		exit 1
	fi
	shift
done

# echo 'export SECinstallPath="`secGetInstallPath.sh`";' #at funcMisc
# echo 'source "$SECinstallPath/lib/ScriptEchoColor/utils/funcMisc.sh";' #at funcVars
echo "source \"$SECinstallPath/lib/ScriptEchoColor/utils/funcVars.sh\";"
echo 'eval "`SECFUNCexportFunctions`";'
echo 'SECFUNCvarInit;'

