#!/bin/bash

# Export Papis library to .bib file
rm ~/.dotfiles/library.bib
papis export --all --format bibtex --out ~/.dotfiles/library.bib
