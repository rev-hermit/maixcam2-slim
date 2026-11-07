# パッチ一覧 / Patch list

- [日本語](#日本語)
- [English](#english)

---

## 日本語

### kernel/

#### `0001-quiet-noisy-kernel-logs-...patch`

起動時に大量に出ていたログを止めます。
Silences the noisy boot-time logs.

| ファイル | 変更 |
|---|---|
| `rwnx_platform.c` | `get_txpwr_max()`, `set_txpwr_loss_ofst()`, `rwnx_load_firmware()`, userconfig の無条件 `printk` を `AICWFDBG(LOGDEBUG, ...)` へ。`aicwf_dbg_level=1` で抑制可能に |
| `aic_btsdio.h` | `AICBT_DBG_FLAG` を 1 → 0（毎フレームのログを停止） |
| `btsdio.c` | フレーム送受信ごとの `AICBT_INFO` を `AICBT_DBG` へ |
| `aic_btsdio.c` | 同上 |
| `ax-panel-simple.c` | DCS コマンド送信ごとの `print_hex_dump`（"send success, cmd:"）を削除 |
| `hyn/hyn_core.h` | 未使用の古いドライバコピーの `HYN_ENTER` を無効化 |

#### `0002-quiet-hynitron-touch-driver-logs-...patch`

実際にビルドされるタッチドライバ（`hyn_driver_release_qm/`）のログを止めます。
Silences the touch driver that is actually built (`hyn_driver_release_qm/`).

| ファイル | 変更 |
|---|---|
| `hyn_driver_release_qm/hyn_core.h` | `HYN_ENTER()` を no-op に（触るたびに出ていた `[HYN][enter]release_all_finger`） |
| `hyn_driver_release_qm/hyn_core.c` | notifier と "don't care" を `HYN_INFO2`（`log_level > 0` のときだけ）へ |

#### 効果 / Effect

| 項目 | 変更前 | 変更後 |
|---|---:|---:|
| dmesg 行数（起動時） | 約 888 | 約 510 |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

エラー系のログ（`Load %s fail`, `wrong size`, `AICBT_ERR` など）は残しています。
Error-path logs (`Load %s fail`, `wrong size`, `AICBT_ERR`, ...) are preserved.

### rootfs/

| ファイル | 配置先 | 内容 |
|---|---|---|
| `opt.scripts/wifi.sh` | `/opt/scripts/wifi.sh` | AP モード修正、パスワード非ログ、`aicwf_dbg_level=1` |
| `opt.scripts/update_kernel.sh` | `/opt/scripts/update_kernel.sh` | 非アクティブスロットのみ書込、`--switch`/`--both`/`--dry-run` |
| `opt.scripts/update_dtb.sh` | `/opt/scripts/update_dtb.sh` | 同上（p12/p13） |
| `etc.fstab` | `/etc/fstab` | `/boot` umask=077、`/tmp`・`/dev/shm` 64M |
| `etc.rc.local` | `/etc/rc.local` | `hwclock --hctosys --utc` |
| `etc.sysctl.d.99-maixcam2.conf` | `/etc/sysctl.d/` | `vm.min_free_kbytes` など |
| `etc.systemd.journald.conf.d.99-maixcam2.conf` | `/etc/systemd/journald.conf.d/` | journal 256M / 1週間 |
| `etc.systemd.system.launcher.service.d.restart.conf` | `/etc/systemd/system/launcher.service.d/` | `Restart=always` |
| `maixapp.app.info` | `/maixapp/apps/app.info` | `app_store` / `settings` のみ |

`/maixapp/maixcam_lib.version` と `/usr/lib/libmaixcam_lib.so.<ver>` は
`20_slim_rootfs.sh` が生成します（「Runtime not installed」対策）。
`/maixapp/maixcam_lib.version` and `/usr/lib/libmaixcam_lib.so.<ver>` are
created by `20_slim_rootfs.sh` (fixes "Runtime not installed").

---

## English

### kernel/

#### `0001-quiet-noisy-kernel-logs-...patch`

| File | Change |
|---|---|
| `rwnx_platform.c` | Unconditional `printk` in `get_txpwr_max()`, `set_txpwr_loss_ofst()`, `rwnx_load_firmware()` and userconfig upload replaced with `AICWFDBG(LOGDEBUG, ...)` so `aicwf_dbg_level=1` can suppress them |
| `aic_btsdio.h` | `AICBT_DBG_FLAG` 1 -> 0 (stops per-frame logging) |
| `btsdio.c` | Per-frame `AICBT_INFO` -> `AICBT_DBG` |
| `aic_btsdio.c` | Same |
| `ax-panel-simple.c` | Removed the per-DCS-command `print_hex_dump` ("send success, cmd:") |
| `hyn/hyn_core.h` | Disabled `HYN_ENTER` in the unused legacy driver copy |

#### `0002-quiet-hynitron-touch-driver-logs-...patch`

| File | Change |
|---|---|
| `hyn_driver_release_qm/hyn_core.h` | `HYN_ENTER()` becomes a no-op (removes `[HYN][enter]release_all_finger` on every touch release) |
| `hyn_driver_release_qm/hyn_core.c` | notifier and "don't care" logs moved to `HYN_INFO2` (only when `log_level > 0`) |

#### Effect

| Item | Before | After |
|---|---:|---:|
| dmesg lines at boot | ~888 | ~510 |
| `get_txpwr_max` | 15 | **0** |
| `aic_btsdio` | 213 | **0** |
| `send success, cmd:` | 97 | **0** |
| `[HYN][enter]` | 20 | **0** |

### rootfs/

| File | Destination | Purpose |
|---|---|---|
| `opt.scripts/wifi.sh` | `/opt/scripts/wifi.sh` | AP-mode fixes, no password logging, `aicwf_dbg_level=1` |
| `opt.scripts/update_kernel.sh` | `/opt/scripts/update_kernel.sh` | Writes only to the inactive slot; `--switch` / `--both` / `--dry-run` |
| `opt.scripts/update_dtb.sh` | `/opt/scripts/update_dtb.sh` | Same (p12/p13) |
| `etc.fstab` | `/etc/fstab` | `/boot` umask=077, `/tmp` and `/dev/shm` 64M |
| `etc.rc.local` | `/etc/rc.local` | `hwclock --hctosys --utc` |
| `etc.sysctl.d.99-maixcam2.conf` | `/etc/sysctl.d/` | `vm.min_free_kbytes` etc. |
| `etc.systemd.journald.conf.d.99-maixcam2.conf` | `/etc/systemd/journald.conf.d/` | journal 256M / 1 week |
| `etc.systemd.system.launcher.service.d.restart.conf` | `/etc/systemd/system/launcher.service.d/` | `Restart=always` |
| `maixapp.app.info` | `/maixapp/apps/app.info` | Keep only `app_store` and `settings` |
