#!/bin/bash

shopt -s extglob

source $HOME/Source/bash-scripts/string-utils.sh

print_state() {
	local -n arr_ref="${1}__STATE__"
	echo "$(fill_string "STATE :: $1" "=" 60)"
	for key in "${!arr_ref[@]}"; do
		${arr_ref[$key]} $key
	done
	echo "$(fill_string -l "(END STATE :: $1)" "=" 60)"
}

wait_on_keypress() {
	local key=
	echo "Type '$1' to continue"
	until [[ "$key" == "$1" ]]; do
		read -s -n ${#1} key
	done
}

confirm() {
	while :; do
		read -s -p "$1" -n 1 r
		echo
		case "$REPLY" in
			nN)
				exit 1
				;;
			yY)
				exit 0
				;;
			*)								# Keep waiting for input of the form [nN|yY]
				;;
		esac
	done
}

get_writable_filename() {
	_parse_helper() {
		case "$1" in
			--)
				echo 'break' && return 0
				;;
			--confirm=*)
				echo 'confirm="${1#--confirm=}"' && return 0
				;;
			-c|--confirm)
				echo 'local -n var_to_set="confirm"' && return 0
				;;
			--filename=*)
				echo 'filename="${1#--filename=}"' && return 0
				;;
			-f|--filename)
				echo 'local -n var_to_set="filename"' && return 0
				;;
			-q|--quiet)
				echo 'quiet=1'
				;;
			*)
				echo '' && return 1
				;;
		esac
	}
	local filename=
	local confirm=1
	local cmd=
	local quiet=0
	unset var_to_set
	while (( $# )); do
		cmd="$(_parse_helper "$1")"		# Returns command to execute if opt name is found
		if [[ -z "{var_to_set+x}" ]]; then
			[[ -n "$cmd" ]] && $cmd || goboom "get_writable_filename: Unknown option '$1'"
		else
			[[ -n "$cmd" ]] && goboom "Option '${!var_to_set}' requires a value" \
				|| var_to_set="$1"
			unset var_to_set
		fi
		shift
	done

	# First check if file already exists and ask for confirmation if it does
	if [[ -f "$filename" ]]; then
		if (( confirm )); then
			(( quiet == 1 )) && goboom "Aborted" 
			confirm "Overwrite existing file '$filename'?" || goboom "Aborted"
		fi
	fi

	# Now check if path is writable
	touch "$filename"  || goboom "Path '$filename' is not writable!"

	# Finally, append filename if path is a directory
	if [[ -d "$filename" ]]; then
		filename+="/$BACKUP_FILENAME"
	fi

	# Return filename and handle random errors
	[[ -f "$filename" ]] && echo "$filename" && return 0 \
		|| goboom "Unknwon error creating file '$filename'"
}
