# Build recipe for libmp3lame (LAME) 3.100 — autotools.

set(DEP_SOURCE_URL    "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz")
set(DEP_SOURCE_SHA256 "ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e")

set(DEP_BUILD_SYSTEM autotools)
set(DEP_CONFIGURE_ARGS --disable-frontend)
# macOS linker errors on lame_init_old (exported but undefined); Linux ld ignores it.
set(DEP_PATCHES patch/0001-drop-lame_init_old-export.patch)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc10")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc192")
