#!/bin/bash

eror_string='Error in function %s'

# Instructive but practically useless, since printf is just better
format() {
    local template="$1" && shift
    declare -a pos=()
    while :; do
        case "$1" in
            *=*)
                local "${1%%=*}"="${1#*=}"
                ;;
            *)
                pos+=("$1")
                ;;
        esac
        shift || break
    done
    set -- "${pos[@]}"
    eval echo "$template"
}

