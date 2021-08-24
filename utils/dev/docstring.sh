#!/bin/bash
# TODO: Fix _tabularize: Each "row" is currently treated as a separate table,
# causing alignment issues when the columns have different sizes
# TODO: Add opts to 'usage' implemented in install.sh (file descriptor, exit
# code specification)
#+
# USAGE:
# >usage [opts] ...
#
# OPTIONS:
# >-D |Debug.  Use this option to print debug output for usage-related functions
# only.  NOT IMPLEMENTED|
# >-L |Logfile|
#
# EXAMPLES:
# >First example
# >Second example
#

_get_path() {
    local file="$*"
    if command -v realpath >/dev/null; then
        echo `realpath "${file}"`
    elif command -v readlink >/dev/null; then
        echo `readlink -m "${file}"`
    else
        echo "Could not find a safe way to resolve true filepath" >&2
        return 2
    fi
    return $?
}

# TODO: Figure out how this should be modified if it's in a sourced file
__FILE__="$(_get_path "${BASH_SOURCE[1]}")"
__DIR__="$(dirname "${__FILE__}")"

usage() {
    unset prefix
    unset suffix
    local debug=
    local file="${__FILE__}"
    local remove_blank_top=
    while getopts ":p:s:f:D" opt; do
        case "${opt}" in
            p)
                local prefix="${OPTARG}"
                ;;
            s)
                local suffix="${OPTARG}"
                ;;
            f)
                file="${OPTARG}"
                ;;
            D)
                debug=1
                ;;
            *)
                echo "usage: Unknown option '${opt}' encountered"
                break
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1
    read -r -d '' remove_blank_top <<-"SED"
		:a
		    /[^\s]/bb
		    d
		:b
		    p;n;bb
	SED
    [[ -n "${prefix+x}" ]] && echo "${prefix}"
    _tabularize "$(_get_helptext_lines "${file}")" |
        sed -n "${remove_blank_top}" | tac |
        sed -n "${remove_blank_top}" | tac
    [[ -n "${suffix+x}" ]] && echo "${suffix}"
}

_get_helptext_lines() {
    local file="${1:-${__FILE__}}"
    local script=
    read -r -d '' script <<-"SED"
		${z;x;bP}
		/^#+/bD
		d
		:D
		    # Remove first "word" of '#' plus non-alphanumeric chars
		    s/^#[@\$&\*!+]*//
		    # Begin new cycle if no leading '#' found
		    T
		    # Trim leading whitespace, leaving tabs
		    s/^ *//
		    # Hold and begin new cycle
		    H;n;bD
		:P
		    G
		    # Apply indent (multiline mode)
		    s/^\(\s*\)>/\1	/M
		    tP
		    # Tabularize
		    x;G
		    s/^\(.*|.*\)|$/column -t -s'|' <<< '\1'/e
		    # Print and quit
		    p;q
	SED
     cat "${file}" | sed -n "${script}"
}

_tabularize() {
    local awk_script=
    read -r -d '' awk_script <<-"AWK"
	{
	    if ($0 ~ /\|/) {
	        tabular = $0
	        while ($0 !~ /\|\s*$/) {
	            getline && tabular = tabular " " $0
	        }
	        # Set RS here---we'll need it to be "|" for the next getline
	        RS = "|"
	        split(tabular, cols, /\|/)
	        # Don't count the last column bc it's empty
	        num_cols = length(cols) - 1
	        concat_cmd = "paste -d:"
	        for (colnum in cols) {
	            cmd = "fold -s -w $(( 80/" num_cols " )) <<< '" cols[colnum] "'"
	            "bash -c \"" cmd "\"" | getline cols[colnum]
	            concat_cmd = concat_cmd " <(echo '" cols[colnum] "')"
	        }
	        "bash -c \"" concat_cmd "\"" | getline
	        gsub(/\n:/, "\n :")
	        col_cmd = "column -s: -t <<< '" $0 "'"
	        "bash -c \"" col_cmd "\"" | getline
	        gsub(/\n\s*\n/, "")
	        RS = "\n"
	        print
	        next
	    }
	    print
	}
	AWK
    awk "${awk_script}" <<< "$*"
}

main() {
    usage "$@"
}

main "$@"

_usage_devel() {
    # Ideas for further development
    # Constants: Used to demarcate special usage-related comments by the caller
    local DOCSTRING_MARKERS="@+%!"

    # Define these locals as empty for now.  Defaults are defined below.
    local return_status=
    local fd=
    local display=
    local unknown=

    while getopts "F:s:A:D:U:" opt; do
        case "$opt" in
            F)
                fd=$(( OPTARG ))
                ;;
            s)
                return_status=$(( OPTARG ))
                ;;
            A)
                assumed="$OPTARG"
                ;;
            D)
                display="$OPTARG"
                ;;
            U)
                unknown="$OPTARG"

                # Presumably this is an error condition, so...
                return_status=${return_status:-1}
                fd=${fd:-2}
                ;;
            *)
                # We want to return an error code **different from** the one
                # potentially passed to us by the caller
                # Only way I could find to suppress stderr here
                # TODO: Find a better way to do this?
                return_status=$( exec 2>/dev/null; echo $(( return_status )) )
                (( ++return_status )) || (( return_status -= 2 ))
                break
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1

    # The remaining (positional) args define the "command stack", i.e., the
    # options / arguments that were passed to the main script / function.
    # This can be used to define contextual helptext, instead of just one
    # "catchall" usage text as is usually done.
    # The command stack can be passed in several ways:
    # 1. As a getopts-style string:
    #     "fo:l" --> options "-f" and "-o" were passed to the main script but
    #     should be ignored ("assumed"); helptext for option "l" should be
    #     displayed.  This is useful if some options are "contextual", i.e., only
    #     available or meaningful if certain other options have been passed first.
    #     "fo:l?q" --> Same as above, but unknown option "q" was also passed
    # 2. As arguments to the options -A ("assumed"), -D ("display"), and -U
    # ("unknown"):
    #     usage -A "fo" -D "l" -U "q" --> equivalent to the second example given
    #     above
}
