#!/bin/bash

if [ "$1" == "" ]; then
    echo "$0 port [port [port [...]]]"
    exit 1
fi
 
IPTABLES_TARGET="DROP"
IPTABLES_CHAINNAME="TOR"
TMP_TOR_LIST="/tmp/temp_tor_list"
IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')  # eth0 specific

# Create the iptables chain if it doesn't exist 
if [ ! iptables -L "$IPTABLES_CHAINNAME" -n >/dev/null 2>&1 ]
then
    iptables -N "$IPTABLES_CHAINNAME" >/dev/null 2>&1
fi

# Download the exist list from the tor project, build the temp file. Also
# filter out any commented (#) lines.
rm $TMP_TOR_LIST
touch $TMP_TOR_LIST
for port in "$@"
do
    wget -q -O - "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$IP_ADDRESS&port=$port" -U NoSuchBrowser/1.0 >> $TMP_TOR_LIST
    echo >> $TMP_TOR_LIST
done

sed -i 's|^#.*$||g' $TMP_TOR_LIST


# Block the contents of the list in top

 
iptables -F "$IPTABLES_CHAINNAME"
 
for IP in $(cat $TMP_TOR_LIST | uniq | sort)
do
    iptables -A "$IPTABLES_CHAINNAME" -s $IP -j $IPTABLES_TARGET
done
 
iptables -A "$IPTABLES_CHAINNAME" -j RETURN
 

