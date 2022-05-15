# auto-nsc2e.sh
author: Jeff Sani
current version: 1.0

<h2>Description</h2>
nsc2e is a utility application which converts Citrix ADC newnslog counter databases to Excel format so that data analysis can be performed more in-depthly.  It was developed back in the day by Jeff Xu.  Jeff if you are still out there, I hope this breathes new life into your much appreciated effort.  The tool takes a conf file input to indicate what specific counters should be processed as well as the target newnslog file to precess.  You can also specify filters for these if you desire to exclude data.  Some example conf files are included in the repo.  ADC counter data is useful for a wide variety of applications such as historical usage, trending, or sizing.  If you were looking for information that would be useful for sizing a pooled license or SDX platform resource allocation, you might be interested in looking at the following set of counters for example:
</br>
<table>
  <tr><td><h3>Network</h3></td></tr>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>allnic_tot_rx_mbits</td><td>Number of megabits received across all interfaces</td></tr>
  <tr><td>allnic_tot_tx_mbits</td><td>Number of megabits transmitted across all interfaces</td></tr>
  <tr><td>allnic_tot_rx_packets</td><td>Number of packets received all interfaces</td></tr>
  <tr><td>nic_err_rl_pkt_drops</td><td>Number of packets dropped due to platform license rate limit</td></tr>
  <tr><td colspan="2"><h3>CPU</h3></td></tr>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>avg_cpu_usage_pcnt</td><td>This counter tracks the average CPU utilization percentage</td></tr>
  <tr><td>mgmt_cpu_usage_pcnt</td><td> 	This counter tracks the management CPU utilization percentage</td></tr>
  <tr><td>packet_cpu_usage_pcnt</td><td>This counter tracks the packet CPU utilization percentage</td></tr>
  <tr><td colspan="2"><h3>Memory</h3></td></tr>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>mem_tot_MB</td><td>This counter tracks the total Main memory available for use by packet engine (PE), in megabytes</td></tr>
  <tr><td>mem_tot_use_MB</td><td>This counter tracks the total NetScaler Memory in use, in megabytes</td></tr>
  <tr><td>mem_usage_pcnt</td><td>This counter tracks the percentage of memory utilization on NetScaler</td></tr>
  <tr><td colspan="2"><h3>SSL</strong></h3></tr>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>ssl_tot_sslInfo_TotalTxCount</td><td>This counter tracks the number of SSL transactions on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_TotalSessionCount</td><td>This counter tracks the number of SSL sessions on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_SessionNew</td><td>This counter tracks the rate of new SSL sessions on the NetScaler appliance</td></tr> 
  <tr><td>ssl_tot_sslInfo_Auth_RSA</td><td>This counter tracks the number of RSA authentications on the NetScaler appliance</td></tr>
  <tr><td>ssl_tot_sslInfo_Cipher_AES_256</td><td>This counter tracks the number of AES 256-bit cipher encryption on the NetScaler appliance.</td></tr>
  <tr><td>ssl_cur_q_size</td><td>This counter tracks the current queue size</td></tr>
  <tr><td colspan="2"><h3>HTTP</h3></td></tr>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>http_tot_Requests</td><td>This counter tracks HTTP requests received</td></tr>
  <tr><td>http_tot_Responses</td><td>This counter tracks HTTP responses sent</td></tr>
  <tr><td>http_tot_rxRequestBytes</td><td>This counter tracks the bytes of HTTP data received</td></tr>
  <tr><td>http_tot_rxResponseBytes</td><td>This counter tracks the bytes received as response data</td></tr>
</table>

You can learn about the specific counters available on ADC here - https://support.citrix.com/search/#/All%20Products?ct=All%20types&searchText=adc%20counters&sortBy=Relevance&pageIndex=1.  Note: ADC counters are not synonymous with SNMP counters. While some are represented as SNMP counters, not all of them are.  Be aware that the more counters you specify in the configuration file, the longer it will take to execute the data extraction and overall script runtime will increase.

What the tool does not do is automate the processing of all the newnslog files making this a tedious process if you have many newnslog archives to process (normally up to 100).  This script will automate the use of the tool against a list of ADC devices and iterate through the current newnslog and all archived files, process these in accord with the counters specified in the configuration file, combine them to a single file, and then download the resultant file to your host for further processing.

<h2>Requirements:</h2>
- a Linux host to run the script on
- a list of the ADCs that you would like to iterate through
- a username and password that will work for each device

<h3>Required Packages:</h3>
-sshpass
