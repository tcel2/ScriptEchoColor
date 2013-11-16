#!/bin/bash

cmd="$1"
if [[ -z "$cmd" ]];then
	cmd="echo -n"
fi
bash -c "\
	export PATH=\"$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin:$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin.extras:$PATH\";\
	eval \`secLibsInit.sh\`;\
	$cmd;\
	echoc --alert ' now copy and run this (triple click on the line below) ';\
	echo 'eval \`secLibsInit.sh\`';\
	echo;\
	bash;"

