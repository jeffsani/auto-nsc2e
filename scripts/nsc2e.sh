#!/bin/bash
#nsc2e.sh
#This script initiates the processng of the nsc2e utility against all newnslog archives
#and concatenates the results into a single data file

set -o pipefail

#Change the working directory
cd /var/tmp/nsc2e-tmp

#Copy current newnslog file to working directory
cp -r /var/nslog/newnslog .

#Untar all newnslog archives
for file in /var/nslog/*.tar.gz; do tar -xzf "$file"; done
find newnslog* -prune -type d | while IFS= read -r d; do 
   #Process the counter data for nCores
   for f in $d/*; do 
   ./nsc2e -c /netscaler/nsconmsg -K "$f" -f nsc2e.conf
   done
   #Concatenate the resultant files
   awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-nsc2e.conf-newnslog.ppe.* > $d.tsv
   #Remove ppe files
   rm nsc2e-nsc2e.conf-newnslog.ppe.*
done

#Concatenate all data to single file
awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-tmp/*.tsv > nsc2e.tsv

#Compress file for transfer to script host
tar -czf nsc2e.tsv.gz nsc2e.tsv