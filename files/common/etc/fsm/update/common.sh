Tbl=/tmp/p2ptbl/update
TblIf=br-mesh
FwDir=/tmp/firmware

# updates global state using current internal state; implicit
# definition of the table format
GS_update () {
    p2ptbl update $Tbl "$NodeId" "$CurFw\t$TargetFw\t$TargetTime\t$AckTime" $TblIf
}

# assemble internal state
CurState=$1
CurTime=$(date +%s)
NodeId=$(cat /proc/sys/kernel/random/boot_id) # TODO: replace with stable machine id
CurFw="$(cat /etc/firmware)"
[ -n "$NodeId" -a -n "$CurFw" ]

# get current global state from p2ptable
p2ptbl init $Tbl
GS=$(p2ptbl get $Tbl $NodeId)
if [ -n "$GS" ]; then
    GSCurFw=$(   echo "$GS" | cut -f1)
    TargetFw=$(  echo "$GS" | cut -f2)
    TargetTime=$(echo "$GS" | cut -f3)
    AckTime=$(   echo "$GS" | cut -f4)
    # update stale firmware entries .. should only happen after manual
    # edit of /etc/firmware
    [ "$CurFw" == "$GSCurFw" ] || GS_update
else
    # no entry exists -> create one
    TargetFw=""
    TargetTime=""
    AckTime=""
    GS_update
fi
FwDst=$FwDir/$TargetFw
