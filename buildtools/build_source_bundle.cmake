# Produces a source bundle .7z for an amalgamated source-delivery dep (no
# compilation: the consumer compiles the sources in-tree). Mirrors build_dep.cmake.
#
#   cmake -DLIB=lv2sdk/0.24.26 -P buildtools/build_source_bundle.cmake
#
# Reads <name>/<version>/recipe/sources.cmake (DEP_SOURCES = "subdir|git|ref"),
# clones each repo at its ref, strips .git, and packages a single
# <name>-<version>-src.7z (top-level entries are the subdirs). Upload it to the
# release tagged <name>-<version>.

cmake_minimum_required(VERSION 3.16)

if (NOT DEFINED LIB)
    message(FATAL_ERROR "pass -DLIB=<name>/<version>")
endif()

string(REPLACE "/" ";" _parts "${LIB}")
list(GET _parts 0 NAME)
list(GET _parts 1 VERSION)

set(_root "${CMAKE_CURRENT_LIST_DIR}/..")
include("${_root}/${NAME}/${VERSION}/recipe/sources.cmake")

set(_work "${_root}/.build/${NAME}-${VERSION}-src")
file(REMOVE_RECURSE "${_work}")
file(MAKE_DIRECTORY "${_work}")

set(_subs "")
foreach(_s ${DEP_SOURCES})
    string(REPLACE "|" ";" _f "${_s}")
    list(GET _f 0 _sub)
    list(GET _f 1 _git)
    list(GET _f 2 _ref)
    message(STATUS "[bundle] ${_sub} <- ${_git}@${_ref}")
    execute_process(COMMAND git clone --quiet "${_git}" "${_work}/${_sub}" RESULT_VARIABLE _rc)
    if (_rc)
        message(FATAL_ERROR "[bundle] clone failed: ${_git}")
    endif()
    execute_process(COMMAND git -C "${_work}/${_sub}" checkout --quiet "${_ref}" RESULT_VARIABLE _rc)
    if (_rc)
        message(FATAL_ERROR "[bundle] checkout failed: ${_git}@${_ref}")
    endif()
    file(REMOVE_RECURSE "${_work}/${_sub}/.git")
    list(APPEND _subs "${_sub}")
endforeach()

set(_archive "${_root}/.build/${NAME}-${VERSION}-src.7z")
file(REMOVE "${_archive}")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cf "${_archive}" --format=7zip ${_subs}
    WORKING_DIRECTORY "${_work}"
    RESULT_VARIABLE _rc)
if (_rc)
    message(FATAL_ERROR "[bundle] packaging failed")
endif()

message(STATUS "[bundle] wrote ${_archive}")
