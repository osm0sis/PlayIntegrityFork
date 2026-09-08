MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
if [ -n "$ASH_STANDALONE" ]; then
    set +o standalone
    unset ASH_STANDALONE
fi

[ -f "$MODPATH/skipmatchmode" ] || MATCHMODE=-m

sh $MODPATH/autopif4.sh $MATCHMODE || exit 1

echo -e "\nDone!"

# warn since KernelSU/APatch's implementation automatically closes if successful
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$KSU_SUKISU" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    sleep 20
fi
