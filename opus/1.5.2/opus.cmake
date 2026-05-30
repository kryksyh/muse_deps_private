# Consume metadata for opus 1.5.2. Three resolution entrypoints used by the
# consumer's populate(): _Populate (prebuilt), _PopulateBuild (from source),
# _PopulateSystem (system-installed). All set the same opus_* globals + target.

set(opus_release_base "https://github.com/kryksyh/muse_deps_private/releases/download/opus-1.5.2")
set(opus_recipe_base  "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")

# Set opus_* globals + imported target from an extracted/installed prefix
# (include/, lib/ laid out exactly as the .7z and as `cmake --install`).
function(_opus_set_from_prefix prefix os)
    if (os STREQUAL "linux")
        set(inc ${prefix}/include ${prefix}/include/opus)
        set(libs ${prefix}/lib/libopus.so.0.10.1 ${prefix}/lib/libopus.so.0 ${prefix}/lib/libopus.so)
        set(install ${libs})
    elseif (os STREQUAL "macos")
        set(inc ${prefix}/include ${prefix}/include/opus)
        set(libs ${prefix}/lib/libopus.0.10.1.dylib ${prefix}/lib/libopus.0.dylib ${prefix}/lib/libopus.dylib)
        set(install ${libs})
    elseif (os STREQUAL "windows")
        set(inc ${prefix}/include ${prefix}/include/opus)
        set(libs ${prefix}/lib/opus.lib)
        set(install ${prefix}/bin/opus.dll)
    else()
        message(FATAL_ERROR "[opus] Not supported os: ${os}")
    endif()

    if(NOT TARGET Opus::opus)
       add_library(Opus::opus INTERFACE IMPORTED GLOBAL)
       target_include_directories(Opus::opus INTERFACE ${inc})
       target_link_libraries(Opus::opus INTERFACE ${libs})
    endif()

    set_property(GLOBAL PROPERTY opus_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY opus_LIBRARIES ${libs})
    set_property(GLOBAL PROPERTY opus_INSTALL_LIBRARIES ${install})
endfunction()

# Prebuilt. Non-fatal: if there is no release asset for this os/arch, sets
# opus_AVAILABLE=FALSE and returns so the caller can fall back to a source build.
function(opus_Populate remote_url local_path os arch build_type)

    if (os STREQUAL "linux")
        set(name "linux_${arch}_relwithdebinfo_gcc12")
    elseif (os STREQUAL "macos")
        if (arch STREQUAL "x86_64")
            set(name "macos_x86_64_relwithdebinfo_appleclang15_os109")
        elseif (arch STREQUAL "aarch64")
            set(name "macos_aarch64_relwithdebinfo_appleclang15_os1013")
        elseif (arch STREQUAL "universal")
            set(name "macos_universal_relwithdebinfo_appleclang15_os1013")
        else()
            set_property(GLOBAL PROPERTY opus_AVAILABLE FALSE)
            return()
        endif()
    elseif (os STREQUAL "windows")
        set(bt ${build_type})
        if (bt STREQUAL "release")
            set(bt "relwithdebinfo")
        endif()
        set(name "windows_${arch}_${bt}_msvc194")
    else()
        set_property(GLOBAL PROPERTY opus_AVAILABLE FALSE)
        return()
    endif()

    if (NOT EXISTS ${local_path}/${name}.7z)
        file(MAKE_DIRECTORY ${local_path})
        message(STATUS "[opus] prebuilt: ${opus_release_base}/${name}.7z")
        file(DOWNLOAD ${opus_release_base}/${name}.7z ${local_path}/${name}.7z)
    endif()

    # A missing release asset yields a 404 body, not a 7z — validate the magic.
    set(valid FALSE)
    if (EXISTS ${local_path}/${name}.7z)
        file(READ ${local_path}/${name}.7z magic LIMIT 6 HEX)
        if (magic STREQUAL "377abcaf271c")
            set(valid TRUE)
        endif()
    endif()
    if (NOT valid)
        file(REMOVE ${local_path}/${name}.7z)
        set_property(GLOBAL PROPERTY opus_AVAILABLE FALSE)
        return()
    endif()

    if (NOT EXISTS ${local_path}/include)
        file(ARCHIVE_EXTRACT INPUT ${local_path}/${name}.7z DESTINATION ${local_path})
    endif()

    _opus_set_from_prefix(${local_path} ${os})
    set_property(GLOBAL PROPERTY opus_AVAILABLE TRUE)
endfunction()

# Build from source (with patches) into local_path, then use it. Fetches the
# shared driver + this dep's recipe the same way this .cmake itself is fetched.
function(opus_PopulateBuild remote_url local_path os arch build_type)

    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")

    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${opus_recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${opus_recipe_base}/opus/1.5.2/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${opus_recipe_base}/opus/1.5.2/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[opus] building from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME opus RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    _opus_set_from_prefix(${local_path} ${os})
endfunction()

# System-installed.
function(opus_PopulateSystem)

    find_path(opus_INCLUDE_DIR NAMES opus/opus.h)
    find_library(opus_LIBRARY NAMES opus)
    if (NOT opus_INCLUDE_DIR OR NOT opus_LIBRARY)
        message(FATAL_ERROR "[opus] system opus not found (USE_SYSTEM enabled)")
    endif()

    set(inc ${opus_INCLUDE_DIR} ${opus_INCLUDE_DIR}/opus)

    if(NOT TARGET Opus::opus)
       add_library(Opus::opus INTERFACE IMPORTED GLOBAL)
       target_include_directories(Opus::opus INTERFACE ${inc})
       target_link_libraries(Opus::opus INTERFACE ${opus_LIBRARY})
    endif()

    set_property(GLOBAL PROPERTY opus_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY opus_LIBRARIES ${opus_LIBRARY})
    set_property(GLOBAL PROPERTY opus_INSTALL_LIBRARIES "")
endfunction()
