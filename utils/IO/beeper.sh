#!/bin/bash

source "${SOURCE_DIR}/bash-scripts/include/include.sh"

typeset FREQUENCY
typeset DURATION
declare -A VOLUME_OPTS=(
    [SOFT]='25%'
    [MEDIUM]='50%'
    [LOUD]='75%'
    [MAX]='100%'
)
VOLUME="${VOLUME:-${VOLUME_OPTS[MEDIUM]}}"
_PITCH_TABLE="${__DIR__}/pitch.tsv"

usage() {
    cat <<-USAGE
	
	${__NAME__}
	$(echo ${__NAME__} | tr [:graph:] [=*])
	
	USAGE:
	    beeper.sh [-F freq] [-D duration] [-V volume] [-h]
	
	OPTIONS:
	    -F      Set beep frequency in hertz.
	    -N      Set beep frequency as a named note.  Notes are specified in
	            the usual way, with an initial capital letter indicating the scale
	            scale degree (i.e., A-G) and a subsequent (optional) accidental, either
	            '#' or 'b'.  In addition, a final digit may be appended in order to
	            indicate the desired octave / register (default is 3).
	    -D      Set beep duration in seconds.
	    -V      Set beep volume.  Can be specified numerically (as a percentage)
	            or as one of the case-insensitive values SOFT, MEDIUM, LOUD, and
	            MAX.
	    -h      Display this help message and exit.
	
	USAGE
}

die() {
    printf "$@" >&2 && echo >&2 && exit 1 || exit -1
    # usage >&2 && exit $1
}

set_volume() {
    amixer sset 'Master' "${1}" 2>&1 >/dev/null
    return $? # TODO: `amixer`'s exit status is always 0
              # Figure out a better way to test if command succeeded
}

play_beep() {
    play -nq -t alsa synth "$DURATION" sine "$FREQUENCY"
}

main() {
    while getopts ":F:N:D:V:h" opt; do
        case "$opt" in
            F)
                FREQUENCY="$OPTARG"
                ;;
            N)
                if [[ ! "$OPTARG" =~ [[:digit:]]$ ]]; then
                    OPTARG+=3
                fi
                FREQUENCY=$(
                    grep "${OPTARG^*}" "${_PITCH_TABLE}" |
                        cut -d'	' -f2
                )
                ;;
            D)
                DURATION="$OPTARG"
                ;;
            V)
                OPTARG="$(tr a-z A-Z <<< "$OPTARG")"
                VOLUME="${VOLUME_OPTS[$OPTARG]:-${OPTARG:-$VOLUME}}"
                set_volume "$VOLUME" || {
                    die "Could not set volume to specified level of '%s'" \
                    "$OPTARG"
                }
                ;;
            h)
                usage && exit 0
                ;;
            *)
                usage >&2 && exit 1
                ;;
        esac
    done
    # set -- "${@:$OPTIND}"
    shift $(( OPTIND - 1 )) && let OPTIND=1
    DURATION=${DURATION:-${1:-1}}
    FREQUENCY=${FREQUENCY:-${2:-440}}
    play_beep
}

main "$@"
