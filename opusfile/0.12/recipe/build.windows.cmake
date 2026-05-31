# Windows/MSVC build of opusfile (no upstream CMake; autotools can't run).
# Builds a static opusfile.lib, decode-only (no http -> no openssl). A static
# lib only needs ogg/opus HEADERS to compile (the app links the actual ogg/opus
# libs via the consume targets), so we just add the dep include dirs — no
# find_package/link. Runs in build_dep scope: SRC/INSTALL/BD_DEPENDS_PREFIXES.

set(_dep_incs "")
foreach(p ${BD_DEPENDS_PREFIXES})
    string(APPEND _dep_incs " \"${p}/include\" \"${p}/include/opus\"")
endforeach()

file(WRITE "${SRC}/CMakeLists.txt"
"cmake_minimum_required(VERSION 3.16)\n"
"project(opusfile C)\n"
"add_library(opusfile STATIC src/info.c src/internal.c src/opusfile.c src/stream.c)\n"
"target_include_directories(opusfile PRIVATE \"\${CMAKE_CURRENT_SOURCE_DIR}/include\" \"\${CMAKE_CURRENT_SOURCE_DIR}/src\"${_dep_incs})\n"
"install(TARGETS opusfile ARCHIVE DESTINATION lib)\n"
"install(DIRECTORY include/ DESTINATION include)\n"
)

_bd_cmake_build("${SRC}")
