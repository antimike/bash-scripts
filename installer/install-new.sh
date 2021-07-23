#!/bin/bash
# Script to determine which lines of $INSTALLED have not been committed and run
# them

# To store paragraphs (chunks) that fail or are rejected by the user
declare -a FAILED=()

_get_path() {
    local file="$*"
    if command -v realpath >/dev/null; then
        echo `realpath "${file}"`
    elif command -v readlink >/dev/null; then
        echo `readlink -m "${file}"`
    else
        echo "Could not find a safe way to resolve true filepath" >&2
        return 2
    fi
    return $?
}

__FILE__="$(_get_path "${BASH_SOURCE[0]}")"
__DIR__="$(dirname "${__FILE__}")"

die() {
    # Prints a formatted message to the designated file descriptor and exits
    # with the designated exit code.  Prints usage information by default (this
    # can be disabled).
    local fd=2
    local exit_status=1
    local display_usage=1
    local format_str='%s\n'
    while getopts "F:f:s:u" opt; do
        case "$opt" in
            F)
                fd=$(( OPTARG ))
                ;;
            f)
                format_str="$OPTARG"
                ;;
            s)
                exit_status=$(( OPTARG ))
                ;;
            u)
                display_usage=1
                ;;
            *)
                break
                ;;
        esac
    done
    shift $(( OPTIND - 1 )) && OPTIND=1
    printf "$format_str" "$@" >&${fd}
    if (( display_usage )) && (type usage | grep -q "function" &>/dev/null);
    then
        # usage -s ${exit_status} -F ${fd}
        usage &>${fd}
    fi
    exit ${exit_status}
}

usage() {
    :
}

_get_commands() {
    # TODO: Fix this to support chunk editing
    read -r -d '' insert_para_lnums <<-AWK
	/^\s*$/{
	    if (getline && $0 ~ /./)
	        printf "\n# %s\n%s\n", (NR - 1), $0; next
	} /./{print;}
	AWK
    local file="$1"
    cd "$(dirname "${file}")" && {
        git status &>/dev/null
        (( $? )) && die -s $? -F 2 -- \
            "File '${file}' does not appear to be located in a git repository"
        git blame "${file}" |
            grep -i 'not committed' |
            sed 's/.*(.*) \(.*\)$/\1/'
    } || {
        die -s $? -F 2 \
            -f "Could not cd to parent directory of file '%s'" \
            "${file}"
    }
}

_process_paragraph() {
    local para="$*"
    bat <<-COMMENT
# Exit this preview to choose whether to (1) run these commands as is, (2) edit
# them interactively and then run them, or (3) skip this script altogether.

${para}
COMMENT

    REPLY=; select opt in "Run as-is" "Edit interactively" "Skip"; do
        case "$REPLY" in
            1)
                echo "Executing...are you sure?"
                read -n1 -s; case "$REPLY" in
                    [yY]) echo "OK!" && eval "${para}" ;;
                    [nN]) echo "Aborting!" && return 4 ;;
                    [xq]) exit 5 ;;
                    *) echo "The dude abides" && return 17 ;;
                esac
                return $?
                ;;
            2)
                eval "$(
                    printf '# %s\n' \
                        "Commands will be executed when the editor exits" |
                        cat - <<< "${para}" | vipe
                )"
                (( $? )) && echo "Script failed :(" >&2 && return $? || {
                    echo "Success!" && return 0
                }
                ;;
            3)
                echo "Aborting.  Adding this chunk to the install queue." >&2
                return 1
                ;;
            *)
                echo "Please select one of the above three options" >&2
                ;;
        esac
    done </dev/tty # TODO: Try to find a better way of doing this
                   # e.g., it seems to prevent traps from catching SIGINT
}

process_cmds() {
    local para=
    local heredoc=
    local heredoc_regex=".*<<-\?\s*\"\?\([[:alpha:]_]\+\)\"\?\(\s\|$\).*"
    while IFS= read -r line; do
        # We only want to ignore blank lines that are not part of a heredoc
        if [[ "${line}" =~ ^[[:space:]]*$ && -z "${heredoc}" ]]; then
            # Finished collecting paragraph; now process
            if [[ -n "${para}" ]]; then
                _process_paragraph "$para"
                (( $? )) && FAILED+=( "$para" )
            fi
            # Reset paragraph and continue
            para= && continue
        else
            para+="$(printf '\n%s' "${line}")"
            if [[ -z "${heredoc}" ]]; then
                # Potentially the beginning of a heredoc
                # Use regex to extract EOF indicator if it is
                heredoc=`expr "${line}" : "${heredoc_regex}"`
            elif [[ "${heredoc}" = "${line##	}" ]]; then
                # End of heredoc
                heredoc=
            fi
        fi
    done <<< "$*"
    return $?
}

append_failed() {
    local file="$1"
    for para in "${FAILED[@]}"; do
        echo "${para}" | sed '1{x;p;x}' >>"${file}"
    done
    return $?
}

main() {
    local file="$(_get_path "${1:-$INSTALLED}")" || {
        die -s $? -F 2 -f "Could not locate file '%s'" -- "${1}"
    } && cd "$(dirname "${file}")"
    process_cmds "$(_get_commands "${file}")"
    echo "Processing of uncommitted commands complete."
    local -a opts=(
        "Commit changes to '${file}' and append failed chunks (uncommitted)"
        "Open tig to interactively stage, unstage, and commit changes)"
        "Don't commit changes"
    )
    select opt in "${opts[@]}"; do
        case "${REPLY}" in
            1)
                read -p "Enter commit message: " msg && echo
                git add "${file}" && git commit -m "${msg}" && {
                    echo "Commit succeeded!"
                    echo "Appending failed chunks..." \
                        && append_failed "${file}" \
                        || die -s $? "Could not append failed chunks"
                    echo "Exiting install script."
                    exit 0
                } || {
                    die -s $? -F 2 -f '%s\n' \
                        "Commit failed!" \
                        "Please review git status and stage / commit changes manually."
                }
                ;;
            2)
                tig && {
                    append_failed "${file}" && echo "Bye!" && exit 0 \
                        || die -s $? "Could not append failed chunks"
                } || {
                    die -s $? -F 2 -f '%s\n' \
                        "tig encountered an unknown issue." \
                        "Please review git status and stage / commit changes manually."
                }
                ;;
            3)
                echo "Exiting with no further changes.  Bye!"
                exit 0
                ;;
        esac
    done
}

trap 'kill $(jobs -p); echo "Aborted"; exit 12' SIGINT SIGTERM
main "$*"
