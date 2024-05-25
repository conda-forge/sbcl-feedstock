#!/usr/bin/env bash

set -ex

XC_HOST="--xc-host='sbcl --disable-debugger --no-userinit --no-sysinit'"
if [[ "${target_platform}" == "linux-ppc64le" ]]; then
  SBCL_ARGS="${XC_HOST}  --arch=ppc64le"
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
  echo "Building for aarch64"
  SBCL_ARGS="${XC_HOST}  --arch=arm64"
elif [[ "${target_platform}" == "osx-arm64" ]]; then
  SBCL_ARGS="${XC_HOST}  --arch=arm64"
else
  SBCL_ARGS=""
fi

# if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" ]]; then
#   CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_TABLEGEN_EXE=$BUILD_PREFIX/bin/llvm-tblgen -DNATIVE_LLVM_DIR=$BUILD_PREFIX/lib/cmake/llvm"
#   CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD;-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2;-DCMAKE_EXE_LINKER_FLAGS=\"-L$BUILD_PREFIX/lib\";-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS=;-DCMAKE_STATIC_LINKER_FLAGS=;-DCMAKE_AR=$(which ${AR});-DCMAKE_RANLIB=$(which ${RANLIB});-DCMAKE_PREFIX_PATH=${BUILD_PREFIX}"
# else
#   rm -rf $BUILD_PREFIX/bin/llvm-tblgen
# fi

function build_install_stage() {
  local src_dir=$1
  local stage_dir=$2
  local install_dir=$3
  local final=${4:-false}
  local current_dir

  current_dir=$(pwd)

  mkdir -p "${stage_dir}"
  cp -r "${src_dir}"/* "${stage_dir}"

  cd "${stage_dir}"
    if [[ "${final}" == "true" ]]; then
      bash make.sh --fancy ${SBCL_ARGS}
    else
      bash make.sh > _sbcl_build_log.txt 2>&1
    fi

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh
  cd "${current_dir}"
}

case $(uname) in
  Darwin)
    mamba install -y sbcl
    build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${SRC_DIR}/_conda_stage1-install" "true"
    cp -r "${INSTALL_ROOT}"/* "${PREFIX}" > /dev/null 2>&1
    ;;
  *)
    export INSTALL_ROOT=$PREFIX
    sh install.sh
    ;;
esac

cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"

# Install SBCL in conda-forge environment
ACTIVATE_DIR=${PREFIX}/etc/conda/activate.d
DEACTIVATE_DIR=${PREFIX}/etc/conda/deactivate.d
mkdir -p "${ACTIVATE_DIR}"
mkdir -p "${DEACTIVATE_DIR}"

cp "${RECIPE_DIR}"/scripts/activate.sh "${ACTIVATE_DIR}"/sbcl-activate.sh
cp "${RECIPE_DIR}"/scripts/deactivate.sh "${DEACTIVATE_DIR}"/sbcl-deactivate.sh

chmod +x "${ACTIVATE_DIR}"/sbcl-activate.sh
chmod +x "${DEACTIVATE_DIR}"/sbcl-deactivate.sh
