# auto-nsc2e.sh
author: Jeff Sani
current version: 1.0

<h1>Description</h1>
nsc2e is a utility application which converts Citrix ADC newnslog counter databases to Excel format so that data analysis can be performed more in-depthly.  The tool takes a conf file input to indicate what specific counters should be processed as well as the target newnslog file to precess.  Some common counter sets include:

<strong>Network</strong>
<table>
  <th>Newnslog Counter Name</th><th>Description</th>
  <tr><td>nic_tot_rx_mbits</td><td>Number of megabits received by this interface</td></tr>
  <tr><td>nic_tot_tx_mbits</td><td>Number of megabits transmitted by this interface</td></tr>
</table>
	



CPU

Memory

Disk

LB

SSL

You can learn about the specific counters available on ADC here - https://support.citrix.com/search/#/All%20Products?ct=All%20types&searchText=adc%20counters&sortBy=Relevance&pageIndex=1.  Note: ADC counters are not synonymous with SNMP counters. While some are represented as SNMP counters, not all of them are.

What the tool does not do is automate the processing of all the newnslog files making this a tedious process if you have many newnslog archives to process (normally up to 100).  This script will automate the use of the tool against a list of ADC devices and iterate through the current newnslog and all archived files, process these in accord with the counters specified, and download them to your host.

Requirements:
- a Linux host to run the script on

Required Packages
-sshpass
