#!/bin/bash
#nsc2e.sh
#This script initiates the processng of the nsc2e utility against all newnslog archives

#Create a temporary directory for the xfer
mkdir nsc2e
#Untar all newnslog files
for file in *.tar.gz; do tar -xzf "/nsc2e/$(file)"; done
#shopt -s dotglob
find /nsc2e/newnslog* -prune -type d | while IFS= read -r d; do 
    #Process the counter data for nCores
    for f in $d/*; do ../../nsc2e -c /netscaler/nsconmsg -K "$d/$f" -f ../../nsc2e.conf; done
    #Concatenate the resultant files
    awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-nsc2e.conf-newnslog.ppe.* >$(f).txt;
    #Move data file to root
    mv $(f) ../../
done
#Concatenate all data to single file
awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' *.txt >nsc2e.txt;
exit 0