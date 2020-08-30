#!/bin/bash

DEFAULT_OUTPUT_BASENAME="exported-references.bib"
OUTPUT_FILENAME_SANITATION_SCRIPT="sanitize-filename-input-arg.sh"
INPUT_FILENAME_SANITATION_SCRIPT=""
CERMINE_JAR_FILENAME="/usr/share/java/cermine-impl-1.13-jar-with-dependencies.jar"

OUTPUT_FILENAME="$(eval "$OUTPUT_FILENAME_SANITATION_SCRIPT '${2:-"$(pwd)"}' '$DEFAULT_OUTPUT_BASENAME'")"

TEMPDIR=$(mktemp -d)

# I spent awhile debugging this and this is the only way I could get it to work.
# Probably (almost certainly) not best, but too lazy to fix it atm
eval "if [ -d $1 ]; then
	cp ${1}/*.pdf $TEMPDIR
elif [ -f $1 ]; then
	cp $1 $TEMPDIR
else
	echo 'Bad joojoo homes, try again'
	exit 2
fi"

# Loose the awesome, but shockingly incomplete, power of CERMINE on the contents of the tmp dir
java -cp $CERMINE_JAR_FILENAME pl.edu.icm.cermine.ContentExtractor -outputs text,jats -path $TEMPDIR

# Consolidate text results
cat $TEMPDIR/*.cermtxt > $TEMPDIR/output.txt

# Apply anystyle to extract references in bib format
anystyle -f bib find $TEMPDIR/output.txt > $TEMPDIR/output.bib

# Copy aggregated results to destination
eval "cat $TEMPDIR/output.bib > $OUTPUT_FILENAME"

# Clean up
rm -R $TEMPDIR
