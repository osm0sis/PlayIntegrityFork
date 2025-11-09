#!/system/bin/sh

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
  echo "autopif2: need root permissions"; exit 1;
fi;
case "$HOME" in
  *termux*) echo "autopif2: need su root environment"; exit 1;;
esac;

FORCE_TOP=1;
FORCE_DEPTH=1;
until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) echo "sh autopif2.sh [-a|-s] [-m] [-t #] [-d #]"; exit 0;;
    -a|--advanced|advanced) ARGS="-a"; shift;;
    -s|--strong|strong) FORCE_STRONG=1; shift;;
    -m|--match|match) FORCE_MATCH=1; shift;;
    -t|--top|top) echo "$2" | grep -q '^[1-9]$' || exit 1; FORCE_TOP=$2; shift 2;;
    -d|--depth|depth) echo "$2" | grep -q '^[1-9]$' || exit 1; FORCE_DEPTH=$2; shift 2;;
    *) break;;
  esac;
done;

echo "Pixel Beta pif.prop generator script \
  \n  by osm0sis @ xda-developers";

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*autopif2.sh$')";;
esac;
DIR=$(dirname "$(readlink -f "$DIR")");

item() { echo "\n- $@"; }
die() { echo "\nError: $@, install busybox!"; exit 1; }

find_busybox() {
  [ -n "$BUSYBOX" ] && return 0;
  local path;
  for path in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
    if [ -f "$path" ]; then
      BUSYBOX="$path";
      return 0;
    fi;
  done;
  return 1;
}

if which wget2 >/dev/null; then
  wget() { wget2 "$@"; }
elif which curl >/dev/null; then
  # map arguments for simple equivalent use with:
  # wget -q -O <file> --no-check-certificate <url>
  wget() { curl -S -s -k -o "$3" "$5"; }
elif ! which wget >/dev/null || grep -q "wget-curl" $(which wget); then
  if ! find_busybox; then
    die "wget not found";
  elif $BUSYBOX ping -c1 -s2 android.com 2>&1 | grep -q "bad address"; then
    die "wget broken";
  else
    wget() { $BUSYBOX wget "$@"; }
  fi;
fi;

if date -D '%s' -d "$(date '+%s')" 2>&1 | grep -qE "bad date|invalid option"; then
  if ! find_busybox; then
    die "date broken";
  else
    date() { $BUSYBOX date "$@"; }
  fi;
fi;

if ! echo "A\nB" | grep -m1 -A1 "A" | grep -q "B"; then
  if ! find_busybox; then
    die "grep broken";
  else
    grep() { $BUSYBOX grep "$@"; }
  fi;
fi;

if [ "$DIR" = /data/adb/modules/playintegrityfix ]; then
  DIR=$DIR/autopif2;
  mkdir -p $DIR;
fi;
cd "$DIR";

item "Crawling Android Developers for latest Pixel Beta ...";
wget -q -O PIXEL_VERSIONS_HTML --no-check-certificate https://developer.android.com/about/versions 2>&1 || exit 1;
wget -q -O PIXEL_LATEST_HTML --no-check-certificate $(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n$FORCE_TOP | tail -n1) 2>&1 || exit 1;
wget -q -O PIXEL_OTA_HTML --no-check-certificate https://developer.android.com$(grep -o 'href=".*download-ota.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n$FORCE_DEPTH | tail -n1) 2>&1 || exit 1;
echo "$(grep -m1 -oE 'tooltip>Android .*[0-9]' PIXEL_OTA_HTML | cut -d\> -f2) $(grep -oE 'tooltip>QPR.* Beta' PIXEL_OTA_HTML | cut -d\> -f2 | head -n$FORCE_DEPTH | tail -n1)";

BETA_REL_DATE="$(date -D '%B %e, %Y' -d "$(grep -m1 -A1 'Release date' PIXEL_OTA_HTML | tail -n1 | sed 's;.*<td>\(.*\)</td>.*;\1;')" '+%Y-%m-%d')";
BETA_EXP_DATE="$(date -D '%s' -d "$(($(date -D '%Y-%m-%d' -d "$BETA_REL_DATE" '+%s') + 60 * 60 * 24 * 7 * 6))" '+%Y-%m-%d')";
echo "Beta Released: $BETA_REL_DATE \
  \nEstimated Expiry: $BETA_EXP_DATE";

MODEL_LIST="$(grep -A1 'tr id=' PIXEL_OTA_HTML | grep 'td' | sed 's;.*<td>\(.*\)</td>;\1;')";
PRODUCT_LIST="$(grep -o 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\/ -f2)";
OTA_LIST="$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)";

if [ "$FORCE_MATCH" ]; then
  DEVICE="$(getprop ro.product.device)";
  case "$(echo ' '$PRODUCT_LIST' ')" in
    *" ${DEVICE}_beta "*)
      MODEL="$(getprop ro.product.model)";
      PRODUCT="${DEVICE}_beta";
      OTA="$(echo "$OTA_LIST" | grep "$PRODUCT")";
    ;;
  esac;
fi;
item "Selecting Pixel Beta device ...";
if [ -z "$PRODUCT" ]; then
  set_random_beta() {
    local list_count="$(echo "$MODEL_LIST" | wc -l)";
    local list_rand="$((RANDOM % $list_count + 1))";
    local IFS=$'\n';
    set -- $MODEL_LIST;
    MODEL="$(eval echo \${$list_rand})";
    set -- $PRODUCT_LIST;
    PRODUCT="$(eval echo \${$list_rand})";
    set -- $OTA_LIST;
    OTA="$(eval echo \${$list_rand})";
    DEVICE="$(echo "$PRODUCT" | sed 's/_beta//')";
  }
  set_random_beta;
fi;
echo "$MODEL ($PRODUCT)";

(ulimit -f 2; wget -q -O PIXEL_ZIP_METADATA --no-check-certificate $OTA) 2>/dev/null;
FINGERPRINT="$(grep -am1 'post-build=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)";
SECURITY_PATCH="$(grep -am1 'security-patch-level=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)";
if [ -z "$FINGERPRINT" -o -z "$SECURITY_PATCH" ]; then
  case "$(getprop ro.product.cpu.abi)" in
    armeabi-v7a|x86) [ "$BUSYBOX" ] && ISBB32MSG=", install wget2";;
  esac;
  echo "\nError: Failed to extract information from metadata$ISBB32MSG!";
  exit 1;
fi;

item "Dumping values to minimal pif.prop ...";
cat <<EOF | tee pif.prop;
MANUFACTURER=Google
MODEL=$MODEL
FINGERPRINT=$FINGERPRINT
PRODUCT=$PRODUCT
DEVICE=$DEVICE
SECURITY_PATCH=$SECURITY_PATCH
DEVICE_INITIAL_SDK_INT=32
EOF

for MIGRATE in migrate.sh /data/adb/modules/playintegrityfix/migrate.sh; do
  [ -f "$MIGRATE" ] && break; 
done;
if [ -f "$MIGRATE" ]; then
  for OLDPIF in /data/adb/modules/playintegrityfix/custom.pif.prop /data/adb/modules/playintegrityfix/custom.pif.json; do
    [ -f "$OLDPIF" ] && break;
  done;
  if [ -f "$OLDPIF" ]; then
    grep -q '//"\*.security_patch"' $OLDPIF && PATCH_COMMENT=1;
    grep -q '#\*.security_patch' $OLDPIF && PATCH_COMMENT=1;
    grep -qE "verboseLogs|VERBOSE_LOGS" $OLDPIF && ARGS="-a";
  else
    FORCE_STRONG=1;
  fi;
  if [ "$FORCE_STRONG" ]; then
    item "Forcing configuration for <A13 PI Strong ...";
    ARGS="-a"; PATCH_COMMENT=1; spoofProvider=0;
  else
    item "Retaining existing configuration ...";
  fi;
  [ -d /data/adb/tricky_store ] && unset PATCH_COMMENT;
  item "Converting pif.prop to custom.pif.prop with migrate.sh:";
  rm -f pif.json custom.pif.json custom.pif.prop;
  sh $MIGRATE -i $ARGS pif.prop;
  if [ -n "$ARGS" ]; then
    grep_config() {
      if [ -f "$2" ]; then
        case $2 in
          *.json) grep -m1 "$1" $2 | cut -d\" -f4;;
          *.prop) grep -m1 "$1=" "$2" | cut -d= -f2 | cut -d\# -f1 | sed 's/[[:space:]]*$//';;
        esac;
      fi;
    }
    verboseLogs=$(grep_config "VERBOSE_LOGS" $OLDPIF);
    ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature spoofVendingFinger spoofVendingSdk verboseLogs";
    for SETTING in $ADVSETTINGS; do
      eval [ -z \"\$$SETTING\" ] \&\& $SETTING=$(grep_config "$SETTING" $OLDPIF);
      eval TMPVAL=\$$SETTING;
      [ -n "$TMPVAL" ] && sed -i "s;\($SETTING=\).;\1$TMPVAL;" custom.pif.prop;
    done;
  fi;
  [ "$PATCH_COMMENT" ] && sed -i 's;\*.security_patch;#\*.security_patch;' custom.pif.prop;
  echo "\n# Beta Released: $BETA_REL_DATE\n# Estimated Expiry: $BETA_EXP_DATE" >> custom.pif.prop;
  cat custom.pif.prop;
fi;

if [ "$DIR" = /data/adb/modules/playintegrityfix/autopif2 ]; then
  if [ -f /data/adb/modules/playintegrityfix/migrate.sh ]; then
    NEWNAME="custom.pif.prop";
  else
    NEWNAME="pif.prop";
  fi;
  for OLDPIF in $NEWNAME custom.pif.json; do
    if [ -f "../$OLDPIF" ]; then
      item "Renaming old file to $OLDPIF.bak ...";
      mv -fv ../$OLDPIF ../$OLDPIF.bak;
    fi;
  done;
  item "Installing new prop ...";
  cp -fv $NEWNAME ..;
  TS_DIR=/data/adb/tricky_store;
  if [ -d "$TS_DIR" ]; then
    item "Updating Tricky Store security_patch.txt ...";
    TS_SECPAT=$TS_DIR/security_patch.txt;
    touch $TS_SECPAT;
    [ -s "$TS_SECPAT" ] || echo "all=" > $TS_SECPAT;
    grep -qE '^[0-9]{8}$' $TS_SECPAT && sed -i "s/^.*$/${SECURITY_PATCH//-}/" $TS_SECPAT;
    grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' $TS_SECPAT && sed -i "s/^.*$/$SECURITY_PATCH/" $TS_SECPAT;
    grep -q 'all=' $TS_SECPAT && sed -i "s/all=.*/all=$SECURITY_PATCH/" $TS_SECPAT;
    grep -q 'system=' $TS_SECPAT && sed -i "s/system=.*/system=$(echo ${SECURITY_PATCH//-} | cut -c-6)/" $TS_SECPAT;
    sed -i '$a\' $TS_SECPAT;
    cat $TS_SECPAT;
  fi;
  if [ -f /data/adb/modules/playintegrityfix/killpi.sh ]; then
    item "Killing any running GMS DroidGuard/Play Store processes ...";
    sh /data/adb/modules/playintegrityfix/killpi.sh 2>&1 || true;
  fi;
fi;
