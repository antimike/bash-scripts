#!/bin/bash

repo=$(dirname $0)
for file in $repo/*.sh; do
	sudo ln -s $file "/usr/local/bin/$(basename "$file")"
done
