# Build recipe for ogg 1.3.5 — read by buildtools/build_dep_lib.cmake.

set(DEP_SOURCE_URL    "https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.gz")
set(DEP_SOURCE_SHA256 "0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DINSTALL_DOCS=OFF
    -DBUILD_TESTING=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
