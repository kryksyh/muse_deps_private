# Consumer API: include this (after setting EXTDEPS_DIR if not the including
# app's submodule layout), then run manifest files of require_dep /
# require_source_dep calls. Resolution + imported targets only; installing the
# bundled runtime libs/licenses is the app's packaging policy. Each consumed dep
# accumulates in the EXTDEPS_CONSUMED global property (list of names; per-dep
# globals <name>_INSTALL_LIBRARIES and <name>_PREFIX carry the rest).

cmake_minimum_required(VERSION 3.19)

get_filename_component(EXTDEPS_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)

if (NOT DEFINED LOCAL_ROOT_PATH OR LOCAL_ROOT_PATH STREQUAL "")
    set(LOCAL_ROOT_PATH "${CMAKE_BINARY_DIR}/_deps")
endif()

# Platform id used in prebuilt.lock (os: windows|linux|macos; arch: x86_64|aarch64|universal).
# Script mode (cmake -P, e.g. the codestyle/crashdumps tools) has no toolchain
# vars: CMAKE_SYSTEM_NAME/PROCESSOR are empty, which misdetects every host as
# linux-x86_64, so ask the host directly there.
set(_extdeps_sys "${CMAKE_SYSTEM_NAME}")
set(_extdeps_proc "${CMAKE_SYSTEM_PROCESSOR}")
if (_extdeps_sys STREQUAL "")
    cmake_host_system_information(RESULT _extdeps_sys QUERY OS_NAME)
    cmake_host_system_information(RESULT _extdeps_proc QUERY OS_PLATFORM)
endif()
if (NOT DEFINED LIB_OS OR LIB_OS STREQUAL "")
    if (_extdeps_sys STREQUAL "Windows")
        set(LIB_OS "windows")
    elseif (_extdeps_sys MATCHES "Darwin|macOS")
        set(LIB_OS "macos")
    else()
        set(LIB_OS "linux")
    endif()
endif()
if (NOT DEFINED LIB_ARCH OR LIB_ARCH STREQUAL "")
    if (LIB_OS STREQUAL "macos")
        list(LENGTH CMAKE_OSX_ARCHITECTURES _n)
        if (_n GREATER 1)
            set(LIB_ARCH "universal")
        elseif (CMAKE_OSX_ARCHITECTURES STREQUAL "arm64")
            set(LIB_ARCH "aarch64")
        elseif (CMAKE_OSX_ARCHITECTURES STREQUAL "x86_64")
            set(LIB_ARCH "x86_64")
        elseif (_extdeps_proc MATCHES "arm64|aarch64")
            set(LIB_ARCH "aarch64")
        else()
            set(LIB_ARCH "x86_64")
        endif()
    elseif (_extdeps_proc MATCHES "[Aa][Rr][Mm]64|aarch64")
        set(LIB_ARCH "aarch64")
    else()
        set(LIB_ARCH "x86_64")
    endif()
endif()

# Allow forcing the mode from the environment (CI/offline can't always thread cache
# vars through the build driver). An explicit -D always wins.
if (NOT DEFINED EXTDEPS_OVERRIDE_ALL AND DEFINED ENV{EXTDEPS_OVERRIDE_ALL})
    set(EXTDEPS_OVERRIDE_ALL "$ENV{EXTDEPS_OVERRIDE_ALL}")
endif()

# Pristine source cache for source/REBUILD builds: -DEXTDEPS_CACHE wins, else a
# pre-set $EXTDEPS_CACHE, else build_dep_lib's ~/.cache default.
if (EXTDEPS_CACHE)
    set(ENV{EXTDEPS_CACHE} "${EXTDEPS_CACHE}")
endif()

# Include the dep's metadata (DEP_VERSION + resolve keys), its recipe spec for
# non-system modes, and the engine, then run extdeps_resolve.
function(_extdeps_run name mode)
    set(local_path ${LOCAL_ROOT_PATH}/${name})
    include("${EXTDEPS_DIR}/${name}/${name}.cmake")
    set(version "${DEP_VERSION}")
    if (NOT mode STREQUAL "system")
        if ("${version}" STREQUAL "")
            message(FATAL_ERROR "[deps] '${name}': metadata DEP_VERSION is missing")
        endif()
        include("${EXTDEPS_DIR}/${name}/${version}/recipe/spec.cmake")
    endif()
    # A "local" source builds a working tree in place: point local_path at its
    # parent so both SOURCE_DIR consumers and post_resolve hooks (which take
    # local_path) resolve <local_path>/<subdir> to it. _extdeps_populate_source skips
    # the fetch.
    foreach(_s ${DEP_SOURCES})
        string(REPLACE "|" ";" _sf "${_s}")
        list(GET _sf 1 _sk)
        if(_sk STREQUAL "local")
            list(GET _sf 2 _sloc)
            get_filename_component(local_path "${_sloc}" DIRECTORY)
        endif()
    endforeach()
    include("${EXTDEPS_DIR}/buildtools/resolve.cmake")
    extdeps_resolve("${name}" "${version}" "${mode}" "${local_path}" "${LIB_OS}" "${LIB_ARCH}")
    set_property(GLOBAL PROPERTY ${name}_PREFIX "${local_path}")
    set_property(GLOBAL APPEND PROPERTY EXTDEPS_CONSUMED "${name}")
endfunction()

# Override the manifest-declared mode. EXTDEPS_OVERRIDE_<NAME> (per-dep, wins) or
# EXTDEPS_OVERRIDE_ALL (global) name a mode: REBUILD | SYSTEM | PREBUILT (the same
# words as the require_dep DSL). Returns the mapped mode in <out>, or "" when no
# override applies. A blanket OVERRIDE_ALL leaves a manifest-declared SYSTEM dep
# alone (libcurl/openssl have no recipe to rebuild); an explicit per-dep override
# always wins, and fails loudly downstream if it cannot be honored.
function(_extdeps_override name manifest_mode out)
    string(TOUPPER ${name} _u)
    set(_v "")
    if (DEFINED EXTDEPS_OVERRIDE_${_u})
        set(_v "${EXTDEPS_OVERRIDE_${_u}}")
    elseif (DEFINED EXTDEPS_OVERRIDE_ALL AND NOT manifest_mode STREQUAL "system")
        set(_v "${EXTDEPS_OVERRIDE_ALL}")
    endif()
    if ("${_v}" STREQUAL "")
        set(${out} "" PARENT_SCOPE)
        return()
    endif()
    string(TOUPPER "${_v}" _v)
    if (_v STREQUAL "REBUILD")
        set(${out} "rebuild" PARENT_SCOPE)
    elseif (_v STREQUAL "SYSTEM")
        set(${out} "system" PARENT_SCOPE)
    elseif (_v STREQUAL "PREBUILT")
        set(${out} "prebuilt" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "[deps] ${name}: EXTDEPS_OVERRIDE_* must be REBUILD, SYSTEM or PREBUILT (got '${_v}')")
    endif()
endfunction()

# Resolve include dirs / link libs / install libs for a dep and set its imported
# target. Mode is decided here; the engine does the work, driven by metadata.
function(require_dep name)
    # Manifest forms: require_dep(<n>) | require_dep(<n> REBUILD) | require_dep(<n> SYSTEM)
    # Version is owned by the deps repo (metadata DEP_VERSION).
    if (ARGC GREATER 2)
        message(FATAL_ERROR "[deps] ${name}: require_dep accepts at most one mode argument")
    endif()
    set(mode "prebuilt")
    if ("${ARGV1}" STREQUAL "SYSTEM")
        set(mode "system")
    elseif ("${ARGV1}" STREQUAL "REBUILD")
        set(mode "rebuild")
    elseif (NOT "${ARGV1}" STREQUAL "")
        message(FATAL_ERROR "[deps] ${name}: require_dep accepts only REBUILD or SYSTEM (got '${ARGV1}')")
    endif()

    _extdeps_override("${name}" "${mode}" _ov)
    if (NOT "${_ov}" STREQUAL "")
        set(mode "${_ov}")
    endif()

    _extdeps_run("${name}" "${mode}")

    get_property(include_dirs GLOBAL PROPERTY ${name}_INCLUDE_DIRS)
    get_property(libraries GLOBAL PROPERTY ${name}_LIBRARIES)
    get_property(instal_libraries GLOBAL PROPERTY ${name}_INSTALL_LIBRARIES)
    set(${name}_INCLUDE_DIRS ${include_dirs} PARENT_SCOPE)
    set(${name}_LIBRARIES ${libraries} PARENT_SCOPE)
    set(${name}_INSTALL_LIBRARIES ${instal_libraries} PARENT_SCOPE)
endfunction()

# Build-time tools (host executables a dep needs while building, e.g. yasm for
# mpg123's x86/x64 asm decoder). Fetch the locked prebuilt (or build/find it),
# then prepend its bin/ to PATH so later dep builds' find_program() locate it.
# Must precede the deps that need it in the manifest. Honors EXTDEPS_OVERRIDE_<NAME>
# / EXTDEPS_OVERRIDE_ALL, like require_dep.
function(require_tool name)
    set(mode "prebuilt")
    _extdeps_override("${name}" "${mode}" _ov)
    if (NOT "${_ov}" STREQUAL "")
        set(mode "${_ov}")
    endif()
    _extdeps_run("${name}" "${mode}")

    get_property(bindir GLOBAL PROPERTY ${name}_BIN_DIR)
    if (bindir)
        if (WIN32)
            set(ENV{PATH} "${bindir};$ENV{PATH}")
        else()
            set(ENV{PATH} "${bindir}:$ENV{PATH}")
        endif()
        message(STATUS "[tool] ${name} available on PATH (${bindir})")
    endif()
endfunction()

# Source-delivery deps: extdeps ships a pinned source tree the consumer compiles
# in-tree, exposed via the ${name}_SOURCE_DIR global, or a target the dep's
# post_resolve builds. require_source_dep(<n> SYSTEM) binds the system package
# instead (the dep's post_resolve must implement that path). Overrides apply as
# elsewhere, except a source dep reaches "system" only if it declares a system path
# (DEP_SOURCE_SYSTEM): a blanket EXTDEPS_OVERRIDE_ALL=SYSTEM binds the ones that can
# and leaves picojson/googletest/vst3sdk/... building, and a per-dep
# EXTDEPS_OVERRIDE_<NAME>=REBUILD keeps one vendored under a system base (e.g. the
# .mnx chain on a distro without nlohmann_json 3.12).
function(require_source_dep name)
    if (ARGC GREATER 2)
        message(FATAL_ERROR "[deps] ${name}: require_source_dep accepts at most one mode argument")
    endif()
    set(mode "rebuild")
    if ("${ARGV1}" STREQUAL "SYSTEM")
        set(mode "system")
    elseif (NOT "${ARGV1}" STREQUAL "")
        message(FATAL_ERROR "[deps] ${name}: require_source_dep accepts only SYSTEM (got '${ARGV1}')")
    endif()
    _extdeps_override("${name}" "${mode}" _ov)
    if (NOT "${_ov}" STREQUAL "")
        set(mode "${_ov}")
    endif()
    if (mode STREQUAL "system" AND NOT "${ARGV1}" STREQUAL "SYSTEM")
        include("${EXTDEPS_DIR}/${name}/${name}.cmake")   # reads DEP_SOURCE_SYSTEM
        if (NOT DEP_SOURCE_SYSTEM)
            set(mode "rebuild")
        endif()
    endif()
    _extdeps_run("${name}" "${mode}")
endfunction()

# Standard packaging policy: install every consumed dep's runtime libs + license
# dir into the app layout. macOS bundles into <bundle>/Contents/{Frameworks,
# Resources/licenses}; Windows/Linux use GNUInstallDirs BIN/LIB + top-level
# licenses/. The app calls this once after its manifests run; MACOS_BUNDLE names
# the .app (audacity.app / mscore.app). Reads the EXTDEPS_CONSUMED set and the
# per-dep <name>_INSTALL_LIBRARIES / <name>_PREFIX globals the engine populates.
function(extdeps_install_consumed)
    cmake_parse_arguments(ARG "" "MACOS_BUNDLE" "" ${ARGN})
    get_property(_deps GLOBAL PROPERTY EXTDEPS_CONSUMED)
    list(REMOVE_DUPLICATES _deps)
    foreach(_d ${_deps})
        get_property(_libs GLOBAL PROPERTY ${_d}_INSTALL_LIBRARIES)
        if (_libs)
            if (APPLE)
                install(FILES ${_libs} DESTINATION "${ARG_MACOS_BUNDLE}/Contents/Frameworks")
            elseif (WIN32)
                install(FILES ${_libs} TYPE BIN)
            else()
                install(FILES ${_libs} TYPE LIB)
            endif()
        endif()
        get_property(_prefix GLOBAL PROPERTY ${_d}_PREFIX)
        if (_prefix AND EXISTS "${_prefix}/licenses")
            if (APPLE)
                install(DIRECTORY "${_prefix}/licenses/" DESTINATION "${ARG_MACOS_BUNDLE}/Contents/Resources/licenses/${_d}")
            else()
                install(DIRECTORY "${_prefix}/licenses/" DESTINATION licenses/${_d})
            endif()
        endif()
    endforeach()
endfunction()
