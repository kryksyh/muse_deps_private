# Build recipe for opusfile 0.12. No upstream CMake and autotools can't run on
# MSVC, so build.cmake is a uniform static, decode-only (no http -> no openssl)
# CMake build for every platform. Deps: ogg + opus (headers only — static lib).
set(DEP_SOURCE_URL    "https://github.com/xiph/opusfile/archive/v0.12.tar.gz")
set(DEP_SOURCE_SHA256 "a20a1dff1cdf0719d1e995112915e9966debf1470ee26bb31b2f510ccf00ef40")

set(DEP_DEPENDS ogg opus)

set(DEP_LICENSE_FILES COPYING)
