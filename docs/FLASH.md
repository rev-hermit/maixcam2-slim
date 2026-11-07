# 書き込み手順 / Flashing Guide

- [日本語](#日本語)
- [English](#english)

---

## 日本語

### ⚠️ 注意

- **書き込むと eMMC の内容はすべて消えます。** 先にバックアップしてください。
- 実機の型番は MaixCAM2（eMMC 起動）。`*_sd.img` は TF カード起動用なので使わないでください。

### 1. アップグレードモードに入る

1. 実機の電源を切る（USB を抜く）
2. USB ケーブルを PC につなぐ
3. 電源を入れ、**1 秒以内に Func（boot）ボタンを押し続ける**
4. **3 秒ほどで離す**

PC 側に「約 29GB の USB ディスク」が見えれば成功です。
`Linux File-Stor Gadget` / serial `maixcam2` のように表示されます。

### 2. 書き込みツール

**Win32DiskImager** を使います。

```powershell
winget install Win32diskimager.win32diskimager
```

> **Rufus は使えません。** このイメージは独自パーティションレイアウトのため
> 「非対応のイメージです」と拒否されます。

### 3. 書き込み

1. Win32DiskImager を**管理者として**起動
2. **Image File** に `out/maixcam2-slim.img` を指定
3. **Device** で 29GB のデバイスを選択（**他のディスクを選ばないこと**）
4. **Write** → 確認で「はい」
5. 完了まで待つ（10.05GiB / 40MB/s 前後で 5〜10 分）

書き込み後に Windows が「フォーマットしますか？」と聞いてきても **キャンセル**。

### 4. 代替: Linux から `dd`

```bash
lsblk -o NAME,SIZE,MODEL,TRAN     # 29.1G の USB デバイスを確認（例: /dev/sdb）
sudo dd if=out/maixcam2-slim.img of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

`/dev/sdX` はサイズ（29.1G）と `TRAN=usb` を必ず確認してから指定してください。

### 5. 初回起動後

```sh
# rootfs を 29GB に拡張（必須）
resize2fs /dev/mmcblk0p17
df -h /

# 確認
uname -a
fw_printenv -n bootsystem
systemctl --failed
```

### 6. 起動しないとき

1. **B スロットへ戻す**（SSH が入れる場合）

   ```sh
   /etc/init.d/S99checkboot systemB
   reboot
   ```

2. **AXDL で復旧**（Method 1）
   - `maixcam2-2026-05-29-maixpy-v4.12.5.axp`
   - AXDL: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z>
   - ドライバ: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z>

3. **ブート部だけ復旧** → `boot_parts_*.axp` を AXDL で焼き、その後 `.img` を書き直す

---

## English

### ⚠️ Warning

- **Flashing erases the entire eMMC.** Back up your data first.
- Target is MaixCAM2 (eMMC boot). Do not use `*_sd.img` (that one boots from a TF card).

### 1. Enter upgrade mode

1. Power off (unplug USB)
2. Connect the USB cable to your PC
3. Power on, then **press and hold Func (boot) within 1 second**
4. **Release after about 3 seconds**

A ~29 GB USB disk should appear on the PC
(shown as `Linux File-Stor Gadget`, serial `maixcam2`).

### 2. Flashing tool

Use **Win32DiskImager**.

```powershell
winget install Win32diskimager.win32diskimager
```

> **Rufus will not work.** It rejects this image ("unsupported image") because
> the board uses a custom partition layout.

### 3. Flash

1. Start Win32DiskImager **as administrator**
2. Select `out/maixcam2-slim.img` as **Image File**
3. Select the 29 GB **Device** (do **not** pick any other disk)
4. Click **Write** and confirm
5. Wait for completion (10.05 GiB, ~5-10 min at ~40 MB/s)

If Windows asks to format the disk afterwards, choose **Cancel**.

### 4. Alternative: `dd` from Linux

```bash
lsblk -o NAME,SIZE,MODEL,TRAN     # find the 29.1G USB device (e.g. /dev/sdb)
sudo dd if=out/maixcam2-slim.img of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

Always verify size (29.1G) and `TRAN=usb` before choosing `/dev/sdX`.

### 5. After first boot

```sh
# grow the rootfs to 29 GB (required)
resize2fs /dev/mmcblk0p17
df -h /

# check
uname -a
fw_printenv -n bootsystem
systemctl --failed
```

### 6. Recovery

1. **Switch back to slot B** (if SSH is available)

   ```sh
   /etc/init.d/S99checkboot systemB
   reboot
   ```

2. **Recover with AXDL** (Method 1)
   - `maixcam2-2026-05-29-maixpy-v4.12.5.axp`
   - AXDL: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/AXDL_V1.24.22.1.7z>
   - Driver: <https://dl.sipeed.com/fileList/MaixCAM/MaixCAM2/Software/Tools/Driver_V1.20.46.1.7z>

3. **Restore the boot area only** with `boot_parts_*.axp`, then reflash the `.img`.
