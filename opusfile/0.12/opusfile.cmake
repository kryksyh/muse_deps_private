function(opusfile_Populate remote_url local_path os arch build_type)

    if (os STREQUAL "linux")

        set(compiler "gcc12")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[opusfile] Populate: ${remote_url}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(opusfile_INCLUDE_DIRS ${local_path}/include)
        set(opusfile_LIBRARIES
            ${local_path}/lib/libopusfile.a
        )
        set(opusfile_INSTALL_LIBRARIES ${opusfile_LIBRARIES})

    elseif(os STREQUAL "macos")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        if (arch STREQUAL "x86_64")
            set(name "macos_x86_64_relwithdebinfo_appleclang15_os109")
        elseif (arch STREQUAL "aarch64")
            set(name "macos_aarch64_relwithdebinfo_appleclang15_os1013")
        elseif (arch STREQUAL "universal")
            set(name "macos_universal_relwithdebinfo_appleclang15_os1013")
        else()
            message(FATAL_ERROR "Not supported macos arch: ${arch}")
        endif()

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[opusfile] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(opusfile_INCLUDE_DIRS ${local_path}/include)
        set(opusfile_LIBRARIES
            ${local_path}/lib/libopusfile.a
        )
        set(opusfile_INSTALL_LIBRARIES ${opusfile_LIBRARIES})

    elseif(os STREQUAL "windows")

        set(compiler "msvc194")

        if (build_type STREQUAL "release")
            set(build_type "relwithdebinfo")
        endif()

        set(name "windows_${arch}_${build_type}_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[opusfile] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(opusfile_INCLUDE_DIRS ${local_path}/include)
        set(opusfile_LIBRARIES ${local_path}/lib/opusfile.lib)
        set(opusfile_INSTALL_LIBRARIES ${opusfile_LIBRARIES})

    else()
        message(FATAL_ERROR "[opusfile] Not supported os: ${os}")
    endif()

    if(NOT TARGET opusfile::opusfile)
       add_library(opusfile::opusfile INTERFACE IMPORTED GLOBAL)

       target_include_directories(opusfile::opusfile INTERFACE ${opusfile_INCLUDE_DIRS} )
       target_link_libraries(opusfile::opusfile INTERFACE ${opusfile_LIBRARIES} Opus::opus)
    endif()

    set_property(GLOBAL PROPERTY opusfile_INCLUDE_DIRS ${opusfile_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY opusfile_LIBRARIES ${opusfile_LIBRARIES})
    # opusfile is static library, so we don't need to export it for install
    set_property(GLOBAL PROPERTY opusfile_INSTALL_LIBRARIES "")

endfunction()

function(opusfile_PopulateBuild remote_url local_path os arch build_type)
    message(FATAL_ERROR "[opusfile] source build not yet supported (autotools). Use prebuilt or MUSE_USE_SYSTEM_OPUSFILE.")
endfunction()

function(opusfile_PopulateSystem)
    find_path(opusfile_INCLUDE_DIR NAMES opus/opusfile.h)
    find_library(opusfile_LIBRARY NAMES opusfile)
    if (NOT opusfile_INCLUDE_DIR OR NOT opusfile_LIBRARY)
        message(FATAL_ERROR "[opusfile] system opusfile not found (USE_SYSTEM enabled)")
    endif()
    if(NOT TARGET opusfile::opusfile)
       add_library(opusfile::opusfile INTERFACE IMPORTED GLOBAL)
       target_include_directories(opusfile::opusfile INTERFACE ${opusfile_INCLUDE_DIR} ${opusfile_INCLUDE_DIR}/opus)
       target_link_libraries(opusfile::opusfile INTERFACE ${opusfile_LIBRARY} Opus::opus)
    endif()
    set_property(GLOBAL PROPERTY opusfile_INCLUDE_DIRS ${opusfile_INCLUDE_DIR} ${opusfile_INCLUDE_DIR}/opus)
    set_property(GLOBAL PROPERTY opusfile_LIBRARIES ${opusfile_LIBRARY})
    set_property(GLOBAL PROPERTY opusfile_INSTALL_LIBRARIES "")
endfunction()
