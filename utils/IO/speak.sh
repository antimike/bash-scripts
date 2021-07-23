#!/bin/bash
# Convenience wrapper around `festival` and `espeak`
# TODO: Add some options:
#     * Options to control timing, e.g. by specifying delays
#     * Usage / logging / etc.
#     * Conditionals / branching: say different things given different conditions
#     * Support files and piped input
#         * Maybe set aside designated named "speech pipe?"
#         * Requires long-running "watch script"
#     * Short / abbreviated options for different voices
#         * Allow changing voices in the middle of a command
#         * Can this be done with GNU getopts?
#     * Explicitly specify festival / espeak

__FILE__="$(realpath "${BASH_SOURCE[0]}")"
__DIR__="$(dirname "${__FILE__}")"

NOTIFY_SCR=

VOICEFILE="${VOICEFILE:-voice_cmu_us_slt_arctic_hts}"
declare -A VOLUME_OPTS=(
    [WHISPER]='25%'
    [SOFT]='50%'
    [MEDIUM]='75%'
    [LOUD]='85%'
    [MAX]='100%'
)
typeset DEBUG="${DEBUG+x}"

debug() {
    if [ -z "${DEBUG+x}" ]; then
        return 0
    else
        printf "DEBUG: " >&2
        printf "$@" >&2 && echo >&2 && return 0 || exit -2
    fi
}

die() {
    printf "$@" >&2 && echo >&2 && exit 1 || exit -1
}

set_volume() {
    debug "Call: set_volume %s" "$*"
    amixer sset 'Master' "${1}" 2>&1 >/dev/null
    return $? # TODO: `amixer`'s exit status is always 0
              # Figure out a better way to test if command succeeded
}

festival_say() {
    debug "Call: festival_say $*"
    festival -b "(${VOICEFILE})" \
        "(SayText \"$*\")"
    return $?
}

espeak_say() {
    debug "Call: espeak_say $*"
    espeak "$*"
    return $?
}

main() {
    local -a text=( )
    local volume="${VOLUME_OPTS[MEDIUM]}"
    while getopts ":V:t:D" opt; do
        case "$opt" in
            V)
                OPTARG="$(tr a-z A-Z <<< "$OPTARG")"
                volume="${VOLUME_OPTS[$OPTARG]:-${OPTARG:-$volume}}"
                ;;
            t)
                text="$OPTARG"
                ;;
            D)
                DEBUG="${DEBUG:-1}"
                ;;
            *)
                die "Unknown option '%s'" "$opt"
                ;;
        esac
    done
    (( $? == 0 )) || die "Failed to parse options"
    shift $(( OPTIND - 1 )) && OPTIND=1
    set_volume "$volume" || {
        die "Could not set volume to specified level of '%s'" \
        "$OPTARG"
    }
    # set -- "${@:$OPTIND:}"; text+=$@ # Append all other args to `$text`
    text+=( "$@" )
    debug "text = ${text[*]}"
    if command -v festival &>/dev/null; then
        festival_say "$text"
    elif command -v espeak &>/dev/null; then
        espeak_say "$text"
    else
        die "Could not find either 'espeak' or 'festival'"
    fi
    return $?
}

main "$@"
