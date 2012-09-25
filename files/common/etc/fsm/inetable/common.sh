cloud_is_online () {
    # look for mac addrs in batman gateway list
    batctl gwl | tail -n-1 | egrep -q '([0-9a-f]{2}:){5}[0-9a-f]{2}'
}

## add/remove IPv4/IPv6 address from mesh iface
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
delete network.mesh.netmask
" | uci batch
    if [ "$(uci -q get network.mesh.ip6addr)" == "" ]; then
	uci set network.mesh.proto=none
    fi
}

mesh_add_ipv6 () {
    ifconfig br-mesh add $1
    echo "
set network.mesh.ip6addr=$1
set network.mesh.proto=static
" | uci batch
}

mesh_del_ipv6() {
    ifconfig br-mesh del $1
    echo "
delete network.mesh.ip6addr
" | uci batch
    if [ "$(uci -q get network.mesh.ipaddr)" == "" ]; then
        uci set network.mesh.proto=none
    fi
}

# enable/disable uhttpd instance in uci config; the parameters are
# 1. instance name
enable_httpd () {
    uci set uhttpd.$1=uhttpd
}

disable_httpd () {
    uci set uhttpd.$1=disabled
}
