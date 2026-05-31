# Consume metadata for wxWidgets 3.2.6 (wxBase only). Include/lib flags come
# from wx-config (handles wx's setup.h layout). No prebuilt yet -> _Populate
# reports unavailable so the consumer falls back to a source build.

set(wxwidgets_recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")

# Derive flags from a wx-config. install_libs = libs to bundle (empty for system).
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

    # When we built wx ourselves, link our libs by FULL PATH instead of
    # wx-config's -L/-lwx_*: CMake only adds a dir to the consumer's RUNPATH for
    # full-path library inputs, so this is what makes libwx_baseu resolve to our
    # build rather than a system copy (matches how the codecs are linked). Keep
    # wx-config's other flags (-pthread, system libs). System wx: flags as-is.
    if (install_libs)
        set(wx_other "")
        foreach(f ${wx_libs_list})
            if (NOT f MATCHES "^-L" AND NOT f MATCHES "^-lwx")
                list(APPEND wx_other ${f})
            endif()
        endforeach()
        set(link_libs ${install_libs} ${wx_other})
    else()
        set(link_libs ${wx_libs_list})
    endif()

    if(NOT TARGET wxwidgets::wxwidgets)
       add_library(wxwidgets::wxwidgets INTERFACE IMPORTED GLOBAL)
       target_include_directories(wxwidgets::wxwidgets INTERFACE ${incs})
       target_compile_options(wxwidgets::wxwidgets INTERFACE ${opts})
       target_link_libraries(wxwidgets::wxwidgets INTERFACE ${link_libs})
    endif()
    set_property(GLOBAL PROPERTY wxwidgets_INCLUDE_DIRS ${incs})
    set_property(GLOBAL PROPERTY wxwidgets_LIBRARIES ${link_libs})
    set_property(GLOBAL PROPERTY wxwidgets_INSTALL_LIBRARIES ${install_libs})
endfunction()

function(wxwidgets_Populate local_path os arch build_type version)
    # No prebuilt published yet; trigger the source-build fallback.
    set_property(GLOBAL PROPERTY wxwidgets_AVAILABLE FALSE)
endfunction()

function(wxwidgets_PopulateBuild local_path os arch build_type version)
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${wxwidgets_recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${wxwidgets_recipe_base}/wxwidgets/${version}/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    string(TOUPPER ${os} _os)
    foreach(pf ${DEP_PATCHES} ${DEP_PATCHES_${_os}})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${wxwidgets_recipe_base}/wxwidgets/${version}/recipe/${pf} ${recipe_dir}/${pf})
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
