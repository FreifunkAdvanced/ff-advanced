#!/bin/sh
 
HOSTNAME="${COLLECTD_HOSTNAME:-`cat /proc/sys/kernel/hostname`}"
INTERVAL="${COLLECTD_INTERVAL:-10}"

ifacecount=$(cat /etc/config/wireless  | grep wifi-iface | wc -l )
case $ifacecount in 
	3)
	ADHOCIF="wlan0-2"
	;;
	*)
	ADHOCIF="wlan0-1"
	;;
esac

while sleep "$INTERVAL"
do
 
mesh_peers=$(cat /sys/kernel/debug/batman_adv/bat0/originators | grep $ADHOCIF | cut -f1 -d' ' | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | wc -l)
n2n_peers=$(cat /sys/kernel/debug/batman_adv/bat0/originators | grep n2n1 | cut -f1 -d' ' | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | wc -l)
connected_clients=$(iw dev wlan0 station dump |grep Station | wc -l)
dhcp_leases=$(cat /tmp/dhcp.leases |wc -l)

echo "PUTVAL $HOSTNAME/mesh/mesh_peers interval=$INTERVAL N:$mesh_peers"
echo "PUTVAL $HOSTNAME/mesh/n2n_peers interval=$INTERVAL N:$n2n_peers"
echo "PUTVAL $HOSTNAME/mesh/connected_clients interval=$INTERVAL N:$connected_clients"
echo "PUTVAL $HOSTNAME/mesh/dhcp_leases interval=$INTERVAL N:$dhcp_leases"
 
done
