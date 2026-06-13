# Build recipe for libopusenc 0.2.1. No upstream CMake and autotools can't run on
# MSVC, so build.cmake is a uniform static CMake build for every platform. No
# config.h needed (every source guards it behind HAVE_CONFIG_H). Deps: ogg + opus
# (headers only — static lib; the app links the real ogg/opus via consume targets).
set(DEP_SOURCE_URL    "https://github.com/xiph/libopusenc/archive/v0.2.1.tar.gz")
set(DEP_SOURCE_SHA256 "56952a926ff962c62a468b43cc8506c069bda767cade4dc92824b74edd570d68")

set(DEP_DEPENDS "ogg/1.3.5" "opus/1.5.2")

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
