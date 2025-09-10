#!/usr/bin/env bash

# NOTE: this script is for developers to pack assets for release, do not use if not necessary

set -e

source ./env.sh

ASSETS_LIST=$(find ${ASSETS_DIR} -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)

for ASSET in ${ASSETS_LIST}; do
  if [ -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Packing ${ASSET}..."
    tar -I zstd -cf "${ASSETS_DIR}/${ASSET}.tar.zst" -C "${ASSETS_DIR}" "${ASSET}"
  fi
done
