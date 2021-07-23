#!/bin/bash

echo "$(sed 's/\(\s\)/\\\1/g' <<< "$1")"
