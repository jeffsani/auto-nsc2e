#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to excel format across a set of ADCs

set -o pipefail

#Variables
NEWNSLOG_PATH="/var/nslog"
LOGFILE="$(date '+%m%d%Y')-auto-nsc2e.log"
CITRIX_ADC_USER="nsroot"
CITRIX_ADC_PASSWORD="Marig0ld"

#Cleanup function
function do_cleanup {
echo "Searching for old logs > 30 days and removing them..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
find *.log -type f -not -name '*auto-nsc2e-init.log' -mtime -30 -delete
}

#Start Logging
echo "User $(whoami) started the script" | ts '[%H:%M:%S]' | tee -a $LOGFILE
echo "Starting auto-nsc2e Log..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

# Check to see if one of the required environment variables for the script is not set
source ~/.bashrc
if [[ -z "${CITRIX_ADC_USER}" || -z "${CITRIX_ADC_PASSWORD}" ]]; then
    echo "One or more of the required environment variables for the script is not set properly..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
    exit 1;
fi

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
while IFS=: read -r CITRIX_ADC_IP CITRIX_ADC_PORT
do
  echo "Now processing ADC at $CITRIX_ADC_IP on Port: $CITRIX_ADC_PORT..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
  #Transfer tool and configuration to ADC
  echo "Transfering files to ADC..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
  sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT ../nsc2e/nsc2e ../nsc2e/nsc2e.conf nsc2e.sh $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH >> $LOGFILE
  echo "Setting execute permissions on nsc2e..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell chmod 744 $NEWNSLOG_PATH/nsc2e.sh $NEWNSLOG_PATH/nsc2e" >> $LOGFILE
  echo "Executing nsc2e remotely..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell /bin/sh $NEWNSLOG_PATH/nsc2e.sh"; >> $LOGFILE
  echo "Transferring data back to script host..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH/nsc2e.txt ./$(date '+%m%d%Y')-$CITRIX_ADC_IP.txt >> $LOGFILE
  echo "Removing remote files and folders..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell rm -rf $NEWNSLOG_PATH/nsc2e*" >> $LOGFILE
  echo "Done processing $CITRIX_ADC_IP..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
done < $INPUT
echo "All done..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

do_cleanup