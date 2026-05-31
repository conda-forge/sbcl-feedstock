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
  if [[ "${target_platform}" == "linux-ppc64le" ]]; then
    SBCL_ARGS+=(--arch=ppc64)
    export SBCL_MAKE_TARGET_2_OPTIONS="--dynamic-space-size 1024"
    export SBCL_RUNTIME_LAUNCHER="${BUILD_PREFIX}/bin/qemu-execve-ppc64le"
  elif [[ "${target_platform}" == "linux-riscv64" ]]; then
    export CC="${ZIG_CC}"
    SBCL_ARGS+=(--arch=riscv64 --without-sb-core-compression)
    export SBCL_MAKE_TARGET_2_OPTIONS="--dynamic-space-size 1024"
    export SBCL_RUNTIME_LAUNCHER="${BUILD_PREFIX}/bin/qemu-execve-riscv64"
    export SBCL_CONTRIB_LAUNCHER="${BUILD_PREFIX}/bin/qemu-riscv64"
  else
    SBCL_ARGS=(--fancy)
  fi
  
  # Build and install SBCL
  cd "${stage_dir}"
    # zig-cc (clang) does not pick up conda's include path the way gcc did; make zstd.h findable
    export CPPFLAGS="${CPPFLAGS:-} -I${PREFIX}/include"

    bash -x make.sh "${SBCL_ARGS[@]}" 2>&1 | tee /tmp/sbcl-make.log
    rc=${PIPESTATUS[0]}
    if [ $rc -ne 0 ]; then
        echo "=== make.sh FAILED with rc=$rc, dumping SBCL internal logs ==="
        for f in output/build*.log output/*.log _conda-build/output/*.log build-output.log; do
            if [ -f "$f" ]; then
                echo "--- $f ---"
                tail -300 "$f"
            fi
        done
        exit $rc
    fi

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh

    # Build shared library on linux systems
    bash make-shared-library.sh > _sbcl_lib_build.log 2>&1
    install -m 644 src/runtime/libsbcl.so "${install_dir}/lib/libsbcl.so"

    if [[ $(uname) == Darwin ]]; then
      ln -s "${install_dir}/lib/libsbcl.so" "${install_dir}/lib/libsbcl.dylib"
    fi

    if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "0" ]]; then
      strip "${install_dir}"/bin/sbcl
    fi
  cd "${current_dir}"
}

# --- Main ---

set -ex

build_install_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda-build" "${PREFIX}"

# Copy the license and credits for conda-recipe packaging
cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"
cp "${SRC_DIR}"/sbcl-source/CREDITS "${SRC_DIR}"

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
  mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
  cp "${RECIPE_DIR}/scripts/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}-${CHANGE}.sh"
done
