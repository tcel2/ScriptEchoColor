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

source "`secGetInstallPath.sh`/lib/ScriptEchoColor/utils/funcBase.sh";
SECastrFuncFilesShowHelp+=("$SECinstallPath/lib/ScriptEchoColor/utils/funcMisc.sh")

################ FUNCTIONS

function SECFUNCfileLock() { #Waits until the specified file is unlocked/lockable.\n\tCreates a lock file for the specified file.\n\t<realFile> cannot be a symlink or a directory
	SECFUNCdbgFuncInA;
	local lbUnlock=false
	local lbCheckIfIsLocked=false
	local lbNoWait=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCfileLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--unlock" ]];then #SECFUNCfileLock_help releases the lock for the specified file.
			lbUnlock=true
		elif [[ "$1" == "--islocked" ]];then #SECFUNCfileLock_help check if is locked and, if so, outputs the locking pid.
			lbCheckIfIsLocked=true
		elif [[ "$1" == "--nowait" ]];then #SECFUNCfileLock_help will not wait for lock to be freed and will return 1 if cannot get the lock
			lbNoWait=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local lfile="${1-}" #can be with full path
	if [[ ! -f "$lfile" ]];then
		SECFUNCechoErrA "file='$lfile' does not exist (if symlink must point to a file)"
		return 1
	fi
	lfile=`readlink -f "$lfile"`
	
	local lsedMd5sumOnly='s"([[:alnum:]]*) .*"\1"'
	local lmd5sum="`echo "$lfile" |md5sum |sed -r "$lsedMd5sumOnly"`"
	local lfileLock="$SEC_TmpFolder/.SEC.FileLock.$lmd5sum.lock"	
	local lfileLockPid="${lfileLock}.pid"	
	local lfileLockQUICKLOCKvalidate="${lfileLock}.QUICKLOCK.toValidateCurrentLock"	
	local lfileLockQUICKLOCKacquire="${lfileLock}.QUICKLOCK.toTryToAquireTheLock"	
	local lfileLockQUICKLOCKremoveQuickLock="${lfileLock}.QUICKLOCK.toRemoveQuickLock"	
	local llockingPid=-1 #no pid can be -1 right?
	local lnNoWaitReturn=0
	local lfSleepDelay="`SECFUNCbcPrettyCalc --scale 3 "$SECnLockRetryDelay/1000.0"`"
	
	#if [[ "$lfSleepDelay" == "0.000" ]];then
	if SECFUNCbcPrettyCalc --cmpquiet "$lfSleepDelay<0.001";then
		SECFUNCechoBugtrackA "SECnLockRetryDelay='$SECnLockRetryDelay' but lfSleepDelay='$lfSleepDelay'"
		#lfSleepDelay="0.001"
		lfSleepDelay="0.1" #seems something went wrong so use default
	fi
	
	function SECFUNCfileLock_LockingPidTrick_set() {
		SECFUNCdbgFuncInA;
		local lstrQuickLockFileName="$1"
		SECFUNCechoDbgA "trick by setting pid at lstrQuickLockFileName='$lstrQuickLockFileName' timestamp"
		touch --no-dereference --date "@$$" "$lstrQuickLockFileName";nRet=$?; #do not send error msgs output to /dev/stderr
		if((nRet==0));then 
			SECFUNCdbgFuncOutA;return 0
		else
			# could be a warning but in this case, it should not have happened so I will threat as an error...
			SECFUNCechoBugtrackA "touch lstrQuickLockFileName='$lstrQuickLockFileName' with pid failed nRet='$nRet'"
			SECFUNCdbgFuncOutA;return 1
		fi
		SECFUNCdbgFuncOutA;
	}
	function SECFUNCfileLock_LockingPidTrick_get() {
		SECFUNCdbgFuncInA;
		# the pid is trickly stored in the symlink timestamp
		local lstrQuickLockFileName="$1"
		
		# CRITICAL CHECK: if the timestamp is greater than SECnPidMax, it is a expected to be real timestamp so there is no pid stored there, if the machine gets it time set too much near Epoch, this will fail...
		local lnSysTime="`date +"%s"`" 
		#local lnSysTime="$SECnPidMax" #TO TEST
		local lstrMinDate="`date --date="@$SECnPidMax"`"
		#SECFUNCechoDbgA "lnSysTime=$lnSysTime;SECnPidMax=$SECnPidMax"
		if((lnSysTime<=SECnPidMax));then
			SECFUNCechoErrA "unable to work with a system date time '`date`' set to before than lstrMinDate='$lstrMinDate'"
			_SECFUNCcriticalForceExit
		fi
		
		while true; do
			local lnPidTrick="`stat -c %Y "$lstrQuickLockFileName" 2>/dev/null`"
			
			# file does not exist anymore
			if [[ -z "$lnPidTrick" ]];then
				echo -n "-1"
				break;
			fi
			
			if ((lnPidTrick>0 && lnPidTrick<=SECnPidMax));then
				# valid pid
				echo -n "$lnPidTrick"
				break
			else
				if SECFUNCdelay "`SECFUNCfixIdA "${FUNCNAME}"`" --checkorinit 3;then
					# the invalid lnPidTrick is the real creation timestamp of the symlink
					SECFUNCechoBugtrackA "invalid lnPidTrick='$lnPidTrick', waiting trick touch at lstrQuickLockFileName='$lstrQuickLockFileName' for `SECFUNCfileSleepDelay "$lstrQuickLockFileName"`s"
				fi
			fi
			
			sleep "$lfSleepDelay"
		done
		SECFUNCdbgFuncOutA;
	}
	function SECFUNCfileLock_QuickLockI_remove(){ # simple INTERMEDIARY quick lock remover
		SECFUNCdbgFuncInA;
		local lnToPid=$$
		while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
			if [[ "$1" == "--forcetopid" ]];then
				shift
				lnToPid="$1"
			else
				_SECFUNCcriticalForceExit
			fi
			shift
		done
		local lstrQuickLockFileName="$1"
		
		#SECFUNCexecA rm "${lstrQuickLockFileName}.$lnToPid" #>/dev/null 2>&1
		rm "${lstrQuickLockFileName}.$lnToPid" >/dev/null 2>&1
		SECFUNCdbgFuncOutA;
	}
#	function SECFUNCfileLock_QuickLock_remove(){
#		local lnForceToPid=-1
#		if [[ "$1" == "--forcetopid" ]];then
#			shift
#			lnForceToPid="$1"
#		fi
#		local lstrQuickLockFileName="$1"
#		
#		# on stressing concurrent calls, the file may have changed and so the pid
#		local lnPidQuick="`SECFUNCfileLock_LockingPidTrick_get "$lstrQuickLockFileName"`"
#		if((lnPidQuick!=-1));then
#			local lbRemove=false
#			if(($$==$lnPidQuick));then
#				lbRemove=true
#			fi
#			if((lnForceToPid!=-1)) && ((lnForceToPid==lnPidQuick));then
#				lbRemove=true
#			fi
#		
#			if $lbRemove;then
#					# even after all checks, on stressing concurrent calls, when reaching here, the file may have changed... #TODO how to uniquely identify a symlink?
#					rm "$lstrQuickLockFileName" >/dev/null 2>&1;local lnRet=$?
#					#SECFUNCechoBugtrackA "lbForce='$lbForce' lnPidQuick='$lnPidQuick' lstrQuickLockFileName='$lstrQuickLockFileName' lnRet='$lnRet'"
#			fi
#		fi
#	}
	function SECFUNCfileLock_LockControl(){ # used for maintenance by removing the QuickLock file
		SECFUNCdbgFuncInA;
		local lbRemoveOnly=false
		while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
			if [[ "$1" == "--removeonly" ]];then
				lbRemoveOnly=true
			else
				_SECFUNCcriticalForceExit
			fi
			shift
		done
		local lstrQuickLockFileName="${1-}"
		
		if $lbRemoveOnly;then
			# add a removal request
			echo "$$" >>"$SECstrLockFileRemoveRequests"
			# wait the removal
			while grep -qx "$$" "$SECstrLockFileRemoveRequests" 2>/dev/null;do
				if SECFUNCdelay "${FUNCNAME}_WaitRequestRemoval" --checkorinit 3;then
						SECFUNCechoWarnA "waiting the request to be removed from SECstrLockFileRemoveRequests='$SECstrLockFileRemoveRequests'"
				fi
				sleep "$lfSleepDelay"
			done
			SECFUNCdbgFuncOutA;return
		fi
		
		# USE OF LockControl
		#SECFUNCechoBugtrackA "`ls -l "$SECstrLockFileAllowedPid" |tail -n 1`"
#		local lbAllow=false;
#		if [[ -f "$SECstrLockFileAllowedPid" ]];then
#			local lnAllowedPid="`cat "$SECstrLockFileAllowedPid"`"
#			if [[ -n "$lnAllowedPid" ]];then
#				if(($$==lnAllowedPid));then
#					lbAllow=true
#				fi
#			fi
#		fi
#		if $lbAllow;then
		if SECFUNClockFileAllowedPid --cmp $$;then
			# QUICKLOCK remover
			SECFUNCechoBugtrackA "match SECstrLockFileAllowedPid='$SECstrLockFileAllowedPid'"
			# check if quick lock is a broken symlink
			if [[ -L "$lstrQuickLockFileName" ]] && [[ ! -f "$lstrQuickLockFileName" ]];then
				# remove the quick lock symlink that points to the INTERMEDIARY one
				SECFUNCechoBugtrackA "removing lstrQuickLockFileName='$lstrQuickLockFileName'"
				rm "$lstrQuickLockFileName" >/dev/null 2>&1 #->2
				# wait other pid get lstrQuickLockFileName to prevent simultaneous creation of such symlink (@->1) and attempt to this same being removed (@->2) by a failed symlink creation flow that may be running very slowly because of cpu and io (probably).
				while [[ ! -L "$lstrQuickLockFileName" ]];do
					if ! SECFUNClockFileAllowedPid --hasotherpids $$;then
						break
					fi
					if SECFUNCdelay "${FUNCNAME}_WaitOtherGetQuickLock" --checkorinit 3;then
						SECFUNCechoWarnA "waiting some pid get lstrQuickLockFileName='$lstrQuickLockFileName'"
						if [[ ! -f "$SECstrLockFileRequests" ]];then
							#stop if there are no other pids..
							break
						fi
					fi
					sleep "$lfSleepDelay"
				done
			fi
			# removes granted LockControl lock of self
			SECFUNCfileLock_LockControl --removeonly # did the maintenance task of checking and removing broken lock
			#rm "$SECstrLockFileAllowedPid" >/dev/null 2>&1
			
			#SECFUNCechoBugtrackA "removed '$SECstrLockFileAllowedPid'"
			#echo "$$" >>"$SECstrLockFileRemoveRequests"
			#lbRemove=false; #removed from LockControl script array queue astrRequests, so quit the loop!
#						sleep "$lfSleepDelay"
#						continue;
		else
			#if ! $lbRemoveOnly;then
				# add self to the lock request queue
				echo "$$" >>"$SECstrLockFileRequests"
				SECFUNCechoBugtrackA "adding request $$"
			#fi
		fi
		SECFUNCdbgFuncOutA;
	}
	function SECFUNCfileLock_QuickLock(){ # will wait til get the quick lock (will remove the lock if its locking pid dies)
		SECFUNCdbgFuncInA;
		local lstrQuickLockFileName="$1"
		
		local lnPidQuick
		lnPidQuick="`SECFUNCfileLock_LockingPidTrick_get "$lstrQuickLockFileName"`"
		if(($$==$lnPidQuick));then
			SECFUNCechoWarnA "pid already has lstrQuickLockFileName='$lstrQuickLockFileName'"
		else
			#create an INTERMEDIARY symlink as $lstrQuickLockFileName.$$, symlink $lstrQuickLockFileName to it; on removing, remove $lstrQuickLockFileName.$$ and only remove $lstrQuickLockFileName if broken! 
			ln -s "$lfile" "${lstrQuickLockFileName}.$$" >/dev/null 2>&1
			while true;do #TODO <- this while is the concurrent bug workaround, not good?
				while ! ln -s "${lstrQuickLockFileName}.$$" "$lstrQuickLockFileName" >/dev/null 2>&1;do #->1
					SECFUNCechoBugtrackA "failed to symlink lstrQuickLockFileName='$lstrQuickLockFileName' to '${lstrQuickLockFileName}.$$'"
					SECFUNCfileLock_LockControl "$lstrQuickLockFileName"
					
					if $lbNoWait;then
						lnNoWaitReturn=1
						SECFUNCdbgFuncOutA;return 1 #has no file to remove
					fi
			
					if SECFUNCdelay "`SECFUNCfixIdA --justfix "${FUNCNAME}_${lstrQuickLockFileName}"`" --checkorinit 3;then
						lnPidQuick="`SECFUNCfileLock_LockingPidTrick_get "$lstrQuickLockFileName"`"
						if((lnPidQuick!=-1));then #-1 means the file already does not exist
							if ps -p $lnPidQuick >/dev/null 2>&1;then
								SECFUNCechoWarnA "lstrQuickLockFileName='$lstrQuickLockFileName' still locked with pid $lnPidQuick"
							else
								SECFUNCechoWarnA "no lnPidQuick='$lnPidQuick', removing lstrQuickLockFileName='$lstrQuickLockFileName.$lnPidQuick'"
								#TODO BUG, the guess is: on stressing concurrent calls, one will detect and remove, the other will detect too at the same time, but when trying to remove, will remove another newly created one before it have been touched! :(, some way to uniquely identify a file and uniquely remove it even it has the same canonical filename is required...
								SECFUNCfileLock_QuickLockI_remove --forcetopid $lnPidQuick "$lstrQuickLockFileName"
							fi
						fi
					fi
					sleep "$lfSleepDelay"
				done
				#TODO this is the concurrent bug workaround, not good?
				if SECFUNCfileLock_LockingPidTrick_set "$lstrQuickLockFileName";then
					#echo "$$" >>"$SECstrLockFileRemoveRequests"
					SECFUNCfileLock_LockControl --removeonly # got the quicklock so remove self from request queue
					break
				fi
			done
		fi
		SECFUNCdbgFuncOutA;return 0
	}
	
	SECFUNCfileLock_removeLock(){
		SECFUNCdbgFuncInA;
		rm "$lfileLock" >/dev/null 2>&1
		rm "$lfileLockPid" >/dev/null 2>&1
		SECFUNCdbgFuncOutA;
	}
	
	SECFUNCfileLock_validate(){
		SECFUNCdbgFuncInA;
		SECFUNCfileLock_QuickLock "$lfileLockQUICKLOCKvalidate"
	
		# validate lock
		if [[ -f "$lfileLockPid" ]];then
			llockingPid="`cat "$lfileLockPid"`"
			# must only contain digits
			if [[ -n "$llockingPid" ]];then
				if [[ -n "`echo "$llockingPid" |tr -d "[:digit:]"`" ]];then
					# must have only digits
					# if after removing all digits anything else remains
					SECFUNCechoErrA "invalid llockingPid='$llockingPid' at lfileLockPid='$lfileLockPid'"
					llockingPid=-1
				elif ! ps -p "$llockingPid" >/dev/null 2>&1;then
					SECFUNCechoWarnA "llockingPid='$llockingPid' died"
					llockingPid=-1
				fi
			else
				llockingPid=-1
			fi
		fi
	
		# remove invalid lock
		if((llockingPid==-1));then
			#SECFUNCechoDbgA "validating"
			SECFUNCfileLock_removeLock
		fi
		
		#rm "$lfileLockQUICKLOCKvalidate"
		# THIS LINE MUST BE REACHED to remove the lock!
		SECFUNCfileLock_QuickLockI_remove "$lfileLockQUICKLOCKvalidate"
		#while grep -q "^$$$" "$SECstrLockFileRequests";do
#		while grep -qx "$$" "$SECstrLockFileRequests";do
#			# must remove self from the requests queue before continuing
#			SECFUNCfileLock_LockControl --remove "$lfileLockQUICKLOCKvalidate"
#			sleep "$lfSleepDelay"
#		done
		#SECFUNCfileLock_LockControl --removeonly
		SECFUNCdbgFuncOutA;
	}
	SECFUNCfileLock_validate
	
	if $lbUnlock;then
		if(($$==$llockingPid));then
			#SECFUNCechoDbgA "unlocking"
			SECFUNCfileLock_removeLock
			SECFUNCdbgFuncOutA;return 0
		else
			SECFUNCechoWarnA "cant unlock, llockingPid=$llockingPid differs from this pid"
			SECFUNCdbgFuncOutA;return 1
		fi
	elif $lbCheckIfIsLocked;then
		if((llockingPid!=-1));then
			SECFUNCdbgFuncOutA;return 0
		else
			SECFUNCdbgFuncOutA;return 1		
		fi
	else # try to set/acquire the REAL FILE lock
		if(($$==$llockingPid));then
			SECFUNCechoWarnA "pid already has lfileLock='$lfileLock'"
		else
		
			if SECFUNCfileLock_QuickLock "$lfileLockQUICKLOCKacquire";then
				while true;do
					SECFUNCfileLock_validate
					if ln -s "$lfile" "$lfileLock" >/dev/null 2>&1;then
						echo "$$" >"$lfileLockPid"
						#rm "$lfileLockQUICKLOCKacquire"
						break
					else
						if $lbNoWait;then
							#rm "$lfileLockQUICKLOCKacquire"
							#return 1
							lnNoWaitReturn=1 #set also at quicklock
							break
						fi
						if SECFUNCdelay "${FUNCNAME}_lfileLock" --checkorinit 3;then
							SECFUNCechoWarnA "still unable to lfileLock='$lfileLock' owned by llockingPid='$llockingPid'"
							#SECFUNCfileLock_validate #here causes less cpu usage
						fi
					fi
				
					sleep "$lfSleepDelay"
				done
				# THIS LINE MUST BE REACHED to remove the lock!
				SECFUNCfileLock_QuickLockI_remove "$lfileLockQUICKLOCKacquire"
				#SECFUNCfileLock_LockControl --removeonly
			fi
			
		fi
	fi
	
	if $lbNoWait;then
		SECFUNCdbgFuncOutA;return $lnNoWaitReturn
	fi
	
	SECFUNCdbgFuncOutA;return 0
}

function SECFUNCuniqueLock() { #Creates a unique lock that help the script to prevent itself from being executed more than one time simultaneously. If lock exists, outputs the pid holding it.
	#set -x
	local l_bRelease=false
	local l_pid=$$
	local l_bQuiet=false
	local lbDaemon=false
	local lbWaitDaemon=false
	#local lstrId="`basename "$0"`"
	local lstrCanonicalFileName="`readlink -f "$0"`"
	local lstrId="`basename "$lstrCanonicalFileName"`"
	SECnPidDaemon=0
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--help" ]];then #SECFUNCuniqueLock_help show this help
			SECFUNCshowHelp ${FUNCNAME}
			return
		elif [[ "$1" == "--quiet" ]];then #SECFUNCuniqueLock_help prevent all output to /dev/stdout
			l_bQuiet=true
		elif [[ "$1" == "--notquiet" ]];then #SECFUNCuniqueLock_help allow output to /dev/stdout
			l_bQuiet=false
		elif [[ "$1" == "--id" ]];then #SECFUNCuniqueLock_help <id> set the lock id, if not set, the 'id' defaults to `basename $0`
			shift
			lstrId="$1"
		elif [[ "$1" == "--pid" ]];then #SECFUNCuniqueLock_help <pid> force pid to be related to the lock
			shift
			l_pid=$1
			if ! ps -p $l_pid >/dev/null 2>&1;then
				SECFUNCechoErrA "invalid pid: '$l_pid'"
				return 1
			fi
		elif [[ "$1" == "--release" ]];then #SECFUNCuniqueLock_help release the lock
			l_bRelease=true
		elif [[ "$1" == "--daemon" ]];then #SECFUNCuniqueLock_help Auto set the DB to the daemon DB if it is already running, or create a new DB; Also sets this variable: SECbDaemonWasAlreadyRunning.
			lbDaemon=true
		elif [[ "$1" == "--daemonwait" ]];then #SECFUNCuniqueLock_help will wait for the other daemon to exit, and then will become the daemon
			lbDaemon=true
			lbWaitDaemon=true
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	lstrId="`SECFUNCfixIdA --justfix "$lstrId"`"
#	if ! SECFUNCvalidateIdA "$lstrId";then
#		return 1
#	fi
	
	if ${lbDaemon:?};then #will call this self function, beware..
		SECONDS=0
		while true;do
			#set -x
			SECbDaemonWasAlreadyRunning=false #global NOT to export #TODO WHY?
			if SECFUNCuniqueLock --quiet --id "$lstrId"; then
				SECFUNCvarSetDB -f
				SECnPidDaemon=$l_pid # ONLY after the lock has been acquired!
			else
				#echo ">>>$SECvarFile,$lstrId,`SECFUNCuniqueLock --id "$lstrId"`"
				#set -x
				SECFUNCvarSetDB `SECFUNCuniqueLock --id "$lstrId"` #allows intercommunication between proccesses started from different parents
				#set +x
				#echo ">>>$SECvarFile"
				SECbDaemonWasAlreadyRunning=true
			fi
			#set +x
			
			if ${lbWaitDaemon:?};then
				if $SECbDaemonWasAlreadyRunning;then
					echo -ne "Wait Daemon '$lstrId': ${SECONDS}s...\r" >>/dev/stderr
					sleep 1 #keep trying to become the daemon
				else
					break #has become the daemon, breaks loop..
				fi
			else
				break; #always break, because DB is always set (child or master)
			fi
		done
		return 0 # to prevent bugs..
	fi
	
	#local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$l_pid.$lstrId"
	local l_runUniqueFile="$SEC_TmpFolder/.SEC.UniqueRun.$lstrId"
	#local l_lockFile="${l_runUniqueFile}.lock"
	if [[ ! -f "$l_runUniqueFile" ]];then
		local lstrQuickLock="${l_runUniqueFile}.ToCreateRealFile.lock"
		if ln -s "$l_runUniqueFile" "$lstrQuickLock";then
			echo $l_pid >"$l_runUniqueFile"
			rm "$lstrQuickLock"
		fi
	fi
		
	function SECFUNCuniqueLock_release() {
		SECFUNCfileLock "$l_runUniqueFile" --unlock
		rm "$l_runUniqueFile";
		#rm "$l_lockFile";
	}
	
	if ${l_bRelease:?};then
		SECFUNCuniqueLock_release
		return 0
	fi
	
#	#####################################
#	if [[ -f "$l_runUniqueFile" ]];then
#		local l_lockPid=`cat "$l_runUniqueFile"`
#		if ps -p $l_lockPid >/dev/null 2>&1; then
#			if(($l_pid==$l_lockPid));then
#				SECFUNCechoWarnA "redundant lock '$lstrId' request..."
#				return 0
#			else
#				if ! ${l_bQuiet:?};then
#					echo "$l_lockPid"
#				fi
#				return 1
#			fi
#		else
#			SECFUNCechoWarnA "releasing lock '$lstrId' of dead process..."
#			SECFUNCuniqueLock_release
#		fi
#	fi
#	
#	if [[ ! -f "$l_runUniqueFile" ]];then
#		# try to create a symlink lock file to the unique file
#		if ! ln -s "$l_runUniqueFile" "${l_runUniqueFile}.lock";then
#			# other pid created the symlink first!
#			return 1
#		fi
#	
#		echo $l_pid >"$l_runUniqueFile"
#		return 0
#	fi
	
	local lnLockPid=`SECFUNCfileLock "$l_runUniqueFile" --islocked` #lock will be validated and released here
	if [[ -n "$lnLockPid" ]];then
		if(($l_pid==$lnLockPid));then
			SECFUNCechoWarnA "redundant lock '$lstrId' request..."
			return 0
		else
			if ! ${l_bQuiet:?};then
				echo "$lnLockPid"
			fi
			return 1
		fi
	else
		if SECFUNCfileLock --nowait "$l_runUniqueFile";then
			echo $l_pid >"$l_runUniqueFile"
		else
			return 1 #concurrent attempts can make it fail so pass failure to caller
		fi
	fi
}

function SECFUNCcfgFileName() { #Application config file for scripts.\n\t[cfgIdentifier], if not set will default to `basename "$0"`
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	local lpath="$HOME/.ScriptEchoColor/SEC.AppVars.DB"
	if [[ ! -d "$lpath" ]];then
		mkdir -p "$lpath"
	fi
	
	# SECcfgFileName is a global
	if [[ -n "${1-}" ]];then
		SECcfgFileName="$lpath/${1}.cfg"
	#fi
	else
	#if [[ -z "$SECcfgFileName" ]];then
		local lstrCanonicalFileName="`readlink -f "$0"`"
		#echo "lstrCanonicalFileName=$lstrCanonicalFileName" >/dev/stderr
		#SECcfgFileName="$lpath/`basename "$0"`.cfg"
		SECcfgFileName="$lpath/`basename "$lstrCanonicalFileName"`.cfg"
	fi
	
	#echo "$lpath/${SECcfgFileName}.cfg"
	#echo "$SECcfgFileName"
}
function SECFUNCcfgRead() { #read the cfg file and set all its env vars at current env
	#echo oi;eval `cat tst.db`;return
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	if [[ "${1-}" == "--help" ]];then
		SECFUNCshowHelp ${FUNCNAME}
		return
	fi
	
	if [[ -f "$SECcfgFileName" ]];then
  	SECFUNCfileLock "$SECcfgFileName"
  	
  	#declare -p aDaemonsPid
  	#echo "$SECcfgFileName"
  	#cat "$SECcfgFileName"
  	#source "$SECcfgFileName"
  	#local lstrCfgData=`cat "$SECcfgFileName"`
  	#echo $lstrCfgData
  	#eval $lstrCfgData
  	#eval `cat "$SECcfgFileName"`
  	#echo ">>>tst=${tst-}"
  	eval "`cat "$SECcfgFileName"`"
  	#declare -p aDaemonsPid
  	
  	SECFUNCfileLock --unlock "$SECcfgFileName"
  fi
}
function SECFUNCcfgWriteVar() { #<var>[=<value>] write a variable to config file
	local lbRemoveVar=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--remove" ]];then #SECFUNCcfgWriteVar_help remove the variable from config file
			lbRemoveVar=true
		elif [[ "${1-}" == "--help" ]];then
			SECFUNCshowHelp ${FUNCNAME}
			return
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	# if var is being set, eval (do) it
	local lbIsArray=false
	if echo "$1" |grep -q "^[[:alnum:]_]*=";then # here the var will never be array
#		local lsedVarId='s"^([[:alnum:]_]*)=.*"\1"'
#		local lsedValue='s"^[[:alnum:]_]*=(.*)"\1"'
#		lstrVarId=`echo "$1" |sed -r "$lsedVarId"`
#		local lstrValue=`echo "$1" |sed -r "$lsedValue"`
#		eval "$lstrVarId=\"$lstrValue\""
		eval "`echo "$1" |sed -r 's,^([[:alnum:]_]*)=(.*),\
			\1="\2";\
			lstrVarId="\1";\
			lstrValue="\2";\
		,'`"
	else
		local lstrVarId="$1"
#		local lstrArrayToWrite=`declare -p ${lstrVarId}`
#		if $lstrArrayToWrite |grep -q "^declare -[aA]";then
#			lbIsArray=true
#			#local lstrValue=`declare -p ${lstrVarId} |sed -r "s,^declare -[aA] ([[:alnum:]_]*)='(.*)',\2,"`
#		else
#			local lstrValue="${!lstrVarId-}"
#		fi
	fi
	
	if [[ -z "$SECcfgFileName" ]];then
		SECFUNCcfgFileName
	fi
	
	if [[ -z "`declare |grep "^${lstrVarId}="`" ]];then
		SECFUNCechoErrA "invalid var '$lstrVarId' to write at cfg file '$SECcfgFileName'"
		return 1
	fi
	
	# `declare` must be stripped off or the evaluation of the cfg file will fail!!!
	if declare -p ${lstrVarId} |grep -q "^declare -[aA]";then
		lbIsArray=true
	fi
	
	local lstrPliqForArray=""
	if $lbIsArray;then
		lstrPliqForArray="'"
		#lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^(declare -[[:alpha:]-]* [[:alnum:]_]*)='(.*)'$,${lstrVarId}=\"\";unset ${lstrVarId};\1=\2,"`
#		lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)='(.*)'$,\1=\2,"`
#	else
#		lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=(.*)$,\1=\2,"`
	fi
	
	local lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	
#	local lstrPliqForArray=""
#	local lstrPrepareArray=""
#	if $lbIsArray;then
#		lstrPliqForArray="'"
#		
#		local lstrDeclareArray=`declare -p $lstrVarId |sed -r 's"^([^=]*)=.*"\1"'`
#		lstrPrepareArray="$lstrVarId='';unset $lstrVarId;$lstrDeclareArray;"
#	fi
#	lstrToWrite=`declare -p ${lstrVarId} |sed -r "s,^declare -[[:alpha:]-]* ([[:alnum:]_]*)=${lstrPliqForArray}(.*)${lstrPliqForArray}$,\1=\2,"`
	#echo "lstrToWrite=$lstrToWrite"
	#eval export ${lstrVarId}
	
	if [[ ! -f "$SECcfgFileName" ]];then
		echo -n >"$SECcfgFileName"
	fi
	
	SECFUNCfileLock "$SECcfgFileName"
	#set -x	
	local lstrMatchLineToRemove=`echo "$lstrToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
	sed -i "/$lstrMatchLineToRemove/d" "$SECcfgFileName" #will remove the variable line
	if ! $lbRemoveVar;then
		echo "${lstrToWrite};" >>"$SECcfgFileName" #append new line with var
	fi
	#set +x
#	if $lbIsArray;then
#		local lstrMatchLineToRemove=`echo "$lstrArrayToWrite" |sed -r 's,(^[^=]*=).*,\1,'`
#		sed "/$lstrMatchLineToRemove/d" "$SECcfgFileName"
#		echo "$lstrArrayToWrite;" >>"$SECcfgFileName"
#	else
#		if grep -q "^${lstrVarId}=" "$SECcfgFileName";then
#			# sed substitute variable and value
#			sed -i "s'^${lstrVarId}=.*'${lstrVarId}=\"${lstrValue}\";'" "$SECcfgFileName"
#		else
#			echo "${lstrVarId}=\"${lstrValue}\";" >>"$SECcfgFileName"
#		fi
#	fi
	SECFUNCfileLock --unlock "$SECcfgFileName"
}

#function SECFUNCdaemonsControl() {
#	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
#		if [[ "$1" == "--help" ]];then #SECFUNCdaemonsControl_help show this help
#			SECFUNCshowHelp "$FUNCNAME"
#			return
#		elif [[ "$1" == "--set" ]];then #SECFUNCdaemonsControl_help set vars on daemons control main file
#			shift
#			local lstrVar="$1"
#			shift
#			local lstrValue="$1"
#		else
#			SECFUNCechoErrA "invalid option: $1"
#			return 1
#		fi
#	done
#	local lstrFile="$SEC_TmpFolder/SEC.DaemonsControl.tmp"
#}
function SECFUNCdaemonCheckHold() { #used to fastly check and hold daemon execution, this code fully depends on what is coded at secDaemonsControl.sh
	: ${SECbDaemonRegistered:=false}
	if ! $SECbDaemonRegistered;then
		secDaemonsControl.sh --register
		SECbDaemonRegistered=true
	fi
	_SECFUNCdaemonCheckHold_SubShell() {
		# IMPORTANT: subshell to protect parent envinronment variable SECcfgFileName
		local bHoldScripts=false
		SECFUNCcfgFileName secDaemonsControl.sh
		SECFUNCcfgRead
		#echo "$SECcfgFileName";cat "$SECcfgFileName";echo "bHoldScripts=$bHoldScripts"
		if $bHoldScripts;then
			secDaemonsControl.sh --checkhold #will cause recursion if this function is called on that command...
		fi
	};export -f _SECFUNCdaemonCheckHold_SubShell
	bash -c "_SECFUNCdaemonCheckHold_SubShell"
}

function SECFUNCfileSleepDelay() { #<file> show how long (in seconds) a file is not active (has not been updated or touch)
	
	local lbReal=false
	while ! ${1+false} && [[ "${1:0:2}" == "--" ]];do
		if [[ "$1" == "--real" ]];then #SECFUNCfileSleepDelay_help force the file checked to be the real one, not symlinks
			lbReal=true
		elif [[ "${1-}" == "--help" ]];then
			SECFUNCshowHelp ${FUNCNAME}
			return
		else
			SECFUNCechoErrA "invalid option: $1"
			return 1
		fi
		shift
	done
	
	local lfile="$1"
	
	if $lbReal;then
		lfile="`readlink -f "$lfile"`"
	fi
	
	if [[ ! -f "$lfile" ]] && [[ ! -L "$lfile" ]];then
		#echo -n "0"
		SECFUNCechoErrA "invalid file '$lfile'"
		return 1
	fi
	
	local lnSecondsFile=`stat -c "%Y" "$lfile"`;
	local lnSecondsNow=`date +"%s"`;
	local lnSecondsDelay=$((lnSecondsNow-lnSecondsFile))
	echo -n "$lnSecondsDelay"
}

#function SECFUNCexit() { #useful to do 'before exit' tasks
#	local lnStatus=$?
#	if [[ -n "${1-}" ]];then
#		lnStatus=$1
#	fi
#	
#	SECFUNCvarWriteDB #to remove dups
#	
#	exit $nStatus
#}

if [[ `basename "$0"` == "funcMisc.sh" ]];then
	while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
		if [[ "$1" == "--help" ]];then
			SECFUNCshowFunctionsHelp
			exit
		fi
		shift
	done
fi

