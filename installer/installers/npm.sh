#!/bin/bash
#+
# Options:
# >-g |Installs the package globally.  This is the default.|
# >-l |Installs the package locally, to the directory provided as an argument.
# Uses the curent directory if no argument is provided.|

# Install scheduler: Specifies
#     - installer script
#     - name
#     - notes (reasons for install, etc.)
#     - metadata (timestamp, etc.)
#     - upstream and downstream dependencies

# Install script:
#     - consumes JSON / YAML / some other structured data from scheduler
#     - validation and parse logic --> probably easier in Python
#     - needs some way to expose "blank" DTO fields for user input
#     - just store blank markup in file
#     - alternatively, structure it like a REST API...
#         - Javascript?
#                - Too many dependencies

_npm_local=

_npm_get_info() {
    :
}

_npm_getopts() {
    while getopts ":gl:" opt; do
        case "$opt" in
            g)
                _npm_local=
                ;;
            l)
                _npm_local="${OPTARG:-`pwd`}"
                [ -f "${_npm_local}" ] || exit "${BAD_OPTS_RETURN}"
                ;;
            *)
                exit ${BAD_OPTS_RETURN:-2}
                ;;
        esac
    done
}

_npm_install() {
    if [ -n "${_npm_local}" ]; then
        cd "${_npm_local}" && npm i "${name}"
    else
        sudo npm i -g "${name}"
    fi
}
