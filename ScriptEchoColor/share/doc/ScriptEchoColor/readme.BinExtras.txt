The extras package, of experimental scripts, is optional and depends on main ScriptEchoColor one.

Status: (needs updating)

[beta]	secAutoScreenLock.sh
[beta]	secAutoUnmount.sh
[beta]	secBashForScriptEchoColorDevelopment.sh
[alpha]	secChromiumTabWindowFocus.sh
[beta]	secDaemonsControl.sh
[beta]	secDelayedExec.sh
[beta]	secDemaximize.sh
[beta]	secDevBaseScriptToCopyFrom.sh
[beta]	secDevTestGeneric.sh
[beta]	secDmesgCheckDaemon.sh
[?]	secExecControl.sh
[alpha]	secExec.sh
[?]	secExportArray.sh
[beta]	secFastFileAccess.sh
[beta]	secFixCompizAutoReplace.sh
[beta]	secFixDropboxCpulimit.sh
[?]	secGetParentestWindow.sh
[beta]	secHighTmprMon.sh
[alpha]	secLogSessionLock.sh
[beta]	secLyricsForBanshee.sh
[beta]	secMountAsSambaShare.sh
[alpha]	secNautilusRestartAndRestoreTabs.sh
[alpha]	secNetMon.sh
[alpha]	secNetworkControl.sh
[beta]	secOpenNewX.sh
[beta]	secOrganizeXterminals.sh
[alpha]	secRemoteInfo.sh
[beta]	secResizetexture.sh
[beta]	secRunAtYakuake.sh
[beta]	secRunUnison.sh
[beta]	secScreenShotOnMouseStop.sh
[beta]	secToDoList2txt.sh
[beta]	secUpdateRemoteBackupFiles.sh
[alpha]	secVisualMacro.sh
[beta]	secXtermDetached.sh
[beta]	sec.Bluetooth.SendFile.NautilusScript.sh
[beta]	sec.EditSymlink.NautilusScript.sh
[beta]	sec.OpenLocationOnYakuake.NautilusScript.sh
[beta]	sec.OpenMidnightCommanderOnYakuake.NautilusScript.sh
[beta]	sec.RemBkp.AddCopy.NautilusScript.sh
[beta]	sec.RemBkp.LsFilesNotThere.NautilusScript.sh
[beta]	sec.RunOnXterm.NautilusScript.sh
[alpha]	sec.SymlinkRelative.NautilusScript.sh
[beta]	sec.TouchFileDateTimeToNow.NautilusScript.sh

PS.: pretty list all with
#cd `secGetInstallPath`/bin.extras;ls sec* -1 |LC_ALL="C.UTF-8" sort -n |column -c `tput cols` |column -t |sed "s'.*' &'"
cd `secGetInstallPath`/bin.extras;ls sec* -1 |LC_ALL="C.UTF-8" sort -n |sed "s'.*' &'"
#if echoc -q "all scripts require review for the presence of a failproof --help option before this can work...";then export SECbShowHelpSummaryOnly=true;export SECbRunLog=false;astrFileList=($(cd `secGetInstallPath`/bin.extras;ls sec* -1 |LC_ALL="C.UTF-8" sort -n |sed "s'.*'&'"));for strFile in "${astrFileList[@]}";do strSummary="`SECFUNCexecA -ce "$strFile" --help`";strSummary="`echo "$strSummary" |tr '\n' ' '`";done;fi

