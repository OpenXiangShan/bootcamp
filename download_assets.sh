#!/usr/bin/env bash

# Download assets from GitHub release

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "${SCRIPT_DIR}" && source ./env.sh && cd -

GITHUB_REPO="OpenXiangShan/bootcamp"
RELEASE_TAG="25.09.10"

ASSETS_LIST=(
  "emu-precompile"
  "gem5-precompile"
  "workload"
  "emu-perf-result"
  "emu-spec-topdown-result"
  "gem5-spec-topdown-result"
  "tltest-precompile"
)

if [ -z "${ASSETS_DIR}" ]; then
  echo "Error: ASSETS_DIR is not set, source ./env.sh may failed"
  exit 1
fi

mkdir -p ${ASSETS_DIR}

function download_asset() {
  local ASSET=$1
  if [ -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Asset folder ${ASSET} already exists, overwrite..."
    rm -rf "${ASSETS_DIR}/${ASSET}"
  fi

  if [ ! -f "${ASSETS_DIR}/${ASSET}.tar.zst" ]; then
    echo "Downloading ${ASSET} from GitHub release..."
    curl -Ljo "${ASSETS_DIR}/${ASSET}.tar.zst" "https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ASSET}.tar.zst"
  fi

  echo "Extracting ${ASSET}..."
  tar -I zstd -xf "${ASSETS_DIR}/${ASSET}.tar.zst" -C "${ASSETS_DIR}"
  # rm "${ASSETS_DIR}/${ASSET}.tar.zst"
}

if [ "$1" != "" ]; then
  if [[ ! "${ASSETS_LIST[@]}" =~ "$1" ]]; then
    echo "Error: Asset $1 not found in ASSETS_LIST"
    exit 1
  fi
  download_asset $1
  exit 0
else
  echo "Downloading all assets..."
  for ASSET in "${ASSETS_LIST[@]}"; do
    download_asset ${ASSET}
  done
fi
