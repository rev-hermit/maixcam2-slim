# Changelog

All notable changes to this project are documented here.

**English** | [日本語](#日本語)

---

## English

### [0.1.0] - 2026-11-08

#### Added
- Build scripts to create a minimal firmware from the official 2026-05-29 image (`make check`, `prepare`, `slim`, `patch`, `kernel`, `write-kernel`, `verify`).
- Rootfs patches: Wi-Fi AP mode fix (`wifi.sh`), A/B update scripts (`update_kernel.sh`, `update_dtb.sh`), and optimized configurations (`systemd`, `sysctl`, `journald`, `fstab`).
- Kernel patch for boot/runtime log quieting (suppresses verbose Wi-Fi, Bluetooth, panel, and touch logs).

#### Changed
- Restructured README with English first, followed by the Japanese section.
- Cleaned rootfs: emptied `/root/models`, removed 44 demo apps, and pruned `site-packages` from 231 to 28 packages.
- Reduced rootfs size from 10,500 MB to ~3,100 MB (free space increased from 2.3 MB to ~6,500 MB).
- Reduced boot-time dmesg logs from ~888 lines to ~510 lines.

#### Fixed
- Fixed "Runtime not installed" error on display by generating `/maixapp/maixcam_lib.version`.
- Suppressed unconditional `printk` in `aic8800` (`get_txpwr_max`, etc.).
- Silenced per-frame `aic_btsdio` logs, panel DCS hex dumps, and `HYN_ENTER` touch logs.
- Disabled and masked failed `isc-dhcp-server` service.

---

## 日本語

### [0.1.0] - 2026-11-08

#### 追加
- 公式 2026-05-29 イメージを最小化するビルドスクリプト一式（`make check` / `prepare` / `slim` / `patch` / `kernel` / `write-kernel` / `verify`）。
- rootfs パッチ（`wifi.sh` AP モード修正、A/B スロット対応更新スクリプト、systemd / sysctl / journald / fstab の最適化）。
- カーネルログ静音化パッチ（Wi-Fi、Bluetooth、ディスプレイパネル、タッチドライバの冗長ログ抑制を 1 本に集約）。

#### 変更
- README を英語先頭（English first）の構成に変更し、日本語セクションを後半に配置。
- `/root/models` を空にし、デモアプリ 44 個を削除、`site-packages` を 231 から 28 パッケージに削減。
- rootfs 使用量を 10,500 MB から約 3,100 MB に削減（空き容量が 2.3 MB から約 6,500 MB に拡大）。
- 起動時の dmesg ログを約 888 行から約 510 行に削減。

#### 修正
- 画面に「Runtime not installed」と表示される不具合を修正（`/maixapp/maixcam_lib.version` を補完）。
- `aic8800` の無条件 `printk`（`get_txpwr_max` 等）を抑制。
- `aic_btsdio` の毎フレームログ、パネル DCS の hex dump、タッチ時の `HYN_ENTER` ログを停止。
- `isc-dhcp-server` が failed 状態になる問題を修正（無効化・マスク）。
