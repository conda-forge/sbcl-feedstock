#!/usr/bin/env bash

set -ex

function patchelf_rpath() {
  local bin_path=$1
  local abspath=${2:-false}

  if [[ "${abspath}" == "false" ]]; then
    run_path="\$ORIGIN/.."
  elif [[ -d "${abspath}" ]]; then
    run_path=${abspath}
  else
    echo "Error: ${abspath} is not a directory"
    exit 1
  fi

  patchelf --set-interpreter "/lib64/ld-linux-x86-64.so.2" "${bin_path}"
  # patchelf --remove-rpath "${bin_path}"
  run_path="\$ORIGIN/.."
  patchelf --set-rpath "${run_path}/lib" "${bin_path}"

  # patchelf --add-rpath "${run_path}/x86_64-conda-linux-gnu/sysroot/lib64" "${bin_path}"
  # patchelf --add-rpath "${run_path}/lib" "${bin_path}"
  # patchelf --add-rpath "${run_path}/x86_64-conda-linux-gnu/sysroot/usr/lib64" "${bin_path}"
  # patchelf --add-needed librt.so.1 "${bin_path}"
  patchelf --remove-needed ld-linux-x86-64.so.2 "${bin_path}"
}

function build_install_stage() {
  local src_dir=$1
  local stage_dir=$2
  local install_dir=$3

  local current_dir
  current_dir=$(pwd)

  mkdir -p "${stage_dir}"
  cp -r "${src_dir}"/* "${stage_dir}"

  if [[ "${target_platform}" == "linux-ppc64le" ]]; then
    SBCL_ARGS=(--arch=ppc64 --dynamic-space-size=1Gb --without-sb-thread)
  elif [[ "${target_platform}" == "linux-aarch64" ]]; then
    SBCL_ARGS=(--fancy --arch=arm64)
  elif [[ "${target_platform}" == "osx-arm64" ]]; then
    SBCL_ARGS=(--fancy --arch=arm64)
  else
    SBCL_ARGS=(--fancy)
  fi

  cd "${stage_dir}"
    bash make.sh "${SBCL_ARGS[@]}" > _sbcl_build.log 2>&1

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh

    # Patch the rpath of the installed binaries - Actually, this should not be needed since it is done in build
    if [[ "${target_platform}" == "linux-64" ]]; then
      patchelf_rpath "${INSTALL_ROOT}/bin/sbcl"
    fi
  cd "${current_dir}"
}

if [[ "${target_platform}" == "osx-64" ]] || \
   [[ "${target_platform}" == "linux-64" ]] || \
   [[ "${target_platform}" == "linux-ppc64le" ]] || \
   [[ "${target_platform}" == "linux-aarch64" ]]
then
  # sbcl is installed in the host environment if x-compiling
  if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "0" ]]; then
    mamba install -y sbcl
    export CROSSCOMPILING_EMULATOR=""
  fi

  build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${SRC_DIR}/_conda_stage1-install"
  cp -r "${INSTALL_ROOT}"/* "${PREFIX}" > /dev/null 2>&1

  cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"
  cp "${SRC_DIR}"/sbcl-source/CREDITS "${SRC_DIR}"
else
  export INSTALL_ROOT=$PREFIX
  export SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
  sh install.sh
fi

# Install SBCL in conda-forge environment
ACTIVATE_DIR=${PREFIX}/etc/conda/activate.d
DEACTIVATE_DIR=${PREFIX}/etc/conda/deactivate.d
mkdir -p "${ACTIVATE_DIR}"
mkdir -p "${DEACTIVATE_DIR}"

cp "${RECIPE_DIR}"/scripts/activate.sh "${ACTIVATE_DIR}"/sbcl-activate.sh
cp "${RECIPE_DIR}"/scripts/deactivate.sh "${DEACTIVATE_DIR}"/sbcl-deactivate.sh

chmod +x "${ACTIVATE_DIR}"/sbcl-activate.sh
chmod +x "${DEACTIVATE_DIR}"/sbcl-deactivate.sh
