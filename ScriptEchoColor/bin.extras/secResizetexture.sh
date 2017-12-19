#!/bin/bash
# Copyright (C) 2004-2012 by Henrique Abdalla
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

############## FUNCTIONS #######################################################
bForceProcessLastBatch=false
function FUNCexitError() {
		((--totFiles))
		SECFUNCvarWriteDB
		echoc -p -- "$@"
		if((countFiles<=totFiles));then
			exit 1
		else
			bProcessLastBatch=true
		fi
}

function FUNCcheckMissing () {
	if [[ -z "$1" ]] || [[ "${1:0:1}" == "-" ]]; then
		echoc -p -- "$2 missing value"
		exit 1
	fi
}

function FUNCcreateGimpScript () {
	local l_where="$1"
	l_where="$l_where/scripts/SECresizeTexture.scm"
	if [[ -f "$l_where" ]]; then
		if ! grep -q "SECresizeTexture" "$l_where"; then
			echo "################## GIMP SCRIPT >>--> ###################"
			echo "### $l_where ###"
			cat "$l_where"
			echo "################## <--<< GIMP SCRIPT ###################"
			if ! echoc -q "invalid gimp script (see above) replace $l_where required, continue"; then
				exit 1
			fi
		fi
	fi
	
	# update always!
	cat >$l_where <<EOF
(define (SECresizeTexture filename width height)
	(let* (
			(img (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
			(drawable (car (gimp-image-get-active-drawable img)))
			(name (car (gimp-image-get-name img)))
		)
		(gimp-image-scale img width height)
		(gimp-file-save RUN-NONINTERACTIVE img drawable filename name)
		(gimp-image-delete img) ;close the image to release memory
	)
)

(script-fu-register "SECresizeTexture to use them with 3D objects"
  _"_ResizeTexture"
  _"Scale the texture to new width and height, to be used by `basename $0`."
  "Henrique A."
  "Henrique A."
  "Oct 2012"
  ""
)
EOF
	if(($?!=0));then
		echoc -p "fail to write gimp script at $l_where"
		exit 1
	fi
};export -f FUNCcreateGimpScript #to work with find -exec

function FUNCcreateGimpScriptEverywhere () {
	find $HOME -type d -name ".gimp-*" -exec bash -c 'FUNCcreateGimpScript "{}"' \; 2>/dev/null
}

function FUNCheader() { 
	echo -n "[$countFiles/$totFiles]`echo -n $(($countFiles*100/$totFiles))`%[$countResizedFiles](${elapsed}s)"; 
}

function FUNCbkpFileName() { 
	bkpFile="${filename}.$currentSize-`printf "%03d" $index`.bkp";
}

#@@@R strOptRecursive=""

############### DEFAULTS #######################################################
# if bOptRecursive is not set, initialize them all, it will be already set when this script is called by find command.
bOnce=false
if [[ ! -n ${bOptRecursive+dummy} ]]; then
	source <(secinit)
#	echoc -c
	
	SECvarOptWriteAlways=false
	SECFUNCvarSet --default beginAt=`date +"%s"`
	SECFUNCvarSet --default maxSize=1024
	SECFUNCvarSet --default bAllowWrongMaxSize=false
	SECFUNCvarSet --default bOptRecursive=false
	SECFUNCvarSet --default bHalfsize=false
	SECFUNCvarSet --default bReportOnly=false
	SECFUNCvarSet --default logFile="$HOME/.`basename $0`.log"
	SECFUNCvarSet --default strExtension=""
	SECFUNCvarSet --default countFiles=0
	SECFUNCvarSet --default countResizedFiles=0
	SECFUNCvarSet --default totFiles=1
	SECFUNCvarSet --default strExclude=""
	SECFUNCvarSet --default batchAmmount=0
	SECFUNCvarSet --default batchCount=0
	SECFUNCvarSet --default elapsed=0
	batchArray=();SECFUNCvarSet --array batchArray;
	SECFUNCvarSet --default bBatch=false
	SECFUNCvarSet --default allowlayers=false
	SECFUNCvarSet --default countTooManyLayersFailure=0
	SECvarOptWriteAlways=true
	
	SECFUNCvarWriteDB
	
	bOnce=true
fi
bOptRecursive=false # can only be set if there is a cmdline option for it...

############### OPTIONS ########################################################
while ! ${1+false} && [[ "${1:0:1}" == "-" ]];do
	opt="$1"
	if [[ "$1" == "--help" ]];then #help
		SECFUNCshowHelp --colorize "Lower texture sizes til a max of (default) 1024x1024 (change with --maxsize)."
		SECFUNCshowHelp --colorize "It will resize all texture that gimp supports like .dds, .tga, .jpg, .gif etc, but mainly used in 3D applications or 3D games, so your low mem gfx card can run it!"
		SECFUNCshowHelp
		exit
	elif [[ "$1" == "--recursive" ]]; then #help <extension> recursively find and modifies all files with the given extension
		bOptRecursive=true;
		shift
		FUNCcheckMissing "${1-}" "$opt"
		strExtension="$1"
	elif [[ "$1" == "--maxsize" ]]; then #help <size> max width or height to resize if greater
		shift
		FUNCcheckMissing "${1-}" "$opt"
		maxSize="$1"
	elif [[ "$1" == "--halfsize" ]]; then #help resize to half in w and h
		bHalfsize=true
	elif [[ "$1" == "--batch" ]]; then #help <ammount> execute in a batch of ammount (may work faster)
		bBatch=true
		shift
		FUNCcheckMissing "${1-}" "$opt"
		batchAmmount=$1
	elif [[ "$1" == "--allowlayers" ]]; then #help multiple layers still does not work with the simple script-fu? to try anyway, use this option.
		allowlayers=true
	elif [[ "$1" == "--exclude" ]]; then #help <pattern> exclude files matching pattern, can have more than one, ex.: "*tmp*.txt"
		shift 
		FUNCcheckMissing "${1-}" "$opt"
		strExclude="$strExclude -not -name \"$1\" "
	elif [[ "$1" == "--reportonly" ]]; then #help will just report what files can be worked with chosen options
		bReportOnly=true
	elif [[ "$1" == "--" ]];then #help params after this are ignored as being these options
		shift
		break
	else
		echoc -p "invalid option '$1'"
		exit 1
	fi
	shift
done
#while true; do
#	if [[ "${1:0:2}" == "--" ]];then
#		opt="${1:2}"
#		if [[ "$opt" == "help" ]]; then #opt show this help
#			grep "#help" $0 |grep -v "#skip"
#			
#			sedCleanHelp='s".*\$opt.*==.*\"\(.*\)\".*#opt \(.*\)"\t--\1\t\2"' #skip
#			grep "#opt" $0 |grep -v "#skip" |sed "$sedCleanHelp"
#			
#			exit 0
#		elif [[ "$opt" == "recursive" ]]; then #opt <extension> recursively find and modifies all files with the given extension
#			bOptRecursive=true;
#			shift
#			FUNCcheckMissing "$1" "$opt"
#			strExtension="$1"
#		elif [[ "$opt" == "maxsize" ]]; then #opt <size> max width or height to resize if greater
#			shift
#			FUNCcheckMissing "$1" "$opt"
#			maxSize="$1"
#		elif [[ "$opt" == "halfsize" ]]; then #opt resize to half in w and h
#			bHalfsize=true
#		elif [[ "$opt" == "batch" ]]; then #opt <ammount> execute in a batch of ammount (may work faster)
#			bBatch=true
#			shift
#			FUNCcheckMissing "$1" "$opt"
#			batchAmmount=$1
#		elif [[ "$opt" == "allowlayers" ]]; then #opt multiple layers still does not work with the simple script-fu? to try anyway, use this option.
#			allowlayers=true
#		elif [[ "$opt" == "exclude" ]]; then #opt <pattern> exclude files matching pattern, can have more than one, ex.: "*tmp*.txt"
#			shift 
#			FUNCcheckMissing "$1" "$opt"
#			strExclude="$strExclude -not -name \"$1\" "
#		elif [[ "$opt" == "reportonly" ]]; then #opt will just report what files can be worked with chosen options
#			bReportOnly=true
#		else
#			echoc -p "invalid option $1"
#			exit 1
#		fi
#		shift
#		continue
#	fi
#	break #filename at tail param
#done

if $bOnce; then
	SECFUNCvarWriteDB
	#FUNCcreateGimpScript
	FUNCcreateGimpScriptEverywhere
fi

############### VALIDATIONS ####################################################
# maxSize
if((maxSize<=0));then
	echoc -p "maxSize must be > 0"
	exit 1
fi
if ! $bAllowWrongMaxSize; then
	tmpSizeCheck=2
	while true; do
		if((maxSize==tmpSizeCheck));then
			break;
		elif((tmpSizeCheck>maxSize));then
			if echoc -q "`SECFUNCvarShowSimple maxSize` is not power of 2 (..246,512,1024..), continue anyway (gfx cards may not like it!)";then
				SECFUNCvarSet bAllowWrongMaxSize=true
				break
			else
				exit 0
			fi
		fi
		((tmpSizeCheck*=2))
	done
fi

############### MAIN CODE ######################################################
if $bOptRecursive; then
	SECFUNCvarSet --show totFiles=`find -iname "*.$strExtension" 2>/dev/null |wc -l`	
	
	#@@@R find -iname "*.$strExtension" -exec $0 $strOptRecursive '{}' \; 2>&1 |tee $logFile
	SECFUNCvarWriteDB
	echoc -x "`cat \
<<EOF
find -iname "*.$strExtension" $strExclude -exec $0 '{}' \; |tee $logFile
EOF`"	
	SECFUNCvarReadDB	
	
	SECFUNCvarShowSimple elapsed
	SECFUNCvarShowSimple totFiles
	SECFUNCvarShowSimple countFiles
	SECFUNCvarShowSimple countResizedFiles
	exit 0
else
	SECFUNCvarReadDB
	
	filename="$1"
	#echo ">>>$filename"
	if [[ ! -f "$filename" ]]; then
		echoc -p "missing texture filename"
		exit 1
	fi
	
	SECvarOptWriteAlways=false #to speed up, requires SECFUNCvarWriteDB somewhere...
	#cat $SECvarFile;exit
#			echo -n ">0>cat>";cat $SECvarFile |grep batchArray |grep -v SECvars #@@@R
#			echo ">0>array> ${batchArray[@]}"
	#echo ">>>SECvars=(${SECvars[@]})";
	#echo $SECvarFile;cat $SECvarFile;

	#((++countFiles)); #SECFUNCvarSet countFiles $((++countFiles))
	#echo $SECvarFile;cat $SECvarFile;read

	timeNow=`date +"%s"`
	#SECFUNCvarSet 
	elapsed=`echo "$timeNow-$beginAt" |bc`
	echo -en "`FUNCheader`\r"
	
	if [[ ! -f "$filename" ]]; then
		FUNCexitError "invalid file: $filename"
	fi
	
	#ls -l "$filename";
	#identify "$filename"; 
	
	# validate file
	strIdentify=`identify "$filename"`
	ret=$?
	if((ret!=0));then 
		#echoc -p $ret
		FUNCexitError "identify fail"
	fi 
	
	if ! $allowlayers; then
		SECFUNCvarSet layerCount=`identify -verbose "$filename" |grep "^Image:" -c`
		if((layerCount>1));then
			SECFUNCvarShowSimple layerCount
			((countTooManyLayersFailure++))
			FUNCexitError "image '$filename' has more than one layer try with --allowlayers"
		fi
	fi
	
	bDoIt=false
	if $bForceProcessLastBatch; then
		bDoIt=true
	else
		((++countFiles)); #SECFUNCvarSet countFiles $((++countFiles))
	
		sedWidthHeight='s".* .* \([0-9]*\)x\([0-9]*\) .*"currentWidth=\1;currentHeight=\2;"'
		eval `echo "$strIdentify" |sed "$sedWidthHeight"`
		#echo "maxSize=$maxSize currentWidth=$currentWidth currentHeight=$currentHeight"
		currentSize="${currentWidth}x${currentHeight}"
	
		width=$currentWidth
		height=$currentHeight
	
		if $bHalfsize; then
				width=$((width/2))
				height=$((height/2))
		else
			while((width>maxSize));do 
				width=$((width/2))
				height=$((height/2)) #to keep aspect ratio
			done
			while((height>maxSize));do
				height=$((height/2))
				width=$((width/2)) #to keep aspect ratio
			done
		fi

		if((width<currentWidth)) || ((height<currentHeight));then
			bDoIt=true;
		fi
		if $bHalfsize; then
			bDoIt=true;
		fi
	fi
	
	if $bDoIt;then
		bResized=false
		if ! $bReportOnly; then
			if ! $bForceProcessLastBatch; then
				# clean output line
				#printf "%`tput cols`s\n" " "
			
				# create an indexed backup
				index=0
				bkpFile=""
				bAlreadyBkp=false
				FUNCbkpFileName #init
				while [[ -f "$bkpFile" ]]; do
					if cmp --quiet "$filename" "$bkpFile"; then
						bAlreadyBkp=true
						break;
					fi
					((++index))
					FUNCbkpFileName
				done
				if ! $bAlreadyBkp; then
					cp -v "$filename" "$bkpFile"
				fi
			
				#SECFUNCvarSet 
				batchCount=$((++batchCount))
			
				batchArray+=(" -b \"(SECresizeTexture \\\"$filename\\\" $width $height)\" ");
				#echo ">>>${batchArray[@]}"
				#SECFUNCvarSet --array batchArray;
			fi
			
			echo -en "`FUNCheader`\r"
			#echo "$strStatus: `FUNCheader` $filename: old $currentSize, new ${width}x${height}"			
			if $bBatch; then
				if $bForceProcessLastBatch || ((batchCount==batchAmmount)) || ((countFiles>=totFiles));then
					echoc -x 'gimp -i '${batchArray[@]}' -b "(gimp-quit 0)"'
					
					#eval 'gimp -i '${batchArray[@]}' -b "(gimp-quit 0)"' #stdout is good here...
					if(($?==0));then
						bResized=true
						#SECFUNCvarSet countResizedFiles $((countResizedFiles+batchCount))
						((countResizedFiles+=batchCount)) 
					fi
					
#					echo ">a> ${batchArray[@]}" #@@@R
#					for((i=0;i<${#batchArray[*]};i++));do echo ">i> ${batchArray[i]}"; done
#					echo ">>>${#batchArray[*]} ${batchArray[@]}"
					for((i=0;i<${#batchArray[*]};i++));do
						sedGetFilename='s|^.*SECresizeTexture \\\"\(.*\)\\\" .* .*)\".*|\1|'
#						echo ">i> ${batchArray[i]}" #@@@R
						#tmpFile=`echo "${batchArray[i]}" |sed -e 's|^.*SECresizeTexture \(.*\) [[:digit:]]* [[:digit:]]*)\".*|\1|' -e 's|^\\\"||' -e 's|\\\"$||'`
						tmpFile=`echo "${batchArray[i]}" |sed "$sedGetFilename"`
						#echo ">f> $tmpFile" #@@@R
						#identify "$tmpFile"
						#echo ">a>${batchArray[i]}<<<"
						#echo ">f>$tmpFile<<<"
						identify "$tmpFile"
					done
					
					#SECFUNCvarSet 
					batchCount=0
					batchArray=();#SECFUNCvarSet --array batchArray
				fi
			else
				# resize!
				echoc -x "`cat <<EOF
					gimp -i \
						-b "(SECresizeTexture \\\"$filename\\\" $width $height)" \
						-b "(gimp-quit 0)" >>$logFile #prevents stdout (so skip tee too)
EOF`"
				if(($?==0));then
					bResized=true
					#SECFUNCvarSet countResizedFiles $((++countResizedFiles))
					((++countResizedFiles))
				fi
			fi
			
			#ls -l "$filename";
		fi 
		strStatus="OK"
		if $bResized;then 
			strStatus="OK";
		else 
			if $bReportOnly; then
				strStatus="CanTry";
			else
				if $bBatch; then
					strStatus="BatchCaching($batchCount/$batchAmmount)";
				else
					strStatus="FAIL";
				fi
			fi
		fi
		echo "$strStatus: `FUNCheader` $filename: old $currentSize, new ${width}x${height}"
		#identify "$filename"; 
	fi
#			echo -n ">2>cat>";cat $SECvarFile |grep batchArray |grep -v SECvars #@@@R
#			echo ">2>array> ${batchArray[@]}"
	SECFUNCvarWriteDB
fi

