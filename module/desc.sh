#!/system/bin/sh

# Rewrite module.prop's description into a live status line so the manager's
# module card shows the active spoof at a glance:
#   [Device] OnePlus CPH2747 · API 36 · tracks OTAs
#   [Pixel]  Pixel 9 Pro · API 32 · expires 2026-08-15
# Safe here: PlayIntegrityFork does not CRC-check module.prop.

MODDIR=/data/adb/modules/playintegrityfix
CFG="$MODDIR/custom.pif.prop"
PROP="$MODDIR/module.prop"
[ -f "$PROP" ] || exit 0

if [ ! -s "$CFG" ]; then
    desc="Not configured — open the WebUI or run autopif4"
else
    model="$(grep -m1 '^MODEL=' "$CFG" | cut -d= -f2)"
    api="$(grep -m1 '^\*api_level=' "$CFG" | cut -d= -f2)"
    if [ -f "$MODDIR/devicefingerprint" ]; then
        tag="Device"; tail="tracks OTAs"
    else
        tag="Pixel"
        exp="$(grep -m1 'Estimated Expiry:' "$CFG" | sed 's/.*Expiry:[[:space:]]*//' | tr -d '[:space:]')"
        [ -n "$exp" ] && tail="expires $exp" || tail="fetched"
    fi
    desc="[$tag] ${model:-unknown}"
    [ -n "$api" ] && desc="$desc · API $api"
    [ -n "$tail" ] && desc="$desc · $tail"
fi

# Escape the sed delimiter (;) and & in the replacement text.
esc="$(printf '%s' "$desc" | sed 's/[&;]/\\&/g')"
sed -i "s;^description=.*;description=$esc;" "$PROP"
