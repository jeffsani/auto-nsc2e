#!/bin/bash

#create a temporary directory for the xfer
mkdir nsc2e

#untar all newnslog files
for file in *.tar.gz; do tar -xzf "$file"; done
#shopt -s dotglob
find newnslog* -prune -type d | while IFS= read -r d; do 
    cd "$d"
    #process the counter data for nCores
    for f in *; do ../nsc2e -c /netscaler/nsconmsg -K "$f" -f ../nsc2e.conf; done
    #Concatenate the resultant files
    awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-nsc2e.conf-newnslog.ppe.* >../nsc2e/$(f).txt;
    cd ..
done
