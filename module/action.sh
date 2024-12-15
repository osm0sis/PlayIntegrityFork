MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
set +o standalone
unset ASH_STANDALONE

sh $MODPATH/autopif2.sh || exit 1

echo "Done!"

# dont sleep on Magisk and MMRL
# those environments stops exec
# and lets the user read
if [ -z "$MAGISKTMP" ] && [ -z "$MMRL" ]; then
    echo "Closing dialog in 20 seconds ..."
    sleep 20
fi
