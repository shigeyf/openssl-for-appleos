#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for iPhoneOS and iPhoneSimulator
#

for TARGET in ${TARGETS}
do
  # Determine relevant SDK version
  if [[ "${TARGET}" == tvos* ]]; then
    SDKVERSION="${TVOS_SDKVERSION}"
  elif [[ "${TARGET}" == "mac-catalyst"* ]]; then
    SDKVERSION="${MACOSX_SDKVERSION}"
  else
    SDKVERSION="${IOS_SDKVERSION}"
  fi

  # These variables are used in the configuration file
  export SDKVERSION
  export IOS_MIN_SDK_VERSION
  export TVOS_MIN_SDK_VERSION
  export CONFIG_DISABLE_BITCODE

  # Determine platform
  if [[ "${TARGET}" == "iossimulator-"* ]]; then
    PLATFORM="iPhoneSimulator"
  elif [[ "${TARGET}" == "tvossimulator-"* ]]; then
    PLATFORM="AppleTVSimulator"
  elif [[ "${TARGET}" == "tvos64-"* ]]; then
    PLATFORM="AppleTVOS"
  else
    PLATFORM="iPhoneOS"
  fi

  # Extract ARCH from TARGET (part after last dash)
  ARCH=$(echo "${TARGET}" | sed -E 's|^.*\-([^\-]+)$|\1|g')

  # Prepare TARGETDIR and SOURCEDIR
  prepare_target_source_dirs

  ## Determine config options
  # Add build target, --prefix and prevent async (references to getcontext(),
  # setcontext() and makecontext() result in App Store rejections) and creation
  # of shared libraries (default since 1.1.0)
  LOCAL_CONFIG_OPTIONS="${TARGET} --prefix=${TARGETDIR} ${CONFIG_OPTIONS} no-async no-shared"

  # Only relevant for 64 bit builds
  if [[ "${CONFIG_ENABLE_EC_NISTP_64_GCC_128}" == "true" && "${ARCH}" == *64  ]]; then
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
  fi

  # Run Configure
  run_configure

  # Run make
  run_make

  # Run make install
  set -e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make install_dev | tee -a "${LOG}"
  else
    make install_dev >> "${LOG}" 2>&1
  fi

  # Remove source dir, add references to library files to relevant arrays
  # Keep reference to first build target for include file
  finish_build_loop
done
