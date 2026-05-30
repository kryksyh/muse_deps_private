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

# Like _bd_run but the first argument is the working directory.
function(_bd_run_dir wd)
    execute_process(COMMAND ${ARGN} WORKING_DIRECTORY "${wd}" RESULT_VARIABLE _rc)
    if(NOT _rc EQUAL 0)
        message(FATAL_ERROR "Command failed (${_rc}) in ${wd}: ${ARGN}")
    endif()
endfunction()

function(build_dep)
    cmake_parse_arguments(BD "" "NAME;RECIPE_DIR;OS;ARCH;BUILDTYPE;WORK;INSTALL_DIR" "DEPENDS_PREFIXES" ${ARGN})

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
    if(NOT DEFINED DEP_BUILD_SYSTEM)
        set(DEP_BUILD_SYSTEM "cmake")
    endif()

    # macOS arch/deployment flags (single-arch; used by autotools/openssl)
    if(NOT DEFINED DEP_MACOS_DEPLOYMENT_TARGET)
        set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
    endif()
    set(mac_cflags "")
    if(BD_OS STREQUAL "macos")
        if(BD_ARCH STREQUAL "x86_64")
            set(mac_cflags "-arch x86_64 -mmacosx-version-min=${DEP_MACOS_DEPLOYMENT_TARGET}")
        else()
            set(mac_cflags "-arch arm64 -mmacosx-version-min=${DEP_MACOS_DEPLOYMENT_TARGET}")
        endif()
    endif()

    # Dependency env for non-CMake builds (deps carry pkgconfig + headers/libs).
    set(dep_cppflags "")
    set(dep_ldflags "")
    set(dep_pkgpaths "")
    foreach(p ${BD_DEPENDS_PREFIXES})
        string(APPEND dep_cppflags " -I${p}/include")
        string(APPEND dep_ldflags " -L${p}/lib")
        list(APPEND dep_pkgpaths "${p}/lib/pkgconfig")
    endforeach()
    string(REPLACE ";" ":" dep_pkgpath "${dep_pkgpaths}")

    if(EXISTS "${BD_RECIPE_DIR}/build.cmake")
        include("${BD_RECIPE_DIR}/build.cmake")   # uses SRC, BUILD, INSTALL; must install into INSTALL

    elseif(DEP_BUILD_SYSTEM STREQUAL "cmake")
        set(cfg -S "${SRC}" -B "${BUILD}" -G Ninja
                -DCMAKE_BUILD_TYPE=RelWithDebInfo
                -DCMAKE_INSTALL_PREFIX=${INSTALL}
                -DCMAKE_POLICY_VERSION_MINIMUM=3.5   # allow pre-3.5 projects under CMake 4
                ${DEP_CMAKE_ARGS})
        if(BD_DEPENDS_PREFIXES)
            string(REPLACE ";" "\\;" _pp "${BD_DEPENDS_PREFIXES}")
            list(APPEND cfg "-DCMAKE_PREFIX_PATH=${_pp}")
        endif()
        if(BD_OS STREQUAL "macos")
            if(BD_ARCH STREQUAL "universal")
                set(osx "x86_64;arm64")
            elseif(BD_ARCH STREQUAL "aarch64")
                set(osx "arm64")
            else()
                set(osx "x86_64")
            endif()
            list(APPEND cfg "-DCMAKE_OSX_ARCHITECTURES=${osx}"
                            "-DCMAKE_OSX_DEPLOYMENT_TARGET=${DEP_MACOS_DEPLOYMENT_TARGET}")
        endif()
        _bd_run(${CMAKE_COMMAND} ${cfg})
        _bd_run(${CMAKE_COMMAND} --build "${BUILD}" --config RelWithDebInfo --target install --parallel)

    elseif(DEP_BUILD_SYSTEM STREQUAL "autotools")
        file(MAKE_DIRECTORY "${BUILD}")
        if(DEP_AUTORECONF)
            _bd_run_dir("${SRC}" autoreconf -fi)
        endif()
        cmake_host_system_information(RESULT ncpu QUERY NUMBER_OF_LOGICAL_CORES)
        _bd_run_dir("${BUILD}" ${CMAKE_COMMAND} -E env
            "CFLAGS=${mac_cflags}${dep_cppflags}" "CXXFLAGS=${mac_cflags}${dep_cppflags}"
            "LDFLAGS=${dep_ldflags}" "PKG_CONFIG_PATH=${dep_pkgpath}"
            "${SRC}/configure" --prefix=${INSTALL} --enable-shared --disable-static ${DEP_CONFIGURE_ARGS})
        _bd_run_dir("${BUILD}" make -j${ncpu})
        if(NOT DEFINED DEP_MAKE_INSTALL_TARGET)
            set(DEP_MAKE_INSTALL_TARGET "install")
        endif()
        _bd_run_dir("${BUILD}" make ${DEP_MAKE_INSTALL_TARGET})

    elseif(DEP_BUILD_SYSTEM STREQUAL "openssl")
        # openssl builds in-tree via its perl Configure
        if(BD_OS STREQUAL "macos")
            if(BD_ARCH STREQUAL "x86_64")
                set(ossl_target "darwin64-x86_64-cc")
            else()
                set(ossl_target "darwin64-arm64-cc")
            endif()
        elseif(BD_OS STREQUAL "linux")
            if(BD_ARCH STREQUAL "x86_64")
                set(ossl_target "linux-x86_64")
            else()
                set(ossl_target "linux-aarch64")
            endif()
        else()
            message(FATAL_ERROR "[${BD_NAME}] openssl build unsupported os: ${BD_OS}")
        endif()
        cmake_host_system_information(RESULT ncpu QUERY NUMBER_OF_LOGICAL_CORES)
        _bd_run_dir("${SRC}" ${CMAKE_COMMAND} -E env "CFLAGS=${mac_cflags}"
            perl Configure ${ossl_target} shared no-tests
            --prefix=${INSTALL} --libdir=lib ${DEP_CONFIGURE_ARGS})
        _bd_run_dir("${SRC}" make -j${ncpu})
        _bd_run_dir("${SRC}" make install_sw)

    else()
        message(FATAL_ERROR "[${BD_NAME}] unknown DEP_BUILD_SYSTEM: ${DEP_BUILD_SYSTEM}")
    endif()

    if(DEFINED DEP_LICENSE_FILES)
        file(MAKE_DIRECTORY "${INSTALL}/licenses")
        foreach(lf ${DEP_LICENSE_FILES})
            file(COPY "${SRC}/${lf}" DESTINATION "${INSTALL}/licenses")
        endforeach()
    endif()
endfunction()
