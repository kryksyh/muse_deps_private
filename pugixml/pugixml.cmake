# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.15)

# Source-delivery: the engine builds a `pugixml` static lib from the vendored
# amalgamation, or binds the system package under require_source_dep(pugixml SYSTEM).
# The consumer links `pugixml` unconditionally.
set(DEP_KIND source)

function(pugixml_post_consume mode local_path os arch version)
    if(TARGET pugixml)
        return()
    endif()
    if(mode STREQUAL "system")
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(pugixml REQUIRED IMPORTED_TARGET pugixml)
        add_library(pugixml INTERFACE IMPORTED GLOBAL)
        target_link_libraries(pugixml INTERFACE PkgConfig::pugixml)
    else()
        set(_src "${local_path}/pugixml/src")
        add_library(pugixml STATIC "${_src}/pugixml.cpp")
        target_include_directories(pugixml PUBLIC "${_src}")
        set_target_properties(pugixml PROPERTIES POSITION_INDEPENDENT_CODE ON UNITY_BUILD OFF)
    endif()
endfunction()
