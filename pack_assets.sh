#!/usr/bin/env bash

# NOTE: this script is for developers to pack assets for release, do not use if not necessary

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "${SCRIPT_DIR}" && source ./env.sh && cd -

ASSETS_LIST=$(find ${ASSETS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

function pack_asset() {
  local ASSET=$1
  if [ -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Packing ${ASSET}..."
    tar -I 'zstd -10' -cf "${ASSETS_DIR}/${ASSET}.tar.zst" -C "${ASSETS_DIR}" "${ASSET}"
  fi
}

if [ "$1" != "" ]; then
  if [[ ! "${ASSETS_LIST[@]}" =~ "$1" ]]; then
    echo "Error: Asset $1 not found in ASSETS_LIST"
    exit 1
  fi
  pack_asset $1
else
  echo "Packing all assets..."
  for ASSET in ${ASSETS_LIST}; do
    pack_asset ${ASSET}
  done
fi
