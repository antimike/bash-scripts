#!/bin/bash
# Poor man's YAML parser and writer

if [ -f "$BASH_INCLUDE" ]; then
    source "$BASH_INCLUDE"
else
    echo "Could not find 'include.sh'" >&2
    exit 23
fi

_yaml_usage() {
    :
}

_get_yaml_doc() {
    # Gets YAML text between start-of-doc sigil "---" and end-of-doc "..."
    # Assumes one YAML doc per file
    local file="$1"
    sed -n '/---/,/\.\.\./p' "$file"
    return $?
}

_get_yaml_docs() {
    # Gets YAML fragments from passed files and sticks them in a caller-provided
    # array
    local -n results="$1" && shift
    for file in "$@"; do
        results+=( "$(_get_yaml_doc "$file")" )
    done
    return $?
}

_yaml_indent_doc() {
    local -i level=1
    if [ "$1" = "-n" ]; then
        shift && level="$1" && shift ||
            return -1
    fi
    sed 's/^/  //' "$*"
}

_yaml_insert_dict() {
    # Inserts text at a given "address" in the passed YAML doc
    local yaml="$1" && shift
    local keys="$2" && shift
    
}
