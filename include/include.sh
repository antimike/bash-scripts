#!/bin/bash

shopt -s extglob

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

__FILE__="$(_get_path "${BASH_SOURCE[1]}")"
__DIR__="$(dirname "${__FILE__}")"
__NAME__="$(basename "${__FILE__}")"
__DEBUG__="${_DEBUG+x}"
__PID__=$$

_script_id() {
    printf '%s_%s_%s_%s' \
        "${__NAME__}" \
        "$(date +'%s%N')" \
        "${__PID}" \
        "$(( RANDOM % 1000 ))"
}

_alert() {
    printf "$@" && echo
}

_error() {
    _alert "$@" >&2
}

_die() {
    _error "$@" && exit 1 || exit -1
}

_prettyprint_var() {
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

_debug() {
    [ -z "${__DEBUG__}" ] && return 0
    local -a msg=( )
    local prefix="_DEBUG: ${BASH_SOURCE[1]}@${BASH_LINENO[0]}:${FUNCNAME[1]}"
    local fmt='\t%s\n'
    while [ $# -gt 0 ]; do
        case "$1" in
            -p|--pprint)
                shift && msg+=( "$(_prettyprint_var "$1")" )
                ;;
            -f|--format?(=*))   # extglob
                fmt=`expr "$1" : '--format\=\(.*\)'` ||
                    shift && fmt="$1"
                ;;
            *)
                msg+=( "$1" )
                ;;
        esac
        shift
    done
    _error "$prefix" && _error "${msg[@]}" && return 0 ||
        return -1
}

_get_docstring() {
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
        # TODO: Finish this
        # TODO: Support markup: YAML, asciidoc, markdown, JSON, ...
}
