# auto-nsc2e.sh
author: Jeff Sani</br>
Latest Update: 5/19/2022</br>
current version: 1.0</br>

<img src="nsc2e.png" style="display:block; margin-left: auto; margin-right: auto;">
<strong>Description</strong></br>
This script automates data processing of all newnslog archives which is normally a tedious, manual process if you have many newnslog archives to process (normally up to 100 which is the default in nsagg.conf).  This script will automate the use of the nsc2e utility against a list of ADC devices and iterate through the current newnslog and all archived files, process these in accord with the counters specified in the configuration file, combine them to a single file, and then download the resultant files to your host for further processing.  nsc2e is an application which converts Citrix ADC newnslog counter databases to Excel format so that data analysis can be performed more in-depthly.  It was developed back in the day by one of the orginal NetScaler devs - Jeff Xu.  Jeff if you are still out there, I hope this breathes new life into your much appreciated efforts.  The tool takes a conf file input to indicate what specific counters should be processed as well as the target newnslog file to precess.  You can also specify filters for these if you desire to exclude data.  Some example conf files are included in the <a href="nsc2e/config-examples">nsc2e/config-examples</a> repo folder.  ADC counter data is useful for a wide variety of applications such as historical usage, trending, or sizing.  The other benefit of this script is that you can schedule it to run on an interval so that you have historical data for each device.  By default, ADCs will purge newnslog archives once the file count is > 100. On a busy box, this might mean you only have a few days worth of sample data so you should adjuste the script frequency accordingly. If you were looking for information that would be useful for sizing a pooled license or SDX platform resource allocation, you might be interested in looking at the following set of counters for example:
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
  <tr><td>ssl_tot_sslInfo_Auth_RSA</td><td>This counter tracks the number of RSA authentications on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_Cipher_AES_256</td><td>This counter tracks the number of AES 256-bit cipher encryption on the NetScaler appliance.</td></tr>
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
  <li>Populate adc-list.txt with the list of the ADCs that you would like to iterate through</li>
    <ol>Entries should be input per line with IP and Port in the format: X.X.X.X:NNN</ol>
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
The following variables and their respective values are required at script runtime so it is suggested they be stored in .bashrc
<ul>
   <li>CITRIX_ADC_USER=XXX</li>
   <li>CITRIX_ADC_PASSWORD=XXX</li>
</ul>

<strong>ADC Service Account and Command Policy</strong></br>
It is optional but recommended to create a service account on ADC to use for the purposes of running this script in lieu of just using nsroot:  

<code>add system cmdPolicy nsc2e_cmdpol ALLOW "(^(scp).*/var/netscaler/inbuilt_db*)|(^add\\s+(locationFile|locationFile6))|(^add\\s+(locationFile|locationFile6)\\s+.*)|(^save\\s+ns\\s+config)|(^save\\s+ns\\s+config\\s+.*)"</code></br>
<code>add system user geoip2adc -timeout 900 -maxsession 1 -allowedManagementInterface CLI</code></br>
<code>set system user geoip2adc -password XXXXXX</code></br>
<code>bind system user geoip2adc geoip2adc_cmdpol 100</code>