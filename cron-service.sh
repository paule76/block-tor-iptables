#!/bin/bash

readonly CHAIN_NAME="TOR"
readonly TMP_TOR_LIST="/tmp/temp_tor_list"
readonly IP_ADDRESS=$(ifconfig eth0 | awk '/inet addr/ {split ($2,A,":"); print A[2]}')

if [ "$1" == "" ]; then
    echo "$0 port [port [port [...]]]"
    echo
    echo "First, you must manually create the iptable:"
    echo "  iptables -N $CHAIN_NAME"
    echo "  iptables -I INPUT 1 -j $CHAIN_NAME"
    exit 1
fi 


# Create tor chain if it doesn't exist. This is basically a grouping of
# filters within iptables.
if ! iptables -L "$CHAIN_NAME" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME" >/dev/null 2>&1
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



