#!/bin/bash
# Some basic logging, IO, and convenience functions
# Declares variables __${importer_name}_NAME__, __${importer_name}_DIR__, and
# __${importer_name}_FILE__ for internal use by the script that `source`s this
# file.  The value of ${importer_name} is the basename of the source file with
# the extension removed, whitespace replaced by underscores, and all letters
# capitalized.

shopt -s extglob

__INCLUDE_FILE__="$(get_path "${BASH_SOURCE[0]}")"
__INCLUDE_DIR__="$(dirname "${__INCLUDE_FILE__}")"
__INCLUDE_NAME__="$(basename "${__INCLUDE_FILE__}")"
__DEBUG__="${DEBUG+x}"

# These vars are set in the function _get_file_info.
unset export_name
unset export_file
unset export_dir

# String templates
typeset -A _string_templates=(
    [UNKNOWN_OPT]='_unknown_opt'
)

_unknown_opt() {
    # Template for "unknown opt" errortext
    echo "Unknown option '%s' encountered in function ${FUNCNAME[2]}"
}

_get_file_info

get_path() {
    local file="$*"
    if command -v realpath >/dev/null; then
        echo "`realpath "${file}"`"
    elif command -v readlink >/dev/null; then
        echo "`readlink -m "${file}"`"
    else
        echo "Could not find a safe way to resolve true filepath" >&2
        return 2
    fi
    return $?
}

notify() {
    # Print message to stdout
    # If first argument is recognized as a template name, that template is
    # passed to printf
    # Option -t can also be used to force template specification
    # TODO: Support ANSI codes (colors, text formatting, etc.)
    local template='%s\n'
    if [ -n "${temp_fn=${_string_templates[$1]}}" ]; then
        template="$($temp_fn)"
        shift
    elif [ "$1" = "-t" ]; then
        shift && template="$1" && shift
    fi
    printf "$template" "$@" && return 0 || return -1
}

error() {
    # Print error message to stdout
    # See `notify` for details on passing format strings
    notify "$@" >&2
    return $?
}

die() {
    # Print error messages to stderr and exit
    # See `notify` for details on passing format strings
    local -i code="$1" && shift && error "$@" &&
        exit $code || exit $(( - code ))
}

debug() {
    # Prints debug message(s) to stderr, along with a standard debug header
    # including the source filename, function name, and line number
    local -i status=$?
    if [ -n "${DEBUG+x}" ]; then
        local -i offset=0
        case "$1" in
            --offset=*)
                let offset+="${1#--offset=}" && shift || return -1
                ;;
            *) ;;
        esac
        local source="${BASH_SOURCE[$(( 1 + offset ))]}"
        local func="${FUNCNAME[$(( 1 + offset ))]}"
        local lineno="${BASH_LINENO[$(( 0 + offset ))]}"
        echo "DEBUG: ${source} --> ${func} @${lineno}:"
        printf '    %s\n' "$@"
    fi
    return $status      # To make sure return status isn't "masked" by
                        # successful debug calls
} >&2

debug_vars() {
    # Pretty-prints the values of passed variable names to stderr, along with a
    # standard debug message including the source filename, function name, and
    # line number
    local -i status=$?
    if [ -n "${DEBUG+x}" ]; then
        local -a lines=( )
        for var in "$@"; do
            lines+=( "$var = ${!var}" )
        done
        debug --offset=1 "${lines[@]}"
    fi
    return $status      # To make sure return status isn't "masked" by
                        # successful debug calls
} >&2

_underline() {
    local replacement='='
    local text="$*"
    while getopts "r:c:C" opt; do
        case "$1" in
            -r|-c)      # (r)eplacement / (c)haracter
                replacement="${OPTARG:0:1}"
                text="$*"
                ;;
            -C)         # (C)apitalize
                text="$(tr [a-z] [A-Z] <<< "$text")"
                ;;
            *)
                
                ;;
        esac
    done
    cat <<-UNDERLINE
	$*
	$(tr [:print:] [${replacement}*] <<< "$*")
	UNDERLINE
}

_get_file_info() {
    # Sets global variables for internal use by the calling script
    local file="$(get_path "${BASH_SOURCE[1]}")"
    local dir="$(dirname "${file}")"
    local basename="$(basename "${file}")"
    local name="$(sed 's/\s/_/g' <<< "${basename%%.*}" | tr [a-z] [A-Z])"
    typeset -n export_name="__${name}_NAME__"
    typeset -n export_dir="__${name}_DIR__"
    typeset -n export_file="__${name}_FILE__"
    export_name="$basename"
    export_dir="$dir"
    export_file="$file"
}

_script_id() {
    # Generates a unique identifier for this instance of the script
    # Not currently used
    printf '%s_%s_%s_%s' \
        "${export_name}" \
        "$(date +'%s%N')" \
        "$$" \
        "$(( RANDOM % 1000 ))"
}

_prettyprint_var() {
    # Pretty-prints the value of a passed variable name, including arrays
    # Not currently used
    # TODO: Finish implementing this to support all variable types
    local -n ref="$1"
    read -r -d '' sed_script <<-SED
	s/^\s\+//   # Remove initial whitespace
	s/^\([^\=]\+\)\=(/\1\=(\n/      # Newline after open-paren
        :LBREAK
	s/\(\[[A-Za-z]\+\]\=\"[^"]*\"\) /\t\1\n/g   # Newline after each assoc. element
	SED
    printf '\n%s\n' "$(declare -p "${!ref}")" \
        | sed -e "${sed_script}" | sed -e 's/^/\t/'
}

_get_docstring() {
    # Gets documentation strings from a source file based on certain formatting
    # conventions
    # Currently unfinished
    # TODO: Finish this
    # TODO: Support markup: YAML, asciidoc, markdown, JSON, ...
    echo "Not implemented" >&2 && return 1
    cat <<-"SED" | xargs -I {} sed -n {} "${__FILE__}"
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
}
