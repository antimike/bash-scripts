#!/bin/bash
# Title
# Description
# Usage

# Initialize constants and make readonly
PROGNAME="$(basename $0)"
readonly PROGNAME

# Initialize options.  Example:
# opt1=
# verbose=0

usage() {
	# Display help message on standard error
	echo "Usage: $PROGNAME <args>" 1>&2
}

clean_up() {
	# Dispose of temporary resources and perform other housekeeping tasks
	exit $1
}

goboom() {
	# Display error message and exit
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	clean_up 1
}

main() {
	# Main program logic and control flow
	while :; do
		case $1 in
			-h|-\?|--help)
				usage
				exit
				;;
			-v|--verbose)
				verbose=$(( verbose + 1 )) # Increment verbosity by 1
				;;
			# Example of how to parse both long and short options:
			# -f|--file)
				# if [ "$2" ]; then
					# file=$2
					# shift
				# else
					# goboom 'ERROR: "--file" requires a nonempty option argument'
				# fi
				# ;;
			# --file=?*)
				# file=${1#*=}
				# ;;
			--)                          # End of options sigil
				shift
				break
				;;
			-?*)                         # Catch-all for unknown options
				printf 'WARNING: Unknown option (ignored): %s\n' "$1" >&2
				;;
			*)                           # Break when options are fully parsed
				break
		esac

		shift
	done
}

trap clean_up SIGHUP SIGINT SIGTERM
main "$@"
