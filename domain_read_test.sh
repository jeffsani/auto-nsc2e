#!/bin/bash
# Purpose: Read Comma Separated CSV File
# Author: Vivek Gite under GPL v2.0+
# ------------------------------------------
INPUT=domains.csv
OLDIFS=$IFS
IFS=','
[ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
while read -r domain challenge provider keytype
do
case $provider in
"GD")
	echo "GoDaddy Domains:"
	echo "Domain : $domain"
	echo "Challenge : $challenge"
	echo "Key type : $keytype"
;;
"CF")
	echo "CloudFlare Domains:"
	echo "Domain : $domain"
	echo "Challenge : $challenge"
	echo "Key type : $keytype"
;;
esac
done < $INPUT
IFS=$OLDIFS