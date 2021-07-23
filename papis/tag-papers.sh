#!/bin/bash

__CAUGHT__=1
__UNCAUGHT__=2

goboom() {
	echo "$1" 1>&2 && exit $__CAUGHT__ || exit $__UNCAUGHT__
}

if [[ -z $PAPIS_DIR ]]; then
	goboom "No Papis directory has been set!"
fi

get_yaml_tags() {
	local file="$1"
	if [[ ! -e "$file" ]]; then
		goboom "File '$1' doesn't seem to exist!"
	fi
	tags=( $(yq exec '.tags' "$file") )
}


