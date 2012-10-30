timeout=6000
chain_prefix=splash_db_
chain_id_file=/tmp/splash_chain_id

chain_id=$(cat $chain_id_file 2>/dev/null || true)
if ! [ "$chain_id" -gt 0 ] &>/dev/null; then
    chain_id=1
    echo $chain_id > $chain_id_file
fi

lockSplash () {
    exec 666<$chain_id_file
    flock -x 666
}

unlockSplash () {
    exec 666<&-
}
