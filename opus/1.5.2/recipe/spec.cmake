# Build recipe for opus 1.5.2 — read by buildtools/build_dep.cmake.

set(DEP_SOURCE_URL    "https://github.com/xiph/opus/releases/download/v1.5.2/opus-1.5.2.tar.gz")
set(DEP_SOURCE_SHA256 "65c1d2f78b9f2fb20082c38cbe47c951ad5839345876e46941612ee87f9a7ce1")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DOPUS_BUILD_PROGRAMS=OFF
    -DOPUS_BUILD_TESTING=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")

set(DEP_LICENSE_FILES COPYING)

# find_package name for the USE_SYSTEM path (see opus.cmake: opus_PopulateSystem).
set(DEP_SYSTEM_PACKAGE Opus)

# Prebuilt archive base names — single source of truth, must match opus.cmake.
set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc12")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc194")
