# Build recipe for ogg 1.3.5 — read by buildtools/build_dep.cmake.

set(DEP_SOURCE_URL    "https://github.com/xiph/ogg/releases/download/v1.3.5/libogg-1.3.5.tar.gz")
set(DEP_SOURCE_SHA256 "0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DINSTALL_DOCS=OFF
    -DBUILD_TESTING=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
set(DEP_SYSTEM_PACKAGE Ogg)

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc10")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc192")
