#!/bin/bash

BLUE=34
RED=31
GREEN=32

function sanitize_file_name {
	echo -n $1 | perl -pe 's/[\?\[\]\/\\=<>:;,''"&\$#*()|~`!{}%+]//g;' -pe 's/[\r\n\t -]+/-/g;'
}

function echo_color {
	echo -e "\033[$2;1m"
	echo $1
	echo -e "\033[00m"
}

function colorize_string {
	echo "\$'\\e[$2;1m$1\\e[0m'"
}

file=$1
now=$(date '+%s')

while ! [[ -f "$file" && $(file --mime-type -b "$file") == application/pdf ]]
do
	echo_color "You have either not chosen at all or have chosen poorly." $RED
	#read -e -p $(colorize_string "Pick a valid PDF file to add to library: " $BLUE) file
	read -e -p "Pick a valid PDF file to add to library: " file
	file="${file/#\~/$HOME}"
	ls -l "$file"
done

search=$(pdftitle -p $file)
echo_color "Title of PDF = $search" $GREEN
echo "Is this correct?"
select ans in "Yes" "No"; do
	case $ans in
		Yes ) break;;
		No ) read -p "Enter title or preferred search phrase: " search; break;;
	esac
done

if [ -z "$2" ]
then
	echo_color "Choose a unique identifier or use default based on title?" $BLUE
	select ans in "Choose" "Default"; do
		case $ans in
			#Choose ) read -p $(colorize_string "Pick a unique identifier for the file: " $BLUE) idstr; break;;
			Choose ) read -p "Pick a unique identifier for the file: " idstr; break;;
			Default ) idstr="$(echo $search | head -n1 | awk '{print $search;}')$now"; break;;
		esac
	done
	
else
	idstr=$(sanitize_file_name "$2")
fi

echo_color "ID = $idstr" $GREEN

echo_color "Searching Crossref via JabRef for '$1'..."

jabref -n -f="Crossref:$search" -o "$now.bib"
cat "$now.bib" | sed s/{,/{"$idstr",/g > "$now-mod.bib" 

echo_color "Adding document to Papis..."

papis add $2 --confirm --from bibtex "$now-mod.bib"

rm "$now.bib"
rm "$now-mod.bib"

#TODO: Iterate through resultset using Python until user confirms result is correct
#TODO: Add "author" prompt
#TODO: Add "search tool" prompt
#TODO: After confirmation and addition to Papis, export bibtex for newly-added file and add to pubs
