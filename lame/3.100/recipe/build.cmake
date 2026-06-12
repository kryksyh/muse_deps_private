# Cross-platform pure-C build of LAME (3.100). LAME ships no CMake, and autotools
# can't run under MSVC — so we own a tiny config.h and build the same way on every
# platform. No autotools, no SSE/NASM, no per-arch logic: the SSE
# (HAVE_XMMINTRIN_H) and TAKEHIRO_IEEE754_HACK paths are all #ifdef-gated with
# portable C fallbacks, so leaving them undefined yields a correct pure-C library.
# Runs in build_dep scope (SRC / BUILD / INSTALL / BD_OS / _bd_cmake_build).

# Minimal config.h. These headers exist on every target we build (clang/gcc, and
# MSVC 2019+), so no feature detection is needed (and cmake -P can't check anyway).
file(WRITE "${SRC}/config.h"
"#define STDC_HEADERS 1\n"
"#define HAVE_ERRNO_H 1\n"
"#define HAVE_FCNTL_H 1\n"
"#define HAVE_LIMITS_H 1\n"
"#define HAVE_STDINT_H 1\n"
"#define HAVE_INTTYPES_H 1\n"
"#define HAVE_STRCHR 1\n"
"#define HAVE_MEMCPY 1\n"
"#define HAVE_MPGLIB 1\n"
"#define DECODE_ON_THE_FLY 1\n"
"#define USE_FAST_LOG 1\n"
"typedef float  ieee754_float32_t;\n"   # autotools AC_CHECK_TYPES / configMS.h
"typedef double ieee754_float64_t;\n"
)

# Shared on unix (bundled, LGPL-friendly); static on Windows (avoids the .def/.sym
# export dance — the consumer links mp3lame.lib).
if(BD_OS STREQUAL "windows")
    set(_libtype STATIC)
else()
    set(_libtype SHARED)
endif()

file(WRITE "${SRC}/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.16)\n"
"project(mp3lame C)\n"
"add_definitions(-DHAVE_CONFIG_H)\n"
"file(GLOB SRCS libmp3lame/*.c mpglib/*.c)\n"   # top-level only: skips i386/ + vector/ (asm/SSE)
"add_library(mp3lame ${_libtype} \${SRCS})\n"
"set_target_properties(mp3lame PROPERTIES VERSION 0.0.0 SOVERSION 0)\n"
"target_include_directories(mp3lame PRIVATE \"\${CMAKE_CURRENT_SOURCE_DIR}\" \"\${CMAKE_CURRENT_SOURCE_DIR}/libmp3lame\" \"\${CMAKE_CURRENT_SOURCE_DIR}/mpglib\" \"\${CMAKE_CURRENT_SOURCE_DIR}/include\")\n"
"install(TARGETS mp3lame ARCHIVE DESTINATION lib LIBRARY DESTINATION lib RUNTIME DESTINATION bin)\n"
"install(FILES include/lame.h DESTINATION include/lame)\n"
)

_bd_cmake_build("${SRC}")
