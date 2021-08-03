#!/bin/bash
#+
# OPTIONS:
# >-h |Display usage information and exit|
# >-a |Keystroke-saver for -t apt|
# >-d |Keystroke-saver for -t dnf|
# >-v |Keystroke-saver for -t vim|
# >-g |Keystroke-saver for -t github|
# >-c |Keystroke-saver for -t cargo|
# >-G |Keystroke-saver for -t gem|
# >-n |Keystroke-saver for -t npm|
# >-z |Keystroke-saver for -t zsh|
# >-p |Keystroke-saver for -t python.  Accepts a non-mandatory argument specifying
# major version of Python/Pip to use (default is 3)|

__FILE__="$(realpath "${BASH_SOURCE[0]}")"
__DIR__="$(dirname "$__NAME__")"
__NAME__="$(basename "$__FILE__")"
__HOSTNAME__="${HOSTNAME:-${HOST}}"

INSTALL_DIR="${INSTALL_DIR:-$SOURCE_DIR/bash-scripts/installer/data}"

declare -A _INSTALL_TYPES=(
    [generic]="script"
)

declare BAD_OPTS_RETURN=2

usage() {
    cat <<-USAGE
	
	${__NAME__}
	$(tr [:graph:] [=*] <<< "${__NAME__}")
	
	ENVIRONMENT VARIALBES:
	    - INSTALL_DIR   Default is \$SOURCE_DIR/bash-scripts/installer/data
	
	OPTIONS:
	    -n name         Specify script / package name
	    -D subdir       Specify subdirectory of install dir in which to place 
	                    script
	    -u child        Add downstream dependency
	    -d parent       Add upstream dependency
	    -c comment(s)   Add arg(s) to comments array
	    -s summary      Provide script summary
	    -t tag(s)       Tag install script with arg(s)
	    -h              Display this help message and exit
	
	USAGE
}

_join_array() {
    local -n arr="$1"
    if [ ${#arr} -eq 0 ]; then
        echo && return 0
    else
        printf ',"%s"' "${arr[@]}" | cut -d',' -f2-
    fi
}

commit_changes() {
    cd "$INSTALL_DIR"
    if git status 2>&1 >/dev/null; then
        git add . && git commit -m "$1" &&
            git tag "$2"
    fi
}

main() {
    # For now, the only supported option is the default ("generic install
    # script").
    # TODO: Implement more options
    local name=
    local directory=
    local -a upstream=( )
    local -a downstream=( )
    local -a comments=( )
    local summary=
    local -a tags=( )
    local type="${INSTALL_TYPES[generic]}"

    while getopts ":n:D:u:d:c:s:t:h" opt; do
        case "$opt" in
            n)      # Name
                name="$OPTARG"
                ;;
            D)      # Directory
                directory="$OPTARG"
                ;;
            u)      # Upstream dependencies
                    # i.e., requirements
                upstream+=( "$OPTARG" )
                ;;
            d)      # Downstream dependencies
                    # i.e. "children"
                downstream+=( "$OPTARG" )
                ;;
            c)      # Comments
                comments+=( "$OPTARG" )
                ;;
            s)      # Summary
                summary="$OPTARG"
                ;;
            t)      # Tags
                    # Unquoted to allow expansion
                tags+=( $OPTARG )
                ;;
            h)      # Helptext
                usage && exit 0
                ;;
            *)
                usage >&2 && exit 1
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1

    local path="${INSTALL_DIR}/${directory}"
    [ -d "$path" ] || mkdir -p "$path" || exit -1

    read -r -d '' temp <<-YQ
	{
	"name": "$name",
	"summary": "$summary",
	"type": "$type",
	"upstream": [ $(_join_array upstream) ],
	"downstream": [ $(_join_array downstream) ],
	"comments": [ $(_join_array comments) ],
	"tags": [ $(_join_array tags) ],
	"queued": [
	    "${__HOSTNAME__}": "$(date -u)"
	],
	"installed": []
	}
	YQ

    cat <<-TEMPLATE | vipe >>"${path}/${name}"
	---
	$(yq -n eval "$temp")
	...
	#!/bin/bash
	
	
	TEMPLATE

    commit_changes \
        "Added install script for '$name' in subdirectory '$path'" \
        "$name"
    exit 0
}

main "$@"
