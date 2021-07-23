#!/bin/bash

shopt -s extglob
source $HOME/Source/bash-scripts/logging.sh
source $HOME/Source/bash-scripts/string-utils.sh
source $HOME/Source/bash-scripts/unit-test.sh

declare -A __PARSE____STATE__=(
	[opts_ref]="print_assoc_array"
	[flags_ref]="print_assoc_array"
	[params_ref]="print_assoc_array"
	[__PARAMS__]="print_array"
	[__PARSED__]="print_array"
	[__PARSE_ERRORS__]="print_assoc_array"
)

# Default namerefs to caller vars
declare -n opts_ref="__OPTS__"
declare -n flags_ref="__FLAGS__"
declare -n params_ref="__PARAM_NAMES__"

# Parse results
declare -a __PARAMS__=()
declare -a __PARSED__=()
declare -A __PARSE_ERRORS__=()

parse_opts() {

	# Debug vars
	local parsing_internal_opt="parse_opts: Parsing internal opt '%s' = %s"
	local internal_opt_acquired="parse_opts: Acquired internal opt '%s' = '%s'"
	local breaking_loop="parse_opts: Breaking internal opts parse loop: %s"
	local unknown_internal_opt="parse_opts: Encountered unknown internal opt '%s'"

	notify_debug "Entered parse_opts"
	notify_debug "$(print_state __PARSE__)"

	# First, parse internal options for this function to get namerefs
	while (( $# )); do
		notify_debug -f "$parsing_internal_opt" "$1" "$2"
		breakpoint
		case "$1" in
			-o|--opts?(=*))
				if [[ "$1" = --opts=* ]]; then
					opts_ref="${1#--opts=*}"
					notify_debug -f "$internal_opt_acquired" "opts_ref" "${1#--opts=*}"
				else
					# TODO: Figure out better way to handle edge (error) case
					shift && opts_ref="$1"
					notify_debug -f "$internal_opt_acquired" "opts_ref" "$1"
				fi
				;;
			-f|--flags?(=*))
				if [[ "$1" = --flags=* ]]; then
					flags_ref="${1#--flags=*}"
					notify_debug -f "$internal_opt_acquired" "flags_ref" "${1#--flags=*}"
				else
					# TODO: Figure out better way to handle edge (error) case
					shift && flags_ref="$1"
					notify_debug -f "$internal_opt_acquired" "flags_ref" "$1"
				fi
				;;
			--)
				break
				;;
			*)
				notify_debug -f "$unknown_internal_opt" "$1"
				notify_debug -f "$breaking_loop" "Catchall pattern"
				break
				;;
		esac
		shift || break
	done

	# Remaining args are now parsed
	# These represent both options and positional params to the caller
	while :; do
		notify_debug "Parsing caller (external) arg '$1' and possible successor '$2'"
		case "$1" in
			--)
				if (( "${#__PARAMS__[@]}" )); then
					__PARSE_ERRORS__[--]=\
						"Unknown opts '${__PARAMS__[@]}' encountered before -- in opts expansion"
				fi
				break
				;;
			--*=*)
				add_opt_or_flag "${1%%=*}" "${1#--*=}" || add_param "$1"\
					&& __PARSE_ERRORS__["$1"]=\
						"Unknown opt or flag '$1' encountered"
				;;
			-*)
				if [[ $(add_opt_or_flag "$1" "$2") ]]; then 
					shift
				else
					add_param "$1" && __PARSE_ERRORS__["$1"]=\
						"Unknown opt or flag '$1' encountered"
				fi
				;;
			*)
				add_param "$1"
				;;
		esac
		shift
	done
}

add_opt_or_flag() {

	local name="$1"
	local val="$2"

	# Assumption: Keys will be *patterns*
	# Because of this, we have to iterate
	# Iterate over 'opts' first
	for key in "${!opts_ref[@]}"; do
		case "$name" in
			"$key")
				__PARSED__+=("$name")
				opts_ref["$key"]="$val" && return 0
				;;
			*)
				continue
				;;
		esac
	done

	# Now iterate over 'flags'
	for key in "${!flags_ref[@]}"; do
		case "$name" in
			"$key")
				__PARSED__+=("$name")
				local handler="${flags_ref[$key]}"
				eval $cmd || __PARSE_ERRORS__+=(
					["$name"]="Error calling flag-handler '$handler'"
				)
				return 0 # Return 0 even if handler failed
                 # This is so that the calling fn will know parsing succeeded
				;;
			*)
				continue
				;;
		esac
	done

	# If we reach this point, parsing failed
	return 1
}

add_param() {
	__PARSED__+=("$1")
	__PARAMS__+=("$1")
}

trap "set" SIGINT

#########################################################
## IDEAS
#########################################################

# Use `local -n var_to_set=...` to keep track of when an opt is expecting a successor
#__parse_opt() {
#  case "$1" in
#    --)
#      echo 'break' && return 0
#      ;;
#    --confirm=*)
#      echo 'confirm="${1#--confirm=}"' && return 0
#      ;;
#    -c|--confirm)
#      echo 'local -n var_to_set="confirm"' && return 0
#      ;;
#  esac
#}

filename_option() {
	long_form="filename"
	short_form="f"
	helptext=''
}

declare -A opts=(
	[filename]="$(option filename)"
)
