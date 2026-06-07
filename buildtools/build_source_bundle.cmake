# Produce sources.7z: a self-contained muse_deps snapshot (engine + builder +
# per-dep metadata + recipes) plus every dependency's pinned source (tarballs
# SHA-verified, git pins cloned), for fully-offline source builds. A consumer
# extracts it and points  MUSE_DEPS_URL=file://<root>  and
# MUSE_DEPS_CACHE=<root>/sources  at it — then a normal source/REBUILD build needs
# no network. Layout mirrors what the consumer expects: <root>/buildtools,
# <root>/<name>/<name>.cmake, <root>/<name>/<version>/recipe/..., and
# <root>/sources/downloads/<name>/<tarball|sub.git>.
#
#   cmake -P buildtools/build_source_bundle.cmake     # -> sources.7z at repo root

cmake_minimum_required(VERSION 3.24)
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
find_program(SEVENZIP NAMES 7z 7za 7zr REQUIRED)
find_program(GIT NAMES git REQUIRED)

set(STAGE "${REPO_ROOT}/.build/source_bundle")
file(REMOVE_RECURSE "${STAGE}")
file(MAKE_DIRECTORY "${STAGE}/buildtools")
file(COPY "${REPO_ROOT}/buildtools/consume.cmake"
          "${REPO_ROOT}/buildtools/build_dep_lib.cmake"
     DESTINATION "${STAGE}/buildtools")

# Snapshot every dep's version-agnostic metadata (<name>/<name>.cmake), including
# system-only deps with no source recipe (e.g. libcurl/openssl) — the spec loop
# below only covers deps that ship source, so the consumer would otherwise miss
# these offline.
file(GLOB _all_meta "${REPO_ROOT}/*/*.cmake")
foreach(_m ${_all_meta})
    get_filename_component(_mn "${_m}" NAME_WE)
    get_filename_component(_md "${_m}" DIRECTORY)
    get_filename_component(_mdn "${_md}" NAME)
    if(_mn STREQUAL _mdn)   # matches <name>/<name>.cmake
        file(COPY "${_m}" DESTINATION "${STAGE}/${_mn}")
    endif()
endforeach()

# Fetch + SHA-verify a tarball into the bundle's cache (the layout build_dep reads).
function(_sb_tarball name url sha)
    get_filename_component(an "${url}" NAME)
    set(dst "${STAGE}/sources/downloads/${name}/${an}")
    if(EXISTS "${dst}")
        return()
    endif()
    file(MAKE_DIRECTORY "${STAGE}/sources/downloads/${name}")
    # Retry: release hosts (e.g. github.com/.../releases/download) flake / rate-limit
    # in CI, and a single failure must not abort the whole bundle. NB: don't pass
    # EXPECTED_HASH to file(DOWNLOAD) — on a failed download it hard-aborts ("cannot
    # compute hash on failed download") instead of returning STATUS, defeating the
    # retry. Download, then verify the SHA separately.
    foreach(attempt 1 2 3 4)
        message(STATUS "[source-bundle] fetch ${name} (try ${attempt}): ${url}")
        file(DOWNLOAD "${url}" "${dst}" STATUS st)
        list(GET st 0 code)
        if(code EQUAL 0)
            file(SHA256 "${dst}" got)
            if(got STREQUAL "${sha}")
                return()
            endif()
            message(WARNING "[source-bundle] ${name} sha mismatch (got ${got}, want ${sha})")
        endif()
        file(REMOVE "${dst}")
    endforeach()
    message(FATAL_ERROR "[source-bundle] ${name} download failed after retries: ${st}")
endfunction()

file(GLOB_RECURSE _specs "${REPO_ROOT}/spec.cmake")
list(SORT _specs)
foreach(_s ${_specs})
    get_filename_component(_rdir "${_s}" DIRECTORY)        # .../recipe
    get_filename_component(_vdir "${_rdir}" DIRECTORY)     # .../<version>
    get_filename_component(_ndir "${_vdir}" DIRECTORY)     # .../<name>
    get_filename_component(_v "${_vdir}" NAME)
    get_filename_component(_n "${_ndir}" NAME)

    # metadata (version-agnostic consume file) + the whole recipe dir
    if(EXISTS "${_ndir}/${_n}.cmake")
        file(COPY "${_ndir}/${_n}.cmake" DESTINATION "${STAGE}/${_n}")
    endif()
    file(COPY "${_rdir}" DESTINATION "${STAGE}/${_n}/${_v}")

    # sources: single tarball (DEP_SOURCE_URL) and/or source-delivery (DEP_SOURCES)
    unset(DEP_SOURCE_URL)
    unset(DEP_SOURCE_SHA256)
    unset(DEP_SOURCES)
    include("${_s}")
    if(DEFINED DEP_SOURCE_URL AND DEFINED DEP_SOURCE_SHA256)
        _sb_tarball("${_n}" "${DEP_SOURCE_URL}" "${DEP_SOURCE_SHA256}")
    endif()
    foreach(e ${DEP_SOURCES})
        string(REPLACE "|" ";" f "${e}")
        list(GET f 0 sub)
        list(GET f 1 kind)
        list(GET f 2 loc)
        list(GET f 3 ver)
        if(kind STREQUAL "tarball")
            _sb_tarball("${_n}" "${loc}" "${ver}")
        else() # git commit
            set(gitdir "${STAGE}/sources/downloads/${_n}/${sub}.git")
            if(NOT EXISTS "${gitdir}/.git")
                file(MAKE_DIRECTORY "${STAGE}/sources/downloads/${_n}")
                execute_process(COMMAND ${GIT} clone --quiet "${loc}" "${gitdir}" RESULT_VARIABLE rc)
                if(rc EQUAL 0)
                    execute_process(COMMAND ${GIT} -C "${gitdir}" checkout --quiet "${ver}")
                endif()
            endif()
            message(STATUS "[source-bundle] git ${_n}/${sub} @ ${ver}")
        endif()
    endforeach()
endforeach()

set(OUT "${REPO_ROOT}/sources.7z")
file(REMOVE "${OUT}")
file(GLOB _items RELATIVE "${STAGE}" "${STAGE}/*")
message(STATUS "[source-bundle] package ${_items} -> ${OUT}")
execute_process(COMMAND ${SEVENZIP} a -t7z "${OUT}" ${_items}
                WORKING_DIRECTORY "${STAGE}" RESULT_VARIABLE rc)
if(NOT rc EQUAL 0)
    message(FATAL_ERROR "[source-bundle] package failed (${rc})")
endif()
message(STATUS "[source-bundle] done: ${OUT}")
