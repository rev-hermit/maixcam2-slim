#!/bin/bash
# 設定ファイル・スクリプト・boot パーティションへパッチを適用する
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

require_root
OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}
[ -f "$OUT_IMG" ] || die "OUT_IMG がありません: $OUT_IMG"

MNT=$(mktemp -d /tmp/maixcam2_root.XXXXXX)
BMNT=$(mktemp -d /tmp/maixcam2_boot.XXXXXX)
cleanup() { set +e; umount "$MNT" 2>/dev/null; umount "$BMNT" 2>/dev/null; rmdir "$MNT" "$BMNT" 2>/dev/null; }
trap cleanup EXIT

log "rootfs をマウント"
mount -o loop,offset=$ROOT_OFF,sizelimit=$ROOT_SIZE "$OUT_IMG" "$MNT"

log "スクリプト類"
install -m 755 patches/rootfs/opt.scripts/wifi.sh          "$MNT/opt/scripts/wifi.sh"
install -m 755 patches/rootfs/opt.scripts/update_kernel.sh "$MNT/opt/scripts/update_kernel.sh"
install -m 755 patches/rootfs/opt.scripts/update_dtb.sh    "$MNT/opt/scripts/update_dtb.sh"

log "設定ファイル"
install -m 644 patches/rootfs/etc.fstab "$MNT/etc/fstab"
install -m 755 patches/rootfs/etc.rc.local "$MNT/etc/rc.local"
install -d -m 755 "$MNT/etc/sysctl.d"
install -m 644 patches/rootfs/etc.sysctl.d.99-maixcam2.conf "$MNT/etc/sysctl.d/99-maixcam2.conf"
install -d -m 755 "$MNT/etc/systemd/journald.conf.d"
install -m 644 patches/rootfs/etc.systemd.journald.conf.d.99-maixcam2.conf \
        "$MNT/etc/systemd/journald.conf.d/99-maixcam2.conf"
install -d -m 755 "$MNT/etc/systemd/system/launcher.service.d"
install -m 644 patches/rootfs/etc.systemd.system.launcher.service.d.restart.conf \
        "$MNT/etc/systemd/system/launcher.service.d/restart.conf"

log "systemd のタイムアウト"
sed -i 's/^#\?DefaultTimeoutStartSec=.*/DefaultTimeoutStartSec=30s/; s/^#\?DefaultTimeoutStopSec=.*/DefaultTimeoutStopSec=30s/' \
    "$MNT/etc/systemd/system.conf"
grep -q '^DefaultTimeoutStopSec' "$MNT/etc/systemd/system.conf" \
    || echo 'DefaultTimeoutStopSec=30s' >> "$MNT/etc/systemd/system.conf"
awk '!seen[$0]++' "$MNT/etc/systemd/system.conf" > /tmp/sc.new && cat /tmp/sc.new > "$MNT/etc/systemd/system.conf"
grep -E '^DefaultTimeout' "$MNT/etc/systemd/system.conf"

log "アンマウント"
umount "$MNT"

log "boot パーティション (FAT32)"
mount -o loop,offset=$BOOT_OFF,sizelimit=$BOOT_SIZE "$OUT_IMG" "$BMNT"
CFG="$BMNT/configs"
if [ -f "$CFG" ]; then
    setkey() {
        local f="$1" k="$2" v="$3"
        if grep -q "^$k=" "$f"; then
            sed -i "s|^$k=.*|$k=$v|" "$f"
        else
            printf '%s=%s\n' "$k" "$v" >> "$f"
        fi
    }
    setkey "$CFG" maix_system_console 0
    setkey "$CFG" maix_npu_ai_isp 0
    setkey "$CFG" maix_usb_mode device
    setkey "$CFG" maix_usb_ncm 1
    setkey "$CFG" maix_usb_rndis 1
    setkey "$CFG" maix_wifi_mode sta
    if [ -n "${WIFI_SSID:-}" ]; then
        setkey "$CFG" maix_wifi_ssid "$WIFI_SSID"
        setkey "$CFG" maix_wifi_passwd "${WIFI_PASS:-}"
        printf '%s' "$WIFI_SSID" > "$BMNT/wifi.ssid"; chmod 600 "$BMNT/wifi.ssid"
        printf '%s' "${WIFI_PASS:-}" > "$BMNT/wifi.pass"; chmod 600 "$BMNT/wifi.pass"
        : > "$BMNT/wifi.sta"; chmod 600 "$BMNT/wifi.sta"
        info "Wi-Fi 設定を書き込み（WIFI_SSID/WIFI_PASS）"
    else
        info "Wi-Fi は設定しません（WIFI_SSID 未指定）。設定アプリから行えます"
    fi
    if [ -n "${LOCALE:-}" ]; then
        setkey "$CFG" maix_language_locale "$LOCALE"
    fi
    info "--- configs ---"
    grep -E '^(maix_language_locale|maix_wifi_mode|maix_wifi_ssid|maix_system_console|maix_npu_ai_isp|maix_usb_mode)=' "$CFG" || true
fi
sync
umount "$BMNT"
trap - EXIT
rmdir "$MNT" "$BMNT" 2>/dev/null || true

log "完了"
