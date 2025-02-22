MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
set +o standalone
unset ASH_STANDALONE

sh $MODPATH/autopif2.sh --strong || exit 1

echo -e "\nDone!"

# warn since KernelSU/APatch's implementation automatically closes if successful
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    sleep 20
fi
