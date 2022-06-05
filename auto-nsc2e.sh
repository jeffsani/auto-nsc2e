#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to excel format across a set of ADCs

set -o pipefail

#Variables
NEWNSLOG_PATH="/var/nslog"
LOGFILE="./log/$(date '+%m%d%Y')-auto-nsc2e.log"
DATADIR="./data"

#Cleanup function
function do_cleanup {
echo "Searching for old logs > 30 days and removing them..."
find ./log/*.log -not -name '*auto-nsc2e-init.log' -mtime +30 -delete
echo "Searching for old data files > 180 days and removing them..."
find ./data/*.tsv -mtime +180 -delete
echo "Cleanup completed..."
}

(
#Start Logging
echo "User $(whoami) started the script"
echo "Starting auto-nsc2e Log..."

# Load #Load common variables from conf and check vars to see if one of the required environment variables is not set
. .auto-nsc2e.conf
if [[ -z "$NSC2E_ADC_USER" || -z "$NSC2E_ADC_PASSWORD" || -z "$SSHPASS" ]]; then
    echo "One or more of the required environment variables for the script is not set properly, please run the init script or edit .auto-nsc2e.conf..."
    exit 1;
fi

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT="adc-list.txt"
[ ! -f $INPUT ] && { echo "$INPUT file not found..."; exit 99; }
while IFS=":" read -r NSC2E_ADC_IP NSC2E_ADC_PORT
do
  echo "Now processing ADC at $NSC2E_ADC_IP on Port $NSC2E_ADC_PORT..."
  #Transfer tool and configuration to ADC
  echo "Transfering files to ADC..."
  sshpass -e scp -q -P $NSC2E_ADC_PORT ./bin/nsc2e ./bin/nsc2e.conf ./scripts/nsc2e.sh $NSC2E_ADC_USER@$NSC2E_ADC_IP:$NEWNSLOG_PATH < /dev/null
  echo "Setting execute permissions on nsc2e and nsc2e.sh..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell chmod 744 $NEWNSLOG_PATH/nsc2e.sh $NEWNSLOG_PATH/nsc2e" < /dev/null
  echo "Executing nsc2e remotely..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell bash $NEWNSLOG_PATH/nsc2e.sh" < /dev/null
  echo "Transferring data back to script host..."
  sshpass -e scp -q -P $NSC2E_ADC_PORT $NSC2E_ADC_USER@$NSC2E_ADC_IP:$NEWNSLOG_PATH/nsc2e.txt "$DATADIR/$(date '+%m%d%Y')-$NSC2E_ADC_IP.tsv" < /dev/null
  echo "Removing remote files and folders..."
  sshpass -e ssh -q $NSC2E_ADC_USER@$NSC2E_ADC_IP -p $NSC2E_ADC_PORT "shell rm -rf $NEWNSLOG_PATH/nsc2e*" < /dev/null
  echo "Done processing $NSC2E_ADC_IP..."
done < $INPUT
echo "All done..."

do_cleanup
>> $LOGFILE) 2>&1 | ts '[%H:%M:%S]' | tee -a $LOGFILE