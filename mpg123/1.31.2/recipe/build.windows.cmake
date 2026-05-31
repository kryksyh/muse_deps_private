# Windows (MSVC) build of mpg123: its autotools path can't run, so build the
# official CMake port shipped in ports/cmake. Decoder only (no output modules
# needed). Included by build_dep_lib's per-OS dispatch; uses SRC/BUILD/INSTALL.
set(DEP_CMAKE_ARGS ${DEP_CMAKE_ARGS} -DBUILD_LIBOUT123=OFF)
_bd_cmake_build("${SRC}/ports/cmake")
