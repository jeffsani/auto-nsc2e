#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -o pipefail

#Create data and log directories
mkdir ../log; mkdir ../data;

# Create init logfile
LOGFILE="../log/$(date '+%m%d%Y')-auto-nsc2e-init.log"

# Prompt for and set rc variables 
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
source ~/.bashrc
echo "Script variables set successfully..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

# Download and install pre-requisites
echo "Do you want to install required system pre-requisites (requires elevated privs or sudoer membership) Y/N?..."
read ANSWER1
ANSWER1=${ANSWER1,,} # convert to lowercase
if [ "$ANSWER1" == "y" ]; then
   echo "Installing required system pre-requisites..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   which sudo yum >/dev/null && { sudo yum install sshpass more-utils; }
   which sudo apt-get >/dev/null && { sudo apt install sshpass moreutils; }
else
   echo "Skipping install of required system pre-requisites..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   echo "Please refer to Readme for script requirements..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
fi

#Check for existance of populated adc-list.txt and loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
if [ $(grep -cE "[0-9][0-9]*.[0-9][0-9]*\.[0-9][0-9]*.[0-9][0-9]*:[0-9][0-9]*" $INPUT) -gt 0 ]; then
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
   echo "No entries found in adc-list.txt - Please add at least 1 ADC host in the format IPADDR:PORT (X.X.X.X:NN)..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   exit 1
fi

# Prompt user to create cron job for scheduling the script to be run at a desired interval
echo "Would you like to schedule this script to be run - Y/N?"
read ANSWER2
ANSWER2=${ANSWER2,,} # convert to lowercase
if [ "$ANSWER2" == "y" ]; then
   echo "What interval would you like to run the script - D/W/M?"
   read ANSWER3
   ANSWER3=${ANSWER3,,} # convert to lowercase
   case $ANSWER3 in
	d)
		# Day interval cron job
      echo "Creating daily cron job at 11:59PM..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      echo "59 11 * * * $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
   ;;
	w)
		# Week interval cron job
      echo "Creating weekly cron job at 11:59PM on Saturday..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      echo "59 11 * * 6 $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
	;;
   m)
		# Month Interval cron job
      echo "Creating Monthly cron job at 11:59PM on the 30th of each month..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      echo "59 11 30 * * $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
	;;
	*)
		# Unknown input
      echo "Unknown option input - Skipping Cron setup..."
      exit 1
	;;
   esac
   echo "Removing old cronjob if it exists..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   crontab -l | grep -v "auto-nsc2e.sh" | crontab -
   echo "Creating new cron job..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   crontab auto-nsc2e
   rm auto-nsc2e
fi

echo "All done!..." | ts '[%H:%M:%S]' | tee -a $LOGFILE