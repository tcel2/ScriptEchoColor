#!/bin/bash

while true;do
	echoc --info "Git helper (hit ctrl+c to exit)"
	echoc -Q "git@O_commitWithGitGui/_diffLastTagFromMaster/_pushTagsToRemote/_browseWithGitk";
	case "`secascii $?`" in 
		c) echoc -x "git gui";; 
		b) echoc -x "gitk";; 
		p) echoc -x "git push --tags";;
		d) echoc -x "git difftool -d \"`git tag |tail -n 1`..master\"";;
	esac
done

