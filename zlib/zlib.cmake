# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.3.1)

set(DEP_TARGET zlib::zlib)
set(DEP_LIBS z)
set(DEP_LIBS_WINDOWS zlib)
set(DEP_SYSTEM_HEADER zlib.h)
set(DEP_SYSTEM_LIBS z)

# zlib is consumed two ways: our zlib::zlib target and third-party CMake we
# vendor (bundled freetype, au3) calling find_package(ZLIB). Seed FindZLIB's
# cache vars so both names resolve to this one install, else that path silently
# links a second, system libz.
function(zlib_post_consume mode local_path os arch version)
    get_property(_inc  GLOBAL PROPERTY zlib_INCLUDE_DIRS)
    get_property(_libs GLOBAL PROPERTY zlib_LIBRARIES)
    if(_libs)
        list(GET _libs 0 _lib)
        set(ZLIB_INCLUDE_DIR "${_inc}" CACHE PATH     "from muse_deps zlib" FORCE)
        set(ZLIB_LIBRARY     "${_lib}" CACHE FILEPATH "from muse_deps zlib" FORCE)
    endif()
endfunction()
