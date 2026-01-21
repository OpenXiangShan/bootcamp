#!/usr/bin/env bash

# Download assets from GitHub release

set -e

SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]:-$0}))
source "${SCRIPT_DIR}/env.sh"

GITHUB_REPO="OpenXiangShan/bootcamp"
RELEASE_TAG="25.09.10"

# Format: "name sha256"; leave hash empty until filled.
ASSETS_LIST=(
  "emu-precompile ab9363b943ea584c30acb6a4ce821cb4ff1473e0125c9f7f0964dc5682c9485c"
  "gem5-precompile 6235905e50efe203f8cc13434fdcb898447f79715cb3e9045af30f9521e41aa8"
  "workload a3a0ccb405fd6eb5c4affc254d91ea07bffee7ac7b651d7ff8c84b13be13a8f5"
  "emu-perf-result b43e83cca9d36380afdc0e739df2d0705834fb61311f986bf802fc8a455c1ab8"
  "emu-spec-topdown-result 8403e64d1cde01252d1ac20a91bb38d8ca06e60dea57e0953eac3fddcc1851b2"
  "gem5-spec-topdown-result 21a1b1617e4fa01e1443352eec17fd88e35f94d69d5ce44b6722f855ba55e710"
  "tltest-precompile 1a41b84ba29be9bf0ae7388747686a11bd285624676be505f1002a4e84e33068"
  "gem5-spec06-sms 8da0e4ab1d9caec3452adb87bd499240873558c758a5534982ab8352fb432da0"
  "gem5-spec06-baseline 5411b89e0ee3f13900f8154e242a4c449dbe3a22a20631bdd8e21553530daeb4"
  "gem5-spec06-bop 35a982af4b80a92b64f77a33e263cf774611068ac40fd033e4a02b1877c04c4a"
)

if [ -z "${ASSETS_DIR}" ]; then
  echo "Error: ASSETS_DIR is not set, source ./env.sh may failed"
  exit 1
fi

mkdir -p ${ASSETS_DIR}

function download_asset() {
  local ASSET=$1
  local EXPECTED_HASH=$2
  local ASSET_FILE="${ASSETS_DIR}/${ASSET}.tar.zst"

  if [ -z ${EXPECTED_HASH} ]; then
    echo "Internal Error: Expected hash for asset ${ASSET} is empty, please update ASSETS_LIST in download_assets.sh" >&2
    exit 1
  fi

  if [ -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Asset folder ${ASSET} already exists, overwrite..."
    rm -rf "${ASSETS_DIR}/${ASSET}"
  fi

  if [ -f "${ASSET_FILE}" ]; then
    echo "Verifying existing ${ASSET_FILE}..."
    local CURRENT_HASH
    CURRENT_HASH=$(sha256sum "${ASSET_FILE}" | awk '{print $1}')
    if [ "${CURRENT_HASH}" != "${EXPECTED_HASH}" ]; then
      echo "Hash mismatch for ${ASSET}, redownloading..."
      rm -f "${ASSET_FILE}"
    fi
  fi

  if [ ! -f "${ASSET_FILE}" ]; then
    echo "Downloading ${ASSET} from GitHub release..."
    curl -Ljo "${ASSET_FILE}" "https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ASSET}.tar.zst"

    echo "Verifying downloaded ${ASSET_FILE}..."
    local DOWNLOADED_HASH
    DOWNLOADED_HASH=$(sha256sum "${ASSET_FILE}" | awk '{print $1}')
    if [ "${DOWNLOADED_HASH}" != "${EXPECTED_HASH}" ]; then
      echo "Error: sha256 mismatch for ${ASSET} after download" >&2
      exit 1
    fi
  fi

  echo "Extracting ${ASSET}..."
  tar -I zstd -xf "${ASSET_FILE}" -C "${ASSETS_DIR}"
  # rm "${ASSETS_DIR}/${ASSET}.tar.zst"
}

if [ "$1" != "" ]; then
  for ITEM in "${ASSETS_LIST[@]}"; do
    IFS=' ' read -r NAME HASH <<<"${ITEM}"
    if [ "${NAME}" = "$1" ]; then
      download_asset "${NAME}" "${HASH}"
      exit 0
    fi
  done
  echo "Error: Asset $1 not found in ASSETS_LIST"
  exit 1
else
  echo "Downloading all assets..."
  for ITEM in "${ASSETS_LIST[@]}"; do
    IFS=' ' read -r NAME HASH <<<"${ITEM}"
    download_asset "${NAME}" "${HASH}"
  done
fi
