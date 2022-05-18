#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -o pipefail

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
echo "Script variables set successfully..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

# Download and install pre-requisites
echo "Installing required system pre-requisites..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
which sudo yum >/dev/null && { sudo yum install sshpass more-utils; }
which sudo apt-get >/dev/null && { sudo apt install sshpass moreutils; }

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
while IFS=: read -r CITRIX_ADC_IP CITRIX_ADC_PORT
do
# Check known_hosts file for presence of NSIP and add if not present
if [ $CITRIX_ADC_PORT -eq "22" ]; then
   ssh-keygen -F $CITRIX_ADC_IP -f ~/.ssh/known_hosts &>/dev/null
   if [ "$?" -ne "0" ]; then 
      # Add ADC to known_hosts
      echo "Adding ADC IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      ssh-keyscan $CITRIX_ADC_IP >> ~/.ssh/known_hosts
   else
      echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   fi
else 
   ssh-keygen -F '[$CITRIX_ADC_IP]:$CITRIX_ADC_PORT' -f ~/.ssh/known_hosts &>/dev/null
   if [ "$?" -ne "0" ]; then 
      # Add ADC to known_hosts
      echo "Adding ADC IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      ssh-keyscan -p $CITRIX_ADC_PORT $CITRIX_ADC_IP >> ~/.ssh/known_hosts
   else
      echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   fi
fi
done < $INPUT
echo "All done!..." | ts '[%H:%M:%S]' | tee -a $LOGFILE