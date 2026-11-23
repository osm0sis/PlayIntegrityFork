MODPATH="${0%/*}"

# support launching WebUI from Magisk app then exit early
if [ "$MMRL" != "true" ] && [[ -n "$MAGISKTMP" || "$TMPDIR" = *"magisk"* ]]; then
    if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
        echo "- Launching WebUI in KsuWebUIStandalone ..."
        am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "playintegrityfork"
        exit 0
    fi
    if pm path com.dergoogler.mmrl.wx >/dev/null 2>&1; then
        echo "- Launching WebUI in WebUI X ..."
        # v608 intent || v660 intent
        am start -n "com.dergoogler.mmrl.wx/.ui.webui.WebUIActivity" -e MODULE_ID "playintegrityfork" \
            || am start -n "com.dergoogler.mmrl.wx/.ui.webui.activity.NewProcessWebUIActivity" -e MODULE_ID "playintegrityfork"
        exit 0
    fi
fi

# ensure not running in busybox ash standalone shell
if [ -n "$ASH_STANDALONE" ]; then
    set +o standalone
    unset ASH_STANDALONE
fi

[ -f "$MODPATH/skipmatchdevice" ] || MATCHFLAG=-m

sh $MODPATH/autopif4.sh $MATCHFLAG || exit 1

echo -e "\nDone!"

# warn since APatch's implementation automatically closes if successful
if [ "$APATCH" = "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 20 seconds ..."
    sleep 20
fi
