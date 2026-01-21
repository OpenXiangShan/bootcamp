#!/usr/bin/env bash

# NOTE: this script is for developers to pack assets for release, do not use if not necessary

set -e

SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]:-$0}))
source "${SCRIPT_DIR}/env.sh"

ASSETS_LIST=$(find ${ASSETS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

function pack_asset() {
  local ASSET=$1
  if [ -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Packing ${ASSET}..."
    tar -I 'zstd -10' -cf "${ASSETS_DIR}/${ASSET}.tar.zst" -C "${ASSETS_DIR}" "${ASSET}"
    sha256sum "${ASSETS_DIR}/${ASSET}.tar.zst" > "${ASSETS_DIR}/${ASSET}.tar.zst.sha256"
    echo "Done."
    echo "Don't forget to update ASSET_LIST in download_assets.sh with the new hash($(cat "${ASSETS_DIR}/${ASSET}.tar.zst.sha256"))!"
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
