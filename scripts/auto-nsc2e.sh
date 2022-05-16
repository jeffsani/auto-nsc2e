#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to excel format across a set of ADCs

Variables
#newnslog location on ADC
NEWNSLOG_PATH="/var/nslog"
LOGFILE="$(date '+%m%d%Y')-auto-nsc2e.log"

#Cleanup function
function do_cleanup {
echo "Searching for old logs > 30 days and removing them..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
find *.log -type f -not -name '*auto-nsc2e-init.log' -mtime -30 -delete
}

#Start Logging
echo "User $(whoami) started the script" | ts '[%H:%M:%S]' | tee -a $LOGFILE;
echo "Starting auto-nsc2e Log..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;

# Check to see if one of the required environment variables for the script is not set
source ~/.bashrc
if [[ -z "${CITRIX_ADC_USER}" || -z "${CITRIX_ADC_PASSWORD}" ]]; then
    echo "One or more of the required environment variables for the script is not set properly..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
    exit 1;
fi

#Loop through each ADC in adc-list.txt and process newnslog data with nsc2e
INPUT_FILE="./adc-list.txt"
[ ! -f $INPUT_FILE ] && { echo "$INPUT file not found..." | ts '[%H:%M:%S]' | tee -a $LOGFILE; exit 99; }
while IFS=":", read -r CITRIX_ADC_IP CITRIX_ADC_PORT
echo "Now processing ADC: $CITRIX_ADC_IP"
do
   #Transfer tool and configuration to ADC
   echo "Transfering files to ADC..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
   sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT ./nsc2e/* /scripts/nsc2e.sh $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH;
   #Setting execute permissions on nsc2e files
   echo "Setting execute permissions on nsc2e..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
   sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell chmod 744 /$(NEWNSLOG_PATH)/nsc2e.sh /$(NEWNSLOG_PATH)/nsc2e";
   #Exexcute the nsc2e script on the remote ADC
   echo "Executing nsc2e remotely..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
   sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell /$(NEWNSLOG_PATH)/nsc2e.sh";
   #Transfer data files back to host
   echo "Transferring data back to script host..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
   sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH/nsc2e.txt* ./$(date '+%m%d%Y')-$(CITRIX_ADC_IP).txt;
   #Cleanup remote folders and files
   echo "Removing remote files and folders..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
   sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell rm -rf /$(NEWNSLOG_PATH)/nsc2e*";
   echo "Done processing $CITRIX_ADC_IP..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
done < "$INPUT_FILE"
echo "All done..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;

do_cleanup