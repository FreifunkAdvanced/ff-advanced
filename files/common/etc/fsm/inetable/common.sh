cloud_is_online () {
    # look for mac addrs in batman gateway list
    batctl gwl | tail -n-1 | egrep -q '([0-9a-f]{2}:){5}[0-9a-f]{2}'
}

## add/remove IPv4 address from mesh iface
# manual update to avoid full ifdown+ifup, but update uci state for
# other users (e.g. dnsmasq)
mesh_add_ipv4 () {
    ifconfig br-mesh $1 netmask $2
    echo "
set network.mesh.ipaddr=$1
set network.mesh.proto=static
set network.mesh.netmask=$2
" | uci batch
}

mesh_del_ipv4 () {
    ifconfig br-mesh 0.0.0.0
    echo "
delete network.mesh.ipaddr
delete network.mesh.proto
delete network.mesh.netmask
" | uci batch
}
