#!/system/bin/sh

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
  echo "autopif2: need root permissions"; exit 1;
fi;
case "$HOME" in
  *termux*) echo "autopif2: need su root environment"; exit 1;;
esac;

case "$1" in
  -h|--help|help) echo "sh autopif2.sh [-a|-s]"; exit 0;;
  -a|--advanced|advanced) ARGS="-a"; shift;;
  -s|--strong|strong) ARGS="-a"; PATCH_COMMENT=1; spoofProvider=0; shift;;
esac;

echo "Pixel Beta pif.json generator script \
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

if ! which wget >/dev/null || grep -q "wget-curl" $(which wget); then
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
wget -q -O PIXEL_LATEST_HTML --no-check-certificate $(grep -m1 'developer.android.com/about/versions/' PIXEL_VERSIONS_HTML | cut -d\" -f2) 2>&1 || exit 1;
wget -q -O PIXEL_OTA_HTML --no-check-certificate https://developer.android.com$(grep -om1 'href=".*download-ota"' PIXEL_LATEST_HTML | cut -d\" -f2) 2>&1 || exit 1;
grep -m1 -o 'data-category.*Beta' PIXEL_OTA_HTML | cut -d\" -f2;

BETA_REL_DATE="$(date -D '%B %e, %Y' -d "$(grep -m1 -A1 'Release date' PIXEL_OTA_HTML | tail -n1 | sed 's;.*<td>\(.*\)</td>.*;\1;')" '+%Y-%m-%d')";
BETA_EXP_DATE="$(date -D '%s' -d "$(($(date -D '%Y-%m-%d' -d "$BETA_REL_DATE" '+%s') + 60 * 60 * 24 * 7 * 6))" '+%Y-%m-%d')";
echo "Beta Released: $BETA_REL_DATE \
  \nEstimated Expiry: $BETA_EXP_DATE";

MODEL_LIST="$(grep -A1 'tr id=' PIXEL_OTA_HTML | grep 'td' | sed 's;.*<td>\(.*\)</td>;\1;')";
PRODUCT_LIST="$(grep -o 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\/ -f2)";
OTA_LIST="$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)";

DEVICE="$(getprop ro.product.device)";
if [ "$1" = "-m" ]; then
  DEVICE="$2";
fi;

if echo "$PRODUCT_LIST" | grep -q "${DEVICE}_beta"; then
  case "$PRODUCT_LIST" in
    *${DEVICE}_beta*)
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
FINGERPRINT="$(grep -am1 'post-build=' PIXEL_ZIP_METADATA | cut -d= -f2)";
SECURITY_PATCH="$(grep -am1 'security-patch-level=' PIXEL_ZIP_METADATA | cut -d= -f2)";
if [ -z "$FINGERPRINT" -o -z "$SECURITY_PATCH" ]; then
  echo "\nError: Failed to extract information from metadata!";
  exit 1;
fi;

item "Dumping values to minimal pif.json ...";
cat <<EOF | tee pif.json;
{
  "MANUFACTURER": "Google",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "PRODUCT": "$PRODUCT",
  "DEVICE": "$DEVICE",
  "SECURITY_PATCH": "$SECURITY_PATCH",
  "DEVICE_INITIAL_SDK_INT": "32"
}
EOF

for MIGRATE in migrate.sh /data/adb/modules/playintegrityfix/migrate.sh; do
  [ -f "$MIGRATE" ] && break; 
done;
if [ -f "$MIGRATE" ]; then
  OLDJSON=/data/adb/modules/playintegrityfix/custom.pif.json;
  if [ -f "$OLDJSON" ]; then
    grep -q '//"\*.security_patch"' $OLDJSON && PATCH_COMMENT=1;
    grep -qE "verboseLogs|VERBOSE_LOGS" $OLDJSON && ARGS="-a";
  fi;
  item "Converting pif.json to custom.pif.json with migrate.sh:";
  rm -f custom.pif.json;
  sh $MIGRATE -i $ARGS pif.json;
  if [ -n "$ARGS" ]; then
    grep_json() { [ -f "$2" ] && grep -m1 "$1" $2 | cut -d\" -f4; }
    verboseLogs=$(grep_json "VERBOSE_LOGS" $OLDJSON);
    ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature verboseLogs";
    for SETTING in $ADVSETTINGS; do
      eval [ -z \"\$$SETTING\" ] \&\& $SETTING=$(grep_json "$SETTING" $OLDJSON);
      eval TMPVAL=\$$SETTING;
      [ -n "$TMPVAL" ] && sed -i "s;\($SETTING\": \"\).;\1$TMPVAL;" custom.pif.json;
    done;
  fi;
  [ "$PATCH_COMMENT" ] && sed -i 's;"\*.security_patch";//"\*.security_patch";' custom.pif.json;
  sed -i "s;};\n  // Beta Released: $BETA_REL_DATE\n  // Estimated Expiry: $BETA_EXP_DATE\n};" custom.pif.json;
  cat custom.pif.json;
fi;

if [ "$DIR" = /data/adb/modules/playintegrityfix/autopif2 ]; then
  if [ -f /data/adb/modules/playintegrityfix/migrate.sh ]; then
    NEWNAME="custom.pif.json";
  else
    NEWNAME="pif.json";
  fi;
  if [ -f "../$NEWNAME" ]; then
    item "Renaming old file to $NEWNAME.bak ...";
    mv -fv ../$NEWNAME ../$NEWNAME.bak;
  fi;
  item "Installing new json ...";
  cp -fv $NEWNAME ..;
  if [ -f /data/adb/modules/playintegrityfix/killgms.sh ]; then
    item "Killing any running GMS DroidGuard process ...";
    sh /data/adb/modules/playintegrityfix/killgms.sh 2>&1 || true;
  fi;
fi;
