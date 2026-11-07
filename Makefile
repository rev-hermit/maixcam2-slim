# MaixCAM2 slim image build / MaixCAM2 最小イメージ ビルド
#
#   make check        環境確認
#   sudo make prepare 公式イメージを out/ にコピー（要 root）
#   sudo make slim    rootfs を最小化（要 root）
#   sudo make patch   rootfs / boot へパッチ適用（要 root）
#   make kernel       カーネルをビルド（SDK 取得 + パッチ + 署名）※ root 不要
#   sudo make write-kernel ビルドしたカーネルを p14 へ書き込み（要 root）
#   sudo make verify  成果物を検証（要 root）
#   sudo make image   prepare + slim + patch + (kernel があれば) write-kernel（要 root）
#
# 環境変数:
#   SRC_IMG      公式 .img のパス（必須）
#   TC_DIR       aarch64 ツールチェーンのディレクトリ（make kernel で必須）
#   SDK_DIR      SDK の置き場（既定: ~/maix/maix_ax620e_sdk）
#   OUT_IMG      出力イメージ（既定: out/maixcam2-slim.img）
#   WIFI_SSID / WIFI_PASS / LOCALE   boot 設定へ書き込む値（任意）

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

PY := python3

.PHONY: all check prepare slim patch kernel write-kernel verify image clean help

all: help

help:
	@sed -n '2,20p' Makefile

check:
	@bash scripts/00_check_env.sh

prepare:
	@bash scripts/10_prepare_image.sh

slim:
	@bash scripts/20_slim_rootfs.sh

patch:
	@bash scripts/30_apply_rootfs_patches.sh

kernel:
	@bash scripts/40_build_kernel.sh

write-kernel:
	@bash scripts/50_write_kernel.sh

verify:
	@bash scripts/90_verify_image.sh

image: prepare slim patch
	@if [ -f out/boot_signed.bin ]; then bash scripts/50_write_kernel.sh; else \
	  echo ""; echo "NOTE: out/boot_signed.bin が無いので rootfs のみのイメージになります"; \
	  echo "      make kernel && make write-kernel でカーネルを差し替えられます"; fi

clean:
	@rm -rf out
