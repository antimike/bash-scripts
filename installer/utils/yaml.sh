#!/bin/bash
# Poor man's YAML parser and writer

if [ -f "$BASH_INCLUDE" ]; then
    source "$BASH_INCLUDE"
else
    echo "Could not find 'include.sh'" >&2
    exit 23
fi

_yaml_usage() {
    cat <<-USAGE
	
	$(_underline "${__YAML_NAME__}")
	
	$(_underline -c '-' -C options)
	    -h      Show this message and exit
	
	USAGE
    return 0
}

_get_yaml_from_text() {
    # PASS prelim
    sed -n '/---/,/\.\.\./p' <<< "$*"
}

_get_yaml_from_file() {
    # Gets YAML text between start-of-doc sigil "---" and end-of-doc "..."
    # Assumes one YAML doc per file
    local text="$(cat "$1")"
    if [ $? -eq 0 ]; then
        _get_yaml_from_text "$text"
    fi
    return $?
}

_get_yaml_from_files() {
    # PASS prelim
    # Gets YAML fragments from passed files and sticks them in a caller-provided
    # array
    local -n results="$1" && shift
    for file in "$@"; do
        results+=( "$(_get_yaml_from_file "$file")" )
    done
    return $?
}

_yaml_indent_text() {
    local -i level=1
    if [ "$1" = "-n" ]; then
        shift && level="$1" && shift ||
            return -1
    fi
    sed 's/^/  /' <<< "$*"
}

_yaml_insert_dict_elem_file() {
    # Inserts text at a given "address" in the passed YAML doc
    local file="$1" && shift
    local keys="$2" && shift
    
}

_yaml_get_dict_elem_linenos_text() {
    # PASS prelim
    local yaml="$1"
    local keys="$2"     # Keystack (colon-delimited)
    local re=           # Loop var
    local -i current=1  # Loop var
    local -i offset=1
    local -i status=0   # To break loop if necessary
    local indent=""
    debug_vars keys re current status
    while [[ -n "$keys" && "$status" -eq 0 ]]; do
        keys="${keys#:}"        # Remove leading :
        key="${keys%%:*}"       # Get leading key from stack
        keys="${keys#${key}}"   # Remove leading key from stack
        re="^${indent}\(- \)\{0,1\}${key}:"
        offset=$(grep -n "$re" <<< "$yaml" | cut -f1 -d: | head -1) &&
            [ $offset -gt 0 ] &&
            let current+=offset &&
            yaml="$(sed -n "${offset},\$p" <<< "$yaml" | sed '1d')" ||
            let status=25
        indent+="  "
        debug_vars yaml offset keys re status current
    done
    debug_vars keys status
    local -i last=$(grep -n -v "^${indent}" <<< "$yaml" | 
        cut -f1 -d: | head -1) 2>/dev/null
    if [[ -n "${last}" ]]
    then
        debug_vars last yaml
        # $last is the position of the first line **not belonging to** the
        # desired block.  The last line in the block is thus
        # (( current + (last - 1) - 1 ))
        echo "${current},$(( current + last - 2 ))"
    else
        echo "${current},\$"
    fi
    return $status
}

_yaml_get_dict_elem_linenos_file() {
    # PASS prelim
    local yaml="$(_get_yaml_from_file "$1")"
    if [ $? -eq 0 ]; then
        _yaml_get_dict_elem_linenos_text "$yaml" "$2"
    fi
    return $?
}

_yaml_update_dict_elem_text() {
    # PASS prelim
    local yaml="$1"
    local keys="$2"
    local subst="$3"
    local range="$(_yaml_get_dict_elem_linenos_text "$yaml" "$keys")" ||
        return $?
    local -i start=${range%%,*}
    local indent="$(sed -n "${start}p" <<< "$yaml" | 
        sed "s/^\(\s*\)[^\s].*$/\1/")"
    let start-=1    # We want to "append", not "insert" (because an insert
                    # requires addressing a line that may no longer exists)
    subst="$(sed "s/^/${indent}/" <<< "$subst")"
    debug "indent = '$indent'"
    debug_vars range start subst
    sed "${range}d" <<< "$yaml" | sed "${start}a\\${subst}" 2>/dev/null
}

_yaml_update_dict_elem_file() {
    # PASS prelim
    local yaml="$(_get_yaml_from_file "$1")"
    if [ $? -eq 0 ]; then
        _yaml_update_dict_elem_text "$yaml" "$2" "$3"
    fi
    return $?
}

_yaml_insert_dict_elem_text() {
    :
}

_yaml_insert_addr_elem_text() {
    # Inserts text at a given "address" in the passed YAML text
    local yaml="$1"
    local keys="$2"
    local key=
    local -i status=0
    debug_vars key keys
    while [ -n "$keys" ] && [ $status -eq 0 ]; do
        keys="${keys#:}"        # Remove leading :
        key="${keys%%:*}"       # Get leading key from stack
        keys="${keys#${key}}"   # Remove leading key from stack
        yaml="$(_yaml_insert_dict_elem_text "$yaml" "$key")"
        debug_vars key keys yaml
        status=$?
    done
    echo "$yaml"
    return $status
}

_yaml_get_dict_elem_from_file() {
    local yaml="$(_get_yaml_from_file "$1")"
    if [ $? -eq 0 ]; then
        _yaml_get_dict_elem_from_text "$yaml" "$2"
    fi
    return $?
}

_yaml_get_dict_elem_from_text() {
    # Gets YAML elements associated to a dict key
    # Assumes the key is at the top level or in a top-level array
    local text="$1"
    local key="$2"
    local re="^\(${key}\|- ${key}\):"
    if [ -z "$key" ]; then
        echo "$text" && return 0
    elif grep "$re" <<< "$text" >/dev/null; then
        sed -n "/${re}/,/^[^[:space:]]/p" <<< "$text" |
            sed -e '/^  /!d' -e 's/^  //'
    else
        return 1
    fi
}

_yaml_get_addr_elem_from_text() {
    # PASS prelim
    # Gets YAML element from key "address"
    # Assumes an address of the form "key1:key2:...:lastkey", where each key in
    # the list is directly below the previous one or is a member of an array
    # directly below the previous one
    local text="$1"
    local keys="$2"
    local key=
    local -i status=0
    debug_vars key keys
    while [ -n "$keys" ] && [ $status -eq 0 ]; do
        keys="${keys#:}"        # Remove leading :
        key="${keys%%:*}"       # Get leading key
        keys="${keys#${key}}"   # Remove leading key
        debug_vars text
        text="$(_yaml_get_dict_elem_from_text "$text" "$key")"
        debug_vars key keys text
        status=$?
    done
    echo "$text"
    return $status
}

_yaml_get_addr_elem_from_file() {
    # PASS prelim
    local yaml="$(_get_yaml_from_file "$1")"
    if [ $? -eq 0 ]; then
        _yaml_get_addr_elem_from_text "$yaml" "$2"
    fi
    return $?
}

main() {
    if [ -n "${DEBUG+x}" ]; then
        if [ $# -gt 0 ]; then
            local func="$1" && shift
            $func "$@"
        else
            _yaml_usage
        fi
    fi
    exit $?
}

main "$@"
