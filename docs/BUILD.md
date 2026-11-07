# ビルド手順 / Build Guide

- [日本語](#日本語)
- [English](#english)

---

## 日本語

### 1. 前提

| 項目 | 内容 |
|---|---|
| OS | Ubuntu 22.04 / 24.04 / 26.04（loop mount と ext4 ツールが必要） |
| ディスク | 30GB 以上の空き |
| 権限 | rootfs 編集に `sudo` |
| ベース | 公式 `maixcam2-2026-05-29-maixpy-v4.12.5.img`（10,793,779,200 B） |
| ツールチェーン | gcc-arm-9.2-2019.12 aarch64 |
| SDK | `sipeed/maix_ax620e_sdk`（submodule 含む） |

### 2. パッケージ

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### 3. ツールチェーン

```bash
TC=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
mkdir -p ~/opt && cd ~/opt
curl -LO https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/9.2-2019.12/binrel/${TC}.tar.xz
tar -xf ${TC}.tar.xz
export TC_DIR=$HOME/opt/$TC
```

### 4. ベースイメージ

Sipeed の配布ページから取得します（Baidu Netdisk / 公式リンク）。

<https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html>

分割 7z の場合は 7-Zip で展開してください。

```bash
export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
```

### 5. 実行

```bash
make check          # 環境確認（ext4 マジック・ツール・空き容量）
make prepare        # 公式イメージを out/ にコピー
make slim           # デモ/モデル/パッケージ削除
make patch          # 設定ファイル・スクリプト・boot 設定を適用
make kernel         # SDK 取得 → kernel HEAD → パッチ → ビルド → 署名
make write-kernel   # ビルドした kernel を p14 (A スロット) へ
make verify         # 検証
```

`make kernel` は SDK を clone するため初回は数 GB / 十数分かかります。
`SDK_DIR` を指定すれば既存の SDK を再利用できます。

### 6. パーティション構成（重要）

この基板は **MBR/GPT ではありません**。U-Boot の `blkdevparts`
（`mem=...`, `blkdevparts=mmcblk0:768K(spl),...`）でパーティションが定義されます。
そのため `.img` 内の位置は固定です。

| # | 名前 | オフセット (B) | サイズ (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` は p14 にだけ書きます。p15 はベースイメージのカーネルのまま
残るので、起動不良時のフォールバックになります。

### 7. 詰まったとき

| 症状 | 対処 |
|---|---|
| `ext4 マジックが見つかりません` | ベースイメージのバージョン違い。オフセットを確認 |
| `mount: マウント済みです` | 前回の異常終了。`losetup -a` → `losetup -d`、`umount` |
| `site-packages が見つかりません` | Python のバージョン違い（3.13 前提） |
| カーネルビルドで `initramfs_rootfs.cpio` が無い | `make prepare`（プロジェクト prepare）を先に実行 |
| `Runtime not installed` が画面に出る | `/maixapp/maixcam_lib.version` が無い。`20_slim_rootfs.sh` が作成する |

---

## English

### 1. Requirements

| Item | Value |
|---|---|
| OS | Ubuntu 22.04 / 24.04 / 26.04 (needs loop mount + ext4 tools) |
| Disk | 30 GB free or more |
| Privileges | `sudo` for rootfs editing |
| Base image | official `maixcam2-2026-05-29-maixpy-v4.12.5.img` (10,793,779,200 B) |
| Toolchain | gcc-arm-9.2-2019.12 aarch64 |
| SDK | `sipeed/maix_ax620e_sdk` (with submodules) |

### 2. Packages

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### 3. Toolchain

```bash
TC=gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
mkdir -p ~/opt && cd ~/opt
curl -LO https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-a/9.2-2019.12/binrel/${TC}.tar.xz
tar -xf ${TC}.tar.xz
export TC_DIR=$HOME/opt/$TC
```

### 4. Base image

Get it from Sipeed's download page (Baidu Netdisk / official links).

<https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html>

For split 7z archives, extract with 7-Zip.

```bash
export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
```

### 5. Build

```bash
make check          # verify environment (ext4 magic, tools, free space)
make prepare        # copy the official image into out/
make slim           # remove demos / models / packages
make patch          # apply configs, scripts, boot settings
make kernel         # fetch SDK -> kernel HEAD -> patches -> build -> sign
make write-kernel   # write the built kernel to p14 (slot A)
make verify         # verify the result
```

`make kernel` clones the SDK; the first run downloads several GB and takes
10+ minutes. Set `SDK_DIR` to reuse an existing checkout.

### 6. Partition layout (important)

This board does **not** use MBR/GPT. Partitions are defined by U-Boot's
`blkdevparts` (`mmcblk0:768K(spl),512K(ddrinit),...`), so the byte offsets
inside the `.img` are fixed.

| # | Name | Offset (B) | Size (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` writes to p14 only. p15 keeps the base image kernel and
works as a fallback if the new kernel fails to boot.

### 7. Troubleshooting

| Symptom | Fix |
|---|---|
| `ext4 magic not found` | Different base image version; check the offsets |
| `already mounted` | A previous run died. `losetup -a` → `losetup -d`, `umount` |
| `site-packages not found` | Different Python version (3.13 expected) |
| missing `initramfs_rootfs.cpio` | Run the project `prepare` step first |
| screen shows `Runtime not installed` | `/maixapp/maixcam_lib.version` missing; `20_slim_rootfs.sh` creates it |
