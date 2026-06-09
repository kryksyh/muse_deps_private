# Build recipe for mpg123 1.32.10 — the official CMake port (ports/cmake),
# libmpg123 decoder only, on every platform.

set(DEP_SOURCE_URL    "https://www.mpg123.de/download/mpg123-1.32.10.tar.bz2")
set(DEP_SOURCE_SHA256 "87b2c17fe0c979d3ef38eeceff6362b35b28ac8589fbf1854b5be75c9ab6557c")

set(DEP_CMAKE_SOURCE_SUBDIR ports/cmake)
set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_LIBOUT123=OFF
    -DBUILD_PROGRAMS=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
