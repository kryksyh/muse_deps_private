# Upstream's last release (1.1.0, 2016) predates modern compilers; the pin is
# master, short sha.
set(DEP_VERSION 24b5e7a)

# Source-delivery, header-only: the consumer gets an INTERFACE target.
set(DEP_KIND source)

function(rapidjson_add_to_build)
    if(TARGET rapidjson)
        return()
    endif()
    get_property(_src GLOBAL PROPERTY rapidjson_SOURCE_DIR)
    add_library(rapidjson INTERFACE)
    add_library(rapidjson::rapidjson ALIAS rapidjson)
    target_include_directories(rapidjson INTERFACE "${_src}/rapidjson/include")
endfunction()
