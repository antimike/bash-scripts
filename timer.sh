#!/bin/bash
#+
# -t |Time for which the timer should run.  Can be specified in either the
# format expected by the *nix command `sleep`, e.g. `1m 27s`, or in a clock-like
# colon-delimited format, e.g. `1:23:17`.|
# -p |Message to be printed when the timer completes.|
# -s |Message to be spoken when the timer completes.  This message is passed to
# the script `speak.sh`.|
# -f |`date` format specifier for the displayed countdown.  Defaults to `%T`
# (i.e., HH:MM:SS).|
# -b |Options to pass to the script `beeper.sh`.  Defaults to `-F 440 -D 1`,
# i.e., a 1-second beep at 440 Hz.  The beep can be suppressed by passing the -B
# option.|
# -B |No beep|

__FILE__="$(realpath "${BASH_SOURCE[0]}")"
__DIR__="$(dirname "${__FILE__}")"
SPEAK_SCR="${__DIR__}/speak.sh"
BEEP_SCR="${__DIR__}/beeper.sh"
DEBUG="${DEBUG+x}"
DOC_SCR="${__DIR__}/docstring.sh"

EOL_CHAR='\033[0K'      # Used to print the timer value
                        # to the same line repeatedly.
typeset -i MAX_TIME=$(( 24*3600 )) # The timer can run for a maximum of one day
typeset -i TIME=0
typeset BEEP="-F 440 -D 1"
typeset NOTIFY_SPEAK=
typeset NOTIFY_PRINT=

die() {
    printf "$@" && echo && exit 1 || exit -1
}

debug() {
    if [[ -z "${DEBUG}" ]]; then
        return 0
    else
        printf "DEBUG: " >&2
        printf "$@" >&2 && echo >&2 && return 0 || exit -2
    fi
}

usage() {
    cat <<-USAGE
	
	${__NAME__}
	$(tr [:graph:] [=*] <<< ${__NAME__})
	A simple countdown utility, designed for setting alarms.
	
	USAGE:
	`${DOC_SCR} ${__FILE__}`
	
	USAGE
}

display_countdown() {
    local secs=$(( TIME ))
    local format="${1:-%T}"
    debug "Displaying countdown for T = %s s with format %s" \
        "${secs}" "${format}"
    while (( TIME > 0 )); do
        printf "%s${EOL_CHAR}\r" "$(date -u "+${format}" -d@$(( TIME-- )))"
    done
    debug "Countdown finished"
    return 0
}

human_time() {
    debug "Entering function 'human_time' with args '$*' and globals TIME = ${TIME}"
    local secs=$(( TIME ))
    local mins=$(( TIME / 60 )) && (( TIME %= 60 ))
    local hours=$(( mins / 60 )) && (( mins %= 60 ))
    debug "TIME = %s, mins = %s, hours = %s" "${TIME}" "${mins}" "${hours}"
    set -- "$hours hours" "$mins minutes" "$TIME seconds"
    debug "set -- $*"
    while num=${1%% *} && (( num == 0 )) && (( $# )); do
        shift
    done
    local sep=; (( $# > 2 )) && sep=', and ' || sep=' and '
    local ret="$( printf "${sep}%s" "$@" )"
    ret=`echo "${ret:${#sep}}" | rev | sed 's/dna //2g' | rev`
    debug "ret = %s; echoed: %s" "${ret}" "${ret:-0 seconds}"
    echo "${ret:-0 seconds}"
    return 0
}

notify() {
    debug "Entering function 'nofity' with args '$*'"
    local human=`human_time`
    local speak="$(printf "$1" "$human")"
    local print="$(printf "$2" "$human")"
    debug "human = '%s', speak = '%s', print = '%s'" \
        "${human}" "${speak}" "${print}"
    if [[ -n "$print" ]]; then
        echo "$print"
    fi
    if [[ -n "$speak" ]]; then
        debug "Calling SPEAK_SCR: '%s' with arg '%s'" \
            "${SPEAK_SCR}" "${speak}"
        eval $SPEAK_SCR "$speak"
    fi
    return 0
}

convert_clocktime() {
    local sum=0
    local conversion=1
    local -a parsed; IFS=':' read -r -a parsed <<< "$*"
    if (( ${#parsed[@]} > 3 )); then
        die "Failed to parse user-provided duration string %s" "$*"
    fi
    while (( ${#parsed[@]} )); do
        (( sum += conversion * ${parsed[-1]} ))
        (( conversion *= 60 ))
        unset parsed[-1]
    done
    echo "$sum" && return 0
}

convert_sleeptime() {
    local script; read -r -d '' script <<-SED
	s/[hH]/*3600+/g;s/[mM]/*60+/g;s/[sS]/+/g;
	s/[\*+]\+\s*$//g
	SED
    bc < <(sed "$script" <<< "$*")
    return $?
}

args_to_secs() {
    case "$*" in
        *:*)
            echo "$(convert_clocktime "$@")"
            ;;
        *)
            echo "$(convert_sleeptime "$@")"
            ;;
    esac
}

main() {
    debug "Received: %s" "$*"
    local fmt='%T'
    while getopts ":t:p:s:f:b:BD" opt; do
        case "$opt" in
        t)      # Total time
            TIME=$(( args_to_secs "$OPTARG" ))
            debug "TIME = %s" "$TIME"
            (( TIME > MAX_TIME )) \
                && die "Cannot set timer for longer than 1 day"
            ;;
        p)      # Print message
            NOTIFY_PRINT="$OPTARG"
            debug "NOTIFY_PRINT = ${NOTIFY_PRINT}"
            ;;
        s)      # Spoken message
            NOTIFY_SPEAK="$OPTARG"
            ;;
        f)      # Format string to pass to `date` (for countdown display)
            fmt="${OPTARG:-$fmt}"
            ;;
        b)      # Beep options
            BEEP="${OPTARG:-$BEEP}"
            ;;
        B)
                # No beep
            unset BEEP
            ;;
        D)
            DEBUG=1
            ;;
        *)
            usage >&2 && exit 2
            ;;
        esac
    done
    debug "Args: -t=%s, -p=%s, -s=%s, -f=%s, -b=%s" \
        "$TIME" "$NOTIFY_PRINT" "$NOTIFY_SPEAK" "$FORMAT" "$BEEP"
    display_countdown "$fmt" && {
        if [[ -n "${BEEP+x}" ]]; then
            debug "Countdown completed successfully"
            eval $BEEP_SCR $BEEP && \
                debug "Beep completed successfully"
        fi
        notify $NOTIFY_SPEAK $NOTIFY_PRINT
        return $?
    } || {
        die "Unknown error, countdown failed"
    }
}

main $@
