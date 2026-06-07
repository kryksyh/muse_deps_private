# Consume metadata for openssl — SYSTEM ONLY. It exists solely as libcurl's TLS
# backend; with system libcurl the system openssl comes with it. Two targets
# (SSL, Crypto). Not used on Windows (libcurl there uses Schannel; the manifest
# skips it). Use require_dep(openssl SYSTEM) in the manifest.
function(openssl_consume_override mode local_path os arch buildtype version)
    if(NOT mode STREQUAL "system")
        message(FATAL_ERROR "[openssl] only system mode is supported — use require_dep(openssl SYSTEM)")
    endif()
    find_package(OpenSSL REQUIRED)
    set_property(GLOBAL PROPERTY openssl_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
    set_property(GLOBAL PROPERTY openssl_LIBRARIES ${OPENSSL_LIBRARIES})
    set_property(GLOBAL PROPERTY openssl_INSTALL_LIBRARIES "")
endfunction()
