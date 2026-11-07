# Patches

Overview of patches applied to the kernel and rootfs.

**English** | [日本語](#日本語)

---

## English

### Kernel (`patches/kernel/`)

#### `0001-quiet-noisy-kernel-logs.patch`

Silences verbose kernel log output at boot.

| Target file | Changes |
|---|---|
| `rwnx_platform.c` | Replaced unconditional `printk` calls in `get_txpwr_max()`, `set_txpwr_loss_ofst()`, `rwnx_load_firmware()`, and userconfig upload with `AICWFDBG(LOGDEBUG, ...)`. These can now be suppressed with `aicwf_dbg_level=1`. |
| `aic_btsdio.h` | Changed `AICBT_DBG_FLAG` from 1 to 0 to disable per-frame logging. |
| `btsdio.c` / `aic_btsdio.c` | Changed per-frame `AICBT_INFO` to `AICBT_DBG`. |
| `ax-panel-simple.c` | Removed per-DCS-command hex dump (`print_hex_dump` / `"send success, cmd:"`). |
| `hyn/hyn_core.h` | Disabled `HYN_ENTER` in the legacy/unused driver copy. |
| `hyn_driver_release_qm/hyn_core.h` | Made `HYN_ENTER()` a no-op to eliminate `[HYN][enter]release_all_finger` on every touch release. |
| `hyn_driver_release_qm/hyn_core.c` | Demoted touch notifier and "don't care" logs to `HYN_INFO2` (enabled only when `log_level > 0`). |

#### Effect

| Item | Before | After |
|---|---:|---:|
| Boot dmesg line count | ~888 | **~510** |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

> Note: Essential error logs (`Load %s fail`, `wrong size`, `AICBT_ERR`, etc.) are preserved.

### Rootfs (`patches/rootfs/`)

| Patch file | Destination | Purpose |
|---|---|---|
| `opt.scripts/wifi.sh` | `/opt/scripts/wifi.sh` | Fixes AP mode (DHCP generation, network isolation, hostapd/udhcpd lifecycle, 802.11n), hides passwords from logs, and sets `aicwf_dbg_level=1`. |
| `opt.scripts/update_kernel.sh` | `/opt/scripts/update_kernel.sh` | A/B-safe kernel updater. Writes only to the inactive slot by default; supports `--switch`, `--both`, and `--dry-run`. |
| `opt.scripts/update_dtb.sh` | `/opt/scripts/update_dtb.sh` | A/B-safe DTB updater (p12/p13). |
| `etc.fstab` | `/etc/fstab` | Hardens `/boot` (`umask=077`) and sizes `/tmp` and `/dev/shm` (64 MB tmpfs). |
| `etc.rc.local` | `/etc/rc.local` | Synchronizes system clock from RTC at boot (`hwclock --hctosys --utc`). |
| `etc.sysctl.d.99-maixcam2.conf` | `/etc/sysctl.d/` | Memory and paging tuning (`vm.min_free_kbytes=16384`, `swappiness=10`, `dirty_ratio=20/10`). |
| `etc.systemd.journald.conf.d.99-maixcam2.conf` | `/etc/systemd/journald.conf.d/` | Caps journal log size (256 MB max, 1 week retention). |
| `etc.systemd.system.launcher.service.d.restart.conf` | `/etc/systemd/system/launcher.service.d/` | Adds `Restart=always` for launcher resilience. |
| `maixapp.app.info` | `/maixapp/apps/app.info` | Prunes launcher app registration to `app_store` and `settings`. |

> Note: `/maixapp/maixcam_lib.version` and `/usr/lib/libmaixcam_lib.so.<ver>` are generated during build by `20_slim_rootfs.sh` to resolve the "Runtime not installed" error.

---

## 日本語

### カーネル（`patches/kernel/`）

#### `0001-quiet-noisy-kernel-logs.patch`

起動時に大量に出力されていた冗長なログを抑制します。

| 対象ファイル | 変更内容 |
|---|---|
| `rwnx_platform.c` | `get_txpwr_max()`、`set_txpwr_loss_ofst()`、`rwnx_load_firmware()`、userconfig 転送時の無条件 `printk` を `AICWFDBG(LOGDEBUG, ...)` に変更し、`aicwf_dbg_level=1` で非表示化可能に修正。 |
| `aic_btsdio.h` | `AICBT_DBG_FLAG` を 1 から 0 に変更し、フレーム毎のログ出力を停止。 |
| `btsdio.c` / `aic_btsdio.c` | フレーム送受信ごとの `AICBT_INFO` を `AICBT_DBG` に降格。 |
| `ax-panel-simple.c` | DCS コマンド送信ごとの 16 進ダンプ出力（`print_hex_dump` / `"send success, cmd:"`）を削除。 |
| `hyn/hyn_core.h` | 未使用のレガシードライバ内にある `HYN_ENTER` を無効化。 |
| `hyn_driver_release_qm/hyn_core.h` | タッチ操作のたびに出力されていた `[HYN][enter]release_all_finger` を防ぐため、`HYN_ENTER()` を no-op 化。 |
| `hyn_driver_release_qm/hyn_core.c` | notifier および "don't care" ログを `HYN_INFO2` に降格（`log_level > 0` の場合のみ出力）。 |

#### 効果

| 項目 | 変更前 | 変更後 |
|---|---:|---:|
| 起動時の dmesg 行数 | 約 888 | **約 510** |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

> 注意: エラー系の重要ログ（`Load %s fail`、`wrong size`、`AICBT_ERR` 等）は維持しています。

### rootfs（`patches/rootfs/`）

| パッチファイル | 配置先 | 内容 |
|---|---|---|
| `opt.scripts/wifi.sh` | `/opt/scripts/wifi.sh` | AP モードの修正（DHCP 生成、ネットワーク分離、ホストプロセスのライフサイクル、802.11n 対応）、パスワードのログ非表示化、`aicwf_dbg_level=1` の設定。 |
| `opt.scripts/update_kernel.sh` | `/opt/scripts/update_kernel.sh` | A/B スロット安全更新スクリプト。既定では非アクティブスロットにのみ書き込みを実施（`--switch`、`--both`、`--dry-run` 対応）。 |
| `opt.scripts/update_dtb.sh` | `/opt/scripts/update_dtb.sh` | A/B スロット安全 DTB 更新スクリプト（p12/p13）。 |
| `etc.fstab` | `/etc/fstab` | `/boot` の保護（`umask=077`）、`/tmp` および `/dev/shm` の tmpfs 最適化（64MB）。 |
| `etc.rc.local` | `/etc/rc.local` | 起動時の RTC 時刻同期（`hwclock --hctosys --utc`）。 |
| `etc.sysctl.d.99-maixcam2.conf` | `/etc/sysctl.d/` | メモリ・ページング設定の最適化（`vm.min_free_kbytes=16384`、`swappiness=10`、`dirty_ratio=20/10`）。 |
| `etc.systemd.journald.conf.d.99-maixcam2.conf` | `/etc/systemd/journald.conf.d/` | systemd ジャーナルログの上限設定（最大 256MB、保持期間 1 週間）。 |
| `etc.systemd.system.launcher.service.d.restart.conf` | `/etc/systemd/system/launcher.service.d/` | ランチャーの自動再起動設定（`Restart=always`）。 |
| `maixapp.app.info` | `/maixapp/apps/app.info` | ランチャーの登録アプリを `app_store` と `settings` のみに整理。 |

> 補足: `/maixapp/maixcam_lib.version` および `/usr/lib/libmaixcam_lib.so.<ver>` は、「Runtime not installed」表示を防ぐためビルド時に `20_slim_rootfs.sh` が自動生成します。
