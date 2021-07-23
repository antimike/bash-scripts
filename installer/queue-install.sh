#!/bin/bash
OPTIONS:
>-h |Display usage information and exit|
>-a |Keystroke-saver for -t apt|
>-d |Keystroke-saver for -t dnf|
>-v |Keystroke-saver for -t vim|
>-g |Keystroke-saver for -t github|
>-c |Keystroke-saver for -t cargo|
>-G |Keystroke-saver for -t gem|
>-n |Keystroke-saver for -t npm|
>-z |Keystroke-saver for -t zsh|
>-p |Keystroke-saver for -t python.  Accepts a non-mandatory argument specifying
major version of Python/Pip to use (default is 3)|

declare BAD_OPTS_RETURN=2

main() {
    local name=
    local type=

    while getopts "

    cat <<-TEMPLATE
#!/bin/bash
# ---
# name: ${name}
# type: ${type}
# queued: `date -u`
# ---
TEMPLATE
}

