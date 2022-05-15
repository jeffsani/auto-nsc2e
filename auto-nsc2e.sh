#!/bin/bash
# auto-nsc2e.sh
# This script will automate nsc2e to extract and convert specific newnslog counter data to excel format across a set of ADCs

Variables
#newnslog location on ADC
NEWNSLOG_PATH="/var/nslog"
RM_NSC2E_TOOL="yes"
LOGFILE="$(date '+%m%d%Y')-auto-nsc2e.log"

#Do Cleanup function
function do_cleanup {
echo "Cleaning up disposable files..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
rm -f *.csv* *.txt *.zip* Citrix_Netscaler_InBuilt_GeoIP_DB_IPv4 Citrix_Netscaler_InBuilt_GeoIP_DB_IPv6
echo "Searching for old logs > 30 days and removing them..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
find *.log -type f -not -name '*mmgeoip2adc-init.log' -mtime -30 -delete
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



#Transfer tool and configuration to ADC
echo "Transfering files to ADC..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT nsc2e* $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH;
#Setting execute permissions on nsc2e files
echo "Setting execute permissions on nsc2e..." | ts '[%H:%M:%S]' | tee -a $LOGFILE;
sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell chmod 744 /$(NEWNSLOG_PATH)/nsc2e*";
#Exexcute the nsc2e script on the remote ADC
sshpass -p "$CITRIX_ADC_PASSWORD" ssh -q $CITRIX_ADC_USER@$CITRIX_ADC_IP -p $CITRIX_ADC_PORT "shell /$(NEWNSLOG_PATH)/nsc2e.sh";
#transfer data files back to host
sshpass -p "$CITRIX_ADC_PASSWORD" scp -q -P $CITRIX_ADC_PORT nsc2e* $CITRIX_ADC_USER@$CITRIX_ADC_IP:$NEWNSLOG_PATH;
#
#cleanup
rm -rf nsc2e
find newnslog.* -type d -mtime -30 -delete