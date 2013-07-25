cmd="$1"
if [[ -z "$cmd" ]];then
	cmd="echo -n"
fi
bash -c "\
	export PATH=\"$HOME/Projects/ScriptEchoColor/SourceForge.SVN/scriptechocolor/ScriptEchoColor/bin:$PATH\";\
	eval \`echoc --libs-init\`;\
	$cmd;\
	bash;"

