#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -o pipefail

#Create data and log directories if they do not already exist
echo "checking for log and data directories and creating if they do not exist..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
[ ! -d "../log" ] && mkdir ../log
[ ! -d "../data" ] && mkdir ../data

# Create init logfile
LOGFILE="../log/$(date '+%m%d%Y')-auto-nsc2e-init.log"

# Prompt for and set rc variables 
echo "Setting script variables in ~/.bashrc..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
echo "Enter the Citrix ADC user for the script:"
read ADC_USER
echo "Enter the Citrix ADC user password:"
read ADC_PASSWD
if grep --quiet "#Start-auto-nsc2e-Vars" ~/.bashrc; then
   sed -i -e "s/NSC2E_ADC_USER=.*/NSC2E_ADC_USER=$ADC_USER/" -e "s/NSC2E_ADC_PASSWORD=.*/NSC2E_ADC_PASSWORD=$ADC_PASSWD/" ~/.bashrc
else
cat >>~/.bashrc <<-EOF
#Start-auto-nsc2e-Vars
export NSC2E_ADC_USER="$ADC_USER"
export NSC2E_ADC_PASSWORD="$ADC_PASSWD"
#End-auto-nsc2e-Vars
EOF
fi
source ~/.bashrc
echo "Script variables set successfully..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

# Download and install pre-requisites
echo "Do you want to install required system pre-requisites (requires elevated privs or sudoer membership) [Y/n]?..."
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
   while IFS=: read -r NSC2E_ADC_IP NSC2E_ADC_PORT
   do
   # Check known_hosts file and presence of NSIP and add if not present
   if [ ! -r ~/.ssh/known_hosts ]; then mkdir -p ~/.ssh; touch ~/.ssh/known_hosts; fi
   if [ $NSC2E_ADC_PORT -eq "22" ]; then
      ssh-keygen -F $NSC2E_ADC_IP -f ~/.ssh/known_hosts &>/dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "Adding ADC IP $NSC2E_ADC_IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
         ssh-keyscan $NSC2E_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      fi
   else 
      ssh-keygen -F '[$NSC2E_ADC_IP]:$NSC2E_ADC_PORT' -f ~/.ssh/known_hosts &>/dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "Adding ADC IP $NSC2E_ADC_IP to known_hosts..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
         ssh-keyscan -p $NSC2E_ADC_PORT $NSC2E_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP already present in known_hosts - Skipping add..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
      fi
   fi
   done < $INPUT
else
   #Prompt for first ADC IP and Port to write to adc-list.txt
   echo "No entries found in adc-list.txt - at least one host is required to run the script..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   echo "Input an ADC IP with management enabled - either NSIP or SNIP:"
   read ANSWER2
   echo "Input the ADC Port:"
   read ANSWER3
   echo "$ANSWER2:$ANSWER3" > adc-list.txt
   echo "ADC $ANSWER2:$ANSWER3 added as first entry into adcc-list.txt - add any additional ADC hosts in the format X.X.X.X:NN..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
fi

# Prompt user to create cron job for scheduling the script to be run at a desired interval
echo "Would you like to schedule this script to be run - [Y/n]?"
read ANSWER4
ANSWER4=${ANSWER4,,} # convert to lowercase
if [ "$ANSWER4" == "y" ]; then
   echo "Removing old cronjob if it exists..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   crontab -l | grep -v "auto-nsc2e.sh" | crontab -
   echo "Backing up existing entries..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   crontab -l > auto-nsc2e
   echo "What interval would you like to run the script - [Daily/Weekly/Monthly]?"
   read ANSWER5
   ANSWER5=${ANSWER5,,} # convert to lowercase; 
   ANSWER3=${ANSWER3:0:1} # get first letter;
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
   echo "Creating new cron job..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
   crontab auto-nsc2e
   rm auto-nsc2e
fi

echo "All done!..." | ts '[%H:%M:%S]' | tee -a $LOGFILE