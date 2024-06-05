#!/usr/bin/env bash

# --- Functions ---

function build_install_stage() {
  # Builds SBCL under a custom stage_dir by copying the source files from src_dir (keeps original src)
  # Installs SBCL under install_dir
  local src_dir=$1
  local stage_dir=$2
  local install_dir=$3

  # Remember the current directory
  local current_dir
  current_dir=$(pwd)

  # Prepare the stage/build directory
  mkdir -p "${stage_dir}"
  cp -r "${src_dir}"/* "${stage_dir}"

  # Configure SBCL build arguments, like host architecture, enable fancy features
  if [[ "${target_platform}" == "linux-aarch64" ]]; then
    SBCL_ARGS=(--fancy --arch=arm64)
  elif [[ "${target_platform}" == "osx-arm64" ]]; then
    SBCL_ARGS=(--fancy --arch=arm64)
  else
    SBCL_ARGS=(--fancy)
  fi

  # Build and install SBCL
  cd "${stage_dir}"
    bash make.sh "${SBCL_ARGS[@]}"

    echo "Info for cross-compiling - Temporary"
    echo ""
    echo "   xperfecthash30.lisp-expr"
    echo ""
    cat output/xfloat-math.lisp-expr
    echo ""

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh
  cd "${current_dir}"
}

# --- Main ---

set -ex

# Select the conda architectures that build from source
if [[ "${target_platform}" == "osx-64" ]] || \
   [[ "${target_platform}" == "linux-64" ]] || \
   [[ "${target_platform}" == "linux-aarch64" ]]
then
  # When not cross-compiling, the existing SBCL needs to be installed in the build environment
  if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "0" ]]; then
    mamba install -y sbcl
    export CROSSCOMPILING_EMULATOR=""
  fi
  # When cross-compiling, the build SBCL is installed in the build environment as a dependency

  build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${PREFIX}"

  # Copy the license and credits for conda-recipe packaging
  cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"
  cp "${SRC_DIR}"/sbcl-source/CREDITS "${SRC_DIR}"

# No previous conda version: Need to bootstrap. Once a version is released
# this special case will be merged to the above
elif [[ "${target_platform}" == "linux-ppc64le" ]]; then
  # Install the bootstrap binary in a temporary location
  export INSTALL_ROOT=${SRC_DIR}/_conda_bootstrap-install
  export SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
  sh install.sh > _sbcl_bootstrap-install.log 2>&1

  export PATH=${INSTALL_ROOT}/bin:${PATH}

  # Build SBCL from source
  build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${PREFIX}"

  # Copy the license and credits for conda-recipe packaging
  cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"
  cp "${SRC_DIR}"/sbcl-source/CREDITS "${SRC_DIR}"

# All other architectures install the pre-built SBCL (downloaded in SRC_DIR
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
