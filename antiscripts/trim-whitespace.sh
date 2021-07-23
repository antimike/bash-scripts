#!/bin/bash
# Simple sed script to trim whitespace

# TODO: Add support for opts pass-through (e.g., -i)
__DIRNAME__="$(dirname "${BASH_SOURCE[0]}")"
sed_scr="${__DIRNAME__}/../sed/trim-whitespace.sed"

sed -f "${sed_scr}" "$@"
