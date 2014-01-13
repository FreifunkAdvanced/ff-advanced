#!/bin/sh
# By CyrusFox -> lcb01@jabber.ccc.de

ffdef_set_interface_adhoc() {
	local ifname=$1
	uci batch <<EOF
set network.adhoc='interface'
set network.adhoc.proto='batadv'
set network.adhoc.mesh='bat0'
set network.adhoc.auto='1'
add network device
set network.@device[-1].name='$ifname'
set network.@device[-1].mtu='1518'
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
set network.$meshwan_iface='interface'
set network.$meshwan_iface.proto='dhcp'
set network.$meshwan_iface.ifname='br-mesh'
set network.$meshwan_iface.auto='0'
set network.$meshwan_iponly_iface='interface'
set network.$meshwan_iponly_iface.proto='dhcp'
set network.$meshwan_iponly_iface.ifname='br-mesh'
set network.$meshwan_iponly_iface.defaultroute='0'
set network.$meshwan_iponly_iface.peerdns='0'
set network.$meshwan_iponly_iface.auto='0'
EOF
	ffdef_set_interface_adhoc $adhoc_dev
}

ffdef_add_interface_meshvpn() {
	uci batch <<EOF
set network.mesh_vpn='interface'
set network.mesh_vpn.proto='batadv'
set network.mesh_vpn.ifname='mesh-vpn'
set network.mesh_vpn.mesh='bat0'
set network.mesh_vpn.auto='1'
set network.mesh_vpn.mesh_no_rebroadcast='1'
EOF
}

ffdef_add_interface_batmanport() {
	local interface=$1
	local ifname=$2
	uci batch <<EOF
set network.$interface='interface'
set network.$interface.proto='batadv'
set network.$interface.ifname='$ifname'
set network.$interface.mesh='bat0'
set network.$interface.auto='1'
EOF
}
