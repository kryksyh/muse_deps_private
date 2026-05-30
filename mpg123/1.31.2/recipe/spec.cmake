# Build recipe for mpg123 1.31.2 — autotools (libmpg123 decoder only).

set(DEP_SOURCE_URL    "https://www.mpg123.de/download/mpg123-1.31.2.tar.bz2")
set(DEP_SOURCE_SHA256 "b17f22905e31f43b6b401dfdf6a71ed11bb7d056f68db449d70b9f9ae839c7de")

set(DEP_BUILD_SYSTEM autotools)
set(DEP_CONFIGURE_ARGS --disable-modules --with-default-audio=dummy)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)

set(DEP_ARCHIVE_NAME_linux_x86_64     "linux_x86_64_relwithdebinfo_gcc10")
set(DEP_ARCHIVE_NAME_macos_x86_64     "macos_x86_64_relwithdebinfo_appleclang15_os109")
set(DEP_ARCHIVE_NAME_macos_aarch64    "macos_aarch64_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_macos_universal  "macos_universal_relwithdebinfo_appleclang15_os1013")
set(DEP_ARCHIVE_NAME_windows_x86_64   "windows_x86_64_relwithdebinfo_msvc192")
