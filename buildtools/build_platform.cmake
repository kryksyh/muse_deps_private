# CI / local: build EVERY buildable recipe for one platform and pack a single
# per-platform prebuilt archive — prebuilt-<os>-<arch>.7z laid out as <name>/include,
# <name>/lib, ... per dep, which is exactly what the consumer downloads + extracts.
#
#   cmake -DOS=macos -DARCH=universal -P buildtools/build_platform.cmake
#
# Source-delivery deps (no DEP_SOURCE_URL, e.g. lv2sdk) are skipped — they ship in
# the source bundle, not the prebuilt archive. Deps are built in dependency order
# (DEP_DEPENDS) into sibling staging prefixes.

cmake_minimum_required(VERSION 3.24)
if(NOT DEFINED OS OR NOT DEFINED ARCH)
    message(FATAL_ERROR "Required: -DOS=<macos|linux|windows> -DARCH=<x86_64|aarch64|universal>")
endif()
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
include("${CMAKE_CURRENT_LIST_DIR}/build_dep_lib.cmake")
find_program(SEVENZIP NAMES 7z 7za 7zr REQUIRED)

set(STAGE "${REPO_ROOT}/.build/platform/${OS}_${ARCH}")
file(REMOVE_RECURSE "${STAGE}")
file(MAKE_DIRECTORY "${STAGE}")

# Collect buildable recipes (those with a source tarball): name -> version + dep names.
file(GLOB_RECURSE _specs "${REPO_ROOT}/spec.cmake")
list(SORT _specs)
set(ALL "")
foreach(_s ${_specs})
    unset(DEP_SOURCE_URL)
    unset(DEP_DEPENDS)
    unset(DEP_PLATFORMS)
    include("${_s}")
    if(NOT DEFINED DEP_SOURCE_URL)
        continue()
    endif()
    # Platform applicability: DEP_PLATFORMS entries match <os> or <os>-<arch>
    # (e.g. openssl="linux macos"; yasm="windows-x86_64" — not Windows-ARM64, which
    # uses NEON). Applicable if either form is listed.
    if(DEFINED DEP_PLATFORMS)
        list(FIND DEP_PLATFORMS "${OS}" _pf1)
        list(FIND DEP_PLATFORMS "${OS}-${ARCH}" _pf2)
        if(_pf1 EQUAL -1 AND _pf2 EQUAL -1)
            continue()
        endif()
    endif()
    get_filename_component(_vdir "${_s}" DIRECTORY)   # .../recipe
    get_filename_component(_vdir "${_vdir}" DIRECTORY) # .../<version>
    get_filename_component(_ndir "${_vdir}" DIRECTORY) # .../<name>
    get_filename_component(_v "${_vdir}" NAME)
    get_filename_component(_n "${_ndir}" NAME)
    # DEP_KIND (in the version-agnostic metadata) decides handling: source-delivery
    # is skipped (ships in the source bundle); tools (yasm) are built as build-time
    # deps + put on PATH but NOT packaged; libraries are built + packaged.
    unset(DEP_KIND)
    if(EXISTS "${_ndir}/${_n}.cmake")
        include("${_ndir}/${_n}.cmake")
    endif()
    if(DEP_KIND STREQUAL "source")
        continue()
    endif()
    set(_VER_${_n} "${_v}")
    set(_DEPS_${_n} "")
    foreach(dv ${DEP_DEPENDS})
        string(REPLACE "/" ";" _p "${dv}")
        list(GET _p 0 _dn)
        list(APPEND _DEPS_${_n} "${_dn}")
    endforeach()
    if(DEP_KIND STREQUAL "tool")
        list(APPEND TOOLS "${_n}")
    else()
        list(APPEND ALL "${_n}")
    endif()
endforeach()
list(REMOVE_DUPLICATES ALL)

# Build-time tools (e.g. yasm for mpg123's x86/x64 asm decoder) on PATH before the
# libs. DEP_PLATFORMS already restricted TOOLS to this platform (yasm -> Windows),
# so this is empty elsewhere. Tools are never packaged (built outside STAGE).
if(OS STREQUAL "windows")
    set(_sep ";")
else()
    set(_sep ":")
endif()
foreach(_t ${TOOLS})
    message(STATUS "[platform] tool ${_t}/${_VER_${_t}}")
    build_dep(NAME ${_t} RECIPE_DIR "${REPO_ROOT}/${_t}/${_VER_${_t}}/recipe"
              OS ${OS} ARCH ${ARCH}
              WORK "${REPO_ROOT}/.build/platform/work/${_t}"
              INSTALL_DIR "${REPO_ROOT}/.build/platform/tools/${_t}")
    set(ENV{PATH} "${REPO_ROOT}/.build/platform/tools/${_t}/bin${_sep}$ENV{PATH}")
endforeach()

# Build in dependency order: a dep is built once all its DEP_DEPENDS are staged.
set(DONE "")
list(LENGTH ALL _remaining)
while(_remaining GREATER 0)
    set(_progress FALSE)
    foreach(_n ${ALL})
        list(FIND DONE "${_n}" _f)
        if(NOT _f EQUAL -1)
            continue()
        endif()
        set(_ready TRUE)
        set(_prefixes "")
        foreach(_d ${_DEPS_${_n}})
            list(FIND DONE "${_d}" _df)
            if(_df EQUAL -1)
                set(_ready FALSE)
            else()
                list(APPEND _prefixes "${STAGE}/${_d}")
            endif()
        endforeach()
        if(NOT _ready)
            continue()
        endif()
        message(STATUS "[platform] build ${_n}/${_VER_${_n}}")
        build_dep(NAME ${_n} RECIPE_DIR "${REPO_ROOT}/${_n}/${_VER_${_n}}/recipe"
                  OS ${OS} ARCH ${ARCH}
                  WORK "${REPO_ROOT}/.build/platform/work/${_n}" INSTALL_DIR "${STAGE}/${_n}"
                  DEPENDS_PREFIXES "${_prefixes}")
        list(APPEND DONE "${_n}")
        set(_progress TRUE)
    endforeach()
    if(NOT _progress)
        message(FATAL_ERROR "[platform] dependency cycle / missing dep — done: ${DONE}, all: ${ALL}")
    endif()
    list(LENGTH DONE _d)
    list(LENGTH ALL _total)
    math(EXPR _remaining "${_total} - ${_d}")
endwhile()

# Package: each dep's <name>/ subtree into one archive.
set(OUT "${REPO_ROOT}/prebuilt-${OS}-${ARCH}.7z")
file(REMOVE "${OUT}")
file(GLOB _items RELATIVE "${STAGE}" "${STAGE}/*")
message(STATUS "[platform] package ${_items} -> ${OUT}")
execute_process(COMMAND ${SEVENZIP} a -t7z "${OUT}" ${_items}
                WORKING_DIRECTORY "${STAGE}" RESULT_VARIABLE _rc)
if(NOT _rc EQUAL 0)
    message(FATAL_ERROR "[platform] package failed (${_rc})")
endif()
file(WRITE "${REPO_ROOT}/.build/last_platform_artifact.txt" "${OUT}")
message(STATUS "[platform] done: ${OUT}")
