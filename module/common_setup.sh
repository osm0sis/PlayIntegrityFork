# Remove any definitely conflicting modules that are installed
if [ -d /data/adb/modules/safetynet-fix ]; then
    touch /data/adb/modules/safetynet-fix/remove
    ui_print "! Universal SafetyNet Fix (USNF) module will be removed on next reboot"
fi

# Replace/hide conflicting custom ROM injection app folders/files to disable them
LIST=$MODPATH/example.app_replace.list
[ -f "$MODPATH/custom.app_replace.list" ] && LIST=$MODPATH/custom.app_replace.list
for APP in $(grep -v '^#' $LIST); do
    if [ -e "$APP" ]; then
        case $APP in
            /system/*) ;;
            *) PREFIX=/system;;
        esac
        HIDEPATH=$MODPATH$PREFIX$APP
        if [ -d "$APP" ]; then
            mkdir -p $HIDEPATH
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                setfattr -n trusted.overlay.opaque -v y $HIDEPATH
            else
                touch $HIDEPATH/.replace
            fi
        else
            mkdir -p $(dirname $HIDEPATH)
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                mknod $HIDEPATH c 0 0
            else
                touch $HIDEPATH
            fi
        fi
        case $APP in
            */overlay/*)
                CFG=$(echo $APP | grep -oE '.*/overlay')/config/config.xml
                if [ -f "$CFG" ]; then
                    if [ -d "$APP" ]; then
                        APK=$(readlink -f $APP/*.apk);
                    elif [[ "$APP" = *".apk" ]]; then
                        APK=$(readlink -f $APP);
                    fi
                    if [ -s "$APK" ]; then
                        PKGNAME=$(unzip -p $APK AndroidManifest.xml | tr -d '\0' | grep -oE '[[:alnum:].-_]+\*http' | cut -d\* -f1)
                        if [ "$PKGNAME" ] && grep -q "overlay package=\"$PKGNAME" $CFG; then
                            HIDECFG=$MODPATH$PREFIX$CFG
                            if [ ! -f "$HIDECFG" ]; then
                                mkdir -p $(dirname $HIDECFG)
                                cp -af $CFG $HIDECFG
                            fi
                            sed -i 's;<overlay \(package="'"$PKGNAME"'".*\) />;<!-- overlay \1 -->;' $HIDECFG
                        fi
                    fi
                fi
            ;;
        esac
        if [[ -d "$APP" || "$APP" = *".apk" ]]; then
            ui_print "! $(basename $APP .apk) ROM app disabled, please uninstall any user app versions/updates after next reboot"
            [ "$HIDECFG" ] && ui_print "!  + $PKGNAME entry commented out in copied overlay config"
        fi
    fi
done

# Work around AOSPA PropImitationHooks conflict when their persist props don't exist
if [ -n "$(resetprop ro.aospa.version)" ]; then
    for PROP in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
        resetprop | grep -q "\[$PROP\]" || resetprop -n -p "$PROP" ""
    done
fi

# Work around supported custom ROM PixelPropsUtils conflict when spoofProvider is disabled
if [ -n "$(resetprop persist.sys.pixelprops.pi)" ]; then
    resetprop -n -p persist.sys.pixelprops.pi false
    resetprop -n -p persist.sys.pixelprops.gapps false
    resetprop -n -p persist.sys.pixelprops.gms false
fi
