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

# TODO: Add option to allow "silent" or long-term timers using `at`

if [ -f "$BASH_INCLUDE" ]; then
    . "$BASH_INCLUDE"
fi

SPEAK_SCR="${__TIMER_DIR__}/utils/IO/speak.sh"
BEEP_SCR="${__TIMER_DIR__}/utils/IO/beeper.sh"
DOC_SCR="${__TIMER_DIR__}/utils/dev/docstring.sh"

EOL_CHAR='\033[0K'      # Used to print the timer value to the same line
                        # repeatedly.
typeset -i MAX_TIME=$(( 24*3600 )) # The timer can run for a maximum of one day
typeset -i TIME=0
typeset BEEP="-F 440 -D 1"
typeset NOTIFY_SPEAK=
typeset NOTIFY_PRINT=
typeset NOTIFY_SEND=

_timer_usage() {
    debug_vars __TIMER_NAME__ __TIMER_FILE__ DOC_SCR
    cat <<-USAGE

	$(_underline ${__TIMER_NAME__})
	A simple countdown utility, designed for setting alarms.

	USAGE:
        $(${DOC_SCR} -f ${__TIMER_FILE__})

	USAGE
}

display_countdown() {
    local format="${1:-%T}"
    debug_vars secs format
    while (( TIME > 0 )); do
        printf "%s${EOL_CHAR}\r" "$(date -u "+${format}" -d@$(( TIME )))"
        let TIME-=1
        sleep 1
    done
    debug "Countdown finished"
    return 0
}

human_time() {
    local secs=$(( TIME ))
    local mins=$(( TIME / 60 )) && (( TIME %= 60 ))
    local hours=$(( mins / 60 )) && (( mins %= 60 ))
    debug_vars TIME mins hours
    set -- "$hours hours" "$mins minutes" "$TIME seconds"
    while num=${1%% *} && (( num == 0 )) && (( $# )); do
        shift
    done
    local sep=; (( $# > 2 )) && sep=', and ' || sep=' and '
    local ret="$( printf "${sep}%s" "$@" )"
    ret=`echo "${ret:${#sep}}" | rev | sed 's/dna //2g' | rev`
    debug_vars ret
    echo "${ret:-0 seconds}"
    return 0
}

_timer_notify() {
    local human=`human_time`
    local speak="$(printf "$1" "$human")"
    local print="$(printf "$2" "$human")"
    local nsend="$(printf "$3" "$human")"
    debug_vars human speak print nsend
    if [[ -n "$print" ]]; then
        echo "$print"
    fi
    if [[ -n "$speak" ]]; then
        eval $SPEAK_SCR "$speak"
    fi
    if [[ -n "$nsend" ]]; then
        notify-send "$nsend"
    fi
    return 0
}

convert_clocktime() {
    local sum=0
    local conversion=1
    local -a parsed; IFS=':' read -r -a parsed <<< "$*"
    if (( ${#parsed[@]} > 3 )); then
        die 1 "Failed to parse user-provided duration string %s" "$*"
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
    local fmt='%T'
    local time=10
    while getopts ":t:p:n:s:f:b:BD" opt; do
        case "$opt" in
        t)      # Total time
            time="$OPTARG"
            ;;
        p)      # Print message
            NOTIFY_PRINT="$OPTARG"
            ;;
        n)
                # Redirect message to notify-send
            NOTIFY_SEND="$OPTARG"
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
    shift $(( OPTIND - 1 )) && OPTIND=1
    time="$1"
    debug_vars time TIME NOTIFY_PRINT NOTIFY_SPEAK NOTIFY_SEND FORMAT BEEP
    debug "Positional args: $@"
    exit 0

    TIME=$(( $(args_to_secs "$time") ))
    (( TIME > MAX_TIME )) && die 2 "Cannot set timer for longer than 1 day"

    display_countdown "$fmt" && {
        if [[ -n "${BEEP+x}" ]]; then
            eval $BEEP_SCR $BEEP
        fi
        _timer_notify "$NOTIFY_SPEAK" "$NOTIFY_PRINT" "$NOTIFY_SEND"
        return $?
    } || {
        die "Unknown error, countdown failed"
    }
}

main $@
