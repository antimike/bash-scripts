#!/bin/bash

source "${SOURCE_DIR}/bash-scripts/include/include.sh"
_BEEP_SCR="${__DIR__}/beeper.sh"

typeset -i _TEMPO=1         # Beats per second
typeset -i _REGISTER=3      # Defines reference note (default is C3)
typeset _SCORE=
typeset _VOLUME=            # Default is set in beeper script
typeset -a _PITCHES=( )
typeset -a _BEATS=( )

die() {
    local exit_code=1
    if [ "$1" = "-e" ]; then
        exit_code="$2" && shift 2
    fi
    echo "$@" >&2
    exit $(( exit_code + $? ))
}

usage() {
    cat <<-USAGE
	
	${__NAME__}
	$(tr [:graph:] [=*] <<< ${__NAME__})
	
	USAGE:
	    ${__NAME__} [-f score] [-t tempo] [-r register] [-h]
	
	OPTIONS:
	    -f      Specify a file from which to read the score.
	    -t      Specify the tempo at which the score should be played, in units of
	            beats per second.  Must be an integer.
	    -r      Specify the register in which to score should be played.  Should be
	            an integer between 0 and 7.
	    -V      Set beep volume.  Can be specified numerically (as a percentage)
	            or as one of the case-insensitive values SOFT, MEDIUM, LOUD, and
	            MAX.
	    -D      Dump debug output to stdout.
	    -h      Display this message and exit.
	
	USAGE
}

validate_params() {
    local -a errors=( )
    [ -n "${_SCORE}" ] && [ ! -f "${_SCORE}" ] &&
        errors+=( "The file '${_SCORE}' does not appear to exist" )
    [ ${_REGISTER} -gt 7 ] || [ ${_REGISTER} -lt 0 ] &&
        errors+=( "The register must be between 0 and 7 inclusive" )
    if [ ${#errors} -gt 0 ]; then
        die "${errors[@]}"
    else
        return 0
    fi
}

play_notes() {
    [ -n "${DEBUG+x}" ] && echo "${_PITCHES[@]}"
    local -i idx=0
    while [ $idx -lt ${#_PITCHES[@]} ]; do
        if [ "${_PITCHES[$idx]:0:1}" = "_" ]; then
            sleep "${_BEATS[$idx]}"
        else
            ${_BEEP_SCR} \
                -N "${_PITCHES[$idx]}" \
                -V "${_VOLUME}" \
                -D "${_BEATS[$idx]}"
        fi
        let idx++
    done
    return $?
}

main() {
    local -i register=
    while getopts ":f:t:r:V:hD" opt; do
        case "$opt" in
            f)
                _SCORE="${OPTARG}"
                ;;
            t)
                _TEMPO="${OPTARG}"
                ;;
            r)
                _REGISTER="${OPTARG}"
                ;;
            V)
                _VOLUME="${OPTARG}"
                ;;
            h)
                usage && exit 0
                ;;
            D)
                set -x
                DEBUG=1
                ;;
            *)
                usage >&2 && exit 2
                ;;
        esac
    done
    validate_params &&
        shift $(( OPTIND - 1 )) && OPTIND=1
    while IFS=: read -r line; do
        while read -r -d ' ' note; do
            register=${_REGISTER}
            while [[ "$note" =~ \+.* ]] || [[ "$note" =~ -.* ]]; do
                let register${note:0:1}=1
                note="${note:1}"
            done
            _PITCHES+=( "${note%%.*}${register}" )
            _BEATS+=( $(bc <<< "scale=2; ${note#*.}*1./${_TEMPO}" ) )
        done <<< "$line"
    done < <(cat - "${_SCORE}" <<< "$@")
    play_notes
    exit $?
}

main "$@"
