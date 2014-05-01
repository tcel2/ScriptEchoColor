#!/bin/bash

echoc -Q "git@O_commit/_browse";
case "`secascii $?`" in 
	c) echoc -x "git gui";; 
	b) echoc -x "gitk";; 
esac

