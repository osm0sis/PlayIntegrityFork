MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
if [ -n "$ASH_STANDALONE" ]; then
    set +o standalone
    unset ASH_STANDALONE
fi

# Honor the device-fingerprint marker: use this device's own certified
# fingerprint instead of matching/fetching a Pixel Canary.
if [ -f "$MODPATH/devicefingerprint" ]; then
    sh $MODPATH/autopif4.sh --device || exit 1
else
    sh $MODPATH/autopif4.sh -m || exit 1
fi

echo -e "\nDone!"

# warn since KernelSU/APatch's implementation automatically closes if successful
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$KSU_SUKISU" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    sleep 20
fi
