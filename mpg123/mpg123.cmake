function(mpg123_Populate local_path os arch build_type version)

    if (os STREQUAL "linux")

        set(compiler "gcc10")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[mpg123] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(mpg123_INCLUDE_DIRS ${local_path}/include)
        set(mpg123_LIBRARIES
            ${local_path}/lib/libmpg123.so.0.47.0
            ${local_path}/lib/libmpg123.so.0
            ${local_path}/lib/libmpg123.so
        )
        set(mpg123_INSTALL_LIBRARIES ${mpg123_LIBRARIES})

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
            message(STATUS "[mpg123] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(mpg123_INCLUDE_DIRS ${local_path}/include)
        set(mpg123_LIBRARIES
            ${local_path}/lib/libmpg123.0.dylib
            ${local_path}/lib/libmpg123.dylib
        )
        set(mpg123_INSTALL_LIBRARIES ${mpg123_LIBRARIES})

    elseif(os STREQUAL "windows")

        set(compiler "msvc192")

        if (build_type STREQUAL "release")
            set(build_type "relwithdebinfo")
        endif()

        set(name "windows_${arch}_${build_type}_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[mpg123] Populate: https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD https://github.com/kryksyh/muse_deps_private/releases/download/mpg123-${version}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(mpg123_INCLUDE_DIRS ${local_path}/include)
        set(mpg123_LIBRARIES ${local_path}/lib/mpg123.lib)
        set(mpg123_INSTALL_LIBRARIES ${local_path}/bin/mpg123.dll)

    else()
        message(FATAL_ERROR "[mpg123] Not supported os: ${os}")
    endif()

    if(NOT TARGET mpg123::libmpg123)
       add_library(mpg123::libmpg123 INTERFACE IMPORTED GLOBAL)

       target_include_directories(mpg123::libmpg123 INTERFACE ${mpg123_INCLUDE_DIRS} )
       target_link_libraries(mpg123::libmpg123 INTERFACE ${mpg123_LIBRARIES} )
    endif()

    set_property(GLOBAL PROPERTY mpg123_INCLUDE_DIRS ${mpg123_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY mpg123_LIBRARIES ${mpg123_LIBRARIES})
    set_property(GLOBAL PROPERTY mpg123_INSTALL_LIBRARIES ${mpg123_INSTALL_LIBRARIES})

endfunction()

function(mpg123_PopulateBuild local_path os arch build_type version)
    set(recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${recipe_base}/mpg123/${version}/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${recipe_base}/mpg123/${version}/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[mpg123] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME mpg123 RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    set(inc ${local_path}/include)
    if (os STREQUAL "linux")
        set(libs ${local_path}/lib/libmpg123.so.0.47.0 ${local_path}/lib/libmpg123.so.0 ${local_path}/lib/libmpg123.so)
    elseif (os STREQUAL "macos")
        set(libs ${local_path}/lib/libmpg123.0.dylib ${local_path}/lib/libmpg123.dylib)
    elseif (os STREQUAL "windows")
        set(libs ${local_path}/lib/mpg123.lib)
    endif()
    if(NOT TARGET mpg123::libmpg123)
       add_library(mpg123::libmpg123 INTERFACE IMPORTED GLOBAL)
       target_include_directories(mpg123::libmpg123 INTERFACE ${inc})
       target_link_libraries(mpg123::libmpg123 INTERFACE ${libs})
    endif()
    set_property(GLOBAL PROPERTY mpg123_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY mpg123_LIBRARIES ${libs})
    set_property(GLOBAL PROPERTY mpg123_INSTALL_LIBRARIES ${libs})
endfunction()

function(mpg123_PopulateSystem)
    find_path(mpg123_INCLUDE_DIR NAMES mpg123.h)
    find_library(mpg123_LIBRARY NAMES mpg123)
    if (NOT mpg123_INCLUDE_DIR OR NOT mpg123_LIBRARY)
        message(FATAL_ERROR "[mpg123] system mpg123 not found (USE_SYSTEM enabled)")
    endif()
    if(NOT TARGET mpg123::libmpg123)
       add_library(mpg123::libmpg123 INTERFACE IMPORTED GLOBAL)
       target_include_directories(mpg123::libmpg123 INTERFACE ${mpg123_INCLUDE_DIR})
       target_link_libraries(mpg123::libmpg123 INTERFACE ${mpg123_LIBRARY})
    endif()
    set_property(GLOBAL PROPERTY mpg123_INCLUDE_DIRS ${mpg123_INCLUDE_DIR})
    set_property(GLOBAL PROPERTY mpg123_LIBRARIES ${mpg123_LIBRARY})
    set_property(GLOBAL PROPERTY mpg123_INSTALL_LIBRARIES "")
endfunction()
