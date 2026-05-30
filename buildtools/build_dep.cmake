# CI / local entry point: build a dependency from source and package the .7z.
#
# Usage:
#   cmake -DLIB=opus/1.5.2 -DOS=macos -DARCH=universal [-DBUILDTYPE=relwithdebinfo] \
#         -P buildtools/build_dep.cmake
#
# The build itself lives in build_dep_lib.cmake (shared with consumers). This
# wrapper resolves the repo layout, runs the build, then packages the install
# prefix into <LIB>/<archive>.7z (archive name from spec.cmake).

cmake_minimum_required(VERSION 3.24)

if(NOT DEFINED LIB OR NOT DEFINED OS OR NOT DEFINED ARCH)
    message(FATAL_ERROR "Required: -DLIB=<name>/<version> -DOS=<macos|linux|windows> -DARCH=<x86_64|aarch64|universal>")
endif()
if(NOT DEFINED BUILDTYPE)
    set(BUILDTYPE "relwithdebinfo")
endif()

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
include("${CMAKE_CURRENT_LIST_DIR}/build_dep_lib.cmake")

string(REPLACE "/" ";" lib_parts "${LIB}")
list(GET lib_parts 0 NAME)
list(GET lib_parts 1 VERSION)

set(RECIPE_DIR "${REPO_ROOT}/${LIB}/recipe")
set(WORK "${REPO_ROOT}/.build/${NAME}/${VERSION}/${OS}_${ARCH}")
set(INSTALL "${WORK}/install")

# Build this dep's own dependencies first (DEP_DEPENDS = list of "name/version",
# topologically ordered) into shared prefixes, accumulating CMAKE_PREFIX_PATH.
include("${RECIPE_DIR}/spec.cmake")
set(dep_prefixes "")
foreach(dv ${DEP_DEPENDS})
    string(REPLACE "/" ";" _p "${dv}")
    list(GET _p 0 _dn)
    set(_dprefix "${REPO_ROOT}/.build/prefixes/${_dn}")
    message(STATUS "[${NAME}] dependency: ${dv}")
    build_dep(NAME ${_dn} RECIPE_DIR "${REPO_ROOT}/${dv}/recipe" OS ${OS} ARCH ${ARCH}
              BUILDTYPE ${BUILDTYPE} WORK "${REPO_ROOT}/.build/${dv}/${OS}_${ARCH}"
              INSTALL_DIR "${_dprefix}" DEPENDS_PREFIXES "${dep_prefixes}")
    list(APPEND dep_prefixes "${_dprefix}")
endforeach()

build_dep(NAME ${NAME} RECIPE_DIR "${RECIPE_DIR}" OS ${OS} ARCH ${ARCH}
          BUILDTYPE ${BUILDTYPE} WORK "${WORK}" INSTALL_DIR "${INSTALL}"
          DEPENDS_PREFIXES "${dep_prefixes}")

# --- package ---------------------------------------------------------------
include("${RECIPE_DIR}/spec.cmake")
find_program(SEVENZIP NAMES 7z 7za 7zr REQUIRED)

if(NOT DEFINED DEP_ARCHIVE_NAME_${OS}_${ARCH})
    message(FATAL_ERROR "[${NAME}] no archive name for ${OS}_${ARCH} in spec.cmake")
endif()
set(out "${REPO_ROOT}/${LIB}/${DEP_ARCHIVE_NAME_${OS}_${ARCH}}.7z")
file(REMOVE "${out}")

set(contents include lib)
if(EXISTS "${INSTALL}/bin")
    list(APPEND contents bin)
endif()
if(EXISTS "${INSTALL}/licenses")
    list(APPEND contents licenses)
endif()

message(STATUS "[${NAME}] package -> ${out}")
execute_process(COMMAND ${SEVENZIP} a -t7z "${out}" ${contents}
                WORKING_DIRECTORY "${INSTALL}" RESULT_VARIABLE rc)
if(NOT rc EQUAL 0)
    message(FATAL_ERROR "[${NAME}] package failed (${rc})")
endif()
file(WRITE "${REPO_ROOT}/.build/last_artifact.txt" "${out}")
message(STATUS "[${NAME}] done: ${out}")
