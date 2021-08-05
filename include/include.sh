#!/bin/bash
# Some basic logging, IO, and convenience functions
# Declares variables __${importer_name}_NAME__, __${importer_name}_DIR__, and
# __${importer_name}_FILE__ for internal use by the script that `source`s this
# file.  The value of ${importer_name} is the basename of the source file with
# the extension removed, whitespace replaced by underscores, and all letters
# capitalized.

shopt -s extglob

# These vars are set in the function _get_file_info
export_name=
export_file=
export_dir=

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

_get_script_name() {
    local file="$(get_path "${BASH_SOURCE[2]}")"
    local basename="$(basename "${file}")"
    sed 's/\s/_/g' <<< "${basename%%.*}" | tr [a-z] [A-Z]
}

_get_file_info() {
    # Sets global variables for internal use by the calling script
    local file="$(get_path "${BASH_SOURCE[2]}")"
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

__INCLUDE_FILE__="$(get_path "${BASH_SOURCE[0]}")"
__INCLUDE_DIR__="$(dirname "${__INCLUDE_FILE__}")"
__INCLUDE_NAME__="$(basename "${__INCLUDE_FILE__}")"
__DEBUG__="${DEBUG+x}"
__DEBUG_DEPTH__="${DEBUG_MAXDEPTH:-1}"

# String templates
typeset -A _string_templates=(
    [UNKNOWN_OPT]='_unknown_opt'
    [VARS]='_prettyprint_vars'
)

_prettyprint_vars() {
    # Template for prettyprinting the values of variables
    # Mostly useful for debugging
    # Unfortunately, I don't think this will work with the current template
    # strategy
    # TODO: Think of a way to implement this
    echo "Not implemented" >&2
}

_unknown_opt() {
    # Template for "unknown opt" errortext
    echo "Unknown option '%s' encountered in function '${FUNCNAME[3]}'\n"
}

_get_file_info

_repeat() {
    # Repeats a string N times
    local -i n="$1" && shift
    local text="$*"
    local template="${text}%.0s"
    if [ $n -gt 0 ]; then
        printf "$template" $(eval "echo {1..$n}")
    elif [ $n = 0 ]; then
        printf ''
    else
        debug BAD_ARG $n
        return -1
    fi
    return $?
}

_underline() {
    local replacement='='
    local -i caps=0
    while getopts "r:c:C" opt; do
        case "$opt" in
            r|c)      # (r)eplacement / (c)haracter
                replacement="${OPTARG:0:1}"
                echo ${replacement} >&2
                ;;
            C)         # (C)apitalize
                caps=1
                ;;
            *)
                debug UNKNOWN_OPT "$opt"
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1
    local text="$*"
    if [ $caps -eq 1 ]; then
        text="$(tr [a-z] [A-Z] <<< "$text")"
    fi

    cat <<-UNDERLINE
	$*
	$(tr [:print:] [${replacement}*] <<< "$*")
	UNDERLINE
}

notify() {
    # Print message to stdout
    # If first argument is recognized as a template name, that template is
    # passed to printf
    # Option -t can also be used to force template specification
    # TODO: Support ANSI codes (colors, text formatting, etc.)
    # TODO: Debug tabindent issues (tabindent arg doesn't work for reasons that
    # are extremely mysterious)
    local template='%s\n'
    local -i indent=0
    local -i tabindent=0
    while [ $# -gt 0 ]; do
        unset temp_fn
        if [ -n "${temp_fn=${_string_templates["$1"]}}" ]; then
            template="$($temp_fn)" && shift && continue
        fi
        case "$1" in
            -t)
                shift && template="$1"
                ;;
            -i)
                shift && indent="$1"
                ;;
            -I)
                shift && tabindent="$1"
                ;;
            --)
                shift && break
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    local prefix="$(_repeat $tabindent "	")$(_repeat $indent " ")"
    printf "${template}" "$@" | sed "s/^/${prefix}/" &&
        return 0 || return -1
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
        local format='%s\n'
        case "$1" in
            --offset=*)
                let offset+="${1#--offset=}" 2>/dev/null || 
                    echo "DEBUG: Bad callstack offset passed to 'debug'" >&2 &&
                shift
                ;;
            *) ;;
        esac
        local source="${BASH_SOURCE[$(( 1 + offset ))]}"
        local func="${FUNCNAME[$(( 1 + offset ))]}"
        local lineno="${BASH_LINENO[$(( 0 + offset ))]}"
        # "Allowed" functions: those within __DEBUG_DEPTH__ of the end of the
        # function stack (offset by 2 because of `main`)
        # This ensures that debug messages are printed on recursive calls of
        # arbitrary depth, despite the restriction imposed by __DEBUG_DEPTH__
        local -a allowed_funcs=(
            "${FUNCNAME[@]: $((-__DEBUG_DEPTH__-2)): ${__DEBUG_DEPTH__}}"
        )
        if (( ${#FUNCNAME[@]} - 3 - offset > __DEBUG_DEPTH__ )) &&
            [[ ! " ${allowed_funcs[@]} " = *\ ${func}\ * ]]
        then
            # echo "Debug bailed due to insufficient depth" >&2
            # printf "    Allowed funcs: '%s'\n" "${allowed_funcs[@]}" >&2
            # printf "    Debug caller: '%s'\n" "$func" >&2
            return $status
        else
            # Debug header
            error "DEBUG: ${source} --> ${func} @${lineno}:"

            # Use `error` to print formatted messages to stderr
            error -i 4 "$@"
        fi
    fi
    return $status      # To make sure return status isn't "masked" by
                        # successful debug calls
}

debug_vars() {
    # Pretty-prints the values of passed variable names to stderr, along with a
    # standard debug message including the source filename, function name, and
    # line number
    local -i status=$?
    local val=
    if [ -n "${DEBUG+x}" ]; then
        local -a lines=( )
        for var in "$@"; do
            val="${!var}"
            if [ $(wc -l <<< "$val") -gt 1 ]; then
                val="$(
                    sed -e '1i\\' <<< "$val" | 
                        sed -e '1!s/^/|  /'
                                            )"
            fi
            lines+=( "$var = ${val}" )
        done
        debug --offset=1 "${lines[@]}"
    fi
    return $status      # To make sure return status isn't "masked" by
                        # successful debug calls
} >&2

usage() {
    usage_fn="_$(_get_script_name | tr [A-Z] [a-z])_usage"
    if command -v "${usage_fn}" >/dev/null; then
        ${usage_fn}
        return $?
    else
        return 25
    fi
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
