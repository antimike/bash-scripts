#!/bin/bash

if [ -f "$BASH_INCLUDE" ]; then
    source "$BASH_INCLUDE"
else
    echo "Could not find 'include.sh'" >&2
    exit 23
fi

_test_usage() {
    echo "I'm a usage function!"
}

notify "Hello from ${__TEST_NAME__}!"
debug_vars __TEST_FILE__ __TEST_NAME__ __TEST_DIR__

fn() {
    error UNKNOWN_OPT "opt"
    error -I 1 "Some error"
    usage
    exit $?
}

fn
