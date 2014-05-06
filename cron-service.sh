#!/bin/bash

if [ "$USER" != "root" ]; then
    echo "Must be run as root (you are $USER)."
    exit 1
fi

if [ "$1" == "" ]; then
    echo "$0 port [port [port [...]]]"
    exit 1
fi 

CHAIN_NAME="INPUT"
TMP_TOR_LIST="/tmp/temp_tor_list"
IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

# Create tor chain if it doesn't exist. This is basically a grouping of
# filters within iptables.
if ! iptables -L "$CHAIN_NAME" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME" >/dev/null 2>&1
fi

# Download the exist list from the tor project, build the temp file. Also
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

for IP in $(cat $TMP_TOR_LIST | uniq | sort)
do
    iptables -A $CHAIN_NAME -s $IP -j DROP
done

iptables-save



