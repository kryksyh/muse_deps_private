# Windows/MSVC build of LAME (no upstream CMake; autotools can't run). Builds a
# static mp3lame.lib from the core encoder + mpglib decoder. Uses LAME's MSVC
# config template (configMS.h) as config.h. The x86 SSE file
# libmp3lame/vector/xmm_quantize_sub.c (init_xrpow_core_sse) is needed on x86/x64
# (quantize.c references it when SSE is available) but absent on ARM64 (NEON/C
# path, not referenced) — include it by target arch. Runs in build_dep scope.

# LAME ships a ready MSVC config; the build expects it as config.h.
configure_file("${SRC}/configMS.h" "${SRC}/config.h" COPYONLY)

file(WRITE "${SRC}/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.16)\n"
"project(mp3lame C)\n"
"add_definitions(-DHAVE_CONFIG_H)\n"
"file(GLOB SRCS libmp3lame/*.c mpglib/*.c)\n"
"if(CMAKE_C_COMPILER_ARCHITECTURE_ID MATCHES \"[Xx]64|X86\")\n"
"  file(GLOB VEC libmp3lame/vector/*.c)\n"
"  list(APPEND SRCS \${VEC})\n"
"endif()\n"
"add_library(mp3lame STATIC \${SRCS})\n"
"target_include_directories(mp3lame PRIVATE \"\${CMAKE_CURRENT_SOURCE_DIR}\" \"\${CMAKE_CURRENT_SOURCE_DIR}/libmp3lame\" \"\${CMAKE_CURRENT_SOURCE_DIR}/mpglib\" \"\${CMAKE_CURRENT_SOURCE_DIR}/include\")\n"
"install(TARGETS mp3lame ARCHIVE DESTINATION lib)\n"
"install(FILES include/lame.h DESTINATION include/lame)\n"
)

_bd_cmake_build("${SRC}")
