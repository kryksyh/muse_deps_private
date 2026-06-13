# Pinned version — single source of truth (upstream project version 2.1, pinned
# commit). Source-delivery: built in-tree.
set(DEP_VERSION 2.1)
set(DEP_KIND source)

# The engine builds an `mnxdom` target in-tree from the vendored source, wiring
# mnxdom's otherwise-FetchContent'd deps to the muse_deps chain: nlohmann_json +
# json_schema_validator via find_package (USE_SYSTEM_* + their prefixes on
# CMAKE_PREFIX_PATH), and the MNX schema via MNX_W3C_SOURCE. The consumer links
# `mnxdom` unconditionally. require_source_dep(mnxdom SYSTEM) binds a distro
# package instead.
function(mnxdom_post_consume mode local_path os arch version)
    if(TARGET mnxdom)
        return()
    endif()
    if(mode STREQUAL "system")
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(mnxdom REQUIRED IMPORTED_TARGET mnxdom)
        add_library(mnxdom INTERFACE IMPORTED GLOBAL)
        target_link_libraries(mnxdom INTERFACE PkgConfig::mnxdom)
        target_compile_definitions(mnxdom INTERFACE MNXDOM_SYSTEM)
        return()
    endif()
    get_property(_njson GLOBAL PROPERTY nlohmann_json_PREFIX)
    get_property(_jsv   GLOBAL PROPERTY json_schema_validator_PREFIX)
    get_property(_w3c   GLOBAL PROPERTY mnx_w3c_SOURCE_DIR)
    list(PREPEND CMAKE_PREFIX_PATH "${_njson}" "${_jsv}")
    set(USE_SYSTEM_NLOHMANN_JSON ON CACHE BOOL "" FORCE)
    set(USE_SYSTEM_JSON_SCHEMA_VALIDATOR ON CACHE BOOL "" FORCE)
    set(MNX_W3C_SOURCE "${_w3c}/mnx_w3c" CACHE PATH "" FORCE)
    set(mnxdom_BUILD_TESTING OFF CACHE BOOL "" FORCE)
    add_subdirectory("${local_path}/mnxdom" "${CMAKE_BINARY_DIR}/_deps/mnxdom-build" EXCLUDE_FROM_ALL)
endfunction()
