#!/bin/bash
# 公式イメージを out/ にコピーして検証する
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

[ -n "${SRC_IMG:-}" ] || die "SRC_IMG を指定してください"
[ -f "$SRC_IMG" ] || die "見つかりません: $SRC_IMG"

mkdir -p out
OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}

if [ -e "$OUT_IMG" ]; then
    log "既存の出力を退避"
    mv "$OUT_IMG" "$OUT_IMG.bak-$(date +%Y%m%d_%H%M%S)"
fi

log "コピー（約 10.8GB）"
cp --reflink=auto "$SRC_IMG" "$OUT_IMG"

log "検証"
sz=$(stat -c %s "$OUT_IMG")
info "size : $sz"
[ "$sz" = "$EXPECTED_IMG_SIZE" ] || info "警告: 想定サイズと異なります"
check_ext4_at "$OUT_IMG" "$ROOT_OFF"
info "ext4 : OK"
sha256sum "$OUT_IMG"
info "OUT_IMG=$OUT_IMG"
