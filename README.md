# auto-nsc2e.sh
Author: Jeff Sani</br>
Contributors: Matt Drown</br>
Last Update: 5/27/2022</br>
Current Version: 1.1</br>

<img src="nsc2e.png" style="display:block; margin-left: auto; margin-right: auto;">
<strong>Description</strong></br>
This script automates data processing of all newnslog archives which is normally a tedious, manual process if you have many newnslog archives to process (normally up to 100 which is the default in nsagg.conf).  This script will automate the use of the nsc2e utility against a list of Citrix ADC devices and iterate through the current and archived newnslog files, process these in accord with the counters specified, and combine them to a single tab separated values file which is then downloaded to your script host for further processing.  nsc2e is an application which converts newnslog counter databases to a spreadsheet compatible tab delimited format so that data analysis can be performed more in-depthly.  It was developed back in the day by one of the orginal NetScaler devs - Jeff Xu.  Jeff if you are still out there, I hope this breathes new life into your much appreciated efforts.  nsc2e requires a conf file to indicate what specific counters should be processed as well as the target newnslog file to precess.  You can also specify filters for these if you desire to exclude data such as only data on a specific interface.  Some example conf files are included in the <a href="nsc2e/config-examples">nsc2e/config-examples</a> folder within this repo.  <p> ADC counter data is useful for a wide variety of applications such as historical usage, trending, or sizing.  The other benefit of this script is that you can schedule it to run on an interval so that you have historical data for each device stored in a central location.  By default, ADCs will purge newnslog archives once the file count is > 100. On a busy box, this might mean you only have a few days worth of sample data so you should adjust the script runtime  frequency accordingly if you want to get a full snapshot of data over a specific time interval.  A cron job creation option is available in the init script for the automated setup. If you were looking for information that would be useful for sizing a pooled license or SDX platform resource allocation, you might be interested in looking at the following set of counters for example:
</br></br>
<table>
  <tr><td colspan="2"><strong>Network</strong></td></tr>
  <tr><td>Newnslog Counter Name</td><td>Description</td></tr>
  <tr><td>allnic_tot_rx_mbits</td><td>Number of megabits received across all interfaces</td></tr>
  <tr><td>allnic_tot_rx_packets</td><td>Number of packets received all interfaces</td></tr>
  <tr><td>nic_err_rl_pkt_drops</td><td>Number of packets dropped due to platform license rate limit</td></tr>
  <tr><td colspan="2"><strong>CPU</strong></td></tr>
  <tr><td>Newnslog Counter Name</td><td>Description</td></tr>
  <tr><td>avg_cpu_usage_pcnt</td><td>This counter tracks the average CPU utilization percentage</td></tr>
  <tr><td>mgmt_cpu_usage_pcnt</td><td> 	This counter tracks the management CPU utilization percentage</td></tr>
  <tr><td>packet_cpu_usage_pcnt</td><td>This counter tracks the packet CPU utilization percentage</td></tr>
  <tr><td colspan="2"><strong>Memory</strong></td></tr>
  <tr><td>Newnslog Counter Name</td><td>Description</td></tr>
  <tr><td>mem_tot_MB</td><td>This counter tracks the total Main memory available for use by packet engine (PE), in megabytes</td></tr>
  <tr><td>mem_tot_use_MB</td><td>This counter tracks the total NetScaler Memory in use, in megabytes</td></tr>
  <tr><td>mem_usage_pcnt</td><td>This counter tracks the percentage of memory utilization on NetScaler</td></tr>
  <tr><td colspan="2"><strong>SSL</strong></td></tr>
  <tr><td>Newnslog Counter Name</td><td>Description</td></tr>
  <tr><td>ssl_tot_sslInfo_TotalTxCount</td><td>This counter tracks the number of SSL transactions on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_TotalSessionCount</td><td>This counter tracks the number of SSL sessions on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_SessionNew</td><td>This counter tracks the rate of new SSL sessions on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_KeyEx_RSA_2048</td><td>This counter tracks the number of RSA 2048-bit key exchanges on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_KeyEx_RSA_4096</td><td>This counter tracks the number of RSA 4096-bit key exchanges on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_KeyEx_ECDHE</td><td>This counter tracks the number of ECDHE key exchanges on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_Auth_RSA</td><td>This counter tracks the number of RSA authentications on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_Cipher_AES_256</td><td>This counter tracks the number of AES 256-bit cipher encryption on the NetScaler appliance</td></tr>
  <tr><td>ssl_cur_q_size</td><td>This counter tracks the current queue size</td></tr>
  <tr><td colspan="2"><strong>HTTP</strong></td></tr>
  <tr><td>Newnslog Counter Name</td><td>Description</td></tr>
  <tr><td>http_tot_Requests</td><td>This counter tracks HTTP requests received</td></tr>
  <tr><td>http_tot_Responses</td><td>This counter tracks HTTP responses sent</td></tr>
  <tr><td>http_tot_rxRequestBytes</td><td>This counter tracks the bytes of HTTP data received</td></tr>
  <tr><td>http_tot_rxResponseBytes</td><td>This counter tracks the bytes received as response data</td></tr>
</table>

You can learn about the specific counters available on ADC <a href="https://support.citrix.com/search/#/All%20Products?ct=All%20types&searchText=adc%20counters&sortBy=Relevance&pageIndex=1" target="_blank">here</a>. Note - Be aware that the more counters you specify in the configuration file, the longer it will take to execute the data extraction, processing, and overall script runtime will increase.  It is also recommended to run this utility script during a maintenance window or non-peak usage times as there will be a consistent load applied to the ADC management core which may impact mangement access and other related dataplane functions.

<strong>Automated Setup Steps (For CentOS/Fedora or Ubuntu Linux Host)</strong></br>
<ol type="1">
   <li>Login to your host as the user you want to create the script under</li>
   <li>Install the required Linux packages or follow this prompt in the init script</li>
   <li>Clone the repo into the desired directory on your linux host:</li>
      <ul><li>git clone https://github.com/jeffsani/auto-nsc2e.git</li></ul>
   <li>cd to auto-nsc2e/scripts</li>
   <li>manually populate the adc-list.txt file with the ADCs you want to extract data from (NSIP or SNIP with Management enabled)</li>   
   <li>Run the auto-nsc2e-init.sh script</li>
   <li>Run the auto-nsc2e.sh script</li>
</ol>

<strong>Script Requirements</strong></br>
To implement this script you will need the following if you plan to implement manually and not use the init script:
<ol type="1">
  <li>A Linux host to run the script on</li>
  <li>Citrix ADC Build Version 12.1, 13.0, or 13.1 (It may work on older builds as well but I did not test those and they are EOL)</li>
  <li>A Linux host to run the script on</li>
  <li>Populate adc-list.txt with the list of the ADCs that you would like to iterate through</li>
    <ol>Entries should be input per line with IP and Port in the format: X.X.X.X:NNN</ol>
    <ol>ADC IP addresses should be accessible to script host and have management enabled (specifically SSH)</ol>
  <li>A username and password that will work for each ADC device</li>
   <li>Required Linux Packages:</li>
       <ul>
          <li>Debian/Ubuntu: git sshpass moreutils</li>
          <li>CentOS/Fedora: git sshpass more-utils</li>
       </ul>
   <li>Environment variables set for the user running the script that contain the Citrix ADC user/pass</li>
   <li>Optional cron job to schedule the script run on an optimal interval</li>
</ol>

<strong>Required Environment Variables</strong></br>
The following variables and their respective values are required at script runtime:
<ul>
   <li>NSC2E_ADC_USER=XXX</li>
   <li>NSC2E_ADC_PASSWORD=XXX</li>
</ul>

You can run the init script which will set these for you or create manually

<strong>ADC Service Account and Command Policy</strong></br>
It is optional but recommended to create a service account on ADC to use for the purposes of running this script in lieu of just using nsroot:  

<code>add system cmdPolicy auto-nsc2e_cmdpol ALLOW "^(shell).\*mkdir\\s/var/tmp/nsc2e-tmp|^(scp).\*/var/tmp/nsc2e-tmp/\*|^(shell).\*chmod\\s744\\s/var/tmp/nsc2e-tmp/nsc2e.sh\\s/var/tmp/nsc2e-tmp/nsc2e|^(shella).\*bash\\s/var/tmp/nsc2e-tmp/nsc2e.sh|^(shell).\*rm\\s-rf\\s/var/tmp/nsc2e-tmp"</code></br>
<code>add system user auto-nsc2e -timeout 1800 -maxsession 2 -allowedManagementInterface CLI</code></br>
<code>bind system user auto-nsc2e auto-nsc2e_cmdpol 100</code>
</br></br>
<strong>Note:</strong> On 12.1 systems omit the "-allowedManagementInterface CLI" parameter as that is not supported