#!/bin/sh
interface=$1
mtu=$2
linkmtu=$3
localip=$4
remoteip=$5

ip route del default via $remoteip table openvpn
ip rule del from 10.0.0.0/8 table openvpn
ip rule del from $remoteip/32 table openvpn
ip route del 10.0.0.0/8 dev br-mesh table openvpn
