#!/bin/bash
# Simple debug utilities for printing ad-hoc messages, callstacks, etc.
#+
# USAGE: debug [-v] [-p] [l] [-f] [-F] [-L] [-d delim] ...statements
# OPTS:
# >-v |Set mode to "variable".  This allows passing a list of variable
# names, which will then be pretty-printed along with their values.|
# >-p |Set mode to "print".  This simply prints the passed statements
# verbatim.|
# >-l |Include linenumbers in the prefixed context information.|
# >-f |Include function names in the prefixed context information.|
# >-F |Include source filenames in the prefixed context information.|
# >-d delim |Change delimiter to delim.|
# >-S |Print parsed debug opts.  This is useful should a need arise to
# debug this library, e.g.|

typeset -r __DEBUG_FILE__="$(realpath "${BASH_SOURCE[0]}")"
typeset -r __DEBUG_DIR__="$(dirname "${__DEBUG_FILE__}")"
typeset -r DOC_SCR="${DOC_SCR:-${__DEBUG_DIR__}/docstring.sh}"

# Template strings
typeset -r DEBUG_STATUS='$? = %s'
typeset -r DEBUG_NUM_ARGS='$# = %s'
typeset -r DEBUG_PARAM_STRING='$* = "%q"'
typeset -r DEBUG_PARAM_ARR='$@ = "%q"'
typeset -r -a _DEBUG_TEMPLATES=(
    [DEBUG_STATUS]='$? = %s'
    [DEBUG_NUM_ARGS]='$# = %s'
    [DEBUG_PARAM_STRING]='$* = "%q"'
    [DEBUG_PARAM_ARR]='$@ = "%q"'
)


typeset -i _debug_active_=0
typeset -r -A _debug_defaults_=(
    [MODE]="print"
    [LNUMS]=1
    [FNAMES]=1
    [SFILES]=0
    [DELIM]=' '
)

_debug_internal_vars() {
    # For debugging this script
    # Pretty-prints values of passed variable names
    for arg in $@; do
        echo "$(debug_prettyprint_var "$arg")"
    done
}

_debug_internal() {
    # For debugging this script
    local mode="print"
    local -a comments=()

    # Indent level set by how deep the callstack is
    local indent="$(printf '    %.0s' {1..${#FUNCNAME}})"

    sed -e "s/^/${indent}/" -e '/$/a\' <(
        printf '%s:%s:%s: ' \
            "DEBUG_INTERNAL" \
            "@${BASH_LINENO[0]}" \
            "${FUNCNAME[1]}"        # FUNCNAME is off by 1 from the others

        while [ $# -gt 0 ]; do
            if [ "$1" = "-p" ]; then
                mode="print"
            elif [ "$1" = "-v" ]; then
                mode="var"
            elif [ "$mode" = "print" ]; then
                comments+=( "$1" )
            elif [ "$mode" = "var" ]; then
                comments+=( "$(debug_prettyprint_var "$1")" )
            else
                echo "Problem parsing arguments in _debug_internal" >&2
                return -1
            fi
            shift
        done
        printf "${comments[*]}"
    ) >&2
    return $?
}

debug_usage() {
    # Displays usage information for this script's `debug` function
    # Redirects to an optional file-descriptor argument
    local -i fd=${1:-2}
    cat <<-"HELP" >&${fd}
	debug.sh
	========
	
	USAGE: debug [-v] [-p] [l] [-f] [-F] [-L] [-d delim] ...statements
	OPTS:
	-v              Set mode to "variable".  This allows passing a list of variable
	                names, which will then be pretty-printed along with their values.
	-p              Set mode to "print".  This simply prints the passed statements
	                verbatim.
	-l              Include linenumbers in the prefixed context information.
	-f              Include function names in the prefixed context information.
	-F              Include source filenames in the prefixed context information.
	-d delim        Change delimiter to `delim`.
	-S              Print parsed debug opts.  This is useful should a need arise to
	                debug this library, e.g.
	HELP
    return 0
}

_debug_parse_opts() {
    local -i print_state=
    local -n parsed_ref="$1" && shift || {
        _debug_internal "Couldn't set ref to array '%s'" "$1"
    }
    set -- "$@"
    _debug_internal "$DEBUG_PARAM_STRING" "$*"
    while getopts ":vplfFLd:hS" opt && [ $? -eq 0 ]; do
        case "$opt" in
            v)     # Set var mode
                parsed_ref[MODE]="var"
                ;;
            p)     # Set print mode
                parsed_ref[MODE]="print"
                ;;
            l)     # Toggle LNUMS
                let parsed_ref[LNUMS]^=1
                ;;
            f)     # Toggle FNAMES
                let parsed_ref[FNAMES]^=1
                ;;
            F)     # Toggle SFILES
                let parsed_ref[SFILES]^=1
                ;;
            L)     # Set DELIM to break lines
                parsed_ref[DELIM]='\n\t'
                ;;
            d)     # Set DELIM to arbitrary value
                parsed_ref[DELIM]="${OPTARG}"
                ;;
            h)
                debug_usage; return $?;
                ;;
            S)     # Set flag to print state after parsing all args
                print_state=1
                ;;
            *)
                echo "Unknown debugger option '${opt}'" >&2
                (debug_usage)>&2
                return 1    # This shouldn't be a showstopper
                ;;
        esac
    done

    _debug_internal "$DEBUG_STATUS" "$?"

    # Print parsed opts if requested
    [[ -n "${print_state}" ]] && _print_debug_state "${!parsed_ref}" \
        || _debug_internal "Couldn't print debug state!"
    # _debug_internal '%s' "$(declare -p ${!parsed_ref})"
    _debug_internal -v "${!parsed_ref}"

    # Prepare and echo positional args
    shift $(( OPTIND - 1 )) && OPTIND=1
    echo $@ && return 0
}

debug_activate() {
    _debug_active_=1
    return 0
}

debug_set_global_opts() {
    _debug_active_=1
    # Sets positional args to whatever remains after opt parsing
    set -- `_debug_parse_opts _debug_defaults_ $@`
    # Return successfully iff prev command did and there are no args left to parse
    # _debug_internal '$# = %s, $* = "%s"' $# "$*"
    _debug_internal "$DEBUG_NUM_ARGS, $DEBUG_PARAM_STRING" "$#" "$*"
    return $(( $? + $# ))
}

debug() {
    # Immediately return if not debugging
    (( _debug_active_ == 0 )) && return 0

    # Parse opts
    local -A opts=()
    set -- `_debug_parse_opts opts "$@"`

    # Apply defaults
    for key in "${!_debug_defaults_[@]}"; do
        [[ -z "${opts[${key}]+x}" ]] && {
            opts[${key}]="${_debug_defaults_[${key}]}"
        }
    done

    # Print statements and prefix
    local statement=
    printf '%s' "$(_get_debug_prefix opts)"
    while (( $# )); do
        if [[ "${opts[MODE]}" == "var" ]]; then
            statement="${1} = ${!1}"
        elif [[ "${opts[MODE]}" == "print" ]]; then
            statement="$1"
        fi
        printf "${opts[DELIM]}%s" "$statement"
        shift
    done
    printf '\n' && return 0
}

_get_debug_prefix() {
    # Get "debug prefix"
    # This prefix will be printed to the console prior to the user-supplied
    # messages
    local -n opts_ref="${1:-_debug_defaults_}" || {
        return 1    # If the passed nameref isn't kosher
    }

    prefix="DEBUG:"
    (( opts_ref[SFILES] )) && prefix+=" ${BASH_SOURCE[1]}"
    (( opts_ref[LNUMS] )) && prefix+="@${BASH_LINENO[0]}"
    (( opts_ref[FNAMES] )) && prefix+=":${FUNCNAME[1]}"
    echo "${prefix}: "
    return 0
}

_print_debug_state() {
    local -n state_ref="${1:-_debug_defaults_}"
    echo "state_ref = ${state_ref[@]}" >&2
    printf "Debug defaults: "
    for key in "${!state_ref[@]}"; do
        printf '\n\t%s' "${key} = '${state_ref[${key}]}'"
    done
    printf '\n' && return 0
}

debug_prettyprint_var() {
    local -n ref="$1"
    read -r -d '' sed_script <<-SED
	s/^\s\+//   # Remove initial whitespace
	s/^\([^\=]\+\)\=(/\1\=(\n/      # Newline after open-paren
        :LBREAK
	s/\(\[[A-Za-z]\+\]\=\"[^"]*\"\) /\t\1\n/g   # Newline after each assoc. element
	SED
    printf "\n$(declare -p "${!ref}")\n" \
        | sed -e "${sed_script}" | sed -e 's/^/\t/'
}

if [[ "$(basename "$0")" = "$(basename ${__FILE__})" ]]; then
    usage
fi
