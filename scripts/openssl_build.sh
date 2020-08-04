#
#
#


INCLUDE_DIR=""
OPENSSLCONF_ALL=()
LIBSSL_IOS=()
LIBCRYPTO_IOS=()
LIBSSL_TVOS=()
LIBCRYPTO_TVOS=()

BUILD_TARGET_DIRS='bin include/openssl lib src'

configure_target()
{
    # Determine relevant SDK version
    if [[ "${TARGET}" == tvos* ]]; then
        SDKVERSION="${TVOS_SDKVERSION}"
    elif [[ "${TARGET}" == ios* ]]; then
        SDKVERSION="${IOS_SDKVERSION}"
    else
        SDKVERSION="${MACOSX_SDKVERSION}"
    fi
    
    # Determine platform
    if [[ "${TARGET}" == "iossimulator-"* ]]; then
        PLATFORM="iPhoneSimulator"
    elif [[ "${TARGET}" == "tvossimulator-"* ]]; then
        PLATFORM="AppleTVSimulator"
    elif [[ "${TARGET}" == "tvos64-"* ]]; then
        PLATFORM="AppleTVOS"
    elif [[ "${TARGET}" == "ios64-"* ]]; then
        PLATFORM="iPhoneOS"
    elif [[ "${TARGET}" == "ios32-"* ]]; then
        PLATFORM="iPhoneOS"
    else
        PLATFORM="MacOSX"
    fi
        # Extract ARCH from TARGET (part after last dash)
    ARCH=$(echo "${TARGET}" | sed -E 's|^.*\-([^\-]+)$|\1|g')

    TARGETDIR="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
}

# Prepare target and source dir in build loop
prepare_target_source_dirs()
{
    # Prepare target dir
    #TARGETDIR="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
    mkdir -p "${TARGETDIR}"
    LOG="${TARGETDIR}/build-openssl-${VERSION}.log"

    echo
    echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}..."
    echo "  Logfile: ${LOG}"

    # Prepare source dir
    SOURCEDIR="${CURRENTPATH}/src/${PLATFORM}-${ARCH}"
    mkdir -p "${SOURCEDIR}"
    tar zxf "${CURRENTPATH}/${OPENSSL_ARCHIVE_FILE_NAME}" -C "${SOURCEDIR}"
    cd "${SOURCEDIR}/${OPENSSL_ARCHIVE_BASE_NAME}"
    chmod u+x ./Configure
}

# Run Configure in build loop
run_configure()
{
    echo "  Configure..."
    set +e
    
    if [ "${LOG_VERBOSE}" == "verbose" ]; then
        ./Configure ${LOCAL_CONFIG_OPTIONS} no-tests | tee "${LOG}"
    else
        (./Configure ${LOCAL_CONFIG_OPTIONS} no-tests > "${LOG}" 2>&1) & tools_build_spinner
    fi
    
    # Check for error status
    tools_command_check_status $? "Configure"
}

# Run make in build loop
run_make()
{
    echo "  Make (using ${BUILD_THREADS} thread(s))..."
    if [ "${LOG_VERBOSE}" == "verbose" ]; then
        make -j "${BUILD_THREADS}" | tee -a "${LOG}"
    else
        (make -j "${BUILD_THREADS}" >> "${LOG}" 2>&1) & tools_build_spinner
    fi

    # Check for error status
    tools_command_check_status $? "make"
}

run_make_install()
{
    echo "  Install ..."
    set -e
    if [ "${LOG_VERBOSE}" == "verbose" ]; then
        make install_dev | tee -a "${LOG}"
    else
        make install_dev >> "${LOG}" 2>&1
    fi
}

# Cleanup and bookkeeping at end of build loop
run_build_finish()
{
    # Return to ${CURRENTPATH} and remove source dir
    cd "${CURRENTPATH}"
    #rm -r "${SOURCEDIR}"


    # Add references to library files to relevant arrays
    if [[ "${PLATFORM}" == AppleTV* ]]; then
        LIBSSL_TVOS+=("${TARGETDIR}/lib/libssl.a")
        LIBCRYPTO_TVOS+=("${TARGETDIR}/lib/libcrypto.a")
        OPENSSLCONF_SUFFIX="tvos_${ARCH}"
    elif [[ "${PLATFORM}" == iPhone* ]]; then
        LIBSSL_IOS+=("${TARGETDIR}/lib/libssl.a")
        LIBCRYPTO_IOS+=("${TARGETDIR}/lib/libcrypto.a")
        OPENSSLCONF_SUFFIX="ios_${ARCH}"
    else
        OPENSSLCONF_SUFFIX="catalyst_${ARCH}"
    fi

    # Copy opensslconf.h to bin directory and add to array
    OPENSSLCONF="opensslconf_${OPENSSLCONF_SUFFIX}.h"
    cp "${TARGETDIR}/include/openssl/opensslconf.h" "${CURRENTPATH}/bin/${OPENSSLCONF}"
    OPENSSLCONF_ALL+=("${OPENSSLCONF}")

    # Keep reference to first build target for include file
    if [ -z "${INCLUDE_DIR}" ]; then
        INCLUDE_DIR="${TARGETDIR}/include/openssl"
    fi
}

build_ios_library()
{
    # Build iOS library if selected for build
    if [ ${#LIBSSL_IOS[@]} -gt 0 ]; then
        echo "Build library for iOS..."
        xcrun lipo -create ${LIBSSL_IOS[@]} -output "${CURRENTPATH}/lib/libssl-iOS.a"
        xcrun lipo -create ${LIBCRYPTO_IOS[@]} -output "${CURRENTPATH}/lib/libcrypto-iOS.a"
        echo "\n=====>iOS SSL and Crypto lib files:"
        echo "${CURRENTPATH}/lib/libssl-iOS.a"
        echo "${CURRENTPATH}/lib/libcrypto-iOS.a"
    fi
}

build_tvos_library()
{
    # Build tvOS library if selected for build
    if [ ${#LIBSSL_TVOS[@]} -gt 0 ]; then
        echo "Build library for tvOS..."
        xcrun lipo -create ${LIBSSL_TVOS[@]} -output "${CURRENTPATH}/lib/libssl-tvOS.a"
        xcrun lipo -create ${LIBCRYPTO_TVOS[@]} -output "${CURRENTPATH}/lib/libcrypto-tvOS.a"
        echo "\n=====>tvOS SSL and Crypto lib files:"
        echo "${CURRENTPATH}/lib/libssl-tvOS.a"
        echo "${CURRENTPATH}/lib/libcrypto-tvOS.a"
    fi
}

setup_opensslconf_h()
{
    # Only create intermediate file when building for multiple targets
    # For a single target, opensslconf.h is still present in $INCLUDE_DIR (and has just been copied to the target include dir)
    if [ ${#OPENSSLCONF_ALL[@]} -gt 1 ]; then
    
        # Prepare intermediate header file
        # This overwrites opensslconf.h that was copied from $INCLUDE_DIR
        OPENSSLCONF_INTERMEDIATE="${CURRENTPATH}/include/openssl/opensslconf.h"
        cp "${CURRENTPATH}/include/opensslconf-template.h" "${OPENSSLCONF_INTERMEDIATE}"

        # Loop all header files
        LOOPCOUNT=0
        for OPENSSLCONF_CURRENT in "${OPENSSLCONF_ALL[@]}" ; do
        
            # Copy specific opensslconf file to include dir
            cp "${CURRENTPATH}/bin/${OPENSSLCONF_CURRENT}" "${CURRENTPATH}/include/openssl"

            # Determine define condition
            case "${OPENSSLCONF_CURRENT}" in
            *_ios_x86_64.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_SIMULATOR && TARGET_CPU_X86_64"
                ;;
            *_ios_i386.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_SIMULATOR && TARGET_CPU_X86"
                ;;
            *_ios_arm64.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64"
                ;;
            *_ios_arm64e.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64E"
                ;;
            *_ios_armv7s.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM && defined(__ARM_ARCH_7S__)"
                ;;
            *_ios_armv7.h)
                DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM && !defined(__ARM_ARCH_7S__)"
                ;;
            *_catalyst_x86_64.h)
                DEFINE_CONDITION="(TARGET_OS_MACCATALYST || (TARGET_OS_IOS && TARGET_OS_SIMULATOR)) && TARGET_CPU_X86_64"
                ;;
            *_tvos_x86_64.h)
                DEFINE_CONDITION="TARGET_OS_TV && TARGET_OS_SIMULATOR && TARGET_CPU_X86_64"
                ;;
            *_tvos_arm64.h)
                DEFINE_CONDITION="TARGET_OS_TV && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64"
                ;;
            *)
                # Don't run into unexpected cases by setting the default condition to false
                DEFINE_CONDITION="0"
                ;;
            esac

            # Determine loopcount; start with if and continue with elif
            LOOPCOUNT=$((LOOPCOUNT + 1))
            if [ ${LOOPCOUNT} -eq 1 ]; then
                echo "#if ${DEFINE_CONDITION}" >> "${OPENSSLCONF_INTERMEDIATE}"
            else
                echo "#elif ${DEFINE_CONDITION}" >> "${OPENSSLCONF_INTERMEDIATE}"
            fi
            # Add include
            echo "# include <openssl/${OPENSSLCONF_CURRENT}>" >> "${OPENSSLCONF_INTERMEDIATE}"
        done

        # Finish
        echo "#else" >> "${OPENSSLCONF_INTERMEDIATE}"
        echo '# error Unable to determine target or target not included in OpenSSL build' >> "${OPENSSLCONF_INTERMEDIATE}"
        echo "#endif" >> "${OPENSSLCONF_INTERMEDIATE}"
    fi
}

build_headers()
{
    # Copy include directory
    cp -R "${INCLUDE_DIR}" "${CURRENTPATH}/include/"
    echo "\n=====>Include directory:"
    echo "${CURRENTPATH}/include/"
    setup_opensslconf_h
}

openssl_build_for_targets()
{
    
    # Set reference to custom configuration (OpenSSL 1.1.0)
    # See: https://github.com/openssl/openssl/commit/afce395cba521e395e6eecdaf9589105f61e4411
    export OPENSSL_LOCAL_CONFIG_DIR="${SCRIPTDIR}/configs"

    for TARGET in ${TARGETS}
    do
    
        # Prepare TARGETDIR and SOURCEDIR
        configure_target
        prepare_target_source_dirs
        export SDKVERSION
        export CONFIG_DISABLE_BITCODE

        ## Determine config options
        # Add build target, --prefix,
        # and prevent 
        # - async (references to getcontext(), setcontext() and makecontext() result in App Store rejections)
        # - creation of shared libraries (default since 1.1.0)
        LOCAL_CONFIG_OPTIONS="${TARGET} --prefix=${TARGETDIR} ${CONFIG_OPTIONS} no-async no-shared"


        # Only relevant for 64 bit builds
        #if [[ "${CONFIG_ENABLE_EC_NISTP_64_GCC_128}" == "true" && "${ARCH}" == *64  ]]; then
        #  LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
        #fi

        # Run Configure
        run_configure
        # Run make
        run_make
        # Run make install
        run_make_install
        
        # Remove source dir, add references to library files to relevant arrays
        # Keep reference to first build target for include file
        run_build_finish

        echo "  Done."
    done

    build_ios_library
    build_tvos_library
    build_headers
}
