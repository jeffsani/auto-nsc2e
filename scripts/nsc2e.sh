#!/bin/sh
#nsc2e.sh
#This script initiates the processng of the nsc2e utility against all newnslog archives

set -o pipefail

#Create a temporary directory for the xfer
cd /var/nslog
mkdir nsc2e-tmp
#Untar all newnslog files
for file in *.tar.gz; do tar -xzf "$file" --directory nsc2e-tmp; done
#shopt -s dotglob
find nsc2e-tmp/newnslog* -prune -type d | while IFS= read -r d; do 
   #Process the counter data for nCores
   for f in $d/*; do 
   ./nsc2e -c /netscaler/nsconmsg -K "$f" -f nsc2e.conf;
   done
   #Concatenate the resultant files
   awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-nsc2e.conf-newnslog.ppe.* > $d.txt;
   #Remove ppe files
   rm nsc2e-nsc2e.conf-newnslog.ppe.*
done
#Concatenate all data to single file
awk 'FNR==1 && NR!=1 { while (/^"UTC"/) getline; } 1 {print}' nsc2e-tmp/*.txt > nsc2e.txt;
exit 0