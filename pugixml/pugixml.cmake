# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.15)

# Source-delivery: the engine builds a `pugixml` static lib from the vendored
# amalgamation, or binds the system package under require_source_dep(pugixml SYSTEM)
# / EXTDEPS_OVERRIDE_ALL=SYSTEM. The consumer links `pugixml` unconditionally.
set(DEP_KIND source)
set(DEP_SOURCE_SYSTEM ON)   # has a system path; EXTDEPS_OVERRIDE_ALL=SYSTEM binds the distro pugixml

function(pugixml_post_resolve mode local_path os arch version)
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
