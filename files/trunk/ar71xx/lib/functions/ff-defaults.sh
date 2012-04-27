#!/bin/sh
# By DocFox -> lcb01@jabber.ccc.de

ffdef_set_interface_wlan() {
	local ifname=$1
	uci batch <<EOF
set network.wlan='interface'
set network.wlan.ifname='$ifname'
set network.wlan.mtu='1528'
set network.wlan.proto='none'
set network.wlan.auto='1'
EOF
}

ffdef_set_interface_mesh() {
	local ifname=$1
	uci batch <<EOF
set network.mesh='interface'
set network.mesh.ifname='bat0 $ifname'
set network.mesh.type='bridge'
set network.mesh.proto='none'
set network.mesh.auto='1'
EOF
}


