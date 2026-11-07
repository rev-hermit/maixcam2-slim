# MaixCAM2 Slim Firmware

Sipeed MaixCAM2 公式イメージを **デモ・巨大モデル・不要 Python パッケージを削って最小化**し、
最新カーネル（バグ修正入り）とログ静音化パッチを適用したイメージを **手元で再現ビルド**するための
スクリプトとパッチです。

> 本リポジトリは非公式です。Sipeed とは無関係です。
> **ベンダーのバイナリ（Ubuntu rootfs / Axera ドライバ / Sipeed ファーム）は再配布しません。**
> 公式配布イメージを各自ダウンロードし、その場で変換する方式です。

---

## 何が変わるか

| 項目 | 公式 2026-05-29 | このスクリプト適用後 |
|---|---:|---:|
| rootfs 使用量 | 10,500 MB（空き 2.3 MB） | 約 3,100 MB（空き 6,500 MB） |
| `resize2fs` 後（29GB eMMC） | — | 空き 約 26 GB |
| アプリ | デモ 45 個 | `launcher` / `settings` / `app_store` のみ |
| AI モデル | 4.39 GB | 0（`/root/models` を空に） |
| Python パッケージ | 2.0 GB / 231 | 135 MB / 28 |
| カーネル | 2026-05-29 | HEAD（最新）＋ ログ静音化パッチ |
| 起動時 dmesg | 約 888 行 | 約 510 行 |

削除するもの:

- `/root/models/*` … LLM / VLM / 音声 / 画像生成 / YOLO 各種のデモモデル
- デモアプリ 44 個（`classifier` 83MB, `camera`, `detector`, `speech`, `photos` ほか）
- `site-packages` の大半（`torch`, `transformers`, `diffusers`, `scipy`, `sklearn`,
  `numba`, `llvmlite`, `cv2`, `av`, `onnxruntime`, `sympy`, `yolo_world_utils` など）
- `/maixapp/share/picture/*`（デモ写真）
- `/opt/scripts/llm`（ローカル LLM 用ヘルパー）

残すもの:

- `launcher` / `settings` / `app_store`（アプリ一覧と設定、後からアプリを入れられるように）
- `maix`, `maixpy`, `axengine`, `PIL`, `numpy`, `yaml`, `pip`, `setuptools`, `packaging`,
  `psutil`, `typing_extensions`, `pkg_resources`
- `/maixapp/share/font`（日本語表示に必要）

---

## 必要なもの

- **Linux PC**（Ubuntu 22.04 / 24.04 / 26.04 で確認。loop mount と ext4 ツールが必要）
- 空き 30 GB 程度
- MaixCAM2 公式 `.img`（例: `maixcam2-2026-05-29-maixpy-v4.12.5.img`）
  配布元: <https://wiki.sipeed.com/hardware/en/maixcam/maixcam2_os.html>
- aarch64 ツールチェーン（gcc 9.2）
  <https://developer.arm.com/downloads/-/gnu-a>
- リポジトリ: `sipeed/maix_ax620e_sdk`（submodule 含む）

---

## 使い方

```bash
git clone <this repo>
cd maixcam2-slim

# 1) 公式イメージを用意（パスを指定）
export SRC_IMG=/path/to/maixcam2-2026-05-29-maixpy-v4.12.5.img

# 2) 環境チェック
make check

# 3) rootfs を最小化（公式イメージをコピーして編集）
make slim

# 4) カーネルをビルド（SDK 取得 + パッチ適用 + 署名）
make kernel

# 5) ビルドしたカーネルをイメージの A スロットへ書き込む
make write-kernel

# 6) 検証（サイズ・ハッシュ・中身）
make verify
```

成果物:

```
out/maixcam2-slim.img
```

### 焼き方

[docs/FLASH.md](docs/FLASH.md) を参照。
**Win32DiskImager** を使います（Rufus はこのイメージの独自パーティションレイアウトを扱えません）。

### 初回起動後

```sh
resize2fs /dev/mmcblk0p17      # 29GB に拡張
```

---

## パッチ内容

### rootfs

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
| （追加）`/maixapp/maixcam_lib.version` | ベンダーイメージ欠落のため補完（「Runtime not installed」対策） |

### kernel

| パッチ | 内容 |
|---|---|
| `0001-quiet-noisy-kernel-logs-...` | `aic8800` の無条件 `printk`（`get_txpwr_max` など）を `AICWFDBG(LOGDEBUG)` へ。`aic_btsdio` の毎フレームログを停止。パネル DCS の `print_hex_dump` 削除 |
| `0002-quiet-hynitron-touch-driver-logs-...` | タッチドライバの `HYN_ENTER()` と notifier ログを停止 |

---

## 注意

- **書き込むと eMMC の内容はすべて消えます。** 必ずバックアップしてください。
- 本スクリプトは rootfs を編集するため **root 権限（sudo）** が必要です。
- ベースイメージのバージョンが変わると、パッチやオフセットの調整が必要になる場合があります。
- ライセンスは [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照。

## License

本リポジトリの**スクリプトとパッチ**は MIT。
ベースイメージに含まれる第三者の成果物は、それぞれのライセンスに従います。
