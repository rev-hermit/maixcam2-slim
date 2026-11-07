#!/bin/bash
# ビルド環境の確認
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

log "必須コマンド"
missing=0
for c in dd od truncate mount umount e2fsck resize2fs losetup awk sed grep tar make gcc python3 git; do
    if command -v "$c" >/dev/null 2>&1; then
        info "OK   $c"
    else
        info "MISS $c"
        missing=1
    fi
done
[ "$missing" -eq 0 ] || die "不足しているコマンドがあります（apt install e2fsprogs util-linux ...）"

log "aarch64 ツールチェーン"
if [ -n "${TC_DIR:-}" ] && [ -x "$TC_DIR/bin/aarch64-none-linux-gnu-gcc" ]; then
    info "OK   $TC_DIR"
else
    info "TC_DIR が未設定、またはツールチェーンが見つかりません"
    info "例: export TC_DIR=\$HOME/opt/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu"
fi

log "入力イメージ"
if [ -z "${SRC_IMG:-}" ]; then
    info "SRC_IMG が未設定です"
    info "例: export SRC_IMG=/path/to/$EXPECTED_VER.img"
else
    [ -f "$SRC_IMG" ] || die "SRC_IMG が見つかりません: $SRC_IMG"
    sz=$(stat -c %s "$SRC_IMG")
    info "path : $SRC_IMG"
    info "size : $sz (expected $EXPECTED_IMG_SIZE)"
    [ "$sz" = "$EXPECTED_IMG_SIZE" ] || info "警告: サイズが想定と違います。ベース版が異なる可能性があります"
    check_ext4_at "$SRC_IMG" "$ROOT_OFF"
    info "ext4 : OK (offset $ROOT_OFF)"
fi

log "ディスク空き"
df -h . | tail -1
info "30GB 以上の空きを推奨"

log "sudo"
if sudo -n true 2>/dev/null; then
    info "OK (パスワードなし)"
else
    info "sudo のパスワードを実行時に聞かれます"
fi
