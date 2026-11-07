# MaixCAM2 Slim Firmware

**English** | [日本語](#日本語)

Build scripts and kernel patches that turn the **official Sipeed MaixCAM2 image**
into a **minimal firmware** (no demo apps, no multi-GB models, no unused Python
packages) running an **up-to-date kernel** with **log-quieting patches**.

> This project is **unofficial** and not affiliated with Sipeed.
> It is **not a fork** of any Sipeed repository.
> **No vendor binaries are redistributed.** It operates on an official image
> that you download yourself.

---

## English

### What it does

| Item | Official 2026-05-29 | After this script |
|---|---:|---:|
| rootfs usage | 10,500 MB (2.3 MB free) | ~3,100 MB (~6,500 MB free) |
| Free space after `resize2fs` (29 GB eMMC) | — | **~26 GB** |
| Apps | 45 demos | `launcher` / `settings` / `app_store` only |
| AI models | 4.39 GB | 0 (`/root/models` emptied) |
| Python packages | 2.0 GB / 231 | 135 MB / 28 |
| Kernel | 2026-05-29 | **HEAD + log-quieting patches** |
| Boot-time dmesg | ~888 lines | **~510 lines** |

Removed:

- `/root/models/*` — LLM / VLM / TTS / image-generation / YOLO demo models
- 44 demo apps (`classifier` 83 MB, `camera`, `detector`, `speech`, `photos`, ...)
- Most of `site-packages` (`torch`, `transformers`, `diffusers`, `scipy`,
  `sklearn`, `numba`, `llvmlite`, `cv2`, `av`, `onnxruntime`, `sympy`,
  `yolo_world_utils`, ...)
- `/maixapp/share/picture/*` (demo photos)
- `/opt/scripts/llm`

Kept:

- `launcher` / `settings` / `app_store`
- `maix`, `maixpy`, `axengine`, `PIL`, `numpy`, `yaml`, `pip`, `setuptools`,
  `packaging`, `psutil`, `typing_extensions`, `pkg_resources`
- `/maixapp/share/font` (needed for CJK rendering)

### Requirements

| Item | Value |
|---|---|
| OS | Ubuntu 22.04 / 24.04 / 26.04 (loop mount + ext4 tools) |
| Disk | 30 GB free or more |
| Privileges | `sudo` for editing the rootfs |
| Base image | official `maixcam2-2026-05-29-maixpy-v4.12.5.img` (10,793,779,200 B) |
| Toolchain | gcc-arm-9.2-2019.12 aarch64 |
| SDK | `sipeed/maix_ax620e_sdk` (with submodules) |

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### Usage

```bash
git clone https://github.com/rev-hermit/maixcam2-slim
cd maixcam2-slim

export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
export TC_DIR=$HOME/opt/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu

make check          # verify environment (ext4 magic, tools, free space)
make prepare        # copy the official image into out/
make slim           # remove demos / models / packages
make patch          # apply configs, scripts and boot settings
make kernel         # fetch SDK -> kernel HEAD -> patches -> build -> sign
make write-kernel   # write the built kernel to p14 (slot A)
make verify         # verify the result
```

`make kernel` clones the SDK and downloads several GB on the first run.
Set `SDK_DIR` to reuse an existing checkout.

Output:

```
out/maixcam2-slim.img
```

### Flashing

See [docs/FLASH.md](docs/FLASH.md). Use **Win32DiskImager** —
Rufus rejects this image because the board uses a custom partition layout.

```powershell
winget install Win32diskimager.win32diskimager
```

> ⚠️ Flashing erases the entire eMMC. Back up first.

### After first boot

```sh
resize2fs /dev/mmcblk0p17      # grow the rootfs to 29 GB
df -h /
```

Optional Wi-Fi settings at build time:

```bash
export WIFI_SSID=your-ssid
export WIFI_PASS=your-password
export LOCALE=ja
```

### Partition layout (important)

This board does **not** use MBR/GPT. Partitions come from U-Boot's
`blkdevparts` (`mmcblk0:768K(spl),512K(ddrinit),...`), so byte offsets inside
the `.img` are fixed.

| # | Name | Offset (B) | Size (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` writes only to p14. p15 keeps the base image kernel and
acts as a fallback.

### Patches

#### rootfs

| File | Purpose |
|---|---|
| `opt/scripts/wifi.sh` | AP-mode fixes (DHCP, 192.168.42 separation, hostapd/udhcpd lifecycle, HT/CCMP, chmod 600), no password logging, `aicwf_dbg_level=1` |
| `opt/scripts/update_kernel.sh` | Writes only to the inactive slot; `--switch` / `--both` / `--dry-run` |
| `opt/scripts/update_dtb.sh` | Same for DTB (p12/p13) |
| `etc/fstab` | `/boot` umask=077, `/tmp` and `/dev/shm` 64M |
| `etc/rc.local` | `hwclock --hctosys --utc` |
| `etc/sysctl.d/99-maixcam2.conf` | `vm.min_free_kbytes=16384`, `swappiness=10`, `dirty_ratio=20/10` |
| `etc/systemd/journald.conf.d/99-maixcam2.conf` | journal 256M / 1 week |
| `etc/systemd/system/launcher.service.d/restart.conf` | `Restart=always` |
| `maixapp/apps/app.info` | Keep only `app_store` and `settings` |
| (generated) `/maixapp/maixcam_lib.version` | Vendor image ships no version file, which makes the launcher show "Runtime not installed" |

#### kernel (`patches/kernel/`)

| Patch | Change |
|---|---|
| `0001-quiet-noisy-kernel-logs.patch` | `aic8800`: unconditional `printk` (`get_txpwr_max`, etc.) -> `AICWFDBG(LOGDEBUG)`. `aic_btsdio`: stop per-frame logging. Panel: drop per-DCS-command hex dump. Hynitron touch: silence `HYN_ENTER()` and notifier logs |

Effect:

| Item | Before | After |
|---|---:|---:|
| dmesg lines at boot | ~888 | ~510 |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

Error-path logs (`Load %s fail`, `wrong size`, `AICBT_ERR`, ...) are preserved.

### Notes

- **Flashing erases the whole eMMC.** Back up your data.
- The scripts edit the rootfs, so they need **root (`sudo`)**.
- A different base image version may require adjusted offsets or patches.
- The touch driver that is actually built is `hyn_driver_release_qm/`
  (`hyn/` is an unused copy); the patch touches both.

### Upstream

This is **not a fork**; these are the projects and pages it builds on.

| Name | Link | Purpose |
|---|---|---|
| **MaixCAM2 System / OS** | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html> | official images & flashing |
| MaixCAM2 FAQ | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_faq.html> | troubleshooting |
| Sipeed downloads | <https://dl.sipeed.com/> | tools |
| AXDL (Windows) | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z> | `.axp` flashing / recovery |
| AXDL driver | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z> | same |
| `sipeed/maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | build environment |
| `sipeed/maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | **the kernel we patch** |
| `sipeed/maix_ax620e_sdk_msp` | <https://github.com/sipeed/maix_ax620e_sdk_msp> | media/NPU middleware |
| `sipeed/MaixPy` | <https://github.com/sipeed/MaixPy> | runtime |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | aarch64 toolchain |

> The kernel patches target `sipeed/maix_ax620e_sdk_kernel` `main`
> (`f0c18b62` as of 2026-10-22).

### Acknowledgements

Thanks to Sipeed, Axera, and all upstream OSS developers.

### License

The **scripts and patches** in this repository are MIT.
Third-party components inside the base image remain under their own licenses;
see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

## 日本語

Sipeed MaixCAM2 の**公式イメージを最小化**し、**最新カーネル**と
**ログ静音化パッチ**を適用するためのビルドスクリプトとパッチです。

> 本プロジェクトは**非公式**で、Sipeed とは無関係です。
> Sipeed リポジトリの **fork ではありません**。
> **ベンダーのバイナリは再配布しません。** 各自がダウンロードした公式イメージに対して
> 処理を行います。

### 何が変わるか

| 項目 | 公式 2026-05-29 | このスクリプト適用後 |
|---|---:|---:|
| rootfs 使用量 | 10,500 MB（空き 2.3 MB） | 約 3,100 MB（空き 約 6,500 MB） |
| `resize2fs` 後（29GB eMMC） | — | **空き 約 26 GB** |
| アプリ | デモ 45 個 | `launcher` / `settings` / `app_store` のみ |
| AI モデル | 4.39 GB | 0（`/root/models` を空に） |
| Python パッケージ | 2.0 GB / 231 | 135 MB / 28 |
| カーネル | 2026-05-29 | **HEAD + ログ静音化パッチ** |
| 起動時 dmesg | 約 888 行 | **約 510 行** |

削除するもの:

- `/root/models/*` … LLM / VLM / 音声 / 画像生成 / YOLO 各種のデモモデル
- デモアプリ 44 個（`classifier` 83MB, `camera`, `detector`, `speech`, `photos` ほか）
- `site-packages` の大半（`torch`, `transformers`, `diffusers`, `scipy`, `sklearn`,
  `numba`, `llvmlite`, `cv2`, `av`, `onnxruntime`, `sympy`, `yolo_world_utils` など）
- `/maixapp/share/picture/*`（デモ写真）
- `/opt/scripts/llm`（ローカル LLM 用ヘルパー）

残すもの:

- `launcher` / `settings` / `app_store`
- `maix`, `maixpy`, `axengine`, `PIL`, `numpy`, `yaml`, `pip`, `setuptools`,
  `packaging`, `psutil`, `typing_extensions`, `pkg_resources`
- `/maixapp/share/font`（日本語表示に必要）

### 必要なもの

| 項目 | 内容 |
|---|---|
| OS | Ubuntu 22.04 / 24.04 / 26.04（loop mount と ext4 ツール） |
| ディスク | 30GB 以上の空き |
| 権限 | rootfs 編集に `sudo` |
| ベース | 公式 `maixcam2-2026-05-29-maixpy-v4.12.5.img`（10,793,779,200 B） |
| ツールチェーン | gcc-arm-9.2-2019.12 aarch64 |
| SDK | `sipeed/maix_ax620e_sdk`（submodule 含む） |

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev \
  device-tree-compiler u-boot-tools python3 python3-pip python3-lxml \
  git wget xz-utils cpio kmod libncurses-dev rsync liblzma-dev
```

### 使い方

```bash
git clone https://github.com/rev-hermit/maixcam2-slim
cd maixcam2-slim

export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img
export TC_DIR=$HOME/opt/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu

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

成果物:

```
out/maixcam2-slim.img
```

### 書き込み

[docs/FLASH.md](docs/FLASH.md) を参照。
**Win32DiskImager** を使います（Rufus は独自パーティションレイアウトのため拒否されます）。

```powershell
winget install Win32diskimager.win32diskimager
```

> ⚠️ 書き込むと eMMC の内容はすべて消えます。先にバックアップしてください。

### 初回起動後

```sh
resize2fs /dev/mmcblk0p17      # 29GB に拡張
df -h /
```

ビルド時に Wi-Fi を設定する場合:

```bash
export WIFI_SSID=your-ssid
export WIFI_PASS=your-password
export LOCALE=ja
```

### パーティション構成（重要）

この基板は **MBR/GPT ではありません**。U-Boot の `blkdevparts`
（`mmcblk0:768K(spl),512K(ddrinit),...`）でパーティションが定義されます。
そのため `.img` 内の位置は固定です。

| # | 名前 | オフセット (B) | サイズ (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` は p14 にだけ書きます。p15 はベースイメージのカーネルのまま
残るので、起動不良時のフォールバックになります。

### パッチ内容

#### rootfs

| ファイル | 内容 |
|---|---|
| `opt/scripts/wifi.sh` | AP モード修正（DHCP、192.168.42 分離、hostapd/udhcpd ライフサイクル、HT/CCMP、chmod 600）、パスワード非ログ、`aicwf_dbg_level=1` |
| `opt/scripts/update_kernel.sh` | 非アクティブスロットのみ書込、`--switch` / `--both` / `--dry-run` |
| `opt/scripts/update_dtb.sh` | 同上（p12 / p13） |
| `etc/fstab` | `/boot` を `umask=077`、`/tmp` `/dev/shm` を `size=64M` |
| `etc/rc.local` | `hwclock --hctosys --utc`（RTC 時刻復元） |
| `etc/sysctl.d/99-maixcam2.conf` | `vm.min_free_kbytes=16384`, `swappiness=10`, `dirty_ratio=20/10` |
| `etc/systemd/journald.conf.d/99-maixcam2.conf` | journal 256M / 1 週間 |
| `etc/systemd/system/launcher.service.d/restart.conf` | `Restart=always` |
| `maixapp/apps/app.info` | `app_store` / `settings` のみに整理 |
| （生成）`/maixapp/maixcam_lib.version` | ベンダーイメージに無く、launcher が「Runtime not installed」を表示するため補完 |

#### kernel（`patches/kernel/`）

| パッチ | 変更 |
|---|---|
| `0001-quiet-noisy-kernel-logs.patch` | `aic8800` の無条件 `printk`（`get_txpwr_max` など）を `AICWFDBG(LOGDEBUG)` へ。`aic_btsdio` の毎フレームログを停止。パネル DCS の hex dump 削除。タッチの `HYN_ENTER()` と notifier ログを停止 |

効果:

| 項目 | 変更前 | 変更後 |
|---|---:|---:|
| dmesg 行数（起動時） | 約 888 | 約 510 |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

エラー系ログ（`Load %s fail`, `wrong size`, `AICBT_ERR` など）は残しています。

### 注意

- **書き込むと eMMC の内容はすべて消えます。** 必ずバックアップしてください。
- rootfs を編集するため **root 権限（sudo）** が必要です。
- ベースイメージのバージョンが変わると、オフセットやパッチの調整が必要になる場合があります。
- 実際にビルドされるタッチドライバは `hyn_driver_release_qm/`（`hyn/` は未使用のコピー）。
  パッチは両方に当てています。

### 上流 / Upstream

**fork ではありません。** 参考にしているプロジェクトとページです。

| 名前 | リンク | 用途 |
|---|---|---|
| **MaixCAM2 System / OS** | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html> | 公式イメージの入手・焼き方 |
| MaixCAM2 FAQ | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_faq.html> | トラブルシュート |
| Sipeed ダウンロード | <https://dl.sipeed.com/> | ツール類 |
| AXDL（Windows） | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z> | `.axp` 書き込み・復旧 |
| AXDL ドライバ | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z> | 同上 |
| `sipeed/maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | ビルド環境 |
| `sipeed/maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | **パッチ対象のカーネル** |
| `sipeed/maix_ax620e_sdk_msp` | <https://github.com/sipeed/maix_ax620e_sdk_msp> | メディア/NPU ミドルウェア |
| `sipeed/MaixPy` | <https://github.com/sipeed/MaixPy> | ランタイム |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | aarch64 ツールチェーン |

> カーネルパッチは `sipeed/maix_ax620e_sdk_kernel` の `main`
> （確認時点: `f0c18b62`, 2026-10-22）に対して作成しています。

### 謝辞

Sipeed、Axera、および関連 OSS の開発者に感謝します。

### ライセンス

本リポジトリの**スクリプトとパッチ**は MIT。
ベースイメージに含まれる第三者の成果物は、それぞれのライセンスに従います。
詳細は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照してください。
