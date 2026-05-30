# Build recipe for expat (actual upstream 2.5.0; path label "2.0.5" is historical).

set(DEP_SOURCE_URL    "https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.xz")
set(DEP_SOURCE_SHA256 "ef2420f0232c087801abf705e89ae65f6257df6b7931d37846a193ef2e8cdcbe")

set(DEP_BUILD_SYSTEM cmake)
set(DEP_CMAKE_ARGS
    -DEXPAT_SHARED_LIBS=ON
    -DEXPAT_BUILD_TOOLS=OFF
    -DEXPAT_BUILD_EXAMPLES=OFF
    -DEXPAT_BUILD_TESTS=OFF
    -DEXPAT_BUILD_DOCS=OFF
    -DEXPAT_BUILD_PKGCONFIG=ON
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc10")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc192")
