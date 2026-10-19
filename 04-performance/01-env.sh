# This script will setup XiangShan environment variables for checkpoint
# See 01-checkpoint.ipynb

source ../env.sh

# constant
export WORKLOAD=stream_100000
export CHECKPOINT_INTERVAL=$((50*1000*1000))

# path
export SIMPOINT_HOME=${WORK_DIR}/03-performance/01-checkpoint

export GCPT_PATH=${SIMPOINT_HOME}/gcpt
export LOG_PATH=${SIMPOINT_HOME}/logs
export RESULT_PATH=${SIMPOINT_HOME}/result

export PROFILING_RESULT_PATH=${RESULT_PATH}/profiling

# binary
export NEMU=${NEMU_HOME}/build/riscv64-nemu-interpreter
export GCPT=${GCPT_PATH}/build/gcpt.bin
export SIMPOINT=${NEMU_HOME}/resource/simpoint/simpoint_repo/bin/simpoint

mkdir -p ${SIMPOINT_HOME}
