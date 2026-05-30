# Downloads every dep's pristine source tarball (from each recipe spec.cmake),
# verifies its SHA-256, and stages it as .build/mirror/<name>-<archive> for
# upload to the `sources` release — our "just in case" fallback mirror that
# build_dep_lib falls back to when upstream is down. Run by mirror_sources.yml.
#
#   cmake -P buildtools/mirror_sources.cmake

cmake_minimum_required(VERSION 3.16)

set(REPO "${CMAKE_CURRENT_LIST_DIR}/..")
set(OUT "${REPO}/.build/mirror")
file(REMOVE_RECURSE "${OUT}")
file(MAKE_DIRECTORY "${OUT}")

# Mirror one recipe's tarball (function scope isolates the DEP_* it sets).
function(_mirror_one spec)
    include("${spec}")
    if(NOT DEFINED DEP_SOURCE_URL OR NOT DEFINED DEP_SOURCE_SHA256)
        return()   # git/fork or no tarball source
    endif()
    file(RELATIVE_PATH rel "${REPO}" "${spec}")
    string(REGEX REPLACE "/.*" "" name "${rel}")
    get_filename_component(an "${DEP_SOURCE_URL}" NAME)
    set(dst "${OUT}/${name}-${an}")
    if(EXISTS "${dst}")
        return()   # already mirrored (another version dir of the same dep)
    endif()
    message(STATUS "[mirror] ${name}: ${DEP_SOURCE_URL}")
    file(DOWNLOAD "${DEP_SOURCE_URL}" "${dst}" EXPECTED_HASH SHA256=${DEP_SOURCE_SHA256} STATUS st)
    list(GET st 0 c)
    if(NOT c EQUAL 0)
        file(REMOVE "${dst}")
        message(FATAL_ERROR "[mirror] ${name} download failed: ${st}")
    endif()
endfunction()

file(GLOB_RECURSE specs "${REPO}/*/recipe/spec.cmake")
foreach(spec ${specs})
    _mirror_one("${spec}")
endforeach()
message(STATUS "[mirror] staged into ${OUT}")
