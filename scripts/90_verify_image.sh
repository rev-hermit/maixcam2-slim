#!/bin/bash
# 完成したイメージを検証する / Verify the resulting image
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}
[ -f "$OUT_IMG" ] || die "OUT_IMG がありません: $OUT_IMG"

require_root
MNT=$(mktemp -d /tmp/maixcam2_verify.XXXXXX)
trap 'set +e; umount "$MNT" 2>/dev/null; rmdir "$MNT" 2>/dev/null' EXIT

log "image"
ls -l "$OUT_IMG"
sha256sum "$OUT_IMG"

log "partition / kernel"
echo -n "p14 kernel: "
dd if="$OUT_IMG" bs=65536 skip=$((KERNEL_OFF / 65536)) count=200 status=none | head -c 8559216 | sha256sum
echo -n "p15 kernel (base): "
dd if="$OUT_IMG" bs=65536 skip=$((KERNEL_B_OFF / 65536)) count=200 status=none | head -c 8556368 | sha256sum

log "rootfs"
check_ext4_at "$OUT_IMG" "$ROOT_OFF"
mount -o loop,ro,offset=$ROOT_OFF,sizelimit=$ROOT_SIZE "$OUT_IMG" "$MNT"

info "--- apps ---"
ls "$MNT/maixapp/apps"
info "--- app.info ---"
grep -E '^\[' "$MNT/maixapp/apps/app.info" || true
info "--- models ---"
ls -A "$MNT/root/models" || true
info "--- site-packages ($(ls "$MNT/usr/local/lib/python3.13/site-packages" | wc -l) entries) ---"
ls "$MNT/usr/local/lib/python3.13/site-packages"
info "--- runtime version ---"
cat "$MNT/maixapp/maixcam_lib.version" 2>/dev/null || echo "(missing)"
info "--- sizes ---"
du -sh "$MNT/maixapp" "$MNT/usr/local/lib/python3.13/site-packages" "$MNT/root/models" 2>/dev/null || true
df -h "$MNT" | tail -1

umount "$MNT"
trap - EXIT
rmdir "$MNT" 2>/dev/null || true

log "OK"
