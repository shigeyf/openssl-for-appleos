#!/bin/sh

#  Automatic build script for libssl and libcrypto


# -u  Attempt to use undefined variable outputs error message, and forces an exit
set -u

#
# Default configurations
#

# Default version in case no version is specified
DEFAULTVERSION="1.1.1g"
# Default (=full) set of targets to build
DEFAULTTARGETS="iossimulator-xcrun-x86_64 ios64-xcrun-arm64 ios64-xcrun-arm64e tvossimulator-xcrun-x86_64 tvos64-xcrun-arm64"

# Init optional env variables (use available variable or default to empty string)
CURL_OPTIONS="${CURL_OPTIONS:-}"
CONFIG_OPTIONS="no-idea no-dso no-hw no-engine"
CONFIG_OPTIONS="${CONFIG_OPTIONS:-}"

# Default Enabled options in 1.1.1g
# no-afalgeng
# no-asan
# no-async
# no-buildtest-c++
# no-crypto-mdebug
# no-crypto-mdebug-backtrace
# no-devcryptoeng
# no-dynamic-engine
# no-ec_nistp_64_gcc_128
# no-egd
# no-engine
# no-external-tests
# no-fuzz-afl
# no-fuzz-libfuzzer
# no-heartbeats
# no-md2
# no-msan
# no-rc5
# no-sctp
# no-shared
# no-ssl-trace
# no-ssl3
# no-ssl3-method
# no-tests
# no-ubsan
# no-unit-test
# no-weak-ssl-ciphers
# no-zlib
# no-zlib-dynamic

# Not enabled
# no-dso
# no-hw
# no-comp
# no-idea
# no-dtls
# no-dtls1
# no-threads
# no-err
# no-npn / no-nextprotoneg
# no-psk
# no-srp
# no-ec2m


################################################################################
# main scripts
################################################################################

# Write files relative to current location and validate directory
CURRENTPATH=$(pwd)
case "${CURRENTPATH}" in
  *\ * )
    echo "Your path contains whitespaces, which is not supported by 'make install'."
    exit 1
  ;;
esac
cd "${CURRENTPATH}"
# Determine script directory
SCRIPTDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

source "${SCRIPTDIR}/scripts/print_help.sh"
source "${SCRIPTDIR}/scripts/build_options.sh"
source "${SCRIPTDIR}/scripts/build_tools.sh"
source "${SCRIPTDIR}/scripts/xcode_sdk.sh"

source "${SCRIPTDIR}/scripts/openssl_download.sh"
source "${SCRIPTDIR}/scripts/openssl_build.sh"

# Init optional command line vars
CONFIG_DISABLE_BITCODE=""
LOG_VERBOSE=""
TARGETS=""

# Process command line arguments
for i in "$@"
do
case $i in
  --branch=*)
    BRANCH="${i#*=}"
    shift
    ;;
  --cleanup)
    BUILD_CLEANUP="true"
    ;;
  --disable-bitcode)
    CONFIG_DISABLE_BITCODE="true"
    ;;
  -h|--help)
    print_help
    exit
    ;;
  --noparallel)
    PARALLEL_BUILD="false"
    ;;
  --targets=*)
    TARGETS="${i#*=}"
    shift
    ;;
  -v|--verbose)
    LOG_VERBOSE="verbose"
    ;;
  --verbose-on-error)
    LOG_VERBOSE="verbose-on-error"
    ;;
  --version=*)
    VERSION="${i#*=}"
    shift
    ;;
  *)
    echo "Unknown argument: ${i}"
    ;;
esac
done


# Set default for TARGETS if not specified
if [ ! -n "${TARGETS}" ]; then
  TARGETS="${DEFAULTTARGETS}"
fi

tools_create_build_target_dirs
set_build_threads
set_xcode_sdk_version
show_build_options

# -e  Abort script at first error, when a command exits with non-zero status (except in until or while loops, if-tests, list constructs)
# -o pipefail  Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value
set -eo pipefail

openssl_download
openssl_build_for_targets

echo "Done."
