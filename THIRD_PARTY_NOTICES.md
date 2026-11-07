# Third-Party Notices

Information regarding third-party software, licenses, and components.

**English** | [日本語](#日本語)

---

## English

This repository distributes **only build scripts and patches**.
It does **not** redistribute the vendor base firmware image or third-party binaries.

### Base Image Components

The base firmware image (transformed by these scripts) contains third-party software governed by each vendor's terms and open-source licenses:

| Provider | Components | Applicable Terms / License |
|---|---|---|
| Sipeed | MaixCAM2 system image (`.img` / `.axp`) | Sipeed distribution terms |
| Ubuntu / Canonical | Rootfs (Ubuntu 22.04 LTS base) | Individual package licenses (GPL, MIT, BSD, etc.) |
| Axera | NPU, ISP, and VENC drivers / proprietary binaries | Axera proprietary license |
| RivieraWaves / AIC | `aic8800` Wi-Fi driver | In-tree driver license notices |
| Hynitron | Touchscreen driver | In-tree driver license notices |

> **Redistribution note**: If you redistribute built images, you are responsible for complying with all applicable upstream licenses. This project avoids redistributing proprietary vendor binaries by operating directly on images that users download themselves.

### Referenced Upstream Software

| Project | URL | License |
|---|---|---|
| `maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | See upstream repository notices |
| `maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | Linux kernel (GPL-2.0) |
| `MaixPy` | <https://github.com/sipeed/MaixPy> | Apache-2.0 |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | GPL / ARM license terms |

### Repository License

- Scripts and patches in this repository: **MIT** (see [LICENSE](LICENSE))

---

## 日本語

本リポジトリは **ビルドスクリプトおよびパッチのみ** を配布します。
ベンダー公式のベースファームウェアイメージやバイナリ本体は含みません。

### ベースイメージに含まれるコンポーネント

変換対象となる公式ベースイメージには、各提供元のライセンスに基づく第三者ソフトウェアが含まれます。

| 提供元 | コンポーネント | 適用条件・ライセンス |
|---|---|---|
| Sipeed | MaixCAM2 システムイメージ（`.img` / `.axp`） | Sipeed の配布条件に従う |
| Ubuntu / Canonical | rootfs（Ubuntu 22.04 LTS ベース） | 各パッケージの個別ライセンス（GPL、MIT、BSD 等） |
| Axera | NPU / ISP / VENC ドライバおよびバイナリ | Axera 独自ライセンス |
| RivieraWaves / AIC | `aic8800` Wi-Fi ドライバ | ソースツリー同梱のライセンス表記に従う |
| Hynitron | タッチパネルドライバ | ソースツリー同梱のライセンス表記に従う |

> **再配布に関する注意**: ビルド済みイメージを第三者に再配布する場合は、各自でライセンス条件を確認・遵守してください。本プロジェクトは、利用者が各自で公式イメージを用意して変換を行う構成にすることで、ベンダーバイナリの再配布問題を回避しています。

### 参照しているソフトウェア

| 名称 | URL | ライセンス |
|---|---|---|
| `maix_ax620e_sdk` | <https://github.com/sipeed/maix_ax620e_sdk> | リポジトリのライセンス表記に従う |
| `maix_ax620e_sdk_kernel` | <https://github.com/sipeed/maix_ax620e_sdk_kernel> | Linux カーネル（GPL-2.0） |
| `MaixPy` | <https://github.com/sipeed/MaixPy> | Apache-2.0 |
| ARM GNU Toolchain | <https://developer.arm.com/downloads/-/gnu-a> | GPL / ARM のライセンス条件 |

### 本リポジトリのライセンス

- 本リポジトリのスクリプトおよびパッチ: **MIT ライセンス**（[LICENSE](LICENSE) 参照）
