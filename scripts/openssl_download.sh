#
#
#

BRANCH=""
VERSION=""
check_openssl_version()
{
    # Use either version or branch
    if [[ -n "${VERSION}" && -n "${BRANCH}" ]]; then
        echo "Either select a branch (the script will determine and build the latest version) or select a specific version, but not both."
        exit 1
    
    # Specific version: Verify version number format. Expected: dot notation
    elif [[ -n "${VERSION}" && ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+[a-z]*$ ]]; then
        echo "Unknown version number format. Examples: 1.1.0, 1.1.0l"
        exit 1
    
    # Specific branch
    elif [ -n "${BRANCH}" ]; then
        # Verify version number format. Expected: dot notation
        if [[ ! "${BRANCH}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Unknown branch version number format. Examples: 1.1.0, 1.2.0"
            exit 1

    # Valid version number, determine latest version
    else
        echo "Checking latest version of ${BRANCH} branch on openssl.org..."
        # Get directory content listing of /source/ (only contains latest version per branch), limit list to archives (so one archive per branch),
        # filter for the requested branch, sort the list and get the last item (last two steps to ensure there is always 1 result)
        VERSION=$(curl ${CURL_OPTIONS} -s https://ftp.openssl.org/source/ | grep -Eo '>openssl-[0-9]\.[0-9]\.[0-9][a-z]*\.tar\.gz<' | grep -Eo "${BRANCH//./\.}[a-z]*" | sort | tail -1)

        # Verify result
        if [ -z "${VERSION}" ]; then
            echo "Could not determine latest version, please check https://www.openssl.org/source/ and use --version option"
            exit 1
        fi
    fi

    # Script default
    elif [ -z "${VERSION}" ]; then
        VERSION="${DEFAULTVERSION}"
    fi
}

openssl_download()
{
    check_openssl_version

    # Download OpenSSL when not present
    OPENSSL_ARCHIVE_BASE_NAME="openssl-${VERSION}"
    OPENSSL_ARCHIVE_FILE_NAME="${OPENSSL_ARCHIVE_BASE_NAME}.tar.gz"


    if [ ! -e ${OPENSSL_ARCHIVE_FILE_NAME} ]; then
        echo "Downloading ${OPENSSL_ARCHIVE_FILE_NAME}..."
        OPENSSL_ARCHIVE_URL="https://www.openssl.org/source/${OPENSSL_ARCHIVE_FILE_NAME}"

        # Check whether file exists here (this is the location of the latest version for each branch)
        # -s be silent, -f return non-zero exit status on failure, -I get header (do not download)
        curl ${CURL_OPTIONS} -sfI "${OPENSSL_ARCHIVE_URL}" > /dev/null

        # If unsuccessful, try the archive
        if [ $? -ne 0 ]; then
            BRANCH=$(echo "${VERSION}" | grep -Eo '^[0-9]\.[0-9]\.[0-9]')
            OPENSSL_ARCHIVE_URL="https://www.openssl.org/source/old/${BRANCH}/${OPENSSL_ARCHIVE_FILE_NAME}"

            curl ${CURL_OPTIONS} -sfI "${OPENSSL_ARCHIVE_URL}" > /dev/null
        fi

        # Both attempts failed, so report the error
        if [ $? -ne 0 ]; then
            echo "An error occurred trying to find OpenSSL ${VERSION} on ${OPENSSL_ARCHIVE_URL}"
            echo "Please verify that the version you are trying to build exists, check cURL's error message and/or your network connection."
            exit 1
        fi

        # Archive was found, so proceed with download.
        # -O Use server-specified filename for download
        curl ${CURL_OPTIONS} -O "${OPENSSL_ARCHIVE_URL}"

    else
        echo "Using ${OPENSSL_ARCHIVE_FILE_NAME}"
    fi
}
