# Downloads every dep's pristine source tarball (from each recipe spec.cmake,
# incl. source-delivery DEP_SOURCES entries), verifies its SHA-256, and stages it
# as .build/mirror/<name>-<archive>. The producer attaches these to each dated
# release: they are the corresponding sources of the published binaries AND the
# fallback mirror build_dep_lib uses when upstream is down.
#
#   cmake -P buildtools/mirror_sources.cmake

cmake_minimum_required(VERSION 3.16)

set(REPO "${CMAKE_CURRENT_LIST_DIR}/..")
set(OUT "${REPO}/.build/mirror")
file(REMOVE_RECURSE "${OUT}")
file(MAKE_DIRECTORY "${OUT}")

function(_mirror_fetch name url sha)
    get_filename_component(an "${url}" NAME)
    set(dst "${OUT}/${name}-${an}")
    if(EXISTS "${dst}")
        return()   # already mirrored (another version dir of the same dep)
    endif()
    message(STATUS "[mirror] ${name}: ${url}")
    file(DOWNLOAD "${url}" "${dst}" STATUS st)
    list(GET st 0 c)
    if(c EQUAL 0)
        file(SHA256 "${dst}" got)
        if(got STREQUAL "${sha}")
            return()
        endif()
        message(WARNING "[mirror] ${name}/${an}: sha256 ${got} != ${sha}")
    endif()
    file(REMOVE "${dst}")
    message(FATAL_ERROR "[mirror] ${name} download failed: ${st}")
endfunction()

# Mirror one recipe's sources (function scope isolates the DEP_* it sets):
# the single tarball and/or every DEP_SOURCES tarball entry (source-delivery).
function(_mirror_one spec)
    include("${spec}")
    file(RELATIVE_PATH rel "${REPO}" "${spec}")
    string(REGEX REPLACE "/.*" "" name "${rel}")
    if(DEFINED DEP_SOURCE_URL AND DEFINED DEP_SOURCE_SHA256)
        _mirror_fetch("${name}" "${DEP_SOURCE_URL}" "${DEP_SOURCE_SHA256}")
    endif()
    foreach(e ${DEP_SOURCES})
        string(REPLACE "|" ";" f "${e}")
        list(GET f 1 kind)
        if(kind STREQUAL "tarball")
            list(GET f 2 loc)
            list(GET f 3 sha)
            _mirror_fetch("${name}" "${loc}" "${sha}")
        endif()
    endforeach()
endfunction()

file(GLOB_RECURSE specs "${REPO}/*/recipe/spec.cmake")
foreach(spec ${specs})
    _mirror_one("${spec}")
endforeach()
message(STATUS "[mirror] staged into ${OUT}")
