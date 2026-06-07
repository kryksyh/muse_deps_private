# Build recipe for libmp3lame (LAME) 3.100 — autotools.

set(DEP_SOURCE_URL    "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz")
set(DEP_SOURCE_SHA256 "ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e")

set(DEP_BUILD_SYSTEM autotools)
set(DEP_CONFIGURE_ARGS --disable-frontend)

# Cross-compiling x86_64 on Apple Silicon: lame gates WITH_XMM (the SSE vector lib
# defining init_xrpow_core_sse) on the build-HOST cpu (arm64 -> off), yet an x86_64
# target sets MIN_ARCH_SSE and references the symbol -> undefined. Tell configure
# the real target cpu via --host so WITH_XMM turns on; pass CC/CXX so it doesn't
# look for an x86_64-apple-darwin-gcc cross prefix. (Universal builds in one pass
# with both -arch flags, where the multi-arch xmmintrin probe fails and all the SSE
# paths compile out, so it needs no --host.)
if(BD_OS STREQUAL "macos" AND BD_ARCH STREQUAL "x86_64"
        AND NOT CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
    list(APPEND DEP_CONFIGURE_ARGS --host=x86_64-apple-darwin CC=clang CXX=clang++)
endif()

# macOS-only: its linker errors on lame_init_old (exported but undefined);
# Linux/Windows linkers ignore the missing export.
set(DEP_PATCHES_MACOS patch/0001-drop-lame_init_old-export.patch)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)

# Windows MSVC build override (autotools cannot run there) — fetched by the consumer.
set(DEP_RECIPE_FILES_WINDOWS build.windows.cmake)
