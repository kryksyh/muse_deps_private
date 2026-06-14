# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.17.0)

# Source-delivery: the framework adds it with add_subdirectory when unit tests
# are enabled; never shipped.
set(DEP_KIND source)

function(googletest_materialize)
    if(TARGET gtest)
        return()
    endif()
    get_property(_src GLOBAL PROPERTY googletest_SOURCE_DIR)
    set(INSTALL_GTEST OFF)
    add_subdirectory("${_src}/googletest" googletest)
endfunction()
