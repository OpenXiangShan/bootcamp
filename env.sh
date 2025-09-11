set -e

export XS_PROJECT_ROOT=$(pwd)

# submodule
export NEMU_HOME=${XS_PROJECT_ROOT}/NEMU
export AM_HOME=${XS_PROJECT_ROOT}/nexus-am
export NOOP_HOME=${XS_PROJECT_ROOT}/XiangShan
export DRAMSIM3_HOME=${XS_PROJECT_ROOT}/DRAMsim3
export GEM5_HOME=${XS_PROJECT_ROOT}/GEM5
export GEM5_DATA_PROC_HOME=${XS_PROJECT_ROOT}/gem5_data_proc

# assets and workdir
export ASSETS_DIR=${XS_PROJECT_ROOT}/assets
export WORK_DIR=${XS_PROJECT_ROOT}/work

function get_asset() {
  local ASSET=$1
  local FOLDER=${ASSET%%/*}
  local FILE=
  [[ "$ASSET" == */* ]] && FILE=${ASSET#*/}

  if [ -e "${ASSETS_DIR}/${ASSET}" ]; then
    echo "${ASSETS_DIR}/${ASSET}"
    return
  fi

  echo "Asset ${ASSET} not found, downloading..." >&2
  bash ${XS_PROJECT_ROOT}/download_assets.sh ${FOLDER} >&2
  if [ $? -ne 0 ]; then
    echo "Failed to download asset ${FOLDER}" >&2
    exit 1
  fi
  echo "${ASSETS_DIR}/${ASSET}"
}
