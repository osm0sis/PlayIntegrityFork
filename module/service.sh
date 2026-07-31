MODPATH="${0%/*}"
. $MODPATH/common_func.sh

# Conditional sensitive properties

# Magisk Recovery Mode
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux
resetprop_if_diff ro.boot.selinux enforcing
# use delete since it can be 0 or 1 for enforcing depending on OEM
if ! $SKIPDELPROP; then
    delprop_if_exist ro.build.selinux
fi
# Attestation probes read the live SELinux state (the selinuxfs enforce node
# and access mode), so a permissive kernel stays detectable no matter what
# ro.boot.selinux says. Actually return to enforcing; only hide the state
# (toybox cat avoids bumping atime) if we cannot.
SELINUX_ENFORCE=/sys/fs/selinux/enforce
if [ -r "$SELINUX_ENFORCE" ] && [ "$(toybox cat "$SELINUX_ENFORCE")" = "0" ]; then
    command -v setenforce >/dev/null 2>&1 && setenforce 1 2>/dev/null
    [ "$(toybox cat "$SELINUX_ENFORCE")" = "0" ] && echo 1 > "$SELINUX_ENFORCE" 2>/dev/null
    if [ "$(toybox cat "$SELINUX_ENFORCE")" = "0" ]; then
        chmod 640 "$SELINUX_ENFORCE"
        chmod 440 /sys/fs/selinux/policy
    fi
fi

# Conditional late sensitive properties

# must be set after boot_completed for various OEMs
{
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Device-fingerprint mode: re-capture the device's own fingerprint after an
# OEM OTA changes the build (only when it actually changed). Enable with
# `touch module/devicefingerprint`.
if [ -f "$MODPATH/devicefingerprint" ]; then
    CUR="$(getprop ro.build.fingerprint)"
    SAVED="$(grep -m1 '^FINGERPRINT=' "$MODPATH/custom.pif.prop" 2>/dev/null | cut -d= -f2)"
    [ "$CUR" != "$SAVED" ] && sh "$MODPATH/autopif4.sh" --device >/dev/null 2>&1
fi

# SafetyNet/Play Integrity + OEM
# avoid bootloop on some Xiaomi devices
resetprop_if_diff ro.secureboot.lockstate locked
# avoid breaking Realme fingerprint scanners
resetprop_if_diff ro.boot.flash.locked 1
resetprop_if_diff ro.boot.realme.lockstate 1
# avoid breaking Oppo fingerprint scanners
resetprop_if_diff ro.boot.vbmeta.device_state locked
# avoid breaking OnePlus display modes/fingerprint scanners
resetprop_if_diff vendor.boot.verifiedbootstate green
# avoid breaking OnePlus/Oppo fingerprint scanners on OOS/ColorOS 12+
resetprop_if_diff ro.boot.verifiedbootstate green
resetprop_if_diff ro.boot.veritymode enforcing
resetprop_if_diff vendor.boot.vbmeta.device_state locked

# Other
resetprop_if_diff sys.oem_unlock_allowed 0

# Compact property area to hide modifications on supported root solutions
resetprop --compact >/dev/null 2>&1 || true

}&
