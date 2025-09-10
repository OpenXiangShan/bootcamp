set -e

export XS_PROJECT_ROOT=$(pwd)

# submodule
export NEMU_HOME=${XS_PROJECT_ROOT}/NEMU
export AM_HOME=${XS_PROJECT_ROOT}/nexus-am
export NOOP_HOME=${XS_PROJECT_ROOT}/XiangShan
export DRAMSIM3_HOME=${XS_PROJECT_ROOT}/DRAMsim3
export GEM5_HOME=${XS_PROJECT_ROOT}/GEM5

# assets and workdir
export ASSETS_DIR=${XS_PROJECT_ROOT}/assets
export WORK_DIR=${XS_PROJECT_ROOT}/work

function get_asset() {
  local ASSET=$1
  if [ ! -d "${ASSETS_DIR}/${ASSET}" ]; then
    echo "Asset ${ASSET} not found, downloading..." >&2
    bash ${XS_PROJECT_ROOT}/download_assets.sh ${ASSET} >&2
    if [ $? -ne 0 ]; then
      echo "Failed to download asset ${ASSET}, please check your network or download it manually from https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}" >&2
      exit 1
    fi
  fi
  echo "${ASSETS_DIR}/${ASSET}"
}
