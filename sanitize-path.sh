#!/bin/bash -x

# Other scripts
ESCAPE_SPECIAL_CHARS='/home/user/Documents/Bash/escape-special-chars.sh'
ESCAPE_WHITESPACE='/home/user/Documents/Bash/escape-whitespace-only.sh'

# Process input
INPUT=$($ESCAPE_WHITESPACE $1) 
DIRNAME="$(eval "dirname $INPUT")"
BASENAME="$(eval "basename $INPUT")"
DIRNAME=$($ESCAPE_SPECIAL_CHARS "$DIRNAME")
DIRNAME+="/"
DIRNAME+="$($ESCAPE_SPECIAL_CHARS "$BASENAME")"
echo "$DIRNAME"

#for arg in "$@"
#do 
	
