# MaixCAM2 Slim Firmware

**English** | [日本語](#日本語)

Build scripts and kernel patches that turn the **official Sipeed MaixCAM2 image**
into a **minimal firmware** (no demo apps, no multi-GB models, no unused Python
packages) running an **up-to-date kernel** with a **log-noise reduction patch**.

> This project is **unofficial** and not affiliated with Sipeed.
> It is **not a fork** of any Sipeed repository.
> **No vendor binaries are redistributed.** It operates directly on an official image
> that you download yourself.

---

## English

### What it does

**In one sentence:** the image shrinks from **10.5 GB to 3.1 GB**, the launcher
goes from **46 apps to 2** (Settings & App Store), and the kernel is **updated**
with **much less boot-time log noise**.

| Item | Official 2026-05-29 | After this script |
|---|---:|---:|
| rootfs usage | 10,500 MB (2.3 MB free) | ~3,100 MB (~6,500 MB free) |
| Free space after `resize2fs` (29 GB eMMC) | — | **~26 GB** |
| Apps | 46 installed | `settings` / `app_store` (+ `launcher` shell) |
| AI models | 4.39 GB | 0 (`/root/models` emptied) |
| Python packages | 2.0 GB / 231 | 135 MB / 28 |
| Kernel | 2026-05-29 | **HEAD + log-noise reduction patch** |
| Boot-time dmesg | ~888 lines | **~510 lines** |

#### What it means in practice

**It becomes immediately usable.** The official image ships every demo, AI model, and
Python package bundled together. It fills its 10.5 GB rootfs partition almost
completely — leaving only **2.3 MB** free. You cannot install packages or save photos
until storage is cleared manually. After running this script, you gain **6.5 GB** of free
space, expanding to **~26 GB** free after `resize2fs` on the 29 GB eMMC.

**The app launcher stays clean.** The launcher displays only **Settings** and
**App Store**. All pre-installed demo apps are removed, but can be reinstalled anytime
from the App Store if needed.

**Heavy demos and bulky AI models are stripped.** 4.39 GB of demo models (LLM, VLM,
speech, image generation, YOLO variants) and their heavy Python dependencies
(`torch`, `transformers`, `diffusers`, etc.) are removed. Demos requiring them will
not run until models are downloaded again.

**The kernel is updated and its boot logs are much shorter.** While the official image runs a 2026-05-29
kernel, this build tracks upstream `main` (2026-10-22 at time of writing), incorporating
UART DMA fixes, UVC stability, and aic8800 monitor-mode support. In addition, roughly
**370 lines** of repetitive boot-time kernel log spam are eliminated.

**What keeps working:** launcher, Settings, Wi-Fi, USB networking
(`10.33.42.1` / `10.33.43.1`), display, touch, camera, and NPU acceleration.
The core system is preserved — only optional bloat is pruned.

#### Who is this for?

- **Recommended for:** Dedicated single-purpose appliances, users needing free storage,
  and developers wanting an up-to-date kernel.
- **Not suited for:** Users who want to try out every built-in demo immediately after flashing.
  Use the official vendor image instead, or reinstall specific apps via App Store.

Removed components:

- `/root/models/*` — Pre-loaded LLM / VLM / TTS / image-gen / YOLO demo models
- 44 demo apps (`classifier` 83 MB, `camera`, `detector`, `speech`, `photos`, etc.)
- Most of `site-packages` (`torch`, `transformers`, `diffusers`, `scipy`,
  `sklearn`, `numba`, `llvmlite`, `cv2`, `av`, `onnxruntime`, `sympy`,
  `yolo_world_utils`, etc.)
- `/maixapp/share/picture/*` (sample photos)
- `/opt/scripts/llm` (local LLM helper scripts)

Retained components:

- `launcher` / `settings` / `app_store`
- `maix`, `maixpy`, `axengine`, `PIL`, `numpy`, `yaml`, `pip`, `setuptools`,
  `packaging`, `psutil`, `typing_extensions`, `pkg_resources`
- `/maixapp/share/font` (required for CJK / Japanese font rendering)

### Requirements

| Item | Value |
|---|---|
| **Build OS** | Ubuntu 22.04 / 24.04 / 26.04 — Linux required (loop mount + ext4 tools) |
| Disk space | 30 GB or more free (build) |
| Privileges | `sudo` access for editing the rootfs |
| Base image | Official `maixcam2-2026-05-29-maixpy-v4.12.5.img` (10,793,779,200 bytes) |
| Toolchain | `gcc-arm-9.2-2019.12` aarch64 |
| SDK | `sipeed/maix_ax620e_sdk` (with git submodules) |

> **The build runs on Linux. Flashing does not have to.**
> Editing the image needs `loop` mount and ext4 tools, so the build host must be
> Linux. The finished `out/maixcam2-slim.img` can then be flashed from
> **Windows** (Win32DiskImager, recommended) or **Linux** (`dd`).

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

make check          # verify build environment (ext4 magic, tools, disk space)
sudo make prepare   # copy official image into out/ (needs root, chowns back to you)
sudo make slim      # remove demo apps, models, and heavy packages (needs root)
sudo make patch     # apply system configs, scripts, and boot parameters (needs root)
make kernel         # fetch SDK -> kernel HEAD -> patch -> build -> sign (no root)
sudo make write-kernel   # write compiled kernel to p14 (slot A)
sudo make verify    # verify resulting image integrity
```

> **Only the image-editing steps need root.**
> `prepare` / `slim` / `patch` / `write-kernel` / `verify` mount or write the image
> and therefore need `sudo`. `make kernel` only builds the SDK — run it as your
> normal user so the SDK and build artifacts stay yours.
> Running everything with `sudo` also works, but the SDK will be owned by root.

> `make kernel` clones the SDK; the initial run downloads several GB and takes 10+ minutes. Set `SDK_DIR` to reuse an existing checkout.

Output image:

```text
out/maixcam2-slim.img
```

### Flashing

See [docs/FLASH.md](docs/FLASH.md).
Flashing runs on **Windows** (**Win32DiskImager**, recommended) or **Linux** (`dd`).
Rufus rejects this image due to the board's custom partition table.

```powershell
winget install Win32diskimager.win32diskimager
```

> ⚠️ Flashing completely overwrites the eMMC storage. Back up your data first.

### After First Boot

```sh
resize2fs /dev/mmcblk0p17      # grow rootfs to full 29 GB eMMC capacity
df -h /
```

Optional Wi-Fi configuration at build time:

```bash
export WIFI_SSID=your-ssid
export WIFI_PASS=your-password
export LOCALE=ja
```

### Partition Layout (Important)

This board does **not** use standard MBR/GPT partitioning. Partitions are defined by
U-Boot's `blkdevparts` parameter, fixing byte offsets within the `.img` file.

| # | Name | Offset (bytes) | Size (bytes) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` writes solely to p14 (slot A). p15 (slot B) preserves the vendor
base kernel and serves as a boot fallback.

### Patches

#### Rootfs

| File | Purpose |
|---|---|
| `opt/scripts/wifi.sh` | AP-mode fixes (DHCP generation, subnet isolation, hostapd/udhcpd lifecycle, 802.11n), hides passwords from logs, and sets `aicwf_dbg_level=1`. |
| `opt/scripts/update_kernel.sh` | A/B-safe kernel updater; writes only to the inactive slot by default (`--switch`, `--both`, `--dry-run`). |
| `opt/scripts/update_dtb.sh` | A/B-safe DTB updater (p12/p13). |
| `etc/fstab` | Hardens `/boot` (`umask=077`) and sizes `/tmp` and `/dev/shm` (64 MB tmpfs). |
| `etc/rc.local` | Synchronizes system clock from RTC at boot (`hwclock --hctosys --utc`). |
| `etc/sysctl.d/99-maixcam2.conf` | Memory and paging tuning (`vm.min_free_kbytes=16384`, `swappiness=10`, `dirty_ratio=20/10`). |
| `etc/systemd/journald.conf.d/99-maixcam2.conf` | Caps journal log size (256 MB max, 1 week retention). |
| `etc/systemd/system/launcher.service.d/restart.conf` | Adds `Restart=always` for launcher resilience. |
| `maixapp/apps/app.info` | Prunes launcher app registration to `app_store` and `settings`. |
| (generated) `/maixapp/maixcam_lib.version` | Generates missing runtime version file, preventing the "Runtime not installed" launcher warning. |

#### Kernel (`patches/kernel/`)

| Patch | Change |
|---|---|
| `0001-quiet-noisy-kernel-logs.patch` | Silences unconditional `printk` in `aic8800` (`get_txpwr_max`, etc.) via `AICWFDBG(LOGDEBUG)`. Silences `aic_btsdio` per-frame logging. Removes panel DCS command hex dumps. Silences Hynitron touch driver `HYN_ENTER()` and notifier logs. |

Effect:

| Item | Before | After |
|---|---:|---:|
| Boot dmesg line count | ~888 | **~510** |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

> Essential error logs (`Load %s fail`, `wrong size`, `AICBT_ERR`, etc.) are preserved.

### Notes

- **Flashing erases all eMMC data.** Back up your files before proceeding.
- Rootfs modification requires **root privileges (`sudo`)**.
- A different base image version may require adjusted partition offsets or patch rebasing.
- The compiled touch driver is `hyn_driver_release_qm/` (`hyn/` is an unused legacy copy); the patch updates both.

### Upstream References

This project is **not a fork**. Upstream projects and resources:

| Name | Link | Purpose |
|---|---|---|
| **MaixCAM2 System / OS** | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html> | Official firmware images & flashing guide |
| MaixCAM2 FAQ | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_faq.html> | Official troubleshooting guide |
| Sipeed Downloads | <https://dl.sipeed.com/> | Official tools and binaries |
| AXDL (Windows) | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z> | `.axp` flashing and unbricking tool |
| AXDL Driver | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z> | USB driver for AXDL |
| `sipeed/maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | Build environment |
| `sipeed/maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | Upstream kernel repository |
| `sipeed/maix_ax620e_sdk_msp` | <https://github.com/sipeed/maix_ax620e_sdk_msp> | Media & NPU middleware |
| `sipeed/MaixPy` | <https://github.com/sipeed/MaixPy> | Python runtime |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | AArch64 cross-compiler |

> Kernel patches target `sipeed/maix_ax620e_sdk_kernel` branch `main` (`f0c18b62` as of 2026-10-22).

### Acknowledgements

Thanks to Sipeed, Axera, and all upstream open-source contributors.

### License

The **build scripts and patches** in this repository are licensed under the MIT License.
Third-party components inside the base image remain under their respective licenses; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

---

## 日本語

Sipeed MaixCAM2 の**公式イメージを最小化**し、**最新カーネル**と
**ログ抑制パッチ**を適用するためのビルドスクリプトおよびパッチです。

> 本プロジェクトは**非公式**であり、Sipeed 社とは一切関係ありません。
> Sipeed リポジトリの **フォーク（fork）ではありません**。
> **ベンダーバイナリの再配布は行いません。** 各自が公式配布元からダウンロードした
> イメージに対してローカルで変換処理を行います。

### 何が変わるか

**ひとことで言うと:** イメージが **10.5 GB から 3.1 GB** に縮小し、ランチャーの表示は
**46 個から 2 個**（Settings と App Store）になり、カーネルが **新しくなって起動時のログが大幅に減ります**。

| 項目 | 公式 2026-05-29 | 本スクリプト適用後 |
|---|---:|---:|
| rootfs 使用量 | 10,500 MB（空き 2.3 MB） | 約 3,100 MB（空き 約 6,500 MB） |
| `resize2fs` 後の空き容量（29GB eMMC） | — | **空き 約 26 GB** |
| アプリ数 | 46 個 | `settings` / `app_store`（+ `launcher` シェル） |
| AI モデル | 4.39 GB | 0（`/root/models` を空に） |
| Python パッケージ | 2.0 GB / 231 個 | 135 MB / 28 個 |
| カーネル | 2026-05-29 | **HEAD + ログ抑制パッチ** |
| 起動時 dmesg ログ行数 | 約 888 行 | **約 510 行** |

#### 具体的な変化

**「買ってすぐ実用できる」状態になります。** 公式イメージは多数のデモ、AI モデル、
およびそれらが依存する Python パッケージをすべて同梱しているため、10.5 GB の rootfs
パーティションがほぼ満杯です（空き容量はわずか **2.3 MB**）。手動で何かを削除しない限り、
パッケージのインストールも写真の保存も行えません。本スクリプト適用後は **約 6.5 GB** の
空き容量が確保され、29 GB の eMMC 上で `resize2fs` を実行すれば **約 26 GB** の空きが生まれます。

**ランチャー画面が整理されます。** ホーム画面に表示されるのは **Settings** と
**App Store** のみになります。同梱デモアプリは削除されますが、必要に応じていつでも
App Store から再インストール可能です。

**大容量モデルと不要ライブラリを完全除去します。** 4.39 GB に及ぶ各種モデル
（LLM、VLM、音声合成、画像生成、YOLO 各種）と、それらが利用する重量級 Python
パッケージ（`torch`, `transformers`, `diffusers` 等）を削除します。これらに依存するデモは、
モデルを再取得するまで動作しません。

**カーネルが新しくなり、起動時のログが大幅に減ります。** 公式イメージ同梱の 2026-05-29 カーネルに対し、
本ビルドは上流の `main` ブランチ（作成時点: 2026-10-22）を採用しています。
UART DMA の修正、UVC 動作の安定化、aic8800 のモニターモード修正などが含まれます。
さらに、起動時に出ていた冗長なログを約 **370 行** 削減します。

**維持される機能:** ランチャー、設定、Wi-Fi、USB ネットワーク
（`10.33.42.1` / `10.33.43.1`）、ディスプレイ表示、タッチパネル操作、カメラ入力、
NPU 推論。基本システムはそのまま保持し、追加の肥大化要因のみを削ぎ落としています。

#### 向いている用途 / 向いていない用途

- **向いている用途:** 特定の単一アプリを動かす専用端末、空きストレージ容量を確保したい場合、
  最新カーネルの修正を取り入れたい場合。
- **向いていない用途:** 焼いた直後に同梱デモアプリを一通り動作確認したい場合。
  その場合は公式イメージをご利用いただくか、App Store から必要なアプリを再導入してください。

削除されるもの:

- `/root/models/*`（LLM / VLM / 音声 / 画像生成 / YOLO 各種のデモモデル）
- デモアプリ 44 個（`classifier` 83 MB、`camera`、`detector`、`speech`、`photos` ほか）
- `site-packages` の大半（`torch`、`transformers`、`diffusers`、`scipy`、`sklearn`、
  `numba`、`llvmlite`、`cv2`、`av`、`onnxruntime`、`sympy`、`yolo_world_utils` 等）
- `/maixapp/share/picture/*`（デモ用サンプル写真）
- `/opt/scripts/llm`（ローカル LLM 用ヘルパースクリプト）

保持されるもの:

- `launcher` / `settings` / `app_store`
- `maix`、`maixpy`、`axengine`、`PIL`、`numpy`、`yaml`、`pip`、`setuptools`、
  `packaging`、`psutil`、`typing_extensions`、`pkg_resources`
- `/maixapp/share/font`（日本語・CJK フォント表示に必須）

### 動作要件

| 項目 | 要件 |
|---|---|
| **ビルド OS** | Ubuntu 22.04 / 24.04 / 26.04 — Linux 必須（loop mount と ext4 ツール） |
| 空き容量 | 30 GB 以上（ビルド用） |
| 権限 | rootfs 編集用の `sudo` 権限 |
| ベースイメージ | 公式 `maixcam2-2026-05-29-maixpy-v4.12.5.img`（10,793,779,200 バイト） |
| ツールチェーン | `gcc-arm-9.2-2019.12` aarch64 |
| SDK | `sipeed/maix_ax620e_sdk`（サブモジュール含む） |

> **ビルドは Linux、書き込みは Windows でも可。**
> イメージの編集に `loop` マウントと ext4 ツールが必要なため、ビルド環境は Linux です。
> 完成した `out/maixcam2-slim.img` の書き込みは **Windows**（Win32DiskImager、推奨）
> または **Linux**（`dd`）で行えます。

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

### 書き込み手順

詳細は [docs/FLASH.md](docs/FLASH.md) を参照してください。
書き込みは **Windows**（**Win32DiskImager**、推奨）または **Linux**（`dd`）で行えます。
Rufus は独自パーティションレイアウトのため非対応です。

```powershell
winget install Win32diskimager.win32diskimager
```

> ⚠️ 書き込みを行うと eMMC の全データが消去されます。必要なデータは必ず事前にバックアップしてください。

### 初回起動後の作業

```sh
resize2fs /dev/mmcblk0p17      # rootfs を 29 GB 全域に拡張
df -h /
```

ビルド時に Wi-Fi や言語を設定する場合（環境変数指定）:

```bash
export WIFI_SSID=your-ssid
export WIFI_PASS=your-password
export LOCALE=ja
```

### パーティション構成（重要）

本基板は **一般的な MBR/GPT 形式ではありません**。U-Boot の `blkdevparts`
パラメータ（`mmcblk0:768K(spl),512K(ddrinit),...`）でパーティションが定義されているため、
`.img` 内のバイトオフセットは固定です。

| # | 名前 | オフセット (B) | サイズ (B) |
|---|---|---:|---:|
| 14 | kernel (A) | 22,806,528 | 67,108,864 |
| 15 | kernel_b (B) | 89,915,392 | 67,108,864 |
| 16 | boot (FAT32) | 157,024,256 | 134,217,728 |
| 17 | rootfs (ext4) | 291,241,984 | 10,502,537,216 |

`50_write_kernel.sh` は p14（A スロット）のみに書き込みます。p15（B スロット）はベースイメージのカーネルがそのまま残るため、起動障害時のフォールバックとして利用できます。

### パッチ内容

#### rootfs

| 対象ファイル | 内容 |
|---|---|
| `opt/scripts/wifi.sh` | AP モードの修正（DHCP 生成、ネットワーク分離、ホストプロセスのライフサイクル、802.11n 対応）、パスワードのログ非表示化、`aicwf_dbg_level=1` の設定。 |
| `opt/scripts/update_kernel.sh` | A/B スロット安全更新スクリプト。既定では非アクティブスロットにのみ書き込みを実施（`--switch`、`--both`、`--dry-run` 対応）。 |
| `opt/scripts/update_dtb.sh` | A/B スロット安全 DTB 更新スクリプト（p12/p13）。 |
| `etc/fstab` | `/boot` の保護（`umask=077`）、`/tmp` および `/dev/shm` の tmpfs 最適化（64MB）。 |
| `etc/rc.local` | 起動時の RTC 時刻同期（`hwclock --hctosys --utc`）。 |
| `etc/sysctl.d/99-maixcam2.conf` | メモリ・ページング設定の最適化（`vm.min_free_kbytes=16384`、`swappiness=10`、`dirty_ratio=20/10`）。 |
| `etc/systemd/journald.conf.d/99-maixcam2.conf` | systemd ジャーナルログの上限設定（最大 256MB、保持期間 1 週間）。 |
| `etc/systemd/system/launcher.service.d/restart.conf` | ランチャーの自動再起動設定（`Restart=always`）。 |
| `maixapp/apps/app.info` | ランチャーの登録アプリを `app_store` と `settings` のみに整理。 |
| （自動生成）`/maixapp/maixcam_lib.version` | ベンダーイメージで欠落しているバージョンファイルを補完し、ランチャーの「Runtime not installed」誤表示を防止。 |

#### カーネル（`patches/kernel/`）

| パッチ | 変更内容 |
|---|---|
| `0001-quiet-noisy-kernel-logs.patch` | `aic8800` の無条件 `printk`（`get_txpwr_max` 等）を `AICWFDBG(LOGDEBUG)` に変更。`aic_btsdio` の毎フレームログ出力を停止。パネル DCS コマンドの 16 進ダンプ出力を削除。タッチ操作時の `HYN_ENTER()` および notifier ログを停止。 |

効果:

| 項目 | 変更前 | 変更後 |
|---|---:|---:|
| 起動時の dmesg 行数 | 約 888 | **約 510** |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

> 注意: エラー系の重要ログ（`Load %s fail`、`wrong size`、`AICBT_ERR` 等）は維持しています。

### 注意事項

- **書き込みを実行すると eMMC の全データが消去されます。** 必要なデータは必ず事前にバックアップしてください。
- rootfs を直接編集するため **root 権限（`sudo`）** が必要です。
- ベースイメージのバージョンが異なる場合、パーティションオフセットやパッチの調整が必要になる場合があります。
- 実際にビルドされるタッチドライバは `hyn_driver_release_qm/` です（`hyn/` は未使用の旧ドライバコピーですが、念のため両方に適用しています）。

### 参照元（上流）

**本プロジェクトはフォーク（fork）ではありません。** 参照および利用しているプロジェクト・公式ドキュメント一覧です。

| 名称 | リンク | 用途 |
|---|---|---|
| **MaixCAM2 System / OS** | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html> | 公式ファームウェアの入手および書き込み手順 |
| MaixCAM2 FAQ | <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_faq.html> | トラブルシューティング |
| Sipeed ダウンロード | <https://dl.sipeed.com/> | 公式ツール類 |
| AXDL（Windows） | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z> | `.axp` 書き込み・復旧ツール |
| AXDL ドライバ | <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z> | AXDL 用 USB ドライバ |
| `sipeed/maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | ビルド環境 |
| `sipeed/maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | パッチ対象の上流カーネル |
| `sipeed/maix_ax620e_sdk_msp` | <https://github.com/sipeed/maix_ax620e_sdk_msp> | メディアおよび NPU ミドルウェア |
| `sipeed/MaixPy` | <https://github.com/sipeed/MaixPy> | Python ランタイム |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | AArch64 クロスコンパイラ |

> カーネルパッチは `sipeed/maix_ax620e_sdk_kernel` の `main` ブランチ（確認時点: `f0c18b62`, 2026-10-22）に対して作成しています。

### 謝辞

Sipeed、Axera、および関連オープンソースソフトウェアの開発者コミュニティに感謝いたします。

### ライセンス

本リポジトリに含まれる**ビルドスクリプトおよびパッチ**は MIT ライセンスです。
ベースイメージに含まれる第三者の成果物は、それぞれのライセンスに従います。詳細は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照してください。
