# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 4.1.1)

# Source-delivery, header-only: the engine exposes a `utfcpp` interface target
# carrying the vendored headers, or the system package under
# require_source_dep(utfcpp SYSTEM). The consumer links `utfcpp` unconditionally.
set(DEP_KIND source)

function(utfcpp_post_consume mode local_path os arch version)
    if(TARGET utfcpp)
        return()
    endif()
    add_library(utfcpp INTERFACE IMPORTED GLOBAL)
    if(mode STREQUAL "system")
        find_package(utf8cpp REQUIRED CONFIG)
        target_link_libraries(utfcpp INTERFACE utf8::cpp)
    else()
        target_include_directories(utfcpp INTERFACE "${local_path}/utfcpp/source")
    endif()
endfunction()
