#!/bin/bash
# 共通設定・ヘルパー
set -euo pipefail

# MaixCAM2 (AX630C eMMC) の固定レイアウト（U-Boot の blkdevparts 由来）
#   この基板は MBR/GPT ではなく、U-Boot がパーティションを定義している
ROOT_OFF=291241984      # rootfs (p17)
ROOT_SIZE=10502537216
BOOT_OFF=157024256      # boot (p16, FAT32)
BOOT_SIZE=134217728
KERNEL_OFF=22806528     # kernel A (p14)
KERNEL_B_OFF=89915392   # kernel B (p15)

# ベースイメージ（2026-05-29 / MaixPy 4.12.5）の総サイズ
EXPECTED_IMG_SIZE=10793779200

# 想定するベースイメージ
EXPECTED_VER="maixcam2-2026-05-29-maixpy-v4.12.5"

# Python パッケージの keep リスト（site-packages 直下の名前）
KEEP_PKGS="maix maixpy maixpy-4.12.5.dist-info axengine axengine-0.1.3.dist-info \
PIL pillow.libs pillow-12.0.0.dist-info numpy numpy.libs numpy-2.2.6.dist-info \
yaml _yaml pyyaml-6.0.3.dist-info pip pip-25.3.dist-info \
setuptools setuptools-80.9.0.dist-info pkg_resources \
packaging packaging-25.0.dist-info psutil psutil-7.2.1.dist-info \
_distutils_hack distutils-precedence.pth typing_extensions.py \
typing_extensions-4.15.0.dist-info README.txt"

# アプリの keep リスト（/maixapp/apps 直下の名前）
KEEP_APPS=" launcher settings app_store gen_app_info.py app.info "

log()  { printf '\n=== %s ===\n' "$*"; }
info() { printf '  %s\n' "$*"; }
die()  { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

require_root() {
    [ "$(id -u)" -eq 0 ] || die "root 権限が必要です（sudo で実行してください）"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "$1 が見つかりません"
}

# ext4 のマジックがオフセット位置にあるか確認
check_ext4_at() {
    local img="$1" off="$2"
    local magic
    magic=$(od -An -tx1 -j $((off + 1080)) -N 2 "$img" | tr -d ' \n')
    [ "$magic" = "53ef" ] || die "ext4 マジックが見つかりません (offset=$off, magic=$magic)"
}

# イメージ内の指定範囲の SHA-256 を返す
# （dd | head は SIGPIPE で pipefail に引っかかるため、一時ファイル経由にする）
sha256_range() {
    local img="$1" off="$2" len="$3"
    [ $((off % 65536)) -eq 0 ] || die "offset は 64KiB 境界である必要があります: $off"
    local tmp blocks
    blocks=$(( (len + 65535) / 65536 ))
    tmp=$(mktemp)
    dd if="$img" bs=65536 skip=$((off / 65536)) count="$blocks" status=none of="$tmp"
    truncate -s "$len" "$tmp"
    sha256sum "$tmp" | awk '{print $1}'
    rm -f "$tmp"
}

# 2026-05-29 ベースイメージの boot_signed.bin のサイズ（B スロット確認用）
BASE_KERNEL_LEN=8556368
