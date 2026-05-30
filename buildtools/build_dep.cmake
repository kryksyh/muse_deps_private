# Generic dependency build driver for muse_deps.
#
# Usage:
#   cmake -DLIB=opus/1.5.2 -DOS=macos -DARCH=universal [-DBUILDTYPE=relwithdebinfo] \
#         -P buildtools/build_dep.cmake
#
# Abstract steps, driven by <LIB>/recipe/spec.cmake:
#   1. sources  -> <work>/src      (upstream tarball, or pre-patched fork)
#   2. patch    -> apply recipe/patch/*.patch in order (if any)
#   3. build    -> cmake configure + build + install into <work>/install
#                  (or delegate to recipe/build.cmake for non-CMake libs)
#   4. package  -> 7z the install prefix into <LIB>/<archive>.7z
#
# All per-dep knowledge lives in recipe/spec.cmake; this driver stays generic.

cmake_minimum_required(VERSION 3.24)

if(NOT DEFINED LIB OR NOT DEFINED OS OR NOT DEFINED ARCH)
    message(FATAL_ERROR "Required: -DLIB=<name>/<version> -DOS=<macos|linux|windows> -DARCH=<x86_64|aarch64|universal>")
endif()
if(NOT DEFINED BUILDTYPE)
    set(BUILDTYPE "relwithdebinfo")
endif()

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)

string(REPLACE "/" ";" lib_parts "${LIB}")
list(GET lib_parts 0 NAME)
list(GET lib_parts 1 VERSION)

set(LIB_DIR "${REPO_ROOT}/${LIB}")
set(RECIPE_DIR "${LIB_DIR}/recipe")
set(SPEC "${RECIPE_DIR}/spec.cmake")
if(NOT EXISTS "${SPEC}")
    message(FATAL_ERROR "No recipe spec: ${SPEC}")
endif()
include("${SPEC}")

set(WORK "${REPO_ROOT}/.build/${NAME}/${VERSION}/${OS}_${ARCH}")
set(SRC "${WORK}/src")
set(BUILD "${WORK}/build")
set(INSTALL "${WORK}/install")
file(REMOVE_RECURSE "${WORK}")
file(MAKE_DIRECTORY "${WORK}")

find_program(SEVENZIP NAMES 7z 7za 7zr REQUIRED)
find_program(GIT NAMES git REQUIRED)

function(run)
    execute_process(COMMAND ${ARGN} RESULT_VARIABLE rc)
    if(NOT rc EQUAL 0)
        message(FATAL_ERROR "Command failed (${rc}): ${ARGN}")
    endif()
endfunction()

# --- 1. sources -------------------------------------------------------------
message(STATUS "[${NAME}] sources")
if(DEFINED DEP_FORK_GIT)
    run(${GIT} clone --depth 1 --branch "${DEP_FORK_REF}" "${DEP_FORK_GIT}" "${SRC}")
else()
    get_filename_component(archive_name "${DEP_SOURCE_URL}" NAME)
    set(archive "${WORK}/${archive_name}")
    file(DOWNLOAD "${DEP_SOURCE_URL}" "${archive}"
         EXPECTED_HASH SHA256=${DEP_SOURCE_SHA256} SHOW_PROGRESS)
    set(extract "${WORK}/extract")
    file(MAKE_DIRECTORY "${extract}")
    file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${extract}")
    file(GLOB top LIST_DIRECTORIES true "${extract}/*")
    list(LENGTH top n)
    if(n EQUAL 1)
        list(GET top 0 root)
        file(RENAME "${root}" "${SRC}")
    else()
        file(RENAME "${extract}" "${SRC}")
    endif()
endif()

# --- 2. patch ---------------------------------------------------------------
file(GLOB patches "${RECIPE_DIR}/patch/*.patch")
list(SORT patches)
foreach(p ${patches})
    message(STATUS "[${NAME}] patch ${p}")
    run(${GIT} apply --whitespace=nowarn "${p}" WORKING_DIRECTORY "${SRC}")
endforeach()

# --- 3. build ---------------------------------------------------------------
message(STATUS "[${NAME}] build")
if(EXISTS "${RECIPE_DIR}/build.cmake")
    include("${RECIPE_DIR}/build.cmake")   # must install into ${INSTALL}
else()
    set(cfg -S "${SRC}" -B "${BUILD}" -G Ninja
            -DCMAKE_BUILD_TYPE=RelWithDebInfo
            -DCMAKE_INSTALL_PREFIX=${INSTALL}
            ${DEP_CMAKE_ARGS})
    if(OS STREQUAL "macos")
        if(ARCH STREQUAL "universal")
            set(osx_archs "x86_64;arm64")
        elseif(ARCH STREQUAL "aarch64")
            set(osx_archs "arm64")
        else()
            set(osx_archs "x86_64")
        endif()
        if(NOT DEFINED DEP_MACOS_DEPLOYMENT_TARGET)
            set(DEP_MACOS_DEPLOYMENT_TARGET "10.13")
        endif()
        list(APPEND cfg "-DCMAKE_OSX_ARCHITECTURES=${osx_archs}"
                        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${DEP_MACOS_DEPLOYMENT_TARGET}")
    endif()
    run(${CMAKE_COMMAND} ${cfg})
    run(${CMAKE_COMMAND} --build "${BUILD}" --config RelWithDebInfo --target install --parallel)
endif()

# --- 4. package -------------------------------------------------------------
# Drop build-system metadata the consumers never reference.
file(REMOVE_RECURSE "${INSTALL}/lib/pkgconfig" "${INSTALL}/lib/cmake")

if(DEFINED DEP_LICENSE_FILES)
    file(MAKE_DIRECTORY "${INSTALL}/licenses")
    foreach(lf ${DEP_LICENSE_FILES})
        file(COPY "${SRC}/${lf}" DESTINATION "${INSTALL}/licenses")
    endforeach()
endif()

if(NOT DEFINED DEP_ARCHIVE_NAME_${OS}_${ARCH})
    message(FATAL_ERROR "[${NAME}] no archive name for ${OS}_${ARCH} in spec.cmake")
endif()
set(archive_base "${DEP_ARCHIVE_NAME_${OS}_${ARCH}}")
set(out "${LIB_DIR}/${archive_base}.7z")
file(REMOVE "${out}")

set(contents include lib)
if(EXISTS "${INSTALL}/bin")
    list(APPEND contents bin)
endif()
if(EXISTS "${INSTALL}/licenses")
    list(APPEND contents licenses)
endif()

message(STATUS "[${NAME}] package -> ${out}")
run(${SEVENZIP} a -t7z "${out}" ${contents} WORKING_DIRECTORY "${INSTALL}")
file(WRITE "${REPO_ROOT}/.build/last_artifact.txt" "${out}")
message(STATUS "[${NAME}] done: ${out}")
