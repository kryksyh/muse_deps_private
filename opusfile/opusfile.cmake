function(opusfile_Populate local_path os arch build_type version)

    if (os STREQUAL "linux")

        set(compiler "gcc12")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[opusfile] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version}/${name}.7z ${local_path}/${name}.7z)
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
            message(STATUS "[opusfile] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version}/${name}.7z ${local_path}/${name}.7z)
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
            message(STATUS "[opusfile] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/opusfile-${version}/${name}.7z ${local_path}/${name}.7z)
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

function(opusfile_PopulateBuild local_path os arch build_type version)
    set(recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${recipe_base}/opusfile/${version}/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${recipe_base}/opusfile/${version}/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()
    if (os STREQUAL "windows" AND NOT EXISTS "${recipe_dir}/build.windows.cmake")
        file(DOWNLOAD ${recipe_base}/opusfile/${version}/recipe/build.windows.cmake ${recipe_dir}/build.windows.cmake)
    endif()

    set(dep_prefixes "")
    foreach(dv ${DEP_DEPENDS})
        string(REPLACE "/" ";" _p "${dv}")
        list(GET _p 0 _dn)
        list(APPEND dep_prefixes "${local_path}/../${_dn}")
    endforeach()

    message(STATUS "[opusfile] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME opusfile RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}"
              DEPENDS_PREFIXES "${dep_prefixes}")

    set(inc ${local_path}/include ${local_path}/include/opus)
    if (os STREQUAL "windows")
        set(libs ${local_path}/lib/opusfile.lib)
    else()
        set(libs ${local_path}/lib/libopusfile.a)
    endif()
    if(NOT TARGET opusfile::opusfile)
       add_library(opusfile::opusfile INTERFACE IMPORTED GLOBAL)
       target_include_directories(opusfile::opusfile INTERFACE ${inc})
       target_link_libraries(opusfile::opusfile INTERFACE ${libs} Opus::opus)
    endif()
    set_property(GLOBAL PROPERTY opusfile_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY opusfile_LIBRARIES ${libs})
    set_property(GLOBAL PROPERTY opusfile_INSTALL_LIBRARIES "")
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
