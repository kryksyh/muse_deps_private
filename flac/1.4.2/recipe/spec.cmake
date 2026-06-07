# Build recipe for flac 1.4.2 — read by buildtools/build_dep.cmake.

set(DEP_SOURCE_URL    "https://github.com/xiph/flac/releases/download/1.4.2/flac-1.4.2.tar.xz")
set(DEP_SOURCE_SHA256 "e322d58a1f48d23d9dd38f432672865f6f79e73a6f9cc5a5f57fcaa83eb5a8e4")

set(DEP_DEPENDS "ogg/1.3.5")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_PROGRAMS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_DOCS=OFF
    -DINSTALL_MANPAGES=OFF
    -DWITH_OGG=ON
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING.Xiph COPYING.GPL COPYING.LGPL)
