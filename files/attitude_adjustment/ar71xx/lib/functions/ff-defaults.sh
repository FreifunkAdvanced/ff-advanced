#!/bin/sh
# By DocFox -> lcb01@jabber.ccc.de

ffdef_set_interface_adhoc() {
	local ifname=$1
	uci batch <<EOF
set network.adhoc='interface'
set network.adhoc.proto='batadv'
set network.adhoc.mesh='bat0'
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
EOF
}

ffdev_set_interface_mesh_settings() {
	. /etc/defconfig/ffpreconfigure
	uci batch <<EOF
set network.meshfsm='interface'
set network.meshfsm.proto='fsm'
set network.meshfsm.ifname='br-mesh'
set network.meshfsm.net_robinson='$net_robinson'
set network.meshfsm.net_fake='$net_fake'
set network.meshfsm.net_mesh='$net_mesh'
set network.meshfsm.net_ip6ula='$net_ip6ula'
set network.meshfsm.batman_iface='$batman_iface'
set network.meshfsm.fsm_list='$fsm_list'
set network.meshfsm.gossip_list='$gossip_list'
set network.meshfsm.community_name='$community_name'
set network.meshfsm.auto='1'
EOF
}

