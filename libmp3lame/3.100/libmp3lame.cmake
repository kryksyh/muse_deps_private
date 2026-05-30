function(libmp3lame_Populate remote_url local_path os arch build_type)

    if (os STREQUAL "linux")

        set(compiler "gcc10")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[libmp3lame] Populate: ${remote_url}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(libmp3lame_INCLUDE_DIRS ${local_path}/include)
        set(libmp3lame_LIBRARIES
            ${local_path}/lib/libmp3lame.so.0.0.0
            ${local_path}/lib/libmp3lame.so.0
            ${local_path}/lib/libmp3lame.so
        )
        set(libmp3lame_INSTALL_LIBRARIES ${libmp3lame_LIBRARIES})

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
            message(STATUS "[libmp3lame] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(libmp3lame_INCLUDE_DIRS ${local_path}/include)
        set(libmp3lame_LIBRARIES
            ${local_path}/lib/libmp3lame.0.dylib
            ${local_path}/lib/libmp3lame.dylib
        )
        set(libmp3lame_INSTALL_LIBRARIES ${libmp3lame_LIBRARIES})

    elseif(os STREQUAL "windows")

        set(compiler "msvc192")

        if (build_type STREQUAL "release")
            set(build_type "relwithdebinfo")
        endif()

        set(name "windows_${arch}_${build_type}_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[libmp3lame] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(libmp3lame_INCLUDE_DIRS ${local_path}/include)
        set(libmp3lame_LIBRARIES ${local_path}/lib/mp3lame.lib)
        set(libmp3lame_INSTALL_LIBRARIES ${local_path}/bin/libmp3lame.dll)

    else()
        message(FATAL_ERROR "[libmp3lame] Not supported os: ${os}")
    endif()

    if(NOT TARGET libmp3lame::libmp3lame)
       add_library(libmp3lame::libmp3lame INTERFACE IMPORTED GLOBAL)

       target_include_directories(libmp3lame::libmp3lame INTERFACE ${libmp3lame_INCLUDE_DIRS} )
       target_link_libraries(libmp3lame::libmp3lame INTERFACE ${libmp3lame_LIBRARIES} )
    endif()

    set_property(GLOBAL PROPERTY libmp3lame_INCLUDE_DIRS ${libmp3lame_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY libmp3lame_LIBRARIES ${libmp3lame_LIBRARIES})
    set_property(GLOBAL PROPERTY libmp3lame_INSTALL_LIBRARIES ${libmp3lame_INSTALL_LIBRARIES})

endfunction()

function(libmp3lame_PopulateBuild remote_url local_path os arch build_type)
    set(recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${recipe_base}/libmp3lame/3.100/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${recipe_base}/libmp3lame/3.100/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[libmp3lame] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME libmp3lame RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    set(inc ${local_path}/include)
    if (os STREQUAL "linux")
        set(libs ${local_path}/lib/libmp3lame.so.0.0.0 ${local_path}/lib/libmp3lame.so.0 ${local_path}/lib/libmp3lame.so)
    elseif (os STREQUAL "macos")
        set(libs ${local_path}/lib/libmp3lame.0.dylib ${local_path}/lib/libmp3lame.dylib)
    elseif (os STREQUAL "windows")
        set(libs ${local_path}/lib/mp3lame.lib)
    endif()
    if(NOT TARGET libmp3lame::libmp3lame)
       add_library(libmp3lame::libmp3lame INTERFACE IMPORTED GLOBAL)
       target_include_directories(libmp3lame::libmp3lame INTERFACE ${inc})
       target_link_libraries(libmp3lame::libmp3lame INTERFACE ${libs})
    endif()
    set_property(GLOBAL PROPERTY libmp3lame_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY libmp3lame_LIBRARIES ${libs})
    set_property(GLOBAL PROPERTY libmp3lame_INSTALL_LIBRARIES ${libs})
endfunction()

function(libmp3lame_PopulateSystem)
    find_path(libmp3lame_INCLUDE_DIR NAMES lame/lame.h)
    find_library(libmp3lame_LIBRARY NAMES mp3lame)
    if (NOT libmp3lame_INCLUDE_DIR OR NOT libmp3lame_LIBRARY)
        message(FATAL_ERROR "[libmp3lame] system lame not found (USE_SYSTEM enabled)")
    endif()
    if(NOT TARGET libmp3lame::libmp3lame)
       add_library(libmp3lame::libmp3lame INTERFACE IMPORTED GLOBAL)
       target_include_directories(libmp3lame::libmp3lame INTERFACE ${libmp3lame_INCLUDE_DIR})
       target_link_libraries(libmp3lame::libmp3lame INTERFACE ${libmp3lame_LIBRARY})
    endif()
    set_property(GLOBAL PROPERTY libmp3lame_INCLUDE_DIRS ${libmp3lame_INCLUDE_DIR})
    set_property(GLOBAL PROPERTY libmp3lame_LIBRARIES ${libmp3lame_LIBRARY})
    set_property(GLOBAL PROPERTY libmp3lame_INSTALL_LIBRARIES "")
endfunction()
