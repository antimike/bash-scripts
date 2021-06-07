#!/bin/sh

timeout --kill-after=${2}s ${2}s speaker-test --frequency ${1} --test sine
