
# Cron Service to Block Tor Clients

This is a cron-service that blocks all Tor users from accessing your server. Made for systems that support iptables.

The cron-service.sh script accepts an arbitrary number of arguments. Each positional argument is a port number that you want query for Tor IPs to block. You must specify at least one. For example, the following specifies port 80 and 6667:

    /root/block-tor-iptables/cron-service.sh 80 6667

If you are unfamiliar with cron, you may read about it:
*   http://en.wikipedia.org/wiki/Cron
*   http://www.adminschoice.com/crontab-quick-reference

# Notes
*   The script must be run as root. On Ubuntu, if you add it to your crontab as root with ``crontab -e``, it is necessary to prefix the command with "sudo", for some  reason.
*   The script analyzes the 'eth0' network interface to obtain your IP address, which is required to query the tor bulk exit list. If your network interface is not 'eth0' (perhaps you are running on wlan0, eth1, avian0), then edit the script.

## Credits
The code was derived from:
   http://www.brianhare.com/wordpress/2011/03/02/block-tor-exit-nodes-using-bash-script/
