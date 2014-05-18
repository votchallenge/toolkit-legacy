#!/bin/bash

WIKI=./vot-toolkit.wiki
FILES="$WIKI/Home.md $WIKI/Integration.md $WIKI/Internals.md"

sed -s -e '$a\\' $FILES | sed "s/\[\[\([a-zA-Z 0-9]*\)|\([a-zA-Z 0-9]*\)\]\] document/\1 chapter/g" | sed "s/\[\[\([a-zA-Z 0-9]*\)|\([a-zA-Z 0-9]*\)\]\]/\1/g" | pandoc --include-in-header "header.tex" --include-before-body="cover.tex" --standalone --listings --chapters --toc -f markdown -t latex -o documentation.tex 

pdflatex documentation.tex

