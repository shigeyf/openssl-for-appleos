#
#
#

print_help()
{
  echo "Usage: $0 [options...]"
  echo "Generic options"
  echo "     --branch=BRANCH               Select OpenSSL branch to build. The script will determine and download the latest release for that branch"
  echo "     --cleanup                     Clean up build directories (bin, include/openssl, lib, src) before starting build"
  echo " -h, --help                        Print help (this message)"
  echo "     --noparallel                  Disable running make with parallel jobs (make -j)"
  echo "     --disable-bitcode             Disable embedding Bitcode"
  echo " -v, --verbose                     Enable verbose logging"
  echo "     --verbose-on-error            Dump last 500 lines from log file if an error occurs (for Travis builds)"
  echo "     --version=VERSION             OpenSSL version to build (defaults to ${DEFAULTVERSION})"
  echo "     --targets=\"TARGET TARGET ...\" Space-separated list of build targets"
  echo "                                     Options: ${DEFAULTTARGETS}"
  echo
  echo "For custom configure options, set variable CONFIG_OPTIONS"
  echo "For custom cURL options, set variable CURL_OPTIONS"
  echo "  Example: CURL_OPTIONS=\"--proxy 192.168.1.1:8080\" ./build-libssl.sh"
}
