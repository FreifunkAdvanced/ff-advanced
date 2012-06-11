#!/bin/sh
# By DocFox -> lcb01@jabber.ccc.de

ffdef_set_interface_adhoc() {
	local ifname=$1
	uci batch <<EOF
set network.adhoc='interface'
set network.adhoc.proto='none'
set network.adhoc.auto='1'
add network device
set network.@device[-1].name='$ifname'
set network.@device[-1].mtu='1528'
set network.@device[-1].type='ethernet'
EOF
}

ffdef_set_interface_mesh() {
	local ifname=$1
	uci batch <<EOF
set network.mesh.ifname='bat0 $ifname'
EOF
}

ffdef_add_interface_mesh() {
	uci batch <<EOF
set network.mesh='interface'
set network.mesh.ifname='bat0'
set network.mesh.type='bridge'
set network.mesh.proto='none'
set network.mesh.auto='1'
}

