#!/bin/bash
# 完成したイメージの整合性を検証する / Verify the resulting image
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}
KERNEL_BIN=${KERNEL_BIN:-out/boot_signed.bin}
[ -f "$OUT_IMG" ] || die "OUT_IMG がありません: $OUT_IMG"

require_root
MNT=$(mktemp -d /tmp/maixcam2_verify.XXXXXX)
trap 'set +e; umount "$MNT" 2>/dev/null; rmdir "$MNT" 2>/dev/null' EXIT

log "image"
ls -l "$OUT_IMG"
sha256sum "$OUT_IMG"

log "kernel slots"
if [ -f "$KERNEL_BIN" ]; then
    klen=$(stat -c %s "$KERNEL_BIN")
    src_sha=$(sha256sum "$KERNEL_BIN" | awk '{print $1}')
    img_sha=$(sha256_range "$OUT_IMG" "$KERNEL_OFF" "$klen")
    info "p14 (slot A) : $img_sha"
    if [ "$src_sha" = "$img_sha" ]; then
        info "  -> $KERNEL_BIN と一致"
    else
        info "  -> 不一致（$KERNEL_BIN = $src_sha）"
    fi
else
    info "p14 (slot A) : $KERNEL_BIN が無いためスキップ"
fi
info "p15 (slot B) : $(sha256_range "$OUT_IMG" "$KERNEL_B_OFF" "$BASE_KERNEL_LEN")"

log "rootfs"
check_ext4_at "$OUT_IMG" "$ROOT_OFF"
mount -o loop,ro,offset=$ROOT_OFF,sizelimit=$ROOT_SIZE "$OUT_IMG" "$MNT"

info "--- apps ---"
ls "$MNT/maixapp/apps"
info "--- app.info ---"
grep -E '^\[' "$MNT/maixapp/apps/app.info" || true
info "--- models (should be empty) ---"
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
