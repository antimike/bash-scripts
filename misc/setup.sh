#!/bin/bash

repo=$(dirname $0)
for file in $repo/*.sh; do
	sudo chmod +x $file
	sudo ln -s $file "/usr/local/bin/$(basename "$file")"
done
