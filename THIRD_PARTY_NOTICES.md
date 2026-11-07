# Third-Party Notices / 第三者ライセンス表記

本リポジトリは **スクリプトとパッチのみ** を配布します。
変換対象のベースイメージは含みません。
This repository distributes **only scripts and patches**.
It does not include the base image it transforms.

## ベースイメージ / Base image

| 配布元 / Source | 内容 / Contents | ライセンス / License |
|---|---|---|
| Sipeed | MaixCAM2 system image (`.img` / `.axp`) | Sipeed の配布条件に従う / See Sipeed's terms |
| Ubuntu / Canonical | rootfs (Ubuntu 22.04 base) | 各パッケージのライセンス / Per-package licenses (GPL, MIT, BSD, ...) |
| Axera | NPU/ISP/VENC などのバイナリとドライバ | Axera のライセンスに従う / Axera proprietary |
| RivieraWaves / AIC | `aic8800` Wi-Fi ドライバ | ドライバ同梱の表記に従う / See in-tree notices |
| Hynitron | タッチパネルドライバ | ドライバ同梱の表記に従う / See in-tree notices |

**再配布する場合は、各自でライセンス条件を確認してください。**
本リポジトリはベンダーバイナリを再配布しないため、この点を回避する構成にしています。
If you redistribute a built image, verify the applicable licenses yourself.
This repository avoids that issue by not redistributing vendor binaries.

## 参照するソフトウェア / Referenced software

| 名前 / Name | URL | ライセンス / License |
|---|---|---|
| maix_ax620e_sdk | https://github.com/sipeed/maix_ax620e_sdk | Sipeed の表記に従う / See repo |
| maix_ax620e_sdk_kernel | https://github.com/sipeed/maix_ax620e_sdk_kernel | Linux kernel (GPL-2.0) ベース |
| MaixPy | https://github.com/sipeed/MaixPy | Apache-2.0 |
| GCC ARM toolchain | https://developer.arm.com/downloads/-/gnu-a | GPL / ARM の条件 |

## 本リポジトリの成果物 / This repository

- スクリプト・パッチ: **MIT**（[LICENSE](LICENSE)）
- Scripts and patches: **MIT** (see [LICENSE](LICENSE))
