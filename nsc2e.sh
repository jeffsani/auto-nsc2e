#!/bin/bash

shopt -s dotglob
find newnslog* -prune -type d | while IFS= read -r d; do 
    cd "$d"
    for f in *; do ../nsc2e -c /netscaler/nsconmsg -K "$f" -f ../nsc2e.conf; done
done