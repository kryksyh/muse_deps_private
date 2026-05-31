# Consume metadata for yasm 1.3.0 — a BUILD TOOL (host assembler), not a linked
# library. Consumed via require_tool(): the consumer builds it (or finds a
# system one) and prepends its bin/ to PATH so dependent dep builds (e.g.
# mpg123's find_program(yasm)) locate it. Exposes the global yasm_BIN_DIR.

set(yasm_recipe_base "https://raw.githubusercontent.com/kryksyh/muse_deps_private/main")

# Prebuilt: none published — report unavailable so require_tool builds from source.
function(yasm_Populate local_path os arch build_type version)
    set_property(GLOBAL PROPERTY yasm_AVAILABLE FALSE)
endfunction()

function(yasm_PopulateBuild local_path os arch build_type version)
    set(recipe_dir "${local_path}/recipe")
    file(MAKE_DIRECTORY "${recipe_dir}/patch")
    if (NOT EXISTS "${local_path}/build_dep_lib.cmake")
        file(DOWNLOAD ${yasm_recipe_base}/buildtools/build_dep_lib.cmake ${local_path}/build_dep_lib.cmake)
    endif()
    if (NOT EXISTS "${recipe_dir}/spec.cmake")
        file(DOWNLOAD ${yasm_recipe_base}/yasm/${version}/recipe/spec.cmake ${recipe_dir}/spec.cmake)
    endif()
    include("${recipe_dir}/spec.cmake")
    foreach(pf ${DEP_PATCHES})
        if (NOT EXISTS "${recipe_dir}/${pf}")
            file(DOWNLOAD ${yasm_recipe_base}/yasm/${version}/recipe/${pf} ${recipe_dir}/${pf})
        endif()
    endforeach()

    message(STATUS "[yasm] building tool from source -> ${local_path}")
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME yasm RECIPE_DIR "${recipe_dir}" OS ${os} ARCH ${arch}
              BUILDTYPE ${build_type} WORK "${local_path}/work" INSTALL_DIR "${local_path}")

    set_property(GLOBAL PROPERTY yasm_BIN_DIR "${local_path}/bin")
endfunction()

function(yasm_PopulateSystem)
    find_program(YASM_EXE NAMES yasm)
    if (NOT YASM_EXE)
        message(FATAL_ERROR "[yasm] system yasm not found (USE_SYSTEM enabled)")
    endif()
    get_filename_component(_d "${YASM_EXE}" DIRECTORY)
    set_property(GLOBAL PROPERTY yasm_BIN_DIR "${_d}")
endfunction()
