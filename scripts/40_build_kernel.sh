#!/bin/bash
# Sipeed SDK を取得し、カーネルへパッチを当ててビルド・署名する
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

SDK_DIR=${SDK_DIR:-$HOME/maix/maix_ax620e_sdk}
PROJECT=AX630C_emmc_arm64_k419_sipeed_maixcam2
OUT_BASE=$SDK_DIR/build/out/$PROJECT

[ -n "${TC_DIR:-}" ] || die "TC_DIR を指定してください（aarch64 ツールチェーン）"
[ -x "$TC_DIR/bin/aarch64-none-linux-gnu-gcc" ] || die "ツールチェーンが見つかりません: $TC_DIR"

# ---------- 1. SDK ----------
if [ ! -d "$SDK_DIR/.git" ]; then
    log "SDK を clone（数 GB / 時間がかかります）"
    mkdir -p "$(dirname "$SDK_DIR")"
    git clone --depth 1 --shallow-submodules --recursive \
        https://github.com/sipeed/maix_ax620e_sdk "$SDK_DIR"
fi

log "SDK のバージョン"
git -C "$SDK_DIR" log -1 --format='%h %ad %s' --date=short || true

# ---------- 2. kernel を HEAD へ ----------
log "kernel を origin/main へ更新"
git -C "$SDK_DIR/kernel" fetch --depth 1 origin main
git -C "$SDK_DIR/kernel" checkout FETCH_HEAD
git -C "$SDK_DIR/kernel" log -1 --format='%h %ad %s' --date=short

# ---------- 3. パッチ ----------
log "カーネルパッチを適用"
for p in patches/kernel/*.patch; do
    info "apply $(basename "$p")"
    git -C "$SDK_DIR/kernel" apply --check "$(realpath "$p")" \
        || info "  既に適用済みか、コンフリクトの可能性があります"
    git -C "$SDK_DIR/kernel" am -3 "$(realpath "$p")" 2>/dev/null \
        || git -C "$SDK_DIR/kernel" apply "$(realpath "$p")" \
        || info "  skip"
done
git -C "$SDK_DIR/kernel" log --oneline -3

# ---------- 4. ビルド ----------
export PATH="$TC_DIR/bin:$PATH"

log "initramfs を生成（プロジェクト prepare）"
make -C "$SDK_DIR/build/projects/$PROJECT" p=$PROJECT prepare

log "カーネル + モジュールをビルド"
make -C "$SDK_DIR/kernel/linux" p=$PROJECT all -j"$(nproc)"

log "署名（boot_signed.bin / _signed.dtb）"
make -C "$SDK_DIR/kernel/linux" p=$PROJECT install

log "生成物"
ls -l "$OUT_BASE/images/boot_signed.bin" "$OUT_BASE/images/${PROJECT}_signed.dtb"
sha256sum "$OUT_BASE/images/boot_signed.bin" "$OUT_BASE/images/${PROJECT}_signed.dtb"
mkdir -p out
cp -f "$OUT_BASE/images/boot_signed.bin" out/boot_signed.bin
info "out/boot_signed.bin にコピーしました"
