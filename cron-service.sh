#!/bin/bash

readonly CHAIN_NAME="TOR"
readonly TMP_TOR_LIST="/tmp/temp_tor_list"
# get external IP in private lan
readonly IP_ADDRESS=$(wget -q -O - "http://canihazip.com/s" -U NoSuchBrowser/1.0)
#	Which chain 
#       INPUT for webserver
#       FORWARD for webserver
readonly CHAIN='INPUT'
#readonly CHAIN='FORWARD'

if [ "$1" == "" ]; then
    echo "$0 port [port [port [...]]]"
    exit 1
fi 


# Create tor chain if it doesn't exist. This is basically a grouping of
# filters within iptables.
if ! iptables -L "$CHAIN_NAME" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME" >/dev/null 2>&1
fi
# Create $CHAIN_NAME Rule in $CHAIN
if ! iptables -L "$CHAIN" -n |grep "$CHAIN_NAME" >/dev/null 2>&1 ; then
    iptables -I "$CHAIN" 1 -j "$CHAIN_NAME" >/dev/null 2>&1
fi

# Download the exit list from the tor project, build the temp file. Also
# filter out any commented (#) lines.
rm -f $TMP_TOR_LIST
touch $TMP_TOR_LIST

for PORT in "$@"
do
    wget -q -O - "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$IP_ADDRESS&port=$PORT" -U NoSuchBrowser/1.0 >> $TMP_TOR_LIST
    echo >> $TMP_TOR_LIST
done

sed -i 's|^#.*$||g' $TMP_TOR_LIST

# Block the contents of the list in iptables
iptables -F $CHAIN_NAME

for IP in $(cat $TMP_TOR_LIST | sort -u)
do
    iptables -A $CHAIN_NAME -s $IP -j DROP
done

iptables-save
