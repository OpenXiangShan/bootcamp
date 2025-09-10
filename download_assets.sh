#!/usr/bin/env bash

# Download assets from GitHub release

set -e

source ./env.sh

GITHUB_REPO="OpenXiangShan/bootcamp"
RELEASE_TAG="25.09.10"

# TODO: maybe use some method to do on-demand downloading
ASSETS_LIST=(
  "emu-precompile"
  "gem5-precompile"
  "workload"
  # "emu-result"  # large file, containing emu run logs, used by 03-performance/03-topdown.ipynb
  # "gem5-result" # large file, containing gem5 run logs, used by 04-gem5/05-spec06.ipynb
)

mkdir -p ${ASSETS_DIR}

for ASSET in "${ASSETS_LIST[@]}"; do
  if [ ! -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Downloading ${ASSET}..."
    mkdir -p "${ASSETS_DIR}/${ASSET}"
    curl -Ljo "${ASSETS_DIR}/${ASSET}.tar.zst" "https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ASSET}.tar.zst"

    echo "Extracting ${ASSET}..."
    tar -I zstd -xf "${ASSETS_DIR}/${ASSET}.tar.zst" -C "${ASSETS_DIR}/${ASSET}"
    rm "${ASSETS_DIR}/${ASSET}.tar.zst"
  fi
done
