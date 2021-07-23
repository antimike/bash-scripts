#!/bin/bash
# Function to kill any running background jobs.
# Intended to be sourced, not run as a script.

kill_background_jobs() {
    while IFS=: read -r job_id; do
        kill %${job_id}
    done < <(jobs -l | awk '/^\[/{print $1}' |
        sed 's/^.*\[//;s/\].*$//')
    return $?
}
