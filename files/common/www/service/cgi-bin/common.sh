exec 2>/tmp/www.log."$(basename $SCRIPT_NAME)"
set -x

fail() {
    code=${1:-420}
    reason=${2:-'Unknown reason'}
    echo -e "Status: $code\r
\r
$reason"
    exit 1
}

read_uci() {
    local val
    read val
    if [ "$val" == "uci: Entry not found" ]; then
	val=''
    fi
    read $1 <<EOF
$val
EOF
}

## lazy execution of commands after the web response has been send
lazy() {
    local pos=$1
    shift
    lazy_cmd="$pos $*
$lazy_cmd"
}

exec_lazy() {
    echo "$lazy_cmd" \
	| grep -v '^$' \
	| sort \
	| cut -f2- -d ' ' \
	| uniq \
	| while read; do
	    $REPLY
	done 1>/dev/null 2>/tmp/www.lazy."$(basename $SCRIPT_NAME)" &
}

## some tests
have_internet() {
    if [ -z "$have_internet_cached_result" ]; then
	local mode=$(cat /tmp/fsm/inetable || echo boot)
	if [ "$mode" == drone -o "$mode" == queen -o "$mode" == ghost ]; then
	    have_internet_cached_result=true
	else
	    have_internet_cached_result=false
	fi
    fi
    $have_internet_cached_result
}

is_wired() {
    if [ -z "$is_wired_cached_result" ]; then
	[ -n "$REMOTE_HOST" ]
	local iface=$(grep ^$REMOTE_HOST </proc/net/arp \
	    | awk 'BEGIN { FS = " " } ; { print $6 }')
	if [ "$iface" == br-lan ]; then
	    is_wired_cached_result=true
	else
	    is_wired_cached_result=false
	fi
    fi
    $is_wired_cached_result
}

check_node_auth() {
    is_wired || fail 401 'Keine Berechtigung'
    # TODO: check password (if set)
}

check_self_auth() {
    # think about what to check
    true
}
