#!/system/bin/sh

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
  echo "autopif4: need root permissions"; exit 1;
fi;
case "$HOME" in
  *termux*) echo "autopif4: need su root environment"; exit 1;;
esac;

until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) echo "sh autopif4.sh [-a|-s] [-m]"; exit 0;;
    -a|--advanced|advanced) ARGS="-a"; shift;;
    -s|--strong|strong) FORCE_STRONG=1; shift;;
    -m|--match|match) FORCE_MATCH=1; shift;;
    *) break;;
  esac;
done;

echo "Pixel Canary pif.prop generator script \
  \n  by osm0sis @ xda-developers";

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*autopif4.sh$')";;
esac;
DIR=$(dirname "$(readlink -f "$DIR")");

item() { echo "\n- $@"; }
die() { echo "\nError: $@!"; exit 1; }
die_bb() { die "$@, install busybox"; }
warn() { echo "\nWarning: $@!"; }

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
    die_bb "wget not found";
  elif $BUSYBOX ping -c1 -s2 android.com 2>&1 | grep -q "bad address"; then
    die_bb "wget broken";
  else
    wget() { $BUSYBOX wget "$@"; }
  fi;
fi;

if date -D '%s' -d "$(date '+%s')" 2>&1 | grep -qE "bad date|invalid option"; then
  if ! find_busybox; then
    die_bb "date broken";
  else
    date() { $BUSYBOX date "$@"; }
  fi;
fi;

if ! echo "A\nB" | grep -m1 -A1 "A" | grep -q "B"; then
  if ! find_busybox; then
    die_bb "grep broken";
  else
    grep() { $BUSYBOX grep "$@"; }
  fi;
fi;

if [ "$DIR" = /data/adb/modules/playintegrityfix ]; then
  DIR=$DIR/autopif4;
  mkdir -p $DIR;
fi;
cd "$DIR";

item "Crawling Android Developers for latest Pixel Beta device list ...";
wget -q -O PIXEL_VERSIONS_HTML --no-check-certificate "https://developer.android.com/about/versions" 2>&1 || exit 1;
wget -q -O PIXEL_LATEST_HTML --no-check-certificate "$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n1 | tail -n1)" 2>&1 || exit 1;
wget -q -O PIXEL_FI_HTML --no-check-certificate "https://developer.android.com$(grep -o 'href=".*download.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n1 | tail -n1)" 2>&1 || exit 1;
MODEL_LIST="$(grep -A1 'tr id=' PIXEL_FI_HTML | grep 'td' | sed 's;.*<td>\(.*\)</td>;\1;')";
PRODUCT_LIST="$(grep 'tr id=' PIXEL_FI_HTML | sed 's;.*<tr id="\(.*\)">;\1_beta;')";
echo "$PRODUCT_LIST" | wc -w;

if [ "$FORCE_MATCH" ]; then
  DEVICE="$(getprop ro.product.device)";
  case "$(echo ' '$PRODUCT_LIST' ')" in
    *" ${DEVICE}_beta "*)
      MODEL="$(getprop ro.product.model)";
      PRODUCT="${DEVICE}_beta";
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
    DEVICE="$(echo "$PRODUCT" | sed 's/_beta//')";
  }
  set_random_beta;
fi;
echo "$MODEL ($PRODUCT)";

item "Crawling Android Flash Tool for latest Pixel Canary build info ...";
wget -q -O PIXEL_FLASH_HTML --no-check-certificate "https://flash.android.com/" 2>&1 || exit 1;
wget -q -O PIXEL_STATION_JSON --header "Referer: https://flash.android.com" --no-check-certificate "https://content-flashstation-pa.googleapis.com/v1/builds?product=$PRODUCT&key=$(grep -o '<body data-client-config=.*' PIXEL_FLASH_HTML | cut -d\; -f2 | cut -d\& -f1)" 2>&1 || exit 1;
tac PIXEL_STATION_JSON | grep -m1 -A13 '"canary": true' > PIXEL_CANARY_JSON;
ID="$(grep 'releaseCandidateName' PIXEL_CANARY_JSON | cut -d\" -f4)";
INCREMENTAL="$(grep 'buildId' PIXEL_CANARY_JSON | cut -d\" -f4)";
[ -z "$ID" -o -z "$INCREMENTAL" ] && die "Failed to extract build info from JSON";
echo "Android $(grep 'releaseTrackVersionName' PIXEL_CANARY_JSON | cut -d\" -f4)";

FI="$(grep 'factoryImageDownloadUrl' PIXEL_CANARY_JSON | cut -d\" -f4)";
FI_HOST="$(echo "$FI" | sed 's;^.*://\(.*\)$;\1;' | cut -d/ -f1)";
FI_PATH="/$(echo "$FI" | sed 's;^.*://\(.*\)$;\1;' | cut -d/ -f2-)";
if [ "$FI" -a "$FI_HOST" -a "$FI_PATH" ]; then
  nc $FI_HOST 80 <<EOF | tr -d '\r' > PIXEL_ZIP_HEADERS;
HEAD $FI_PATH HTTP/1.1
Host: $FI_HOST
Connection: close

EOF
else
  warn "Failed to extract Factory Image URL from JSON";
fi;
if [ -f PIXEL_ZIP_HEADERS ] && grep -q 'Last-Modified' PIXEL_ZIP_HEADERS; then
  CANARY_REL_DATE="$(date -D '%a, %d %b %Y %H:%M:%S %Z' -d "$(grep -o 'Last-Modified.*' PIXEL_ZIP_HEADERS | cut -d\  -f2-)" '+%Y-%m-%d')";
  CANARY_EXP_DATE="$(date -D '%s' -d "$(($(date -D '%Y-%m-%d' -d "$CANARY_REL_DATE" '+%s') + 60 * 60 * 24 * 7 * 6))" '+%Y-%m-%d')";
  echo "Canary Released: $CANARY_REL_DATE \
    \nEstimated Expiry: $CANARY_EXP_DATE";
else
  warn "Failed to determine Release Date from HTTP headers";
  CANARY_REL_DATE="Unknown";
  CANARY_EXP_DATE="Unknown";
fi;

item "Crawling Pixel Update Bulletins for corresponding security patch level ...";
CANARY_ID="$(grep '"id"' PIXEL_CANARY_JSON | sed -e 's;.*canary-\(.*\)".*;\1;' -e 's;^\(.\{4\}\);\1-;')";
[ -z "$CANARY_ID" ] && die "Failed to extract build info from JSON";
wget -q -O PIXEL_SECBULL_HTML --no-check-certificate "https://source.android.com/docs/security/bulletin/pixel" 2>&1 || exit 1;
SECURITY_PATCH="$(grep "<td>$CANARY_ID" PIXEL_SECBULL_HTML | sed 's;.*<td>\(.*\)</td>;\1;')";
echo "$SECURITY_PATCH";

item "Dumping values to minimal pif.prop ...";
cat <<EOF | tee pif.prop;
MANUFACTURER=Google
MODEL=$MODEL
FINGERPRINT=google/$PRODUCT/$DEVICE:CANARY/$ID/$INCREMENTAL:user/release-keys
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
  echo "\n# Canary Released: $CANARY_REL_DATE\n# Estimated Expiry: $CANARY_EXP_DATE" >> custom.pif.prop;
  cat custom.pif.prop;
fi;

if [ "$DIR" = /data/adb/modules/playintegrityfix/autopif4 ]; then
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
    TS_SECPAT=$TS_DIR/security_patch.txt;
    touch $TS_SECPAT;
    if [ -f /data/adb/modules/tricky_store/libTEESimulator.so ]; then
        item "Updating TEESimulator security_patch.txt ...";
        if [ ! -s "$TS_SECPAT" ]; then
            cat <<EOF > $TS_SECPAT;
all=

[com.google.android.gms]
system=no
EOF
        fi;
    else
        item "Updating Tricky Store security_patch.txt ...";
        [ -s "$TS_SECPAT" ] || echo "all=" > $TS_SECPAT;
        grep -qE '^[0-9]{8}$' $TS_SECPAT && sed -i "s/^.*$/${SECURITY_PATCH//-}/" $TS_SECPAT;
        grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' $TS_SECPAT && sed -i "s/^.*$/$SECURITY_PATCH/" $TS_SECPAT;
    fi;
    grep -q 'all=' $TS_SECPAT && sed -i "s/all=.*/all=$SECURITY_PATCH/" $TS_SECPAT;
    if ! grep -q 'system=no' $TS_SECPAT; then
        grep -q 'system=' $TS_SECPAT && sed -i "s/system=.*/system=$(echo ${SECURITY_PATCH//-} | cut -c-6)/" $TS_SECPAT;
    fi;
    sed -i '$a\' $TS_SECPAT;
    cat $TS_SECPAT;
  fi;
  if [ -f /data/adb/modules/playintegrityfix/killpi.sh ]; then
    item "Killing any running GMS DroidGuard/Play Store processes ...";
    sh /data/adb/modules/playintegrityfix/killpi.sh 2>&1 || true;
  fi;
fi;
