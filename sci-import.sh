#!/bin/sh

function get_doi() {
  local DIR=/tmp/paper
	rm -rf $DIR
	scidownl -D $1 -o $DIR
	if [[ -d $DIR ]]
	then
		papis add --from doi $1 \
			--set tags $2 \
			$DIR/*.pdf
		return 0
	fi
}

function get_arxiv() {
	papis add --from arxiv $1 \
		--set tags $2
}

function extract_url_id() {
	python3 -c "import sys; from urllib.parse import unquote; print(unquote(sys.argv[1]).replace(sys.argv[2], ''))" "$1" "$2"
	return 0
}

ARXIV_PREFIX='https://arxiv.org/abs/'
DOI_PREFIX='https://doi.org/'

opt=$1
url=$2
tags=$3

if [[ $opt = "-a" ]]	# Get doc from Arxiv
then
	id=$(extract_url_id $url $ARXIV_PREFIX)
	get_arxiv "$id" "$tags"
fi

if [[ $opt = "-d" ]]	# Get doc from DOI using scidownl
then
	id=$(extract_url_id $url $DOI_PREFIX)
	get_doi "$id" "$tags"
fi

# TODO: Implement more options and use args array:

#function test() {
	#args=("$@")
	##echo $args
	#echo "${args[@]:1}"
#}

#test 'boopy' 'shadoopy'
#test boopy shadoopy
