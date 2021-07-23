#!/bin/bash

# OMFG was this annoying to write
# Probably because I'm a n00b

# Other shell scripts
ESCAPE_SPECIAL_CHARS='/home/user/Documents/Bash/escape-special-chars.sh'
ESCAPE_WHITESPACE='/home/user/Documents/Bash/escape-whitespace-only.sh'
SANITIZE_PATH='/home/user/Documents/Bash/sanitize-path.sh'

# Defaults
DEFAULT_BASENAME=${2:-"default"}

# Process user input
SPACE_ESCAPED_INPUT=$($ESCAPE_WHITESPACE "$1")
SANITIZED_PATH="$(eval "SANITIZE_PATH '$SPACE_ESCAPED_INPUT'")"


# Still haven't figured out exactly what's going on here.
# The interior of [[ -d ... ]] needs to be *EXACTLY* the string $SANITIZED_PATH; otherwise there's some sort of evaluation-order or quote-conflict fuckup.
# The best solution I could come up with is to just paste $SANITIZED_PATH into the command I want to run as a string literal, and then evaluate.
eval "if [[ -d $SANITIZED_PATH ]]; then
	SANITIZED_PATH+='/'
	SANITIZED_PATH+='$DEFAULT_BASENAME'
fi"
echo $SANITIZED_PATH
