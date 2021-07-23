#!/bin/bash
# See https://stackoverflow.com/questions/762348/how-can-i-exclude-all-permission-denied-messages-from-find
# Example from that thread:
# Uses **output** process redirection
find_suppress_errors() {
    find . > "$1" 2> >(grep -v 'Permission denied' >&2)
}

# This doesn't work, but I'm too lazy to fix it right now.
suppressed="$1"
2> >(grep -v "${suppressed}" >&2)
