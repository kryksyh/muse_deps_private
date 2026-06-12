# Downloads every dep's pristine source tarball (from each recipe spec.cmake,
# incl. source-delivery DEP_SOURCES entries), verifies its SHA-256, and stages it
# as .build/mirror/<name>-<version>-src.<ext> (per-entry: <name>-<subdir>-src.<ext>). The producer attaches these to each dated
# release: they are the corresponding sources of the published binaries AND the
# fallback mirror build_dep_lib uses when upstream is down.
#
#   cmake -P buildtools/mirror_sources.cmake

cmake_minimum_required(VERSION 3.16)

set(REPO "${CMAKE_CURRENT_LIST_DIR}/..")
set(OUT "${REPO}/.build/mirror")
file(REMOVE_RECURSE "${OUT}")
file(MAKE_DIRECTORY "${OUT}")

include("${CMAKE_CURRENT_LIST_DIR}/build_dep_lib.cmake")   # _bd_src_ext

# Stage <url> as <label>-src.<ext> — our naming, not the upstream basename.
# Upstream is primary; the previous release's mirror asset (same SHA gate, far
# more available than flaky upstreams like surina.net) is the fallback, so a
# re-mirror never depends on every upstream being up at once.
function(_mirror_fetch name label url sha)
    get_filename_component(an "${url}" NAME)
    _bd_src_ext("${an}" ext)
    set(dst "${OUT}/${label}-src.${ext}")
    if(EXISTS "${dst}")
        return()   # already mirrored (another version dir of the same dep)
    endif()
    set(urls "${url}")
    _bd_mirror("${name}" "${REPO}" prev)
    if(prev)
        list(APPEND urls "${prev}/${label}-src.${ext}")
    endif()
    message(STATUS "[mirror] ${label}: ${url}")
    _bd_fetch("${dst}" "${sha}" ${urls})
endfunction()

# Mirror one recipe's sources (function scope isolates the DEP_* it sets):
# the single tarball and/or every DEP_SOURCES tarball entry (source-delivery).
function(_mirror_one spec)
    include("${spec}")
    file(RELATIVE_PATH rel "${REPO}" "${spec}")
    string(REPLACE "/" ";" relparts "${rel}")
    list(GET relparts 0 name)
    list(GET relparts 1 version)
    if(DEFINED DEP_SOURCE_URL AND DEFINED DEP_SOURCE_SHA256)
        _mirror_fetch("${name}-${version}" "${DEP_SOURCE_URL}" "${DEP_SOURCE_SHA256}")
    endif()
    foreach(e ${DEP_SOURCES})
        string(REPLACE "|" ";" f "${e}")
        list(GET f 0 sub)
        list(GET f 1 kind)
        if(kind STREQUAL "tarball")
            list(GET f 2 loc)
            list(GET f 3 sha)
            if(sub STREQUAL name)
                _mirror_fetch("${name}-${version}" "${loc}" "${sha}")
            else()
                _mirror_fetch("${name}-${sub}" "${loc}" "${sha}")
            endif()
        endif()
    endforeach()
endfunction()

# NB: GLOB_RECURSE does not expand intermediate */ components — recurse on the
# bare filename like build_platform does.
file(GLOB_RECURSE specs "${REPO}/spec.cmake")
foreach(spec ${specs})
    _mirror_one("${spec}")
endforeach()
message(STATUS "[mirror] staged into ${OUT}")
