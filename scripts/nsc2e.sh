#!/bin/bash
#nsc2e.sh
#This script initiates the processng of the nsc2e utility against all newnslog archives
#and concatenates the results into a single data file

set -o pipefail

#Change the working directory
cd /var/nslog
#Create a temporary working directory if it does not exist
[ ! -d "./nsc2e-tmp" ] && mkdir nsc2e-tmp
#Untar all newnslog files
for file in *.tar.gz; do tar -xzf "$file" --directory nsc2e-tmp; done
find nsc2e-tmp/newnslog* -prune -type d | while IFS= read -r d; do 
   #Process the counter data for nCores
   for f in $d/*; do 
   ./nsc2e -c /netscaler/nsconmsg -K "$f" -f nsc2e.conf
   done
   #Concatenate the resultant files
   #head -n +1 nsc2e-nsc2e.conf-newnslog.ppe.0 >$d.tsv
   #tail -q -n +2 nsc2e-nsc2e.conf-newnslog.ppe.* >>$d.tsv
   awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-nsc2e.conf-newnslog.ppe.* > $d.tsv
   #Remove ppe files
   rm nsc2e-nsc2e.conf-newnslog.ppe.*
done
#Concatenate all data to single file
awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-tmp/*.tsv > nsc2e.tsv