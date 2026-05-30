# Build recipe for wavpack 5.7.0 — read by buildtools/build_dep.cmake.

set(DEP_SOURCE_URL    "https://github.com/dbry/WavPack/releases/download/5.7.0/wavpack-5.7.0.tar.xz")
set(DEP_SOURCE_SHA256 "e81510fd9ec5f309f58d5de83e9af6c95e267a13753d7e0bbfe7b91273a88bee")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DWAVPACK_BUILD_PROGRAMS=OFF
    -DBUILD_TESTING=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
set(DEP_SYSTEM_PACKAGE WavPack)

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc10")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc192")
