# Build recipe for wxWidgets 3.2.6 (upstream). Audacity only needs wxBase; the
# old 3.1.3-audacity fork was an AU3 requirement and is no longer needed.
# The official release tarball bundles 3rdparty sources (zlib/expat/regex), so
# builtin libs work with no submodules, no patches, no system/external deps.

set(DEP_SOURCE_URL    "https://github.com/wxWidgets/wxWidgets/releases/download/v3.2.6/wxWidgets-3.2.6.tar.bz2")
set(DEP_SOURCE_SHA256 "939e5b77ddc5b6092d1d7d29491fe67010a2433cf9b9c0d841ee4d04acb9dce7")

set(DEP_BUILD_SYSTEM cmake)
set(DEP_CMAKE_ARGS
    -DwxBUILD_SHARED=ON
    -DwxBUILD_SAMPLES=OFF
    -DwxBUILD_TESTS=OFF
    -DwxBUILD_DEMOS=OFF
    -DwxBUILD_INSTALL=ON
    -DwxBUILD_COMPATIBILITY=3.0
    -DwxBUILD_PRECOMP=OFF
    -DwxUSE_GUI=OFF
    -DwxUSE_WEBREQUEST=OFF
    -DwxUSE_ZLIB=builtin
    -DwxUSE_EXPAT=builtin
    -DwxUSE_REGEX=builtin
)

# wx's bundled zlib misdetects modern macOS as classic Mac OS (TARGET_OS_MAC),
# defining `fdopen NULL` which clobbers the SDK. No-op on Linux/Windows.
set(DEP_PATCHES patch/0001-zlib-no-classic-mac-fdopen.patch)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES "docs/licence.txt")

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc12")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc194")
