#!/system/bin/sh

check_reset_prop() {
  local NAME=$1
  local EXPECTED=$2
  local VALUE=$(resetprop $NAME)
  [ -z $VALUE ] || [ $VALUE = $EXPECTED ] || resetprop $NAME $EXPECTED
}

contains_reset_prop() {
  local NAME=$1
  local CONTAINS=$2
  local NEWVAL=$3
  [[ "$(resetprop $NAME)" = *"$CONTAINS"* ]] && resetprop $NAME $NEWVAL
}

{
  # Reset props after boot completed to avoid breaking some weird devices/ROMs...
  while [ "$(getprop sys.boot_completed)" != "1" ]
  do
    sleep 1
  done

  check_reset_prop "ro.boot.vbmeta.device_state" "locked"
  check_reset_prop "ro.boot.verifiedbootstate" "green"
  check_reset_prop "ro.boot.flash.locked" "1"
  check_reset_prop "ro.boot.veritymode" "enforcing"
  check_reset_prop "ro.boot.warranty_bit" "0"
  check_reset_prop "ro.warranty_bit" "0"
  check_reset_prop "ro.debuggable" "0"
  check_reset_prop "ro.secure" "1"
  check_reset_prop "ro.adb.secure" "1"
  check_reset_prop "ro.build.type" "user"
  check_reset_prop "ro.build.tags" "release-keys"
  check_reset_prop "ro.vendor.boot.warranty_bit" "0"
  check_reset_prop "ro.vendor.warranty_bit" "0"
  check_reset_prop "vendor.boot.vbmeta.device_state" "locked"
  check_reset_prop "vendor.boot.verifiedbootstate" "green"
  check_reset_prop "ro.secureboot.lockstate" "locked"

  # Hide that we booted from recovery when magisk is in recovery mode
  contains_reset_prop "ro.bootmode" "recovery" "unknown"
  contains_reset_prop "ro.boot.bootmode" "recovery" "unknown"
  contains_reset_prop "vendor.boot.bootmode" "recovery" "unknown"

  resetprop --delete ro.build.selinux
}&

# Always remove Magisk 32bit support
rm -f /debug_ramdisk/magisk32
killall -9 zygiskd32
