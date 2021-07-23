#!/bin/bash
# Some convenience functions that wrap CLI tools with Rofi dmenu

fd_rofi() {
    # TODO: Immplement basic file-checking logic around args
    # TODO: Add some opts
    # TODO: Rethink how `pick_command` is passed
    local search_dir="$1"
    local selector_title="$2"
    local pick_command="$3"
    fd --type f -e pdf . "${search_dir}" \
        | rofi -keep-right -dmenu -i -p "${selector_title}" -multi-select \
        | xargs -I {} ${pick_command}
}

rg_rofi() {
    # TODO: Implement this
    :
}

recoll_rofi() {
    # TODO: Implement this
    :
}

papis_rofi() {
    # TODO: Implement this
    :
}

hypertag_rofi() {
    # TODO: Implement this
    :
}

buku_rofi() {
    # TODO: Implement this
    :
}
