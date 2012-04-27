#!/bin/sh
# By DocFox -> lcb01@jabber.ccc.de

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

ffdef_add_batman_port {
	local interface=$1
	local ifname=$2
	uci batch <<EOF
set network.$interface='interface'
set network.$interface.ifname='$ifname'
set network.$interface.mtu='1528'
set network.$interface.proto='none'
set network.$interface.auto='1'
add_list batman-adv.bat0.interfaces='$ifname'
EOF
}

