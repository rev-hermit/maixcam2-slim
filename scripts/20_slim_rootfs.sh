#!/bin/bash
# rootfs を最小化する（デモアプリ・モデル・不要パッケージを削除）
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/common.sh

require_root
OUT_IMG=${OUT_IMG:-out/maixcam2-slim.img}
[ -f "$OUT_IMG" ] || die "OUT_IMG がありません。先に make prepare を実行してください: $OUT_IMG"

RUNTIME_VER=${RUNTIME_VER:-4.12.5}
MNT=$(mktemp -d /tmp/maixcam2_root.XXXXXX)
cleanup() { set +e; umount "$MNT" 2>/dev/null; rmdir "$MNT" 2>/dev/null; }
trap cleanup EXIT

log "rootfs をマウント"
mount -o loop,offset=$ROOT_OFF,sizelimit=$ROOT_SIZE "$OUT_IMG" "$MNT"
df -h "$MNT" | tail -1

# ---------- 1. デモモデル ----------
log "デモモデルを削除 (/root/models)"
rm -rf "$MNT"/root/models/*
mkdir -p "$MNT/root/models"

# ---------- 2. デモアプリ ----------
log "デモアプリを削除"
for p in "$MNT"/maixapp/apps/*; do
    n=$(basename "$p")
    case "$KEEP_APPS" in
        *" $n "*) info "keep $n" ;;
        *)        rm -rf "$p" ;;
    esac
done
info "残り: $(ls "$MNT/maixapp/apps" | tr '\n' ' ')"

log "app.info を差し替え"
install -m 644 patches/rootfs/maixapp.app.info "$MNT/maixapp/apps/app.info"

# ---------- 3. デモ写真 ----------
log "デモ写真を削除 (/maixapp/share/picture)"
rm -rf "$MNT"/maixapp/share/picture/*
mkdir -p "$MNT/maixapp/share/picture"

# ---------- 4. Python パッケージ ----------
log "不要な Python パッケージを削除"
SITE="$MNT/usr/local/lib/python3.13/site-packages"
[ -d "$SITE" ] || die "site-packages が見つかりません: $SITE"
for p in "$SITE"/*; do
    n=$(basename "$p")
    keep=0
    for k in $KEEP_PKGS; do [ "$n" = "$k" ] && keep=1 && break; done
    [ $keep -eq 1 ] || rm -rf "$p"
done
rm -rf "$SITE/__pycache__"
info "残り $(ls "$SITE" | wc -l) エントリ / $(du -sh "$SITE" | cut -f1)"

# ---------- 5. LLM ヘルパー ----------
log "/opt/scripts/llm を削除"
rm -rf "$MNT/opt/scripts/llm"

# ---------- 6. 「Runtime not installed」対策 ----------
# ベンダーイメージは /usr/lib/libmaixcam_lib.so にバージョン付き名を持たず、
# /maixapp/maixcam_lib.version も同梱していない。launcher はこのファイルを
# 読めないと「Runtime not installed」を表示する。
log "maixcam_lib.version を補完 ($RUNTIME_VER)"
printf '%s' "$RUNTIME_VER" > "$MNT/maixapp/maixcam_lib.version"
chmod 644 "$MNT/maixapp/maixcam_lib.version"
ln -sf libmaixcam_lib.so "$MNT/usr/lib/libmaixcam_lib.so.$RUNTIME_VER"

# ---------- 7. 不要 unit の無効化 ----------
log "不要な systemd unit を無効化"
for u in isc-dhcp-server isc-dhcp-server6 networkd-dispatcher \
         e2scrub_reap e2scrub_all.timer motd-news.timer \
         apt-daily.timer apt-daily-upgrade.timer; do
    systemctl --root="$MNT" disable "$u" 2>/dev/null && info "disabled $u" || info "skip $u"
done

# ---------- 8. ログ・キャッシュ整理 ----------
log "journal / apt キャッシュを整理"
rm -rf "$MNT"/var/log/journal/* 2>/dev/null || true
rm -f "$MNT"/var/cache/apt/archives/*.deb 2>/dev/null || true

log "結果"
du -sh "$MNT/maixapp/apps" "$MNT/usr/local/lib/python3.13/site-packages" "$MNT/root/models" 2>/dev/null || true
df -h "$MNT" | tail -1

log "アンマウント"
umount "$MNT"
trap - EXIT
rmdir "$MNT" 2>/dev/null || true

log "ファイルシステム検査"
LOOP=$(losetup -f --show --offset=$ROOT_OFF --sizelimit=$ROOT_SIZE "$OUT_IMG")
e2fsck -fy "$LOOP" 2>&1 | tail -5 || true
dumpe2fs -h "$LOOP" 2>/dev/null | grep -iE 'block count|free blocks|block size' || true
losetup -d "$LOOP"

log "完了"
