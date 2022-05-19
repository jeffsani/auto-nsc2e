#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -o pipefail

# Create init logfile
LOGFILE="$(date '+%m%d%Y')-auto-nsc2e-init.log"

# Prompt for and set rc variables 
source ~/.bashrc
if [[ -z "${CITRIX_ADC_USER}" && -z "${CITRIX_ADC_PASSWORD}" ]]; then echo "Required script environment variables are already set - do you need to change them? Y/N"; fi
read ANSWER1
if [ "$ANSWER1" == "Y" ]; then
echo "Setting script variables in ~/.bashrc..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
echo "Enter the Citrix ADC user for the script:"
read ADC_USER
echo "Enter the Citrix ADC user password:"
read ADC_PASSWD
if grep --quiet "#Start-NetScaler-Vars" ~/.bashrc; then
   sed -i -e "s/CITRIX_ADC_USER=.*/CITRIX_ADC_USER=$ADC_USER/" -e "s/CITRIX_ADC_PASSWORD=.*/CITRIX_ADC_PASSWORD=$ADC_PASSWD/" ~/.bashrc
else
cat >>~/.bashrc <<-EOF
#Start-NetScaler-Vars
export CITRIX_ADC_USER="$ADC_USER"
export CITRIX_ADC_PASSWORD="$ADC_PASSWD"
#End-NetScaler-Vars
EOF
fi
echo "Script variables set successfully..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
fi

# Download and install pre-requisites
echo "Do you want to install required system pre-requisites (requires elevated privs or sudoer membership) Y/N?..."
read ANSWER2
if [ "$ANSWER2" == "Y" ]; then
   echo "Installing required system pre-requisites..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   which sudo yum >/dev/null && { sudo yum install sshpass more-utils; }
   which sudo apt-get >/dev/null && { sudo apt install sshpass moreutils; }
else
   echo "Skipping required system pre-requisites..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   echo "Please refer to Readme for script requirements..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
fi

#Check for existance of populated adc-list.txt and loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
if [grep -E -c -q "[0-9][0-9]*.[0-9][0-9]*\.[0-9][0-9]*.[0-9][0-9]*:[0-9][0-9]*" $INPUT -gt 0]; then
   while IFS=: read -r CITRIX_ADC_IP CITRIX_ADC_PORT
   do
   # Check known_hosts file and presence of NSIP and add if not present
   if [ ! -r ~/.ssh/known_hosts ]; then mkdir -p ~/.ssh; touch ~/.ssh/known_hosts; fi
   if [ $CITRIX_ADC_PORT -eq "22" ]; then
      ssh-keygen -F $CITRIX_ADC_IP -f ~/.ssh/known_hosts &>/dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "Adding ADC IP $CITRIX_ADC_IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
         ssh-keyscan $CITRIX_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      fi
   else 
      ssh-keygen -F '[$CITRIX_ADC_IP]:$CITRIX_ADC_PORT' -f ~/.ssh/known_hosts &>/dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "Adding ADC IP $CITRIX_ADC_IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
         ssh-keyscan -p $CITRIX_ADC_PORT $CITRIX_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      fi
   fi
   done < $INPUT
else
   echo "Please add at least 1 ADC host in the format IPADDR:PORT (X.X.X.X:NN) to the adc-list.txt file..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   exit 1
fi
echo "All done!..." | ts '[%H:%M:%S]' | tee -a $LOGFILE