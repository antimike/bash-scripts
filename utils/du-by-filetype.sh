#!/bin/bash
# Script to display filesize info sorted by filetype

duft () {
    find "$1" -type f -printf '%f %s\n' | nawk "$(cat <<-"AWK"
	{
	    split($1, a, ".");                # Get filename
	    ext = a[length(a)];                # Extension
	    size = $2;                                # File size
	    total_size[ext] += size;    # Sum file sizes by catgory
	}
	END {
	    # Print sums
	    for (ext in total_size) {
	        print ext, total_size[ext];
	    }
	}
	AWK
    )"
}

main() {
    duft "$@"
}

main "$@"
