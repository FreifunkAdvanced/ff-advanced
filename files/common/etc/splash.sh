timeout=6000
chain_prefix=splash_db_
chain_id_file=/tmp/splash_chain_id
tbl=/tmp/p2ptbl/splash

lockSplash () {
    exec 666<$chain_id_file
    flock -x 666
}

unlockSplash () {
    exec 666<&-
}

have_splash_iptable () {
    state=${1:-$(fsm get inetable)}
    [ "$state" == "queen" ]
}

# $mac
add_splash_iptable () {
    iptables -t nat -I $chain_prefix$chain_id \
	-m mac --mac-source "$1" -j ACCEPT
}

# $mac $time
add_splash_p2ptbl () {
    p2ptbl update $tbl "$1" "${2:-$(($(date +%s) + $timeout))}" br-mesh
}

# determine current splash iptable iteration
chain_id=$(cat $chain_id_file 2>/dev/null || true)
if ! [ "$chain_id" -gt 0 ] &>/dev/null; then
    # first -> create id file
    chain_id=1
    echo $chain_id > $chain_id_file

    # create splash p2ptbl and add own MAC addr to it with an at least
    # year 2033 timeout
    p2ptbl init $tbl
    add_splash_p2ptbl \
	$(ifconfig br-mesh | egrep -o '([0-9A-F]{2}:){5}[0-9A-F]{2}') \
	2000000000
fi
