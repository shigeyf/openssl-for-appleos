#
#
#

BUILD_THREADS=1
PARALLEL_BUILD="true"
set_build_threads()
{
    # Determine number of cores for (parallel) build
    if [ "${PARALLEL_BUILD}" != "false" ]; then
        BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')
    fi
}

show_build_options()
{
    # Show build options
    echo
    echo "Build options"
    echo "  OpenSSL version: ${VERSION}"
    echo "  Targets: ${TARGETS}"
    echo "  iOS SDK: ${IOS_SDKVERSION}"
    echo "  tvOS SDK: ${TVOS_SDKVERSION}"
    if [ "${CONFIG_DISABLE_BITCODE}" == "true" ]; then
        echo "  Bitcode embedding disabled"
    fi
    echo "  Number of make threads: ${BUILD_THREADS}"
    if [ -n "${CONFIG_OPTIONS}" ]; then
        echo "  Configure options: ${CONFIG_OPTIONS}"
    fi
    echo "  Build location: ${CURRENTPATH}"
    echo
}
