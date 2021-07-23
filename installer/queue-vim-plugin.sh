queue_vim_plugin() {
    local comments=
    local mods=
    local queue=$SOURCE_DIR/bash-scripts/installer/data/queue.json
    while getopts ":m:c:" opt; do
        case $opt in
            m)
                mods=$OPTARG
                ;;
            c)
                comments=$OPTARG
                ;;
            *)
                echo "Unknown option $opt" >&2
                exit 2
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1
    declare -A props=(
        type vim
        id "'$1'"
        name ${1##*/}
        timestamp `date -u`
        comments "$comments"
        install-mods "$mods"
    )
    
}
