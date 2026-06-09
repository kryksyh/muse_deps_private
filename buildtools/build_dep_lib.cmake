# Core build steps, shared by the platform producer (build_platform.cmake) and the
# consume engine's source path (_muse_build in consume.cmake). Include this file,
# then call build_dep(...).
#
# build_dep(NAME <n> RECIPE_DIR <d> OS <os> ARCH <a> WORK <w> INSTALL_DIR <i> [CACHE <c>])
#   sources -> patch -> cmake configure/build/install into INSTALL_DIR.
#   NB: deps are ALWAYS built RelWithDebInfo — a Debug dep would mismatch the app's
#   CRT on Windows (/MDd vs /MD).
#   Requires git + cmake on PATH. Reads <d>/spec.cmake; applies <d>/patch/*.patch.
#   Pristine source archives are fetched into a persistent, SHA-verified cache
#   (CACHE, or $MUSE_DEPS_CACHE, or ~/.cache/muse_deps) so rebuilds and offline
#   builds reuse them; only the extracted + patched tree and build dir are
#   per-config (under WORK, wiped each run).

# Cache root for pristine downloads: $MUSE_DEPS_CACHE, else XDG, else ~/.cache.
function(_bd_resolve_cache out)
    if(DEFINED ENV{MUSE_DEPS_CACHE})
        set(${out} "$ENV{MUSE_DEPS_CACHE}" PARENT_SCOPE)
    elseif(DEFINED ENV{XDG_CACHE_HOME})
        set(${out} "$ENV{XDG_CACHE_HOME}/muse_deps" PARENT_SCOPE)
    else()
        set(${out} "$ENV{HOME}/.cache/muse_deps" PARENT_SCOPE)
    endif()
endfunction()

# Our source mirror (release assets), tried when upstream fails: $MUSE_DEPS_MIRROR
# else the muse_deps `sources` release. Assets are named <name>/<archive>.
function(_bd_mirror out)
    if(DEFINED ENV{MUSE_DEPS_MIRROR})
        set(${out} "$ENV{MUSE_DEPS_MIRROR}" PARENT_SCOPE)
    else()
        set(${out} "https://github.com/kryksyh/muse_deps_private/releases/download/sources" PARENT_SCOPE)
    endif()
endfunction()

# Download <dest> from the first working URL (each retried), then verify SHA256.
# Upstream is primary; our mirror is the "just in case" fallback. Fatal if none
# yield the expected hash.
function(_bd_fetch dest sha256)
    foreach(url ${ARGN})
        foreach(attempt 1 2 3)
            file(DOWNLOAD "${url}" "${dest}" STATUS _st)
            list(GET _st 0 _c)
            if(_c EQUAL 0)
                file(SHA256 "${dest}" _got)
                if(_got STREQUAL "${sha256}")
                    return()
                endif()
                message(WARNING "[fetch] ${url}: sha256 ${_got} != ${sha256}")
            else()
                message(STATUS "[fetch] attempt ${attempt} failed: ${url} (${_st})")
            endif()
            file(REMOVE "${dest}")
        endforeach()
    endforeach()
    message(FATAL_ERROR "[fetch] all sources failed for ${dest}")
endfunction()

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

# Standard CMake configure + build + install of <srcdir> into INSTALL. Reads
# BUILD/INSTALL/BD_*/DEP_CMAKE_ARGS/BD_DEPENDS_PREFIXES from the calling scope
# (dynamic scope). Used by the default cmake build and by per-OS build.<os>.cmake
# recipes (e.g. Windows MSVC builds of deps whose autotools path can't run).
function(_bd_cmake_build srcdir)
    set(cfg -S "${srcdir}" -B "${BUILD}" -G Ninja
            -DCMAKE_BUILD_TYPE=RelWithDebInfo   # always; see build_dep() header (CRT match)
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
        # Pass the arch list via a -C initial-cache file: a universal "x86_64;arm64"
        # would otherwise be split by CMake list semantics as it passes through
        # _bd_run's ${ARGN} into execute_process, dropping arm64.
        file(MAKE_DIRECTORY "${BUILD}")
        file(WRITE "${BUILD}/osx_arch.cmake"
            "set(CMAKE_OSX_ARCHITECTURES \"${osx}\" CACHE STRING \"\" FORCE)\nset(CMAKE_OSX_DEPLOYMENT_TARGET \"${DEP_MACOS_DEPLOYMENT_TARGET}\" CACHE STRING \"\" FORCE)\n")
        list(APPEND cfg -C "${BUILD}/osx_arch.cmake")
    endif()
    _bd_run(${CMAKE_COMMAND} ${cfg})
    _bd_run(${CMAKE_COMMAND} --build "${BUILD}" --config RelWithDebInfo --target install --parallel)
endfunction()

# Linux: ensure each shared lib's SONAME symlink exists. Some builds set the
# soname (e.g. -Wl,-soname,libvorbis.so.0) but install only the full-version file,
# so dependents that record that soname as NEEDED fall back to a system copy
# (breaking self-containment) and the linker warns "may conflict". Idempotent, so
# it also runs on the rebuild-skip path. Prefers readelf; falls back to the
# lib<x>.so.<major> convention when readelf is unavailable.
function(_bd_ensure_sonames os name install_dir)
    if(NOT os STREQUAL "linux")
        return()
    endif()
    find_program(READELF NAMES readelf)
    file(GLOB _sos "${install_dir}/lib/*.so.*")   # versioned real files (dev .so symlink excluded)
    foreach(_so ${_sos})
        if(IS_SYMLINK "${_so}")
            continue()
        endif()
        get_filename_component(_dir "${_so}" DIRECTORY)
        get_filename_component(_base "${_so}" NAME)
        # Names a dependent may record as DT_NEEDED: the conventional major-version
        # (lib<x>.so.<major> — what most builds use) AND the lib's own DT_SONAME
        # (some builds set it to the full version, e.g. libvorbisenc.so.2.0.12, in
        # which case the major link is still the one dependents need).
        set(_wanted "")
        if(_base MATCHES "^(.+\\.so\\.[0-9]+)\\.")
            list(APPEND _wanted "${CMAKE_MATCH_1}")
        endif()
        if(READELF)
            execute_process(COMMAND ${READELF} -d "${_so}"
                            OUTPUT_VARIABLE _dyn ERROR_QUIET RESULT_VARIABLE _rc)
            if(_rc EQUAL 0 AND _dyn MATCHES "\\(SONAME\\)[^\n]*\\[([^]]+)\\]")
                list(APPEND _wanted "${CMAKE_MATCH_1}")
            endif()
        endif()
        if(_wanted)
            list(REMOVE_DUPLICATES _wanted)
        endif()
        foreach(_sn ${_wanted})
            if(NOT _sn STREQUAL _base AND NOT EXISTS "${_dir}/${_sn}")
                file(CREATE_LINK "${_base}" "${_dir}/${_sn}" SYMBOLIC)
                message(STATUS "[${name}] soname symlink ${_sn} -> ${_base}")
            endif()
        endforeach()
    endforeach()
endfunction()

# macOS: make installed dylibs relocatable by forcing LC_ID_DYLIB to @rpath/<base>.
# Most builds already do this, but some (mpg123's CMake port, lame's libtool) bake
# the absolute install prefix — which would bind a prebuilt to the build machine's
# path and break it for any consumer. Idempotent, so it also runs on rebuild-skip.
function(_bd_relocatable_macos os install_dir)
    if(NOT os STREQUAL "macos")
        return()
    endif()
    find_program(INSTALL_NAME_TOOL NAMES install_name_tool)
    find_program(OTOOL NAMES otool)
    if(NOT INSTALL_NAME_TOOL OR NOT OTOOL)
        return()
    endif()
    file(GLOB _dylibs "${install_dir}/lib/*.dylib")
    foreach(_d ${_dylibs})
        if(IS_SYMLINK "${_d}")
            continue()
        endif()
        execute_process(COMMAND ${OTOOL} -D "${_d}" OUTPUT_VARIABLE _id ERROR_QUIET)
        get_filename_component(_b "${_d}" NAME)
        if(NOT _id MATCHES "@rpath/")
            execute_process(COMMAND ${INSTALL_NAME_TOOL} -id "@rpath/${_b}" "${_d}" ERROR_QUIET)
            message(STATUS "[${BD_NAME}] install_name -> @rpath/${_b}")
        endif()
    endforeach()
endfunction()

function(build_dep)
    cmake_parse_arguments(BD "" "NAME;RECIPE_DIR;OS;ARCH;WORK;INSTALL_DIR;CACHE" "DEPENDS_PREFIXES" ${ARGN})

    # Clear any ambient DEP_* so the spec starts from a clean slate — a caller that
    # builds many deps in one process (build_platform) must not leak one recipe's
    # DEP_PATCHES/flags into the next dep whose spec doesn't set them.
    get_cmake_property(_allvars VARIABLES)
    foreach(_v ${_allvars})
        if(_v MATCHES "^DEP_")
            unset(${_v})
        endif()
    endforeach()
    include("${BD_RECIPE_DIR}/spec.cmake")

    # Two-level spec: merge per-OS overrides DEP_<key>_<OS> into the common keys
    # (lists append, scalars override). No per-arch level (handled by the driver
    # via the arch flag + archive naming).
    string(TOUPPER "${BD_OS}" _os)
    foreach(_k CMAKE_ARGS CONFIGURE_ARGS PATCHES DEPENDS)
        if(DEFINED DEP_${_k}_${_os})
            list(APPEND DEP_${_k} ${DEP_${_k}_${_os}})
        endif()
    endforeach()
    if(DEFINED DEP_BUILD_SYSTEM_${_os})
        set(DEP_BUILD_SYSTEM "${DEP_BUILD_SYSTEM_${_os}}")
    endif()
    if(DEFINED DEP_CMAKE_SOURCE_SUBDIR_${_os})
        set(DEP_CMAKE_SOURCE_SUBDIR "${DEP_CMAKE_SOURCE_SUBDIR_${_os}}")
    endif()

    # Skip the (expensive) rebuild when the recipe inputs are unchanged — makes
    # reconfigures fast. The signature hashes os/arch + every recipe file
    # (spec.cmake carries the source URL+SHA and build flags; patches and
    # build.<os>.cmake too), so any real recipe change still triggers a rebuild.
    set(_sig "${BD_OS}|${BD_ARCH}")
    file(GLOB_RECURSE _recipe_files "${BD_RECIPE_DIR}/*")
    list(SORT _recipe_files)
    foreach(_rf ${_recipe_files})
        file(SHA256 "${_rf}" _rh)
        string(APPEND _sig "|${_rh}")
    endforeach()
    string(SHA256 _build_sig "${_sig}")
    set(_build_stamp "${BD_INSTALL_DIR}/.build_stamp")
    if(EXISTS "${_build_stamp}")
        file(READ "${_build_stamp}" _prev_sig)
        if(_prev_sig STREQUAL "${_build_sig}")
            message(STATUS "[${BD_NAME}] up-to-date (recipe unchanged) — skipping build")
            _bd_ensure_sonames("${BD_OS}" "${BD_NAME}" "${BD_INSTALL_DIR}")
            _bd_relocatable_macos("${BD_OS}" "${BD_INSTALL_DIR}")
            return()
        endif()
    endif()

    find_program(GIT NAMES git REQUIRED)

    if(NOT BD_CACHE)
        _bd_resolve_cache(BD_CACHE)
    endif()

    set(SRC "${BD_WORK}/src")
    set(BUILD "${BD_WORK}/build")
    file(REMOVE_RECURSE "${BD_WORK}")
    file(MAKE_DIRECTORY "${BD_WORK}")

    # 1. sources — pristine tarball, cache-first: reuse a cached copy (re-verifying
    # its SHA so tampering/corruption is caught), else download into the cache
    # (file(DOWNLOAD) verifies on fetch), then extract.
    get_filename_component(an "${DEP_SOURCE_URL}" NAME)
    set(dl_dir "${BD_CACHE}/downloads/${BD_NAME}")
    set(archive "${dl_dir}/${an}")
    if(EXISTS "${archive}")
        file(SHA256 "${archive}" _got)
        if(NOT _got STREQUAL "${DEP_SOURCE_SHA256}")
            message(FATAL_ERROR "[${BD_NAME}] cached ${an} SHA256 mismatch: ${_got} != ${DEP_SOURCE_SHA256}")
        endif()
        message(STATUS "[${BD_NAME}] cached ${an}")
    else()
        file(MAKE_DIRECTORY "${dl_dir}")
        message(STATUS "[${BD_NAME}] fetch ${DEP_SOURCE_URL}")
        _bd_mirror(_mirror)
        _bd_fetch("${archive}" "${DEP_SOURCE_SHA256}"
                  "${DEP_SOURCE_URL}" "${_mirror}/${BD_NAME}-${an}")
    endif()
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

    # 2. patch — from the (merged) DEP_PATCHES list so OS-specific patches only
    # apply on their OS (entries are paths relative to the recipe dir).
    foreach(p ${DEP_PATCHES})
        message(STATUS "[${BD_NAME}] patch ${p}")
        _bd_run(${GIT} apply --whitespace=nowarn "${BD_RECIPE_DIR}/${p}" WORKING_DIRECTORY "${SRC}")
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
            set(_mac_arches "-arch x86_64")
        elseif(BD_ARCH STREQUAL "universal")
            set(_mac_arches "-arch x86_64 -arch arm64")   # clang builds universal in one pass
        else()
            set(_mac_arches "-arch arm64")
        endif()
        set(mac_cflags "${_mac_arches} -mmacosx-version-min=${DEP_MACOS_DEPLOYMENT_TARGET}")
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
        include("${BD_RECIPE_DIR}/build.cmake")   # custom CMake build (any platform); uses SRC/BUILD/INSTALL

    elseif(DEP_BUILD_SYSTEM STREQUAL "cmake")
        # Some projects keep their CMake build in a subdir (e.g. mpg123 ports/cmake).
        set(_csrc "${SRC}")
        if(DEP_CMAKE_SOURCE_SUBDIR)
            set(_csrc "${SRC}/${DEP_CMAKE_SOURCE_SUBDIR}")
        endif()
        _bd_cmake_build("${_csrc}")

    elseif(DEP_BUILD_SYSTEM STREQUAL "autotools")
        if(BD_OS STREQUAL "windows")
            message(FATAL_ERROR "[${BD_NAME}] autotools can't run on Windows — set DEP_BUILD_SYSTEM_WINDOWS cmake (with DEP_CMAKE_SOURCE_SUBDIR_WINDOWS for a CMake port, as mpg123 does) or add a recipe/build.cmake")
        endif()
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

    else()
        message(FATAL_ERROR "[${BD_NAME}] unknown DEP_BUILD_SYSTEM: ${DEP_BUILD_SYSTEM} (or provide recipe/build.cmake)")
    endif()

    if(DEFINED DEP_LICENSE_FILES)
        file(MAKE_DIRECTORY "${INSTALL}/licenses")
        foreach(lf ${DEP_LICENSE_FILES})
            file(COPY "${SRC}/${lf}" DESTINATION "${INSTALL}/licenses")
        endforeach()
    endif()

    _bd_ensure_sonames("${BD_OS}" "${BD_NAME}" "${INSTALL}")
    _bd_relocatable_macos("${BD_OS}" "${INSTALL}")

    # Record the recipe signature so an unchanged reconfigure skips the rebuild.
    file(WRITE "${_build_stamp}" "${_build_sig}")
endfunction()
