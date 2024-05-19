#!/usr/bin/env bash

set -ex

mamba install -y sbcl

INSTALL_ROOT="${BUILD_PREFIX}"
SBCL_HOME="${INSTALL_ROOT}/lib/sbcl"
export INSTALL_ROOT SBCL_HOME PATH="${INSTALL_ROOT}/bin:${PATH}"

function bootstrap_sbcl() {
  local bootstrapping_dir=$1
  local build_prefix=$2
  local install_dir=$3
  local current_dir

  current_dir=$(pwd)

  INSTALL_ROOT=${install_dir}
  SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
  export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}

  cd "${bootstrapping_dir}"
    # Install SBCL in $INSTALL_ROOT
    ./install.sh
    # Bootstrapped SBCL is linked to GLIBC 2.35, but only needs 2.28
    patchelf \
        --set-interpreter "${build_prefix}/x86_64-conda-linux-gnu/sysroot/lib64/ld-${LIBC_CONDA_VERSION-2.28}".so \
        --set-rpath "${build_prefix}/x86_64-conda-linux-gnu/sysroot/lib64" \
        "${INSTALL_ROOT}"/bin/sbcl

    # shellcheck disable=SC2086
    ldd ${INSTALL_ROOT}/bin/sbcl > _ldd_bootstrapped_sbcl.txt
  cd "${current_dir}"
}

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

  # Odd case where the SONAME are removed from the executables, thus failing to be parsed by LIEF
  # patchelf --set-soname "${run_path}/x86_64-conda-linux-gnu/sysroot/lib64/ld-linux-x86-64.so.2" "${bin_path}"
}

function build_stage() {
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
      bash make.sh --fancy > _sbcl_build_log.txt 2>&1
    else
      bash make.sh > _sbcl_build_log.txt 2>&1
    fi

    INSTALL_ROOT=${install_dir}
    SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
    export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
    bash install.sh

    case "$(uname)" in
      Linux)
        # Oddly, the executable fails to be parsed correctly by LIEF
        if [[ "${final}" == "true" ]]; then
          patchelf_rpath "${INSTALL_ROOT}"/bin/sbcl
        else
          patchelf_rpath "${INSTALL_ROOT}"/bin/sbcl "${BUILD_PREFIX}"
        fi
      ;;
    esac
  cd "${current_dir}"
}

function elf_debug() {
  local ext=$1

  ldd "${INSTALL_ROOT}"/bin/sbcl > _ldd_sbcl${ext:-}.txt
  readelf -d "${INSTALL_ROOT}"/bin/sbcl > _readelf_sbcl${ext:-}.txt
  python "${RECIPE_DIR}"/build_helpers/elf_reader.py -a --debug "${INSTALL_ROOT}"/bin/sbcl > _python_elf_info${ext:-}.txt 2>&1
}

function install_sbcl() {
  cp -r "${INSTALL_ROOT}"/* "${PREFIX}" > /dev/null 2>&1

  INSTALL_ROOT=${PREFIX}
  SBCL_HOME=${INSTALL_ROOT}/lib/sbcl
  case "$(uname)" in
    Linux)
      patchelf_rpath "${INSTALL_ROOT}"/bin/sbcl
      ;;
  esac

  export INSTALL_ROOT SBCL_HOME PATH=${INSTALL_ROOT}/bin:${PATH}
}

# Once merged, use previous Conda version of SBCL to bootstrap the new version
# mamba install -y sbcl

# BOOTSTRAPPED_DIR="${SRC_DIR}/_conda_bootstrapped"

# bootstrap_sbcl "${SRC_DIR}/bootstrapping" "${BUILD_PREFIX}" "${SRC_DIR}/_conda_bootstrapped"
# elf_debug "_bootstrapped"
build_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage1-build" "${SRC_DIR}/_conda_stage1-install" false

case "$(uname)" in
  Linux)
    elf_debug "_stage1"
    ;;
esac

build_stage "${SRC_DIR}/sbcl-source" "${SRC_DIR}/_conda_stage2-build" "${SRC_DIR}/_conda_stage2-install"

strip "${INSTALL_ROOT}"/bin/sbcl
cp "${SRC_DIR}"/sbcl-source/COPYING "${SRC_DIR}"

case "$(uname)" in
  Linux)
    elf_debug "_stage2"
    ;;
esac
install_sbcl

# Install SBCL in conda-forge environment
ACTIVATE_DIR=${PREFIX}/etc/conda/activate.d
DEACTIVATE_DIR=${PREFIX}/etc/conda/deactivate.d
mkdir -p "${ACTIVATE_DIR}"
mkdir -p "${DEACTIVATE_DIR}"

cp "${RECIPE_DIR}"/scripts/activate.sh "${ACTIVATE_DIR}"/sbcl-activate.sh
cp "${RECIPE_DIR}"/scripts/deactivate.sh "${DEACTIVATE_DIR}"/sbcl-deactivate.sh
