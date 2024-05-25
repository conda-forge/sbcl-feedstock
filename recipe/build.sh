#!/usr/bin/env bash

set -ex

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
      bash make.sh --fancy
    else
      bash make.sh > _sbcl_build_log.txt 2>&1
    fi

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh
  cd "${current_dir}"
}

if [[ "${target_platform}" == "osx-64" ]]; then
  mamba install -y sbcl
  build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${SRC_DIR}/_conda_stage1-install" "true"
  cp -r "${INSTALL_ROOT}"/* "${PREFIX}" > /dev/null 2>&1
  cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"
  cp "${SRC_DIR}"/sbcl-source/CREDITS "${SRC_DIR}"
else
  export INSTALL_ROOT=$PREFIX
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
