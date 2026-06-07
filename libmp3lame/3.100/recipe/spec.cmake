# Build recipe for libmp3lame (LAME) 3.100. LAME ships no CMake and its autotools
# can't run under MSVC, so build.cmake is a uniform pure-C CMake build for every
# platform (owns a minimal config.h; no autotools, no SSE/arch logic).
set(DEP_SOURCE_URL    "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz")
set(DEP_SOURCE_SHA256 "ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e")

set(DEP_RECIPE_FILES build.cmake)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
