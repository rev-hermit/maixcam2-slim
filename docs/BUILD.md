# Build Guide

Instructions for building the minimal firmware and kernel.

**English** | [日本語](#日本語)

---

## English

### 1. Requirements

| Item | Value |
|---|---|
| **Build OS** | Ubuntu 22.04 / 24.04 / 26.04 — Linux required (loop mount + ext4 tools) |
| Disk space | 30 GB or more free |
| Privileges | `sudo` access for editing the rootfs |
| Base image | Official `maixcam2-2026-05-29-maixpy-v4.12.5.img` (10,793,779,200 bytes) |
| Toolchain | `gcc-arm-9.2-2019.12` aarch64 |
| SDK | `sipeed/maix_ax620e_sdk` (with git submodules) |

> **Build on Linux; flashing can be done elsewhere.**
> `make prepare`/`slim`/`patch` need `loop` mount and ext4 tools, so the build
> host must be Linux. The resulting `out/maixcam2-slim.img` can be flashed from
> **Windows** (Win32DiskImager) or **Linux** (`dd`) — see [FLASH.md](FLASH.md).

### 2. Required Packages

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### 3. Toolchain Setup

```bash
TC=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
mkdir -p ~/opt && cd ~/opt
curl -LO https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/9.2-2019.12/binrel/${TC}.tar.xz
tar -xf ${TC}.tar.xz
export TC_DIR=$HOME/opt/$TC
```

### 4. Base Image

Download the official image from Sipeed (Baidu Netdisk or official mirrors):

<https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html>

If downloaded as split 7z archives (`.7z.001`, etc.), extract them with 7-Zip first.

```bash
export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
```

### 5. Build Steps

```bash
make check          # Verify environment (ext4 magic, required tools, disk space)
sudo make prepare   # Copy base image to out/ (root; ownership returned to you)
sudo make slim      # Remove demo apps, models, and unnecessary packages (root)
sudo make patch     # Apply configs, scripts, and boot partition settings (root)
make kernel         # Clone SDK -> update kernel to HEAD -> patch -> build -> sign
sudo make write-kernel   # Write compiled kernel to p14 (slot A)
sudo make verify    # Verify resulting image integrity
```

> **Only the image-editing steps need root.**
> `prepare` / `slim` / `patch` / `write-kernel` / `verify` mount or write the image,
> so they need `sudo`. `make kernel` only builds the SDK — run it as your normal
> user so the SDK and build artifacts stay yours.
> Running everything with `sudo` also works, but the SDK will be owned by root.

> `make kernel` clones the SDK; the initial run downloads several GB and takes 10+ minutes. Set `SDK_DIR` to reuse an existing checkout.

Output file:

```text
out/maixcam2-slim.img
```

### 6. Partition Layout (Important)

This board does **not** use standard MBR/GPT partitioning. Partitions are defined by U-Boot's `blkdevparts` parameters, meaning byte offsets within `.img` are fixed.

| # | Name | Offset (bytes) | Size (bytes) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` writes only to p14 (slot A). p15 (slot B) preserves the vendor base kernel as a reliable fallback.

### 7. Troubleshooting

| Symptom | Cause & Solution |
|---|---|
| `ext4 magic not found` | Different base image version. Check file size and partition offsets. |
| `mount: already mounted` | Previous run terminated unexpectedly. Run `losetup -a` -> `losetup -d <loop>` and `umount`. |
| `site-packages not found` | Different Python version installed in rootfs (script expects Python 3.13). |
| Kernel build fails: missing `initramfs_rootfs.cpio` | The project prepare step did not run. `make kernel` runs it automatically; for manual builds, run `make -C build/projects/<project> p=<project> prepare` first. |
| Screen displays `Runtime not installed` | Missing `/maixapp/maixcam_lib.version`. Run `20_slim_rootfs.sh` to generate it. |

---

## 日本語

### 1. 前提環境

| 項目 | 要件 |
|---|---|
| **ビルド OS** | Ubuntu 22.04 / 24.04 / 26.04 — Linux 必須（loop mount と ext4 ツール） |
| 空き容量 | 30 GB 以上 |
| 権限 | rootfs 編集用の `sudo` 権限 |
| ベースイメージ | 公式 `maixcam2-2026-05-29-maixpy-v4.12.5.img`（10,793,779,200 バイト） |
| ツールチェーン | `gcc-arm-9.2-2019.12` aarch64 |
| SDK | `sipeed/maix_ax620e_sdk`（サブモジュール含む） |

> **ビルドは Linux、書き込みは別環境でも可。**
> `make prepare` / `slim` / `patch` は `loop` マウントと ext4 ツールを使うため、
> ビルド環境は Linux が必要です。完成した `out/maixcam2-slim.img` の書き込みは
> **Windows**（Win32DiskImager）または **Linux**（`dd`）で行えます
> （[FLASH.md](FLASH.md) 参照）。

### 2. 必要パッケージのインストール

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### 3. ツールチェーンの準備

```bash
TC=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
mkdir -p ~/opt && cd ~/opt
curl -LO https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/9.2-2019.12/binrel/${TC}.tar.xz
tar -xf ${TC}.tar.xz
export TC_DIR=$HOME/opt/$TC
```

### 4. ベースイメージの準備

Sipeed の公式配布ページ（Baidu 網盤または公式リンク）から取得します。

<https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html>

分割 7z ファイル（`.7z.001` 等）の場合は、あらかじめ 7-Zip で単一の `.img` ファイルに展開してください。

```bash
export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
```

### 5. ビルド手順

```bash
make check          # 環境確認（ext4 マジック、必要ツール、空き容量）
sudo make prepare   # 公式イメージを out/ へコピー（要 root。所有者は呼び出し元へ戻す）
sudo make slim      # デモアプリ・モデル・不要パッケージの削除（要 root）
sudo make patch     # 設定ファイル・スクリプト・boot 設定の適用（要 root）
make kernel         # SDK 取得 → カーネル HEAD 更新 → パッチ適用 → ビルド → 署名（root 不要）
sudo make write-kernel   # ビルドしたカーネルを p14（A スロット）へ書き込み
sudo make verify    # 成果物イメージの検証
```

> **root が必要なのはイメージを編集する処理だけです。**
> `prepare` / `slim` / `patch` / `write-kernel` / `verify` はイメージをマウント・書き込みするため
> `sudo` が必要です。`make kernel` は SDK をビルドするだけなので、**通常ユーザーで実行**してください
> （SDK とビルド成果物が root 所有になるのを避けられます）。
> すべて `sudo` で実行しても動作しますが、SDK が root 所有になります。

> 初回の `make kernel` は SDK のクローンで数 GB のダウンロードが発生し、10 分以上かかります。既存の SDK がある場合は `SDK_DIR` を指定することで再利用できます。

出力ファイル:

```text
out/maixcam2-slim.img
```

### 6. パーティション構成（重要）

本基板は **一般的な MBR/GPT 形式ではありません**。U-Boot の `blkdevparts` パラメータでパーティションが定義されているため、`.img` 内のバイトオフセットは固定です。

| # | 名前 | オフセット (B) | サイズ (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` は p14（A スロット）のみに書き込みます。p15（B スロット）はベースイメージのカーネルがそのまま残るため、起動障害時のフォールバックとして利用できます。

### 7. トラブルシューティング

| 症状 | 原因と対処 |
|---|---|
| `ext4 マジックが見つかりません` | ベースイメージのバージョン違いです。ファイルサイズやオフセットを確認してください。 |
| `mount: マウント済みです` | 前回の処理が異常終了しています。`losetup -a` で確認後、`losetup -d` および `umount` を実行してください。 |
| `site-packages が見つかりません` | rootfs 内の Python バージョン違いです（本スクリプトは Python 3.13 前提）。 |
| カーネルビルドで `initramfs_rootfs.cpio` が無い | プロジェクト prepare が未実行です。`make kernel` は自動で実行します。手動ビルドの場合は先に `make -C build/projects/<project> p=<project> prepare` を実行してください。 |
| 画面に `Runtime not installed` と表示される | `/maixapp/maixcam_lib.version` が存在しません。`20_slim_rootfs.sh` で生成されます。 |
