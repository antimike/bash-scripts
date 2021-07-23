#!/bin/bash
# See the following SO thread:
# https://unix.stackexchange.com/questions/146756/forward-sigterm-to-child-in-bash

prep_term()
{
    unset term_child_pid
    unset term_kill_needed
    trap 'handle_term' TERM INT
}

handle_term()
{
    if [ "${term_child_pid}" ]; then
        kill -TERM "${term_child_pid}" 2>/dev/null
    else
        term_kill_needed="yes"
    fi
}

wait_term()
{
    term_child_pid=$!
    if [ "${term_kill_needed}" ]; then
        kill -TERM "${term_child_pid}" 2>/dev/null 
    fi
    wait ${term_child_pid} 2>/dev/null
    trap - TERM INT
    wait ${term_child_pid} 2>/dev/null
}

# EXAMPLE USAGE
prep_term
/bin/something &
wait_term

# Alternative solution
terminate_children() {
    # See https://linuxconfig.org/how-to-propagate-a-signal-to-child-processes-from-a-bash-script
    # If certain child processes require special handling, the `$!` builtin can be
    # used to get the relevant PIDs at the time of process creation
    # In this case, however, `wait` must be called twice:  Once immediately after
    # process creation and once in the `trap`.

    # First possibility: Sends SIGTERM to all direct children and awaits
    # This is not recursive, however---"grandchild" processes are not terminated
    # kill $(jobs -p)

    # Second possibility: This is recursive, as it sends a SIGINT to the entire
    # process group.  Care must be taken to avoid a loop, however.
    trap " " # Avoids an infinite `trap` / `sent` loop
    kill 0   # Equivalent to `kill -$$` (since process group ID is -(parent ID))
}

cleanup() {
    :
}

trap 'terminate_children; wait; cleanup' SIGINT SIGTERM
