#!/bin/bash
# Simple script to `eval` lines in a file that haven't yet been committed
# Useful for installer logs, e.g.

__FILE__="$(readlink -m ${BASH_SOURCE[0]})"
__NAME__="$(basename "${__FILE__}")"
__DIR__="$(dirname "${__FILE__}")"

source "${__DIR__}/debug.sh"

FILE="${INSTALLED}"
OUTFILE=
QUIET=
DEBUG="${DEBUG+x}"

die() {
    printf "$@" && echo && exit 1 || exit -1
}

usage() {
    cat <<-"USAGE"

	eval-uncommitted-lines.sh
	=========================
	
	SUMMARY: 
	--------
	Simple script to help with planning, logging, and installing software packages
	in "batches", using a designated install-file to record install commands and git
	to track which lines have been executed.
	
	USAGE:
	------
	eval-uncommitted-lines.sh [-f file] [-o output] [-i] [-q] [-D]
	
	OPTIONS:
	--------
	    -f      File to read commands from
	            Defaults to $INSTALLED
	    -o      File to write output to
	            stdout is used if none is specified
	    -i      Interactively edit commands before executing
	    -q      Suppress output
	            If output file is specified, still writes output to it
	    -h      Display this message
	    -D      Debug mode
	USAGE
    exit $(( $1 ))
}

resolve_symlinks() {
    if command -v readlink; then
        realpath "$1"
    else
        readlink -m "$1"
        touch "$1" 2>/dev/null
    fi
    return $?
}

get_cmds() {
    sed -n '/[nN]ot.*[cC]ommitted/='
    git blame "${file}" \
        | grep -i "not committed" \
        | sed 's/^.*(.*) //'
    return $?
}

get_descriptions() {
    :
}

main() {
    while getopts ":f:o:iqhD:" opt; do
        case "$opt" in
            f)  # File to read commands from
                FILE="${OPTARG}"
                ;;
            o)  # File to write output to
                OUTFILE="${OPTARG}"
                ;;
            i)  # "Interactive"
                # For now, this just means opening an editor before eval
                # TODO: Add levels of interactivity
                INTERACTIVE=1
                ;;
            q)  # Suppress output
                QUIET=1
                ;;
            h)  # Display helptext
                usage
                ;;
            D)  # Set debug mode
                # echo "'${OPTARG}'"
                debug_set_global_opts -S ${OPTARG} || {
                    die "Failed to set global debug options"
                }
                ;;
            *)
                echo "Unknown option: '${opt}'"
                usage 1
                ;;
        esac
    done
    FILE=`resolve_symlinks "$FILE"` || {
        die "Couldn't resolve path '%s'" "$FILE"
    }
    debug FILE OUTFILE INTERACTIVE QUIET DEBUG
    exit $?
}

main "$@"
