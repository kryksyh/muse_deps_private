# Consume metadata for libcurl — SYSTEM ONLY. AU links the system libcurl (which
# brings its own TLS backend), so there is no bundled prebuilt or source build.
# Use require_dep(libcurl SYSTEM) in the manifest.
function(libcurl_consume_override mode local_path os arch buildtype version)
    if(NOT mode STREQUAL "system")
        message(FATAL_ERROR "[libcurl] only system mode is supported — use require_dep(libcurl SYSTEM)")
    endif()
    find_package(CURL REQUIRED)
    set_property(GLOBAL PROPERTY libcurl_INCLUDE_DIRS "${CURL_INCLUDE_DIRS}")
    set_property(GLOBAL PROPERTY libcurl_LIBRARIES CURL::libcurl)
    set_property(GLOBAL PROPERTY libcurl_INSTALL_LIBRARIES "")
endfunction()
