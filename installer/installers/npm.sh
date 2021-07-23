#!/bin/bash
#+
# Options:
# >-g |Installs the package globally.  This is the default.|
# >-l |Installs the package locally, to the directory provided as an argument.
# Uses the curent directory if no argument is provided.|

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
        cd "${_npm_local}" && npm i ${name}
    else
        sudo npm i -g ${name}
    fi
}
