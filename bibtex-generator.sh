#!/bin/bash

now=$(date '+%s')

jabref -n -f="Crossref:$1" -o "$now.bib"
cat "$now.bib" | sed s/{,/{"$3",/g > "$now-mod.bib" 

# Not necessary since Papis only takes the first bibtex entry anyway
#cat "$now-mod.bib" | python3 -c "import sys, bibtexparser as parser; db = parser.load(sys.stdin); print(db.entries[0])" > "$now.bib"

papis add --confirm --link $2 --from bibtex "$now-mod.bib" --commit

rm "$now.bib"
rm "$now-mod.bib"
