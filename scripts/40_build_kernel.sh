#!/bin/bash
# Sipeed SDK を取得し、カーネルへパッチを当ててビルド・署名する
# Fetch the Sipeed SDK, apply kernel patches, build and sign.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

SDK_DIR=${SDK_DIR:-$HOME/maix/maix_ax620e_sdk}
PROJECT=AX630C_emmc_arm64_k419_sipeed_maixcam2
OUT_BASE=$SDK_DIR/build/out/$PROJECT
SDK_URL=https://github.com/sipeed/maix_ax620e_sdk
KERNEL_URL=https://github.com/sipeed/maix_ax620e_sdk_kernel.git

# 一部の submodule は git@github.com: 形式。SSH 鍵が無い環境（root など）でも
# 動くよう、https へ読み替える。
GIT_HTTPS=(-c url."https://github.com/".insteadOf="git@github.com:")

[ -n "${TC_DIR:-}" ] || die "TC_DIR を指定してください（aarch64 ツールチェーン）"
[ -x "$TC_DIR/bin/aarch64-none-linux-gnu-gcc" ] || die "ツールチェーンが見つかりません: $TC_DIR"

# ---------- 1. SDK ----------
if [ ! -d "$SDK_DIR/.git" ]; then
    log "SDK を clone（数 GB / 時間がかかります）"
    mkdir -p "$(dirname "$SDK_DIR")"
    git "${GIT_HTTPS[@]}" clone --depth 1 --shallow-submodules --recursive \
        "$SDK_URL" "$SDK_DIR"
fi

log "SDK のバージョン"
git -C "$SDK_DIR" log -1 --format='%h %ad %s' --date=short || true

# ---------- 2. kernel を HEAD へ ----------
# 明示的な https URL を使う（git@github.com: のままだと SSH 鍵が必要になる）
log "kernel を origin/main へ更新"
git "${GIT_HTTPS[@]}" -C "$SDK_DIR/kernel" fetch --depth 1 "$KERNEL_URL" main
git -C "$SDK_DIR/kernel" checkout FETCH_HEAD
git -C "$SDK_DIR/kernel" log -1 --format='%h %ad %s' --date=short

# ---------- 3. パッチ ----------
# git am は user.name/user.email を要求するため使わない。
# apply で作業ツリーに当てるだけにする（ビルドには十分）。
log "カーネルパッチを適用"
shopt -s nullglob
patches=(patches/kernel/*.patch)
[ ${#patches[@]} -gt 0 ] || die "patches/kernel/*.patch がありません"
for p in "${patches[@]}"; do
    abs=$(realpath "$p")
    name=$(basename "$p")
    if git -C "$SDK_DIR/kernel" apply --check "$abs" 2>/dev/null; then
        git -C "$SDK_DIR/kernel" apply "$abs"
        info "applied  $name"
    elif git -C "$SDK_DIR/kernel" apply --check --reverse "$abs" 2>/dev/null; then
        info "already applied  $name"
    else
        die "パッチを適用できません: $name"
    fi
done
git -C "$SDK_DIR/kernel" status --short | head -20 || true

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
