#!/bin/sh 

pandoc -s -f markdown --filter pandoc-eqnos -t html5 --mathjax -o /tmp/msg.html --resource-path ~/.mutt/templates --template email-revised $1
