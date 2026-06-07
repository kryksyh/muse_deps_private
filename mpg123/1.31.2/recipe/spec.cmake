# Build recipe for mpg123 1.31.2 — autotools (libmpg123 decoder only).

set(DEP_SOURCE_URL    "https://www.mpg123.de/download/mpg123-1.31.2.tar.bz2")
set(DEP_SOURCE_SHA256 "b17f22905e31f43b6b401dfdf6a71ed11bb7d056f68db449d70b9f9ae839c7de")

set(DEP_BUILD_SYSTEM autotools)
set(DEP_CONFIGURE_ARGS --disable-modules --with-default-audio=dummy)

# Windows/MSVC can't run autotools — build mpg123's official CMake port instead
# (ports/cmake). Driven from spec vars so no extra recipe file needs fetching.
set(DEP_BUILD_SYSTEM_WINDOWS cmake)
set(DEP_CMAKE_SOURCE_SUBDIR_WINDOWS ports/cmake)
set(DEP_CMAKE_ARGS_WINDOWS -DBUILD_SHARED_LIBS=ON -DBUILD_LIBOUT123=OFF -DBUILD_PROGRAMS=OFF)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
