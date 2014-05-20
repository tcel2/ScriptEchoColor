#!/bin/bash
# Copyright (C) 2004-2014 by Henrique Abdalla
#
# This file is part of ScriptEchoColor.
#
# ScriptEchoColor simplifies Linux terminal text colorizing, formatting 
# and several steps of script coding.
#
# ScriptEchoColor is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# ScriptEchoColor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ScriptEchoColor. If not, see <http://www.gnu.org/licenses/>.
#
# Homepage: http://scriptechocolor.sourceforge.net/
# Project Homepage: https://sourceforge.net/projects/scriptechocolor/

export SECcmdDevTmp="$1"
if [[ -z "$SECcmdDevTmp" ]];then
	SECcmdDevTmp="echo -n"
fi
#bash -c "\
#	export PATH=\"$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin:$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin.extras:$PATH\";\
#	eval \`secinit\`;\
#	$cmd;\
#	echoc --alert ' now copy and run this (triple click on the line below) ';\
#	echo 'eval \`secinit\`';\
#	echo;\
#	bash;"

#	export PS1="$(echo -e "\E[0m\E[34m\E[106mDev\E[0m")$PS1";\

# Result of this command: echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "
#export SECstrSECdevTmp='echo -e "\E[0m\E[37m\E[44m\E[1m Script \E[0m\E[90m\E[44m\E[1mEcho \E[0m\E[91m\E[44m\E[1mC\E[0m\E[92m\E[44m\E[1mo\E[0m\E[94m\E[44m\E[1ml\E[0m\E[96m\E[44m\E[1mo\E[0m\E[93m\E[44m\E[1mr \E[0m\E[93m\E[43m\E[1m Development \E[0m"'
#export PROMPT_COMMAND="$PROMPT_COMMAND;$SECstrSECdevTmp;"\
#export SECstrBashrcFileTmp="`cat "$HOME/.bashrc"`"
#		echo "$SECstrBashrcFileTmp";\
bash --rcfile <(echo '\
		source "$HOME/.bashrc";\
		export PATH="$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin:$HOME/Projects/ScriptEchoColor/SourceForge.GIT/ScriptEchoColor/bin.extras:$PATH";\
		eval `secinit`;\
		export PROMPT_COMMAND="${PROMPT_COMMAND-}${PROMPT_COMMAND+;}`echoc --escapedchars "@{Bow} Script @{lk}Echo @rC@go@bl@co@yr @{Y} Development "`";\
		$SECcmdDevTmp;\
		set +u;\
	')

