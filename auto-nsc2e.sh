#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to excel format across a set of ADCs

set -o pipefail

#Variables
NEWNSLOG_PATH="/var/nslog"
LOGFILE="./log/$(date '+%m%d%Y')-auto-nsc2e.log"

#Cleanup function
function do_cleanup {
echo "Searching for old logs > 30 days and removing them..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
find ./log/*.log -type f -not -name '*auto-nsc2e-init.log' -mtime -30 -delete
echo "Searching for old data files > 180 days and removing them..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
find ./data/*.txt -type f -not -name '*auto-nsc2e-init.log' -mtime -180 -delete
echo "Cleanup completed..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
}

#Start Logging
echo "User $(whoami) started the script" | ts '[%H:%M:%S]' | tee -a $LOGFILE
echo "Starting auto-nsc2e Log..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

# Check to see if one of the required environment variables for the script is not set
source ~/.bashrc
if [[ -z ${NSC2E_ADC_USER} || -z ${NSC2E_ADC_PASSWORD} ]]; then
    echo "One or more of the required environment variables for the script is not set properly..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
    exit 1;
fi

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT_FILE file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
while IFS=: read -r NSC2E_ADC_IP NSC2E_ADC_PORT
do
  echo "Now processing ADC at $NSC2E_ADC_IP on Port $NSC2E_ADC_PORT..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
  #Transfer tool and configuration to ADC
  echo "Transfering files to ADC..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$NSC2E_ADC_PASSWORD" scp -q -P $NSC2E_ADC_PORT ./nsc2e/nsc2e ./nsc2e/nsc2e.conf /scripts/nsc2e.sh $NSC2E_ADC_USER@$NSC2E_ADC_IP:$NEWNSLOG_PATH &>>$LOGFILE
  echo "Setting execute permissions on nsc2e..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$NSC2E_ADC_PASSWORD" ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell chmod 744 $NEWNSLOG_PATH/nsc2e.sh $NEWNSLOG_PATH/nsc2e" &>>$LOGFILE
  echo "Executing nsc2e remotely..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$NSC2E_ADC_PASSWORD" ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell /bin/sh $NEWNSLOG_PATH/nsc2e.sh" &>>$LOGFILE
  echo "Transferring data back to script host..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$NSC2E_ADC_PASSWORD" scp -q -P $NSC2E_ADC_PORT $NSC2E_ADC_USER@$NSC2E_ADC_IP:$NEWNSLOG_PATH/nsc2e.txt ./data/$(date '+%m%d%Y')-$NSC2E_ADC_IP.txt &>>$LOGFILE
  echo "Removing remote files and folders..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
  sshpass -p "$NSC2E_ADC_PASSWORD" ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell rm -rf $NEWNSLOG_PATH/nsc2e*" &>>$LOGFILE
  echo "Done processing $NSC2E_ADC_IP..." | ts '[%H:%M:%S]' | tee -a $LOGFILE
done < $INPUT
echo "All done..." | ts '[%H:%M:%S]' | tee -a $LOGFILE

do_cleanup