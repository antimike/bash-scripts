#!/bin/bash

# Taken from https://stackoverflow.com/questions/55191585/how-can-i-wrap-text-within-a-multiline-table-without-loosing-formatting
read -r -d '' align_table <<-AWK
	{
	    beg = end = $0
	    sub(/	.*/,"",beg)
	    sub(/[^	]+	/,"",end)
	
	    cmd = "printf \047" end "\n\047 | fold -sw38"
	    while ( (cmd | getline line) > 0 ) {
	        print beg, line
	        gsub(/./," ",beg)
	    }
	}
AWK

read -r -d '' process_opts_comments <<-SED

SED

TARGET_WIDTH=80

while read -r -d '' line; do
    process_line "$line"
done < <(some_cmd)
