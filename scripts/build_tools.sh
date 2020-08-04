#
#
#

BUILD_CLEANUP="false"
BUILD_TARGET_DIRS=""

# Create build target drectories
tools_create_build_target_dirs()
{
    # Clean up target directories if requested and present
    if [ "${BUILD_CLEANUP}" == "true" ]; then

        for _DIR in ${BUILD_TARGET_DIRS}
        do
            if [ -d "${CURRENTPATH}/${_DIR}" ]; then
                rm -r "${CURRENTPATH}/${_DIR}"
            fi
        done
    fi

    for _DIR in ${BUILD_TARGET_DIRS}
    do
        # (Re-)create target directories
        mkdir -p "${CURRENTPATH}/${_DIR}"
    done
}

# Check for error status
tools_command_check_status()
{
    local STATUS=$1
    local COMMAND=$2
    
    if [ "${STATUS}" != 0 ]; then
        if [[ "${LOG_VERBOSE}" != "verbose"* ]]; then
            echo "Problem during ${COMMAND} - Please check ${LOG}"
        fi
        
        # Dump last 500 lines from log file for verbose-on-error
        if [ "${LOG_VERBOSE}" == "verbose-on-error" ]; then
            echo "Problem during ${COMMAND} - Dumping last 500 lines from log file"
            echo
            tail -n 500 "${LOG}"
        fi
        
        exit 1
    fi
}

# Build Spinner for no verbose output
tools_build_spinner()
{
    local pid=$!
    local delay=0.75
    local spinstr='|/-\'

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "  [%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done

    wait $pid
    return $?
}
