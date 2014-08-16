#d15 m08 y2014
	#put this at your .bashrc to log every script output at $SECstrTmpFolderLog, in a log tree of pids
	export SECbRunLog=true 
	
	#look for most important errors with this, look for "(trap)" 
	secMaintenanceDaemon.sh --errmon

#as of d29 m07 y2014
	#secDelayedExec.sh was:
		secDelayedExec.sh <sleepInSeconds> <command>
	#now is
		secDelayedExec.sh -s <sleepInSeconds> <command>


