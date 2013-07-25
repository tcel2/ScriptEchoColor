#!/bin/bash

cmd="$1"
if [[ -z "$cmd" ]];then
	cmd="echo -n"
fi
bash -c "\
	export PATH=\"$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin:$PATH\";\
	eval \`echoc --libs-init\`;\
	$cmd;\
	bash;"

