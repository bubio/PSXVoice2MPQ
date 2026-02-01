#!/bin/bash
set -euo pipefail

STORMLIB_VERSION="v9.31"
CACHE_DIR="${TMPDIR:-/tmp}/stormlib_build_cache"
SRC_DIR="${CACHE_DIR}/StormLib-${STORMLIB_VERSION}"
BUILD_DIR="${SRC_DIR}/build_universal"
ARCHIVE_URL="https://github.com/ladislav-zezula/StormLib/archive/refs/tags/${STORMLIB_VERSION}.tar.gz"
BUILD_DYLIB_NAME="libstorm.dylib"
OUTPUT_DYLIB_NAME="libStorm.dylib"

# Skip if already present in BUILT_PRODUCTS_DIR
if [ -f "${BUILT_PRODUCTS_DIR}/${OUTPUT_DYLIB_NAME}" ]; then
  echo "StormLib already built, skipping."
  exit 0
fi

mkdir -p "${CACHE_DIR}"

# Download source if not cached
if [ ! -d "${SRC_DIR}" ]; then
  echo "Downloading StormLib ${STORMLIB_VERSION}..."
  curl -sL "${ARCHIVE_URL}" | tar xz -C "${CACHE_DIR}"
  # The archive extracts as StormLib-<version without v prefix>
  EXTRACTED_DIR="${CACHE_DIR}/StormLib-${STORMLIB_VERSION#v}"
  if [ -d "${EXTRACTED_DIR}" ] && [ "${EXTRACTED_DIR}" != "${SRC_DIR}" ]; then
    mv "${EXTRACTED_DIR}" "${SRC_DIR}"
  fi
fi

# Build universal binary if not cached
if [ ! -f "${BUILD_DIR}/${BUILD_DYLIB_NAME}" ]; then
  echo "Building StormLib ${STORMLIB_VERSION} (universal binary)..."
  # Patch CMakeLists.txt to disable FRAMEWORK (produces plain .dylib)
  sed -i '' 's/set_target_properties(${LIBRARY_NAME} PROPERTIES FRAMEWORK true)/# FRAMEWORK disabled for plain dylib build/' "${SRC_DIR}/CMakeLists.txt"
  mkdir -p "${BUILD_DIR}"
  cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DSTORM_SKIP_INSTALL=ON
  cmake --build "${BUILD_DIR}" --config Release
fi

# Copy to BUILT_PRODUCTS_DIR (rename to match expected library name)
echo "Copying ${OUTPUT_DYLIB_NAME} to ${BUILT_PRODUCTS_DIR}..."
cp "${BUILD_DIR}/${BUILD_DYLIB_NAME}" "${BUILT_PRODUCTS_DIR}/${OUTPUT_DYLIB_NAME}"
