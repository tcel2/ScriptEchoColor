function _SECFUNCbashCompletion_secMaintenanceDaemon_sh() {
	local cur=${COMP_WORDS[COMP_CWORD]}
	if [[ "$cur" == -* ]]; then
		COMPREPLY=( $( compgen -W " \
			--isdaemonstarted \
			--help \
			--kill \
			--restart \
			--logmon \
			--lockmon \
			--pidmon \
			--errmon \
			--pidlist \
			--errors \
			--criticals \
			--loglist \
			--delay" -- $cur ) )
	fi
}
complete -F _SECFUNCbashCompletion_secMaintenanceDaemon_sh secMaintenanceDaemon.sh

function _SECFUNCbashCompletion_SECFUNCdelay() {
	local cur=${COMP_WORDS[COMP_CWORD]}
	if [[ "$cur" == -* ]]; then
		COMPREPLY=( $( compgen -W "\
			--help\
			--1stistrue\
			--checkorinit\
			--checkorinit1\
			--init\
			--get\
			--getsec\
			--getpretty\
			--getprettyfull\
			--delay" -- $cur ) )
	fi
}
complete -F _SECFUNCbashCompletion_SECFUNCdelay SECFUNCdelay
