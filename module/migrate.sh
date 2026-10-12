#!/bin/sh

N="
";

case "$1" in
  -h|--help|help) echo "sh migrate.sh [-f] [-o] [-a] [-p|-j] [in-file] [out-file]"; exit 0;;
  -i|--install|install) INSTALL=1; shift;;
  *) echo "custom.pif.prop/.json migration script \
    $N  by osm0sis @ xda-developers $N";;
esac;

item() { echo "- $@"; }
die() { [ "$INSTALL" ] || echo "$N$N! $@"; exit 1; }

until [ -z "$1" -o -f "$1" ]; do
  case "$1" in
    -f|--force|force) FORCE=1; shift;;
    -o|--override|override) OVERRIDE=1; shift;;
    -a|--advanced|advanced) ADVANCED=1; shift;;
    -j|--json|json) FORMAT=json; FORCE=1; shift;;
    -p|--prop|prop) FORMAT=prop; FORCE=1; shift;;
    *) die "Invalid argument/file not found: $1";;
  esac;
done;

grep_get_prop() {
  grep -m1 "$1=" "$2" | cut -d= -f2 | cut -d\# -f1 | sed 's/[[:space:]]*$//';
}
grep_check_prop() {
  grep -q "$1" "$2" && [ "$(grep_get_prop "$1" "$2")" ];
}
grep_get_json() {
  eval set -- "$(cat "$2" | tr -d '\r\n' | grep -m1 -o "$1"'".*' | cut -d: -f2- | sed 's|//|#|g')";
  echo "$1" | sed -e 's|"|\\\\\\"|g' -e 's|[,}]*$||';
}
grep_check_json() {
  grep -q "$1" "$2" && [ "$(grep_get_json "$1" "$2")" ];
}
grep_get_config() {
  local target="$FILE";
  [ -n "$2" ] && target="$2";
  case $target in
    *.json) grep_get_json "$1" "$target";;
    *.prop) grep_get_prop "$1" "$target";;
  esac;
}
grep_check_config() {
  local target="$FILE";
  [ -n "$2" ] && target="$2";
  case $target in
    *.json) grep_check_json "$1" "$target";;
    *.prop) grep_check_prop "$1" "$target";;
  esac;
}

if [ -f "$1" ]; then
  FILE="$1";
  DIR="$1";
else
  case "$0" in
    *.sh) DIR="$0";;
    *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*migrate.sh$')";;
  esac;
fi;
DIR=$(dirname "$(readlink -f "$DIR")");

if [ -z "$FILE" ]; then
  for EXT in json prop; do
    [ -f "$DIR/custom.pif.$EXT" ] && FILE="$DIR/custom.pif.$EXT";
  done;
fi;
[ -f "$FILE" ] || die "No config file found";

if [ -z "$FORMAT" ]; then
  case "$FILE" in
    *.json) FORMAT=json;;
    *.prop) FORMAT=prop;;
  esac;
fi;

OUT="$2";
[ -z "$OUT" ] && OUT="$DIR/custom.pif.$FORMAT";

grep_check_config api_level && [ ! "$FORCE" ] && die "No migration required";

[ "$INSTALL" ] || item "Parsing fields ...";

FPFIELDS="BRAND PRODUCT DEVICE RELEASE ID INCREMENTAL TYPE TAGS";
ALLFIELDS="MANUFACTURER MODEL FINGERPRINT $FPFIELDS SECURITY_PATCH DEVICE_INITIAL_SDK_INT";

for FIELD in $ALLFIELDS; do
  eval $FIELD=\"$(grep_get_config $FIELD)\";
done;

if [ -n "$FINGERPRINT" ] && ! grep_check_config build.fingerprint; then
  item 'Simple entry FINGERPRINT found, changing to FINGERPRINT field and "ro.build.fingerprint" property ...';
fi;

if [ -n "$ID" ] && ! grep_check_config build.id; then
  item 'Simple entry ID found, changing to ID field and "ro.build.id" property ...';
fi;

if [ -n "$DEVICE" ] && ! grep_check_config product.device; then
  item 'Simple entry DEVICE found, changing to DEVICE field and "ro.product.device" property ...';
fi;

if [ -n "$PRODUCT" ] && ! grep_check_config product.name; then
  item 'Simple entry PRODUCT found, changing to PRODUCT field and "ro.product.name" property ...';
fi;

if [ -n "$SECURITY_PATCH" ] && ! grep_check_config security_patch; then
  item 'Simple entry SECURITY_PATCH found, changing to SECURITY_PATCH field and "ro.build.version.security_patch" property ...';
fi;

if [ -n "$DEVICE_INITIAL_SDK_INT" ] && ! grep_check_config api_level; then
  item 'Simple entry DEVICE_INITIAL_SDK_INT found, changing to DEVICE_INITIAL_SDK_INT field and "ro.product.first_api_level" property ...';
fi;

if [ -z "$RELEASE" -o -z "$INCREMENTAL" -o -z "$TYPE" -o -z "$TAGS" -o "$OVERRIDE" ]; then
  if [ "$OVERRIDE" ]; then
    item "Overriding values for fields derivable from FINGERPRINT ...";
  else
    item "Missing default fields found, deriving from FINGERPRINT ...";
  fi;
  IFS='/:' read F1 F2 F3 F4 F5 F6 F7 F8 <<EOF
$(grep_get_config FINGERPRINT)
EOF
  i=1;
  for FIELD in $FPFIELDS; do
    eval [ -z \"\$$FIELD\" -o \"$OVERRIDE\" ] \&\& $FIELD=\"\$F$i\";
    i=$((i+1));
  done;
fi;

if [ -z "$SECURITY_PATCH" -o "$SECURITY_PATCH" = "null" ]; then
  item 'Missing required SECURITY_PATCH field and "ro.build.version.security_patch" property value found, leaving empty ...';
  unset SECURITY_PATCH;
fi;

if [ -z "$DEVICE_INITIAL_SDK_INT" -o "$DEVICE_INITIAL_SDK_INT" = "null" ]; then
  item 'Missing required DEVICE_INITIAL_SDK_INT field and "ro.product.first_api_level" property value found, setting to 25 ...';
  DEVICE_INITIAL_SDK_INT=25;
fi;

ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature spoofVendingFinger spoofVendingSdk verboseLogs";

spoofBuild=1;
spoofProps=1;
spoofProvider=1;
spoofSignature=0;
spoofVendingFinger=0;
spoofVendingSdk=0;
verboseLogs=0;

keep_advanced() {
  if grep -qE "verboseLogs|VERBOSE_LOGS" "$1"; then
    item "Retaining existing configuration ...";
    ADVANCED=1;
    grep_check_config VERBOSE_LOGS "$1" && verboseLogs="$(grep_get_config VERBOSE_LOGS "$1")";
    for SETTING in $ADVSETTINGS; do
      eval grep_check_config $SETTING \"$1\" \&\& $SETTING=\"$(grep_get_config $SETTING "$1")\";
    done;
    if grep -qE '//"*.security_patch"|#*.security_patch' "$1"; then
      case $FORMAT in
        json) SECURITY_COMMENT='//';;
        prop) SECURITY_COMMENT='#';;
      esac;
    fi;
  fi;
}
if [ -f "$OUT" ]; then
  keep_advanced "$OUT";
  item "Renaming old file to $(basename "$OUT").bak ...";
  mv -f "$OUT" "$OUT.bak";
else
  case "$FILE" in
    *.$FORMAT) ;;
    *) keep_advanced "$FILE";;
  esac;
fi;

[ "$INSTALL" ] || item "Writing fields and properties to updated custom.pif.$FORMAT ...";
[ "$ADVANCED" ] && item "Adding Advanced Settings entries ...";

case $FORMAT in
  json) CMNT='  //'; EVALPRE='\ \ \ \ \"'; SECPRE1='    '; SECPRE2='"'; PRE='    "'; MID='": "'; POST='",';;
  prop) CMNT='#'; MID='=';;
esac;
([ "$FORMAT" = "json" ] && echo '{';
echo "$CMNT Build Fields";
for FIELD in $ALLFIELDS; do
  eval echo "$EVALPRE$FIELD\$MID\$$FIELD\$POST";
done;
echo "$N$CMNT System Properties";
echo "$PRE"'ro.build.fingerprint'"$MID$FINGERPRINT$POST";
echo "$PRE"'ro.build.id'"$MID$ID$POST";
echo "$PRE"'ro.product.device'"$MID$DEVICE$POST";
echo "$PRE"'ro.product.name'"$MID$PRODUCT$POST";
echo "$SECPRE1$SECURITY_COMMENT$SECPRE2"'ro.build.version.security_patch'"$MID$SECURITY_PATCH$POST";
echo "$PRE"'ro.board.first_api_level'"$MID"'32'"$POST";
echo "$PRE"'ro.product.first_api_level'"$MID$DEVICE_INITIAL_SDK_INT$POST";
if [ "$ADVANCED" ]; then
  echo "$N$CMNT Advanced Settings";
  for SETTING in $ADVSETTINGS; do
    eval echo "$EVALPRE$SETTING\$MID\$$SETTING\$POST";
  done;
fi) | sed '$s/,/\n}/' > "$OUT";

[ "$INSTALL" ] || cat "$OUT";
