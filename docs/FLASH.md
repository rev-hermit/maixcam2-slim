# Flashing Guide

Guide for flashing the minimal image to the MaixCAM2 eMMC storage.

**English** | [日本語](#日本語)

---

## English

### ⚠️ Important Notice

- **Flashing will completely erase all data on the eMMC.** Back up important files first.
- Target device is MaixCAM2 (boots from internal eMMC). Do not use `*_sd.img`, which is designed for TF card boot.

### 1. Enter Upgrade Mode

1. Power off the device (disconnect USB cable).
2. Connect the USB cable between the device and your PC.
3. Power on the device, and **press and hold the Func (boot) button within 1 second**.
4. **Release the button after approximately 3 seconds**.

Once recognized, a ~29 GB USB mass storage drive will appear on your PC (reported as `Linux File-Stor Gadget`, serial `maixcam2`).

### 2. Flashing Tool

Use **Win32DiskImager**:

```powershell
winget install Win32diskimager.win32diskimager
```

> **Rufus cannot be used.** Rufus rejects this image as "unsupported" due to the custom partition layout.

### 3. Flashing Process

1. Run Win32DiskImager **as administrator**.
2. Set **Image File** to `out/maixcam2-slim.img`.
3. In **Device**, select the 29 GB target drive (**verify drive letter carefully; do not select other drives**).
4. Click **Write** and confirm the prompt.
5. Wait for the write to finish (~5-10 minutes at ~40 MB/s for 10.05 GiB).

> If Windows prompts to "Format disk" after writing, click **Cancel**.

### 4. Alternative: Flashing with `dd` on Linux

```bash
lsblk -o NAME,SIZE,MODEL,TRAN     # Identify the ~29.1G USB disk (e.g., /dev/sdb)
sudo dd if=out/maixcam2-slim.img of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

> Double check size (~29.1G) and `TRAN=usb` before running `dd` on `/dev/sdX`.

### 5. After First Boot

Run the following commands on the device (via SSH or serial terminal):

```sh
# Expand rootfs to fill the full 29 GB eMMC (required)
resize2fs /dev/mmcblk0p17
df -h /

# Verify system status
uname -a
fw_printenv -n bootsystem
systemctl --failed
```

### 6. Recovery Methods

1. **Revert to slot B** (if SSH access is still possible):

   ```sh
   /etc/init.d/S99checkboot systemB
   reboot
   ```

2. **Full recovery via AXDL**:
   - Firmware package: `maixcam2-2026-05-29-maixpy-v4.12.5.axp`
   - AXDL tool: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z>
   - USB driver: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z>

3. **Bootloader recovery only**: Flash `boot_parts_*.axp` using AXDL, then reflash the `.img` via Win32DiskImager.

---

## 日本語

### ⚠️ 注意事項

- **書き込みを実行すると eMMC の全データが消去されます。** 必要なデータは必ず事前にバックアップしてください。
- 対象機種は MaixCAM2（内蔵 eMMC 起動）です。`*_sd.img` は TF カード起動専用のため使用しないでください。

### 1. アップグレードモードへの移行

1. 本機の電源を切ります（USB ケーブルを外す）。
2. PC と本機を USB ケーブルで接続します。
3. 電源を入れ、**1 秒以内に Func（boot）ボタンを長押し**します。
4. **約 3 秒押し続けた後に離します**。

正常に認識されると、PC 側に約 29 GB の USB ドライブ（デバイス名 `Linux File-Stor Gadget` / シリアル `maixcam2`）が表示されます。

### 2. 書き込みツールの準備

**Win32DiskImager** を使用します。

```powershell
winget install Win32diskimager.win32diskimager
```

> **注意**: Rufus は独自パーティションレイアウトを認識できず「非対応のイメージです」と拒否されるため使用できません。

### 3. イメージの書き込み

1. Win32DiskImager を**管理者権限で実行**します。
2. **Image File** に `out/maixcam2-slim.img` を選択します。
3. **Device** で認識された約 29 GB のドライブを選択します（**誤って別のディスクを選ばないよう慎重に確認してください**）。
4. **Write** をクリックし、確認ダイアログで「はい」を押します。
5. 書き込み完了まで待機します（10.05 GiB、約 40 MB/s で 5〜10 分程度）。

> 書き込み後に Windows から「フォーマットしますか？」と警告されても、必ず **キャンセル** してください。

### 4. 代替手順: Linux 上で `dd` を使う場合

```bash
lsblk -o NAME,SIZE,MODEL,TRAN     # 約 29.1G かつ TRAN=usb のデバイス名を確認（例: /dev/sdb）
sudo dd if=out/maixcam2-slim.img of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

> `/dev/sdX` の指定を誤ると PC のディスクが破壊されます。サイズ（29.1G）と `TRAN=usb` を必ず再確認してください。

### 5. 初回起動後の作業

実機へ SSH またはシリアルコンソールでログインし、以下のコマンドを実行します。

```sh
# rootfs を 29 GB 全域に拡張（必須）
resize2fs /dev/mmcblk0p17
df -h /

# 状態確認
uname -a
fw_printenv -n bootsystem
systemctl --failed
```

### 6. 起動トラブル時の復旧

1. **B スロットへの切り替え**（SSH ログインが可能な場合）:

   ```sh
   /etc/init.d/S99checkboot systemB
   reboot
   ```

2. **AXDL による完全復旧**:
   - ファームウェア: `maixcam2-2026-05-29-maixpy-v4.12.5.axp`
   - AXDL ツール: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z>
   - USB ドライバ: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z>

3. **ブートローダーのみの復旧**: AXDL で `boot_parts_*.axp` を書き込んだ後、再度 Win32DiskImager で `.img` を書き込み直します。
