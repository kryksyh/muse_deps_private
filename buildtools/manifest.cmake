# Consumer API: include this (after setting MUSE_DEPS_DIR if not the including
# app's submodule layout), then run manifest files of require_dep /
# require_source_dep calls. Resolution + imported targets only; installing the
# bundled runtime libs/licenses is the app's packaging policy — each dep's set
# accumulates in the MUSE_DEPS_CONSUMED global property (list of names; per-dep
# globals <name>_INSTALL_LIBRARIES and <name>_PREFIX carry the rest).

cmake_minimum_required(VERSION 3.19)

get_filename_component(MUSE_DEPS_DIR "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)

if (NOT DEFINED LOCAL_ROOT_PATH OR LOCAL_ROOT_PATH STREQUAL "")
    set(LOCAL_ROOT_PATH "${CMAKE_BINARY_DIR}/_deps")
endif()

# Platform id used in prebuilt.lock (os: windows|linux|macos; arch: x86_64|aarch64|universal).
# Script mode (cmake -P, e.g. the codestyle/crashdumps tools) has no toolchain
# vars — CMAKE_SYSTEM_NAME/PROCESSOR are empty, which used to misdetect every
# host as linux-x86_64; ask the host directly there.
set(_muse_sys "${CMAKE_SYSTEM_NAME}")
set(_muse_proc "${CMAKE_SYSTEM_PROCESSOR}")
if (_muse_sys STREQUAL "")
    cmake_host_system_information(RESULT _muse_sys QUERY OS_NAME)
    cmake_host_system_information(RESULT _muse_proc QUERY OS_PLATFORM)
endif()
if (NOT DEFINED LIB_OS OR LIB_OS STREQUAL "")
    if (_muse_sys STREQUAL "Windows")
        set(LIB_OS "windows")
    elseif (_muse_sys MATCHES "Darwin|macOS")
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
        elseif (_muse_proc MATCHES "arm64|aarch64")
            set(LIB_ARCH "aarch64")
        else()
            set(LIB_ARCH "x86_64")
        endif()
    elseif (_muse_proc MATCHES "[Aa][Rr][Mm]64|aarch64")
        set(LIB_ARCH "aarch64")
    else()
        set(LIB_ARCH "x86_64")
    endif()
endif()

# Allow forcing modes from the environment (CI/offline can't always thread cache
# vars through the build driver). An explicit -D always wins.
if (NOT DEFINED MUSE_BUILD_ALL AND DEFINED ENV{MUSE_BUILD_ALL})
    set(MUSE_BUILD_ALL "$ENV{MUSE_BUILD_ALL}")
endif()
if (NOT DEFINED MUSE_USE_SYSTEM_ALL AND DEFINED ENV{MUSE_USE_SYSTEM_ALL})
    set(MUSE_USE_SYSTEM_ALL "$ENV{MUSE_USE_SYSTEM_ALL}")
endif()

# Pristine source cache for source/REBUILD builds: -DMUSE_DEPS_CACHE wins, else a
# pre-set $MUSE_DEPS_CACHE, else build_dep_lib's ~/.cache default.
if (MUSE_DEPS_CACHE)
    set(ENV{MUSE_DEPS_CACHE} "${MUSE_DEPS_CACHE}")
endif()

# Include the dep's metadata (DEP_VERSION + consume keys), its recipe spec for
# non-system modes, and the engine; run muse_consume.
function(_muse_run name explicit_version mode out_version)
    set(local_path ${LOCAL_ROOT_PATH}/${name})
    include("${MUSE_DEPS_DIR}/${name}/${name}.cmake")
    if (NOT "${explicit_version}" STREQUAL "")
        set(version "${explicit_version}")
    else()
        set(version "${DEP_VERSION}")
    endif()
    if (NOT mode STREQUAL "system")
        if ("${version}" STREQUAL "")
            message(FATAL_ERROR "[deps] '${name}': no version — metadata DEP_VERSION missing and none given in the manifest")
        endif()
        include("${MUSE_DEPS_DIR}/${name}/${version}/recipe/spec.cmake")
    endif()
    include("${MUSE_DEPS_DIR}/buildtools/consume.cmake")
    muse_consume("${name}" "${version}" "${mode}" "${local_path}" "${LIB_OS}" "${LIB_ARCH}")
    set_property(GLOBAL PROPERTY ${name}_PREFIX "${local_path}")
    set_property(GLOBAL APPEND PROPERTY MUSE_DEPS_CONSUMED "${name}")
    set(${out_version} "${version}" PARENT_SCOPE)
endfunction()

# Resolve include dirs / link libs / install libs for a dep and set its imported
# target. Mode is decided here; the engine does the work, driven by metadata.
function(require_dep name)
    # Manifest forms: require_dep(<n>) | require_dep(<n> REBUILD) | require_dep(<n> SYSTEM)
    # Version is owned by the deps repo (metadata DEP_VERSION). An explicit version
    # is an escape hatch to override one dep: require_dep(<n> <ver> [REBUILD]).
    set(explicit_version "")
    set(mode "prebuilt")
    if ("${ARGV1}" STREQUAL "SYSTEM")
        set(mode "system")
    elseif ("${ARGV1}" STREQUAL "REBUILD")
        set(mode "rebuild")
    elseif (NOT "${ARGV1}" STREQUAL "")
        set(explicit_version "${ARGV1}")
        if ("${ARGV2}" STREQUAL "REBUILD")
            set(mode "rebuild")
        endif()
    endif()

    # A manifest-declared SYSTEM is sticky: the global MUSE_BUILD_ALL/MUSE_USE_SYSTEM
    # knobs must not flip it. Some SYSTEM deps (libcurl, openssl) have no recipe, so
    # forcing them to rebuild would fatally fail to find a spec.
    string(TOUPPER ${name} name_upper)
    if (NOT "${ARGV1}" STREQUAL "SYSTEM")
        if (MUSE_USE_SYSTEM_ALL OR MUSE_USE_SYSTEM_${name_upper})
            set(mode "system")
        elseif (MUSE_BUILD_ALL OR MUSE_BUILD_${name_upper})
            set(mode "rebuild")
        endif()
    endif()

    _muse_run("${name}" "${explicit_version}" "${mode}" version)

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
# Must precede the deps that need it in the manifest. Honors
# MUSE_USE_SYSTEM_<NAME> / MUSE_BUILD_<NAME> like require_dep.
function(require_tool name)
    string(TOUPPER ${name} name_upper)
    set(mode "prebuilt")
    if (MUSE_USE_SYSTEM_ALL OR MUSE_USE_SYSTEM_${name_upper})
        set(mode "system")
    elseif (MUSE_BUILD_ALL OR MUSE_BUILD_${name_upper})
        set(mode "rebuild")
    endif()
    _muse_run("${name}" "" "${mode}" version)

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

# Source-delivery deps: muse_deps ships a pinned source tree the consumer
# compiles in-tree. Populated eagerly — gate conditional deps in the manifest.
# Exposes the ${name}_SOURCE_DIR global; metadata may provide a materialize fn.
function(require_source_dep name)
    _muse_run("${name}" "" "rebuild" version)
endfunction()
