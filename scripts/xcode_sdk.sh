#
#
#


IOS_SDKVERSION=""
MACOSX_SDKVERSION=""
TVOS_SDKVERSION=""

set_xcode_sdk_version()
{
    # Determine SDK versions
    if [ ! -n "${IOS_SDKVERSION}" ]; then
        IOS_SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)
    fi
    if [ ! -n "${MACOSX_SDKVERSION}" ]; then
        MACOSX_SDKVERSION=$(xcrun -sdk macosx --show-sdk-version)
    fi

    if [ ! -n "${TVOS_SDKVERSION}" ]; then
        TVOS_SDKVERSION=$(xcrun -sdk appletvos --show-sdk-version)
    fi
}


