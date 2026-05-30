function(openssl_Populate remote_url local_path os arch build_type)

    if (os STREQUAL "linux")

        set(compiler "gcc12")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[openssl] Populate: ${remote_url}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()
    
        set(openssl_INCLUDE_DIRS ${local_path}/include)
        set(ssl_LIBRARIES
            ${local_path}/lib/libssl.so.1.1
            ${local_path}/lib/libssl.so
        )
        set(crypto_LIBRARIES
            ${local_path}/lib/libcrypto.so.1.1
            ${local_path}/lib/libcrypto.so
        )
        set(ssl_INSTALL_LIBRARIES ${ssl_LIBRARIES})
        set(crypto_INSTALL_LIBRARIES ${crypto_LIBRARIES})

    elseif(os STREQUAL "macos")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        if (arch STREQUAL "x86_64")
            set(name "macos_x86_64_relwithdebinfo_appleclang15_os109")
        elseif (arch STREQUAL "aarch64")
            set(name "macos_aarch64_relwithdebinfo_appleclang15_os1013")
        elseif (arch STREQUAL "universal")
            set(name "macos_universal_relwithdebinfo_appleclang15")
        else()
            message(FATAL_ERROR "Not supported macos arch: ${arch}")
        endif()

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[openssl] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(openssl_INCLUDE_DIRS ${local_path}/include)
        set(ssl_LIBRARIES
            ${local_path}/lib/libssl.1.1.dylib
            ${local_path}/lib/libssl.dylib
        )
        set(crypto_LIBRARIES
            ${local_path}/lib/libcrypto.1.1.dylib
            ${local_path}/lib/libcrypto.dylib
        )
        set(ssl_INSTALL_LIBRARIES ${ssl_LIBRARIES})
        set(crypto_INSTALL_LIBRARIES ${crypto_LIBRARIES})

    else()
        message(FATAL_ERROR "[openssl] Not supported os: ${os}")
    endif()

    if(NOT TARGET OpenSSL::SSL)
       add_library(OpenSSL::SSL INTERFACE IMPORTED GLOBAL)

       target_include_directories(OpenSSL::SSL INTERFACE ${openssl_INCLUDE_DIRS} )
       target_link_libraries(OpenSSL::SSL INTERFACE ${ssl_INSTALL_LIBRARIES} )
    endif()

    if (NOT TARGET OpenSSL::Crypto)
       add_library(OpenSSL::Crypto INTERFACE IMPORTED GLOBAL)

       target_include_directories(OpenSSL::Crypto INTERFACE ${openssl_INCLUDE_DIRS} )
       target_link_libraries(OpenSSL::Crypto INTERFACE ${crypto_INSTALL_LIBRARIES} )
    endif()

    set_property(GLOBAL PROPERTY openssl_INCLUDE_DIRS ${openssl_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY openssl_LIBRARIES ${ssl_LIBRARIES} ${crypto_LIBRARIES})
    set_property(GLOBAL PROPERTY openssl_INSTALL_LIBRARIES ${ssl_INSTALL_LIBRARIES} ${crypto_INSTALL_LIBRARIES})

endfunction()

function(openssl_PopulateBuild remote_url local_path os arch build_type)
    set(recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${recipe_base}/openssl/1.1.1t/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${recipe_base}/openssl/1.1.1t/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[openssl] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME openssl RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    set(openssl_INCLUDE_DIRS ${local_path}/include)
    if (os STREQUAL "linux")
        set(ssl_LIBRARIES ${local_path}/lib/libssl.so.1.1 ${local_path}/lib/libssl.so)
        set(crypto_LIBRARIES ${local_path}/lib/libcrypto.so.1.1 ${local_path}/lib/libcrypto.so)
    elseif (os STREQUAL "macos")
        set(ssl_LIBRARIES ${local_path}/lib/libssl.1.1.dylib ${local_path}/lib/libssl.dylib)
        set(crypto_LIBRARIES ${local_path}/lib/libcrypto.1.1.dylib ${local_path}/lib/libcrypto.dylib)
    endif()

    if(NOT TARGET OpenSSL::SSL)
       add_library(OpenSSL::SSL INTERFACE IMPORTED GLOBAL)
       target_include_directories(OpenSSL::SSL INTERFACE ${openssl_INCLUDE_DIRS})
       target_link_libraries(OpenSSL::SSL INTERFACE ${ssl_LIBRARIES})
    endif()
    if(NOT TARGET OpenSSL::Crypto)
       add_library(OpenSSL::Crypto INTERFACE IMPORTED GLOBAL)
       target_include_directories(OpenSSL::Crypto INTERFACE ${openssl_INCLUDE_DIRS})
       target_link_libraries(OpenSSL::Crypto INTERFACE ${crypto_LIBRARIES})
    endif()
    set_property(GLOBAL PROPERTY openssl_INCLUDE_DIRS ${openssl_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY openssl_LIBRARIES ${ssl_LIBRARIES} ${crypto_LIBRARIES})
    set_property(GLOBAL PROPERTY openssl_INSTALL_LIBRARIES ${ssl_LIBRARIES} ${crypto_LIBRARIES})
endfunction()

function(openssl_PopulateSystem)
    find_package(OpenSSL REQUIRED)
    set_property(GLOBAL PROPERTY openssl_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
    set_property(GLOBAL PROPERTY openssl_LIBRARIES ${OPENSSL_LIBRARIES})
    set_property(GLOBAL PROPERTY openssl_INSTALL_LIBRARIES "")
endfunction()
