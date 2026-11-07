# Changelog / 変更履歴

All notable changes to this project are documented here.
本プロジェクトの主な変更点を記録します。

## [0.1.0] - 2026-11-08

### Added / 追加

- 公式 2026-05-29 イメージを最小化するビルドスクリプト一式
  (`make check` / `prepare` / `slim` / `patch` / `kernel` / `write-kernel` / `verify`)
  Build scripts that slim the official 2026-05-29 image.
- rootfs パッチ（`wifi.sh` AP モード修正、A/B 更新スクリプト、systemd / sysctl / journald / fstab）
  Rootfs patches (AP-mode wifi.sh, A/B update scripts, systemd/sysctl/journald/fstab).
- カーネルパッチ 2 本（ログ静音化）
  Two kernel patches (log quieting).

### Changed / 変更

- `/root/models` を空に、デモアプリ 44 個を削除、`site-packages` を 231 → 28 エントリへ
  Emptied `/root/models`, removed 44 demo apps, reduced `site-packages` from 231 to 28 entries.
- rootfs 使用量 10,500 MB -> 約 3,100 MB（空き 2.3 MB -> 約 6,500 MB）
  rootfs usage 10,500 MB -> ~3,100 MB (free 2.3 MB -> ~6,500 MB).
- 起動時 dmesg 888 行 -> 約 510 行
  Boot-time dmesg 888 -> ~510 lines.

### Fixed / 修正

- 画面に「Runtime not installed」が出る問題（`/maixapp/maixcam_lib.version` を補完）
  "Runtime not installed" on screen (create `/maixapp/maixcam_lib.version`).
- `aic8800` の無条件 `printk`（`get_txpwr_max` など）を抑制
  Suppressed unconditional `printk` in `aic8800` (`get_txpwr_max`, etc.).
- `aic_btsdio` の毎フレームログ、パネル DCS の hex dump、タッチの `HYN_ENTER` を停止
  Stopped per-frame `aic_btsdio` logs, panel DCS hex dumps, and touch `HYN_ENTER`.
- `isc-dhcp-server` が failed で残る問題（disable / mask）
  `isc-dhcp-server` left in failed state (now disabled/masked).
