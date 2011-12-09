cloud_is_online () {
    # look for mac addrs in batman gateway list
    # TODO: remove fake gws with almost zero bandwith
    batctl gwl | tail -n-1 | egrep -q '([0-9a-f]{2}:){5}[0-9a-f]{2}'
}
