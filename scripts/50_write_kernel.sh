#!/bin/bash
# ビルドしたカーネルをイメージの A スロット (p14) に書き込む
# Write the built kernel into slot A (p14) of the image.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}
KERNEL_BIN=${KERNEL_BIN:-out/boot_signed.bin}

[ -f "$OUT_IMG" ] || die "OUT_IMG がありません: $OUT_IMG"
[ -f "$KERNEL_BIN" ] || die "カーネルがありません: $KERNEL_BIN（先に make kernel）"

ksize=$(stat -c %s "$KERNEL_BIN")
[ "$ksize" -le 67108864 ] || die "カーネルが p14 のサイズ (64MiB) を超えています: $ksize"

log "p14 (slot A) に書き込み"
dd if="$KERNEL_BIN" of="$OUT_IMG" bs=65536 seek=$((KERNEL_OFF / 65536)) conv=notrunc,fsync status=none

log "検証"
src_sha=$(sha256sum "$KERNEL_BIN" | awk '{print $1}')
img_sha=$(sha256_range "$OUT_IMG" "$KERNEL_OFF" "$ksize")
info "kernel file : $src_sha"
info "p14 in image: $img_sha"
[ "$src_sha" = "$img_sha" ] || die "p14 の内容が一致しません"
info "p15 (slot B) はベースイメージのカーネルのまま（フォールバック）"
