MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
set +o standalone
unset ASH_STANDALONE

if [ -d /data/adb/modules/tricky_store ] && [ ! -f /data/adb/modules/tricky_store/disable ] &&
	[ -f /data/adb/tricky_store/keybox.xml ] && grep -q "com.google.android.gms" /data/adb/tricky_store/target.txt > /dev/null ; then
	# all these passes, then we can
	# let tricky store do its job
	sh $MODPATH/autopif2.sh --strong || exit 1
else
	sh $MODPATH/autopif2.sh || exit 1
fi

echo "Done!"

# dont sleep on Magisk and MMRL
# those environments stops exec
# and lets the user read
if [ -z "$MAGISKTMP" ] && [ -z "$MMRL" ]; then
    echo "Closing dialog in 20 seconds ..."
    sleep 20
fi
