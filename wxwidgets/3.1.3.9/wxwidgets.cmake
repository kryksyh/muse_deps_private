
function(wxwidgets_Populate remote_url local_path os arch build_type)

    if (os STREQUAL "linux")

        set(compiler "gcc12")

        # At the moment only relwithdebinfo
        # I don't think we need debug builds
        set(name "linux_${arch}_relwithdebinfo_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[wxwidgets] Populate: ${remote_url} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(wxwidgets_INCLUDE_DIRS
            ${local_path}/include
            ${local_path}/include/wx-3.1
        )

        set(wxwidgets_LIBRARIES
            ${local_path}/lib/libwx_baseu-3.1.so
        )
        set(wxwidgets_INSTALL_LIBRARIES ${wxwidgets_LIBRARIES})

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
            message(STATUS "[wxwidgets] Populate: ${remote_url}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(wxwidgets_INCLUDE_DIRS
            ${local_path}/include
            ${local_path}/include/wx-3.1
        )

        set(wxwidgets_LIBRARIES
            ${local_path}/lib/libwx_baseu-3.1.dylib
        )
        set(wxwidgets_INSTALL_LIBRARIES ${wxwidgets_LIBRARIES})

    elseif(os STREQUAL "windows")

        set(compiler "msvc194")
        set(suffix "")

        if (build_type STREQUAL "release")
            set(build_type "relwithdebinfo")
        endif()

        if (build_type STREQUAL "debug")
            set(suffix "d")
        endif()

        set(name "windows_${arch}_${build_type}_${compiler}")

        if (NOT EXISTS ${local_path}/${name}.7z)
            message(STATUS "[wxwidgets] Populate: ${remote_url}/${name} to ${local_path} ${os} ${arch} ${build_type}")
            file(DOWNLOAD ${remote_url}/${name}.7z ${local_path}/${name}.7z)
            file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
        endif()

        set(wxwidgets_INCLUDE_DIRS
            ${local_path}/include
        )

        set(wxwidgets_LIBRARIES
            ${local_path}/lib/vc_x64_dll/wxbase31u${suffix}.lib
        )

        set(wxwidgets_INSTALL_LIBRARIES
            ${local_path}/lib/vc_x64_dll/wxbase313u${suffix}_vc_x64_custom.dll
        )

    else()
        message(FATAL_ERROR "[wxwidgets] Not supported os: ${os}")
    endif()

    add_library(wxwidgets::wxwidgets INTERFACE IMPORTED GLOBAL)
    target_include_directories(wxwidgets::wxwidgets INTERFACE ${wxwidgets_INCLUDE_DIRS})
    target_link_libraries(wxwidgets::wxwidgets INTERFACE ${wxwidgets_LIBRARIES})

    set_property(GLOBAL PROPERTY wxwidgets_INCLUDE_DIRS ${wxwidgets_INCLUDE_DIRS})
    set_property(GLOBAL PROPERTY wxwidgets_LIBRARIES ${wxwidgets_LIBRARIES})
    set_property(GLOBAL PROPERTY wxwidgets_INSTALL_LIBRARIES ${wxwidgets_INSTALL_LIBRARIES})

endfunction()


# Derive include/compile/link flags from a wx-config (handles wx's setup.h
# layout). install_libs = libs to bundle (empty for system).
function(_wxwidgets_set_from_wxconfig wxconfig install_libs)
    execute_process(COMMAND ${wxconfig} --cxxflags base OUTPUT_VARIABLE wx_cxx OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${wxconfig} --libs base OUTPUT_VARIABLE wx_libs OUTPUT_STRIP_TRAILING_WHITESPACE)
    separate_arguments(wx_cxx_list NATIVE_COMMAND "${wx_cxx}")
    separate_arguments(wx_libs_list NATIVE_COMMAND "${wx_libs}")

    set(incs "")
    set(opts "")
    foreach(f ${wx_cxx_list})
        if (f MATCHES "^-I(.+)")
            list(APPEND incs ${CMAKE_MATCH_1})
        else()
            list(APPEND opts ${f})
        endif()
    endforeach()

    if(NOT TARGET wxwidgets::wxwidgets)
       add_library(wxwidgets::wxwidgets INTERFACE IMPORTED GLOBAL)
       target_include_directories(wxwidgets::wxwidgets INTERFACE ${incs})
       target_compile_options(wxwidgets::wxwidgets INTERFACE ${opts})
       target_link_libraries(wxwidgets::wxwidgets INTERFACE ${wx_libs_list})
    endif()
    set_property(GLOBAL PROPERTY wxwidgets_INCLUDE_DIRS ${incs})
    set_property(GLOBAL PROPERTY wxwidgets_LIBRARIES ${wx_libs_list})
    set_property(GLOBAL PROPERTY wxwidgets_INSTALL_LIBRARIES ${install_libs})
endfunction()

function(wxwidgets_PopulateBuild remote_url local_path os arch build_type)
    set(recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${recipe_base}/wxwidgets/3.1.3.9/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${recipe_base}/wxwidgets/3.1.3.9/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[wxwidgets] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME wxwidgets RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    file(GLOB wx_install_libs "${local_path}/lib/libwx_baseu*")
    _wxwidgets_set_from_wxconfig("${local_path}/bin/wx-config" "${wx_install_libs}")
endfunction()

function(wxwidgets_PopulateSystem)
    find_program(WX_CONFIG NAMES wx-config)
    if (NOT WX_CONFIG)
        message(FATAL_ERROR "[wxwidgets] wx-config not found (install system wxWidgets dev package)")
    endif()
    _wxwidgets_set_from_wxconfig("${WX_CONFIG}" "")
endfunction()
