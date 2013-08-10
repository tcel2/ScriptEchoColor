IMPORTANT!
	This file `lib/ScriptEchoColor/utils/funcVars.sh`	is experimental code! 
	It is loaded when you use: eval `echoc --libs-init`
	Its main purpose is to share global variables between parent and child, in a way both can write and read each others modifications, what may be unsafe...
	Only use it on non critical (non sudo, non root, non critical work) scripts.
	(just learned about http://modules.sourceforge.net/, on research atm)
	
INSTALL:
  extract this package to a temporary directory and run 
    ./configure
    make install

USAGE:
  you can type 
    ScriptEchoColor --help
  or  
    echoc --help

EXAMPLES:
  at install dir type 
    ./secexamples.sh -a

ARGUMENT SCRIPTS: 
  argget.sh, argset.sh and argclr.sh
  Info:
    This is like a very simple database with 'variable(value)' per line
      within a text file.
    Limits:
      Variable name must start at begin of line!
      Variable value must be just after its name, within 'var(value)' and 
        must be only one line (forbidden multiline 'value')!
      To have 'new line' at 'value' use \n and format it after collecting 
        variable value!


KNOWN BUGS and LIMITATIONS:

TODO (fix at top):
  fix: SECFUNCvarSet (and other functions) without parameters gets crazy..
	fix: echoc "abc!" causes error: 'bash: !": event not found'; workaround is to append space like this "abc! "
  fix: echoc "\$" not working!!!
  fix: arrow keys detection: left right; to select question options
  with -t option, append to the end of the line the remaining time each 10s or each 10% of time passes
  create a deb package (use checkinstall !)
  allow -x -q to work toguether like: echoc -x -q ls
    will show: "EXECUTE: ls (y/...)?"
    colored properly, the "ls" must have execute command colors, the remainder question colors
  add "reset command?" or some kind of terminal reset "with tput?" to INT trap and/or the end of echoc so that the terminal doesnt bug up (like typing and not seeing the letters)
	--ocpt (one command per time option) to recognize ";" as command separator to execute it sequentially showing its output separatedly for each command (wait it exit)
  -qt 1 - with this option, after time ends, append "no" (or "yes" in case "@Dy") to the 
    question line to ppl know what was chosen...
	--tcobo go to libs
	-t 3 -x does not work, -x fails to execute, the (3s) becomes part of the command
  --help-extended acrescenter esse exemplo do EOF, ex.: echoc -x "`cat \
<<EOF
    find ./ -type f -not -iname "." -exec "$0" --fileVarsName $$ '{}' "$pathCopyTo" \;
EOF`"
  --idea add "tput reset" at end of each idea execution!! and their documented scripts also?
  -q if you type "?" at end of string, make it get ignored (as there is already a "?" to now show twice)
  -Q automatic options numbering like @OoptA/optB become @O_1-optA/_2-optB, and ex. @D2 matches!
  acrescentar um exemplo no --help-extended de comentario com -x 
    ex.: echoc -x "ls @B#list directory"
  -p, add space before and after message to look prettier
  at -w with -t option, make the line update showing remaining seconds...
  reimplement the slow parts to speed up the script execution (if possible)
  --box option to surround text with line box
  set limitations and conversions based on each terminal specific limitations, so all
    resulting text will be readable and have the best settings possible.
    Status: 
      already working for ($TERM): 
        linux, xterm, rxvt
      already working for (terminal emulator executable name):
        gnome-terminal, konsole, rxvt
  create info pages with the output of the --help-extended!

BUG REPORTING:
  to the bug report email, add the file ScriptEchoColorBugReport.txt that can
  be created with the command: ScriptEchoColor --test
    Forum at Homepage: https://sourceforge.net/projects/scriptechocolor/
    Project Email: teike@users.sourceforge.net

NOTES (highlights) (for tech info look at CHANGES section):
  v1.15: 
	update to GPL3
	
	Fixed invisible typed characters after hit ctrl+c on `echoc -q`!
	Fixed: eval `echoc --libs-init`; while true; do echoc -w -t 10; done #it wont stop with ctrl+c ...
	
  	New options:
  		--say to allow use of festival to say the text! and envvars added:
  		SEC_SAYALWAYS
  		SEC_SAYVOL
			funSayStack.sh now implemented and help to spoken phrases not overlap!
			--libs option to source your scripts with many functions! but it is still 
			  EXPERIMENTAL!!!
			--escapedchars to show what you would type with `echo -e`
			--info easy coloring option
			--alert easy coloring option
    	"There can only be one!" --tcobo, helps to prevent running more 
        than one script instance (experimental)
   
   
  v1.14:
    Colors work w/o tput now.
    Question mode answear is now case insensitive by default.
    Added helper scripts.
    It now installs with configure and make.

  v1.12:
    Speed enhancements not implemented yet.

    They will probably come when I integrate this package
    with some subprojects of my other project.

    Take a look at https://sourceforge.net/projects/structintegrdb


  v1.10:
    This version brings Major Improvements :D

    I will try to focus more on script execution speed from now on :)

    I still want to add some small adjustments to not main functionalities,
    but I decided to release this version before the New Year 2005 :)
    So version 1.11 may come soon.

    See all enhancements at change log.


  v1.04:
    Before installing this realease, run ./uninstall.sh of the previous version. If you changed preferences in the config file at $HOME, keep it during uninstall, then update (still manually) the file $HOME/.ScriptEchoColor/User.cfg, then you can safely remove the old config file.

    This release allows instalation at /usr/local for ex. so it is more flexible.

    Terminals limitations code is already working so as soon I receive bug reports based on --test option, I will verify and implement them.

    Appending to log file is a lot easier now :)




CHANGES:
  v1.15:
   -t now supports floating like 0.25 etc!
   fix to --help-extended when showing "graphics" mode messing the terminal...
   fix to secascii now converts codes to letters properly...
   improved clear key buffer from 1s to 0.1s delay! (read -t 0.1)
   added option --tcobo to help preventing running more than one script instance
   fixed seclockfile useless error message.
   FIXED! 
    While testing echoc at xterm command line (not from scripts), I found that if you press
    Ctrl+c just after '[clrkeybuf1s]' be shown, echoc is interrupted and then, everything 
    that is typed at terminal is not output but is there, if I type 'ls' then press Enter
    it executes normally. 
      ex.1: `echoc -q`
      ex.2: echoc -qi
    The problem happens in these 2 circunstances:
      ex.1: `\`read -s\`` 
      ex.2: func(){ `read -s`; };`func` 
  
  v1.14:
    bugs fixed:
      -Q was not working...
    added environment variable SEC_CASESENS default false. Now question modes -q -Q 
      can work in case insensitive mode.
    added file sec.helperscript.source with helper functions, read it for usage.
    Color now use `echo -e "\E[??m"` where ?? is a number, instead of `tput ????? ?`.
    SEC_IGNORE_LIMITATIONS default is now "true". Seems to provide better generic results.
    Installation now works with: ./configure --prefix=???; make install

  v1.13:
    bugs fixed:
      seclockfile.sh now works with vfat filesystems concerning user permissions.
    added environment variable SEC_FORCESTDERR, very usefull when normal script 
      output will be used as data, so all ScriptEchoColor output will go to /dev/stderr
  
  v1.12:
    bugs fixed:
      option --help of secascii and secasciicode now works again
    install.sh exemplifies /usr/local as base install path now
    small changes to --help-extended output
    added option --versioncheck <value>
    added environment variable recognition SEC_LOG_AVOID to forcefully prevent log
    automatic foreground to 'konsole' is now 'blue' instead of 'black'.
      Also, default question option hightlight color when using arrows 
      is now @{bYL} (blue fg on light yellow bg), to all, not only 'konsole'.
      Your system can be setup to this default by using option --recreateconfigfile 
      if this is not your first time installing ScriptEchoColor.
    added environment variable SEC_HEADEREXEC, very usefull when executing scripts inside scripts
  
  v1.11:
    bugs fixed:
      missing space between parameters
        ScriptEchoColor a b c
        was echoing 'abc' instead of 'a b c'
  
  v1.10:
    import defaults from User.cfg file in case of version does not match
    added environment variable recognition SEC_BEEP (mute,single,extra) so if beeps are annoying
      you can mute it without changing your script, just set it at terminal :)
    beep default mode is now "single" (the normal beep)
    with option -L and without the environment variable SEC_LOG_FILE, 
      a log file is automatically generated (see --help-extended for details)

    bugs fixed: 
      when using options -xL the command string was doubled ex.: "pwd" as "pwdpwd"
      now answers (at question modes) are logged also
      and other minor bugs
    
    when using these options toguether "-St N" it will work this way: 
      show timed wait question y/n if user want to accept the default;
      to change the default press 'n' (or other non default keys that are ['y',Enter,SpaceBar])
        and type your answear :)
    option -w (wait) now outputs " Press any key to continue... " in case user set no message
    added option -X (like -x "command") but kill parent pid in case of "command" execution error
    added option -v echo and help change environment (ex.: "cd ..")
    added option -V echo, help change environment and exit in case of command execution error
    added environment variable recognition SEC_DEBUG
    added option -- to take following arguments as normal text in case you want to output "--help" for ex.
    added option --parentpidlist
    added option --guesstermemulator
    added option --logfilename
    implemented additional limitations check based on terminal emulator executable filename
    invalid options are warned now
    help text updated
    file examples.sh renamed to secexamples.sh and updated
    file seclockfile.sh added
    it now uses 'seclockfile.sh' to prevent concurrent ScriptEchoColor execution possible problems
    file install.sh updated, you can also now install symbolic links to 
      additional scripts (other functionalities used by ScriptEchoColor) 
      but remember they are not the main development so usage may change 
      without advices.
      It also helps to uninstall a previous installed version and 
        to remove temporary unpacked package directory.

  v1.04:
    install.sh is more flexible as you can set install path and executables path
    uninstall.sh updated too
    at $HOME/.ScriptEchoColor/User.cfg file you can now setup your preferences :)
    md5sum is used to check files before installing
    [clrkeybuf1s] is now properly cleared
    added option -L (easily append unformatted text to logfile, use toguether with exported environment variables SEC_LOG_FILE and optional SEC_LOG_DEFAULT)
    added option --test to make it easy to bug report
    limitations already working for some terminals ($TERM): linux, xterm, rxvt
  
  v1.03:
    install.sh now checks for dependencies
    added option -u (output unformatted)
    added option -l <logfile> (append unformatted text to logfile)
  
  v1.02beta:
    examples.sh now you can choose example at commandline like -10
    uninstall.sh now must be run from install dir $HOME/ScriptEchoColor
    --help shows now the right version
    updated text of help and extended help
  
  v1.01beta:
    option -x (execute string) in case command returns false now shows the command with the exit code
    added examples.sh
    added safety checks to uninstall.sh 
    uploaded homepage content
	
  v1.0beta:
    first release

