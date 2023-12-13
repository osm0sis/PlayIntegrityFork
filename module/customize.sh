# Error on < Android 9
if [ "$API" -lt 28 ]; then
    abort "! You can't use this module on Android < 8.0"
fi

# Remove/warn if conflicting modules are installed
if [ -d /data/adb/modules/safetynet-fix ]; then
    touch /data/adb/modules/safetynet-fix/remove
    ui_print "! Universal SafetyNet Fix (USNF) module will be removed on next reboot"
fi
if [ -d /data/adb/modules/MagiskHidePropsConf ]; then
    ui_print "! MagiskHidePropsConfig (MHPC) module may cause issues with PIF"
fi
rm -f /data/adb/pif.json

# Copy any custom.pif.json to updated module
if [ -f /data/adb/modules/playintegrityfix/custom.pif.json ]; then
    ui_print "- Restoring custom.pif.json"
    cp -af /data/adb/modules/playintegrityfix/custom.pif.json $MODPATH/custom.pif.json
fi

# Clean up any leftover files from previous deprecated methods
rm -f /data/data/com.google.android.gms/cache/pif.prop /data/data/com.google.android.gms/pif.prop
rm -f /data/data/com.google.android.gms/cache/pif.json /data/data/com.google.android.gms/pif.json
# Remove magisk 32bit zy support
rm -f /debug_ramdisk/magisk32
