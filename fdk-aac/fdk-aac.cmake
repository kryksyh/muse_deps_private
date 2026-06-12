# Pinned version — single source of truth for this dep.
set(DEP_VERSION 2.0.3)

# Source-delivery: the consumer compiles it in-tree (muse audio export).
set(DEP_KIND source)

function(fdk_aac_materialize)
    get_property(_src GLOBAL PROPERTY fdk-aac_SOURCE_DIR)
    if(NOT TARGET fdk-aac)
        add_subdirectory("${_src}/fdk-aac" fdk-aac EXCLUDE_FROM_ALL)
    endif()
endfunction()
