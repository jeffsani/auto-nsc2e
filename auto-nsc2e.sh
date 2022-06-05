#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to TSV format across a set of ADCs

set -o pipefail

#Setting ariables
WORKINGDIR="/var/tmp"
LOGFILE="./log/$(date '+%m%d%Y')-auto-nsc2e.log"
DATADIR="./data"
NSC2E_CONF=~/.adcrc

#Cleanup function
function do_cleanup {
echo "Searching for old logs > 30 days and removing them..."
find ./log/*.log -not -name '*auto-nsc2e-init.log' -mtime +30 -delete
echo "Searching for old data files > 180 days and removing them..."
find ./data/*.tsv.gz -mtime +180 -delete
echo "Cleanup completed..."
}

(
#Start Logging
echo "User $(whoami) started the script"
echo "Starting auto-nsc2e Log..."

# Load #Load common variables from conf and check vars to see if one of the required environment variables is not set
. $NSC2E_CONF
if [[ -z "$NSC2E_ADC_USER" || -z "$NSC2E_ADC_PASSWORD" ]]; then
    echo "One or more of the required environment variables for the script is not set properly, exiting..."
    exit 1;
else
  #Set SSHPASS var for automation
  export SSHPASS="$NSC2E_ADC_PASSWORD"
fi

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT file not found..."; exit 99; }
while IFS=":" read -r NSC2E_ADC_IP NSC2E_ADC_PORT
do
  echo "Now processing ADC at $NSC2E_ADC_IP on Port $NSC2E_ADC_PORT..."
  #Transfer tool and configuration to ADC
  echo "Transfering files to ADC..."
  sshpass -e scp -q -P $NSC2E_ADC_PORT ./bin/nsc2e ./bin/nsc2e.conf ./scripts/nsc2e.sh $NSC2E_ADC_USER@$NSC2E_ADC_IP:$WORKINGDIR < /dev/null
  echo "Setting execute permissions on nsc2e and nsc2e.sh..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell chmod 744 $WORKINGDIR/nsc2e.sh $WORKINGDIR/nsc2e" < /dev/null
  echo "Executing nsc2e remotely..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell bash $WORKINGDIR/nsc2e.sh" < /dev/null
  echo "Transferring data back to script host..."
  sshpass -e scp -q -P $NSC2E_ADC_PORT $NSC2E_ADC_USER@$NSC2E_ADC_IP:$WORKINGDIR/nsc2e.tsv.gz "$DATADIR/$(date '+%m%d%Y')-$NSC2E_ADC_IP.tsv.gz" < /dev/null
  echo "Removing remote files and folders..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell rm -rf $WORKINGDIR/nsc2e*" < /dev/null
  echo "Done processing $NSC2E_ADC_IP..."
done < $INPUT
echo "All done..."

do_cleanup
>> $LOGFILE) 2>&1 | ts '[%H:%M:%S]' | tee -a $LOGFILE