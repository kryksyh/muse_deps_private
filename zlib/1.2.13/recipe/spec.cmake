# Build recipe for zlib 1.2.13 (macOS + Windows only; AU doesn't use it on Linux).

set(DEP_SOURCE_URL    "https://github.com/madler/zlib/releases/download/v1.2.13/zlib-1.2.13.tar.gz")
set(DEP_SOURCE_SHA256 "b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30")

set(DEP_BUILD_SYSTEM cmake)
set(DEP_CMAKE_ARGS -DBUILD_SHARED_LIBS=ON)

# macOS-only: zlib 1.2.13's zutil.h misdetects modern macOS as classic Mac OS
# (TARGET_OS_MAC) and defines `fdopen NULL`, clobbering the SDK (cascades into
# bogus errors). Guard it with !__APPLE__.
set(DEP_PATCHES_MACOS patch/0001-zlib-no-classic-mac-fdopen.patch)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")

set(DEP_ARCHIVE_NAME_macos_x86_64     "zlib_macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "zlib_macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "zlib_macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "zlib_windows_x86_64_relwithdebinfo_msvc192")
