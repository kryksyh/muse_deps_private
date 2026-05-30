# Core build steps, shared by the CI -P wrapper (build_dep.cmake) and consumers
# (<name>_PopulateBuild). Include this file, then call build_dep(...).
#
# build_dep(NAME <n> RECIPE_DIR <d> OS <os> ARCH <a> BUILDTYPE <bt> WORK <w> INSTALL_DIR <i>)
#   sources -> patch -> cmake configure/build/install into INSTALL_DIR.
#   Requires git + cmake on PATH. Reads <d>/spec.cmake; applies <d>/patch/*.patch.

function(_bd_run)
    execute_process(COMMAND ${ARGN} RESULT_VARIABLE _rc)
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "Command failed (${_rc}): ${ARGN}")
    endif()
endfunction()

function(build_dep)
    cmake_parse_arguments(BD "" "NAME;RECIPE_DIR;OS;ARCH;BUILDTYPE;WORK;INSTALL_DIR" "" ${ARGN})

    include("${BD_RECIPE_DIR}/spec.cmake")
    find_program(GIT NAMES git REQUIRED)

    set(SRC "${BD_WORK}/src")
    set(BUILD "${BD_WORK}/build")
    file(REMOVE_RECURSE "${BD_WORK}")
    file(MAKE_DIRECTORY "${BD_WORK}")

    # 1. sources
    if(DEFINED DEP_FORK_GIT)
        _bd_run(${GIT} clone --depth 1 --branch "${DEP_FORK_REF}" "${DEP_FORK_GIT}" "${SRC}")
    else()
        get_filename_component(an "${DEP_SOURCE_URL}" NAME)
        set(archive "${BD_WORK}/${an}")
        file(DOWNLOAD "${DEP_SOURCE_URL}" "${archive}" EXPECTED_HASH SHA256=${DEP_SOURCE_SHA256})
        set(extract "${BD_WORK}/extract")
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

    # 2. patch
    file(GLOB patches "${BD_RECIPE_DIR}/patch/*.patch")
    list(SORT patches)
    foreach(p ${patches})
        message(STATUS "[${BD_NAME}] patch ${p}")
        _bd_run(${GIT} apply --whitespace=nowarn "${p}" WORKING_DIRECTORY "${SRC}")
    endforeach()

    # 3. build + install
    set(INSTALL "${BD_INSTALL_DIR}")
    if(EXISTS "${BD_RECIPE_DIR}/build.cmake")
        include("${BD_RECIPE_DIR}/build.cmake")   # uses SRC, BUILD, INSTALL; must install into INSTALL
    else()
        set(cfg -S "${SRC}" -B "${BUILD}" -G Ninja
                -DCMAKE_BUILD_TYPE=RelWithDebInfo
                -DCMAKE_INSTALL_PREFIX=${INSTALL}
                ${DEP_CMAKE_ARGS})
        if(BD_OS STREQUAL "macos")
            if(BD_ARCH STREQUAL "universal")
                set(osx "x86_64;arm64")
            elseif(BD_ARCH STREQUAL "aarch64")
                set(osx "arm64")
            else()
                set(osx "x86_64")
            endif()
            if(NOT DEFINED DEP_MACOS_DEPLOYMENT_TARGET)
                set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
            endif()
            list(APPEND cfg "-DCMAKE_OSX_ARCHITECTURES=${osx}"
                            "-DCMAKE_OSX_DEPLOYMENT_TARGET=${DEP_MACOS_DEPLOYMENT_TARGET}")
        endif()
        _bd_run(${CMAKE_COMMAND} ${cfg})
        _bd_run(${CMAKE_COMMAND} --build "${BUILD}" --config RelWithDebInfo --target install --parallel)
    endif()

    # build-system metadata the consumers never reference
    file(REMOVE_RECURSE "${INSTALL}/lib/pkgconfig" "${INSTALL}/lib/cmake")
    if(DEFINED DEP_LICENSE_FILES)
        file(MAKE_DIRECTORY "${INSTALL}/licenses")
        foreach(lf ${DEP_LICENSE_FILES})
            file(COPY "${SRC}/${lf}" DESTINATION "${INSTALL}/licenses")
        endforeach()
    endif()
endfunction()
