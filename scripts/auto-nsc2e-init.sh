#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -x
set -o pipefail

# Fix perl locale issue
#echo "export LANGUAGE=en_US.UTF-8 
#export LANG=en_US.UTF-8 
#export LC_ALL=en_US.UTF-8">>~/.bashrc

# Create init logfile
LOGFILE="$(date '+%m%d%Y')-auto-nsc2e-init.log"

# Prompt for and set rc variables 
echo "Setting script variables..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
echo "Enter the Citrix ADC user for the script:"
read ADC_USER
echo "Enter the Citrix ADC user password:"
read ADC_PASSWD

if grep --quiet "#Start-auto-nsc2e" ~/.bashrc; then
   sed -i -e "s/CITRIX_ADC_USER=.*/CITRIX_ADC_USER=$ADC_USER/" -e "s/CITRIX_ADC_PASSWORD=.*/CITRIX_ADC_PASSWORD=$ADC_PASSWD/" ~/.bashrc
else
cat >>~/.bashrc <<-EOF
#Start-auto-nsc2e
export CITRIX_ADC_USER="$ADC_USER"
export CITRIX_ADC_PASSWORD="$ADC_PASSWD"
#End-auto-nsc2e
EOF
fi
echo "Script variables set successfully..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;