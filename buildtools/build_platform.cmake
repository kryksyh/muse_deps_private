# CI / local: build every buildable recipe for one platform; pack one archive per
# dep, named <name>-<version>-<os>-<arch>-<sig12>.7z (sig = recipe signature, so a
# recipe change yields a new name — assets stay immutable). Writes the archives
# plus a lock fragment (the per-dep "<name> <version> <os> <arch> <file> <sha256>"
# lines) into .build/platform/out/.
#
#   cmake -DOS=macos -DARCH=universal -P buildtools/build_platform.cmake
#
# Source-delivery deps ship in the source bundle and are skipped. Deps are built
# in dependency order (DEP_DEPENDS) into sibling staging prefixes.

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
    # Platform applicability: DEP_PLATFORMS entries match <os> or <os>-<arch>.
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
    # Source-delivery deps ship in the source bundle, not as prebuilt archives.
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
    list(APPEND ALL "${_n}")
endforeach()
list(REMOVE_DUPLICATES ALL)

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

# Package: one archive per dep (prefix contents at archive root) + lock fragment.
set(OUT_DIR "${REPO_ROOT}/.build/platform/out")
file(REMOVE_RECURSE "${OUT_DIR}")
file(MAKE_DIRECTORY "${OUT_DIR}")
set(_lock "")
foreach(_n ${ALL})
    _bd_recipe_sig("${REPO_ROOT}/${_n}/${_VER_${_n}}/recipe" "${OS}" "${ARCH}" _sig)
    string(SUBSTRING "${_sig}" 0 12 _sig)
    set(_file "${_n}-${_VER_${_n}}-${OS}-${ARCH}-${_sig}.7z")
    message(STATUS "[platform] package ${_file}")
    # -mf=off: no BCJ branch filters — 7z's ARM64 filter is not decodable by
    # CMake's libarchive, which then SILENTLY skips those entries on extract.
    execute_process(COMMAND ${SEVENZIP} a -t7z -mf=off "${OUT_DIR}/${_file}" . -x!.build_stamp
                    WORKING_DIRECTORY "${STAGE}/${_n}" RESULT_VARIABLE _rc)
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "[platform] package ${_n} failed (${_rc})")
    endif()
    # Consumers extract with file(ARCHIVE_EXTRACT), which does not fail on
    # entries it cannot decode — prove round-trip completeness here.
    set(_vdir "${OUT_DIR}/.verify")
    file(REMOVE_RECURSE "${_vdir}")
    file(MAKE_DIRECTORY "${_vdir}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xf "${OUT_DIR}/${_file}"
                    WORKING_DIRECTORY "${_vdir}" RESULT_VARIABLE _rc)
    file(GLOB_RECURSE _staged "${STAGE}/${_n}/*")
    file(GLOB_RECURSE _extracted "${_vdir}/*")
    list(LENGTH _staged _ns)
    list(LENGTH _extracted _ne)
    math(EXPR _ns "${_ns} - 1")   # .build_stamp is excluded from the archive
    if(NOT _rc EQUAL 0 OR NOT _ns EQUAL _ne)
        message(FATAL_ERROR "[platform] ${_file}: cmake extracted ${_ne}/${_ns} files — archive not consumable")
    endif()
    file(REMOVE_RECURSE "${_vdir}")
    file(SHA256 "${OUT_DIR}/${_file}" _sha)
    string(APPEND _lock "${_n} ${_VER_${_n}} ${OS} ${ARCH} ${_file} ${_sha}\n")
endforeach()
file(WRITE "${OUT_DIR}/prebuilt-${OS}-${ARCH}.lock" "${_lock}")
message(STATUS "[platform] done: ${OUT_DIR}")
