#!/bin/bash
# auto-nsc2e-init.sh
# This script will setup your host for the auto-nsc2e script on a debian or fedora/centos based host

set -o pipefail

# Set local variables
LOGFILE="./log/$(date '+%m%d%Y')-auto-nsc2e-init.log"
NSC2E_CONF=~/.adcrc

(
# Create data and log directories and conf if they do not already exist
echo "checking for log and data directories and creating if they do not exist..."
[ ! -d "./log" ] && mkdir log; [ ! -d "./data" ] && mkdir data; [ ! -f "$NSC2E_CONF" ] && touch $NSC2E_CONF

# Prompt for and set variables 
echo "Setting script variables..."
echo "Enter the Citrix ADC user for the script: "; read ADC_USER
echo "Enter the Citrix ADC user password: "; read -s ADC_PASSWD
echo ""

#Load common variables from conf and check vars
. $NSC2E_CONF
if [[ ! -z "$NSC2E_ADC_USER" && ! -z "$NSC2E_ADC_PASSWORD" ]]; then #file exists so update vars
   echo "Exisitng variables detected - refreshing values..."
   sed -i -e "s/NSC2E_ADC_USER=.*/NSC2E_ADC_USER=$ADC_USER/" -e "s/NSC2E_ADC_PASSWORD=.*/NSC2E_ADC_PASSWORD=\'$ADC_PASSWD\'/" $NSC2E_CONF
else #file is empty so write vars
cat >>$NSC2E_CONF <<-EOF
#Start-auto-nsc2e-Vars
export NSC2E_ADC_USER="$ADC_USER"
export NSC2E_ADC_PASSWORD='$ADC_PASSWD'
#End-auto-nsc2e-Vars
EOF
fi
echo "Script variables set successfully..."

# Download and install pre-requisites
echo "Do you want to install required system pre-requisites (requires elevated privs or sudoer membership) [Y/n]? "; read ANSWER1
ANSWER1=${ANSWER1,,} # convert to lowercase
if [ "$ANSWER1" == "y" ]; then
   echo "Installing required system pre-requisites..."
   which sudo yum >/dev/null && { sudo yum install sshpass more-utils; }
   which sudo apt-get >/dev/null && { sudo apt install sshpass moreutils; }
else
   echo "Skipping install of required system pre-requisites..."
   echo "Please refer to README.md for script requirements..."
fi

# Check for existance of populated adc-list.txt and loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..."; exit 99; }
if [ $(grep -cE "[0-9][0-9]*.[0-9][0-9]*\.[0-9][0-9]*.[0-9][0-9]*:[0-9][0-9]*" $INPUT) -gt 0 ]; then
   echo "At least one host found in adc-list.txt - Skipping add..."
   while IFS=: read -r NSC2E_ADC_IP NSC2E_ADC_PORT
   do
   # Check known_hosts file and presence of NSIP and add if not present
   echo "Checking for presence of $NSC2E_ADC_IP in ~/.ssh/known_hosts..."
   if [ ! -r ~/.ssh/known_hosts ]; then mkdir -p ~/.ssh; touch ~/.ssh/known_hosts; fi
   if [ $NSC2E_ADC_PORT -eq "22" ]; then
      ssh-keygen -F $NSC2E_ADC_IP -f ~/.ssh/known_hosts &> /dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "ADC IP $NSC2E_ADC_IP not present in known_hosts - Adding IP..."
         ssh-keyscan $NSC2E_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP $NSC2E_ADC_IP already present in known_hosts - Skipping add..."
      fi
   else 
      ssh-keygen -F '[$NSC2E_ADC_IP]:$NSC2E_ADC_PORT' -f ~/.ssh/known_hosts &> /dev/null
      if [ "$?" -ne "0" ]; then 
         # Add ADC to known_hosts
         echo "ADC IP $NSC2E_ADC_IP not present in known_hosts - Adding IP..."
         ssh-keyscan -p $NSC2E_ADC_PORT $NSC2E_ADC_IP >> ~/.ssh/known_hosts 2> /dev/null
      else
         echo "ADC IP $NSC2E_ADC_IP already present in known_hosts - Skipping add..."
      fi
   fi
   done < $INPUT
else
   # Prompt for first ADC IP and Port to write to adc-list.txt
   echo "No entries found in adc-list.txt - at least one host is required to run the script..."
   echo "Input an ADC IP with management enabled - either NSIP or SNIP: "; read ANSWER2
   echo "Input the ADC Port: "; read ANSWER3
   echo "$ANSWER2:$ANSWER3" > adc-list.txt
   echo "ADC $ANSWER2:$ANSWER3 added as first entry into adc-list.txt - add any additional ADC hosts in the format X.X.X.X:NN..."
fi

# Prompt user to create cron job for scheduling the script to be run at a desired interval
echo "Would you like to schedule this script to be run - [Y/n]? "; read ANSWER4
ANSWER4=${ANSWER4,,} # convert to lowercase
if [ "$ANSWER4" == "y" ]; then
   echo "Removing old cronjob if it exists..."
   crontab -l | grep -v "auto-nsc2e.sh" | crontab -
   echo "Backing up existing entries..."
   crontab -l > auto-nsc2e
   echo "What interval would you like to run the script - [Daily/Weekly/Monthly]? "; read ANSWER5
   ANSWER5=${ANSWER5:0:1}; ANSWER5=${ANSWER5,,} # get first letter and convert to lowercase
   case $ANSWER5 in
	d)
		# Day interval cron job
      echo "Creating daily cron job at 11:59PM..."
      echo "59 11 * * * $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
   ;;
	w)
		# Week interval cron job
      echo "Creating weekly cron job at 11:59PM on Saturday..."
      echo "59 11 * * 6 $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
	;;
   m)
		# Month Interval cron job
      echo "Creating Monthly cron job at 11:59PM on the 30th of each month..."
      echo "59 11 30 * * $(pwd)/auto-nsc2e.sh" >> auto-nsc2e
	;;
	*)
		# Unknown input
      echo "Unknown option input - Skipping Cron setup..."
      exit 1
	;;
   esac
   crontab auto-nsc2e
   rm auto-nsc2e
   echo "Successfully created new cron job..."
fi
echo "All done - Please update bin/nsc2e.conf with desired counters prior to running auto-nsc2e.sh script..."
>> $LOGFILE) 2>&1 | ts '[%H:%M:%S]' | tee -a $LOGFILE