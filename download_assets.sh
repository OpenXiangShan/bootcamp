#!/usr/bin/env bash

# Download assets from GitHub release

set -e

source ./env.sh

GITHUB_REPO="OpenXiangShan/xs-env" # TODO: use OpenXiangShan/bootcamp
RELEASE_TAG="rvsc2025-tutorial"    # TODO: use latest release

ASSETS_LIST=(
  "ready-to-run"
  "gem5-data"
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
