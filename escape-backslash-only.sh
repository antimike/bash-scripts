#!/bin/bash

echo "$(sed 's/\\/\\\\/g' <<< $1)"
