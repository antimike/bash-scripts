#!/bin/bash

ESCAPE_WHITESPACE='/home/user/Documents/Bash/escape-whitespace-only.sh'
ESCAPE_SPECIAL_CHARS='/home/user/Documents/Bash/escape-special-chars.sh'

for arg in "$@"
do
	arg=$($ESCAPE_WHITESPACE $arg)
	DIRNAME="$(eval "dirname $arg")"
	BASENAME="$(eval "basename $arg")"
	arg="$($ESCAPE_SPECIAL_CHARS "$DIRNAME")/$($ESCAPE_SPECIAL_CHARS "$BASENAME")"
	echo "$arg"
done

echo "args: $@"

#echo "${@}\n"
