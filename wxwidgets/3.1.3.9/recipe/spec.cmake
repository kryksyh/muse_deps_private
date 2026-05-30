# Build recipe for wxWidgets (Audacity fork). The "3.1.3.9" label uses the
# v3.1.3.1-audacity source tarball + a patch stack (versions >=3.1.3.2 are
# patch-only on that source). Built as wxBase only (GUI off) with builtin
# sub-libs to avoid the png/jpeg/tiff/zlib/expat subtree.

set(DEP_SOURCE_URL    "https://github.com/audacity/wxWidgets/archive/v3.1.3.1-audacity.tar.gz")
set(DEP_SOURCE_SHA256 "bc62edab621cf0a568ce6716407d5090701c09b57335044f92066b302bb70d1d")

set(DEP_BUILD_SYSTEM cmake)
set(DEP_CMAKE_ARGS
    -DwxBUILD_SHARED=ON
    -DwxBUILD_SAMPLES=OFF
    -DwxBUILD_TESTS=OFF
    -DwxBUILD_DEMOS=OFF
    -DwxBUILD_INSTALL=ON
    -DwxBUILD_COMPATIBILITY=3.0
    -DwxUSE_GUI=OFF
    -DwxUSE_ZLIB=builtin
    -DwxUSE_EXPAT=builtin
    -DwxUSE_REGEX=builtin
)

# Linux-relevant patches (cmake fixes + C++20 deprecated-copy); macOS/Windows
# patches from the Conan recipe are intentionally omitted here.
set(DEP_PATCHES
    patch/0001-cmake-interface-lib-fix.patch
    patch/0002-bump-cmake-version.patch
    patch/0003-avoid-wdeprecated-copy.patch
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc12")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc194")
