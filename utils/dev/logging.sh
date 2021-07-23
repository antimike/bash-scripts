#!/bin/bash

shopt -s extglob
source $HOME/Source/bash-scripts/string-utils.sh

__LOGFILE__="$HOME/.automation.log"
__LOGLEVEL__=0
__NAME__="$(basename $0)"
__PID__="$$"
__START__=

script_id() {
        printf '%s_%s_%s' "${__NAME__}" "$(date +'%s%N')" "$(( RANDOM % 1000 ))"
}

[[ "$MODE" = "STAGING" && "$NEST_LEVEL" -eq 0 ]] && {
        export MODE=EXEC
        exec 3>&1 2>&4
        trap 'exec 1>&3 2>&4' EXIT SIGINT
        (
            (
                    exec $0 "$@"
            ) | tee -a "$LOGFILE" 2>&1
        ) 1>&1 2>&4
}

(( NESTED++ ))

# Main script

declare -A __LOGLEVELS__=(
        [ERROR]=-2
        [WARN]=-1
        [INFO]=0
        [DEBUG]=1
        [TEST]=2
        [START]=1
        [END]=1
)

goboom() {
        nofity ERROR "$1"
        exit 1
}

succeed() {
        echo "$@" && return 0
}

notify_debug() {
        local format='%s\n'
        case "$1" in
                -f|--format?(=*))
                        if [[ "$1" = --format=* ]]; then
                                format="${1#--format=}" && shift
                        else
                                shift && format="$1" && shift
                        fi
        esac
        local msg="$(printf "'$format'" "$@")"
        notify --suppress-logging DEBUG "$msg"
}

notify() {
        local silent=
        [[ "$1" = @(--suppress-logging|-s) ]] && silent=1 && shift
        local level=
        [[ -n "${__LOGLEVELS__[$1]}" ]] && level="$1" && shift || level="INFO"
        while (( $# > 0 )); do
                [[ -z "$silent" ]] && log "$level" "$1"
                if (( __LOGLEVEL__ >= __LOGLEVELS__["$level"] )); then
                        echo "$level: $1"
                fi
                shift
        done
}

human_time() {
        local unix_ms="$1"
        echo "$(date -d@$(( unix_ms / 1000 )))"
}

start_logentry() {
        local title="$(human_time $__START__) :: $__START__ :: $__NAME__ :: PID: $__PID__"
        cat <<-EOF >> "$__LOGFILE__" && return 0
                "$(fill_string "$title" "=" 80)"
                "$(fill_string "(END LOGENTRY: $__START__)" "=" 80)" 
        EOF
}

log() {
        local msg=
        local level="INFO"
        [[ -n "${__LOGLEVELS__[$1]}" ]] && level="$1" && shift
        local time="$(date +%s%3N)"
        if [[ -z "$__START__" ]]; then
                __START__="$time"
                start_logentry || exit 1
        fi
        while (( $# > 0 )); do
                local msg="$(printf "\ \ \ \ ${level} :: $time :: $1")"
                local address="$(grep -n "$__START__" "$__LOGFILE__" | tail -1 | cut -f 1 -d ':')"
                sed -i "${address}i $msg" "$__LOGFILE__"
                shift
        done
}
