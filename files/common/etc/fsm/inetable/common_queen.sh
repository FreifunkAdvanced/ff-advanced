# functions that are allowed to be called if we are in the queen or
# ghost state

gwiptbl=/tmp/p2ptbl/gwip
DHCPLeaseTime=$((12 * 3600))

NodeId="$(cat /etc/nodeid)"
oct3=$(ifconfig br-mesh | egrep -o 'inet addr:[0-9.]*'|cut -f3 -d.)
[ -n "$oct3" ]
gwip=$(ipcalc.sh "$(uci get cloud.cur.net_mesh)" $(($oct3 * 256 + 1)) 1 \
     | grep ^START | cut -f2 -d=)

we_own_our_ip () {
    [ "$(p2ptbl get $gwiptbl $oct3 | cut -sf2)" == "$NodeId" ]
}
