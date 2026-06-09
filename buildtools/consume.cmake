# Generic consume engine — one file replacing the 16 per-dep <name>/<name>.cmake.
#
# The consumer (Audacity's require_dep/require_source_dep/require_tool) fetches
# this engine + the dep's recipe (recipe/spec.cmake [+ patches, build.<os>.cmake,
# consume.cmake]) and calls muse_consume(). Everything is driven by metadata in
# spec.cmake; lib names are DERIVED from the installed prefix, never hand-listed.
#
# spec.cmake consume metadata (beyond the build fields source URL/SHA, build
# system, deps, patches):
#   DEP_KIND              library | source | tool        (default: library)
#   DEP_TARGET            imported target name (e.g. Opus::opus)
#   DEP_LIBS              base lib name(s), unix (e.g. "opus", "vorbis vorbisenc vorbisfile")
#   DEP_TARGETS           multi-target deps only: a list of "target|libs" entries
#                         (libs space-separated), one imported target each from the
#                         same prefix — e.g. "FLAC::FLAC|FLAC" "FLAC::FLAC++|FLAC++".
#                         Replaces DEP_TARGET/DEP_LIBS (and DEP_SYSTEM_LIBS) when set.
#   DEP_LIBS_WINDOWS      base lib name(s), Windows (e.g. "wavpackdll", "portaudio_x64") — defaults to DEP_LIBS
#   DEP_STATIC_WINDOWS    ON if the Windows build is a static .lib (nothing to bundle)
#   DEP_INCLUDE_SUBDIRS   extra include subdirs under <prefix>/include (e.g. "opus")
#   DEP_SYSTEM_HEADER     find_path arg for SYSTEM mode (e.g. opus/opus.h)
#   DEP_SYSTEM_LIBS       find_library name(s) for SYSTEM mode
# A dep may instead define a function <name>_consume_override(mode local_path os
# arch version) in its <name>/<name>.cmake to fully override resolution
# (used by deps with a non-standard layout / multiple targets / system-only:
# wxwidgets, flac, openssl, libcurl).

cmake_minimum_required(VERSION 3.16)

# Derive the link set (what to link) and bundle set (runtime libs to install)
# for <libnames> in <prefix>, by OS convention. Globs handle versioned sonames.
function(_muse_resolve_libs prefix os libnames out_link out_bundle)
    set(link "")
    set(bundle "")
    # The version/soname suffix always begins with a dot, so anchor globs with the
    # literal "." after the base name (else lib<vorbis>* greedily matches
    # lib<vorbisenc>). Link is the exact dev symlink/import lib.
    foreach(n ${libnames})
        if(os STREQUAL "windows")
            list(APPEND link "${prefix}/lib/${n}.lib")        # import lib
            file(GLOB dll "${prefix}/bin/${n}.dll" "${prefix}/bin/${n}[0-9]*.dll")  # opus.dll / zlib1.dll
            list(APPEND bundle ${dll})
        elseif(os STREQUAL "macos")
            file(GLOB vers "${prefix}/lib/lib${n}.dylib" "${prefix}/lib/lib${n}.*dylib")
            list(APPEND link "${prefix}/lib/lib${n}.dylib")   # dev symlink
            list(APPEND bundle ${vers})                       # real + symlinks
        else() # linux/bsd
            file(GLOB vers "${prefix}/lib/lib${n}.so" "${prefix}/lib/lib${n}.so.*")
            list(APPEND link "${prefix}/lib/lib${n}.so")      # dev symlink
            list(APPEND bundle ${vers})                       # real + soname + .so
        endif()
    endforeach()
    if(link)
        list(REMOVE_DUPLICATES link)
    endif()
    if(bundle)
        list(REMOVE_DUPLICATES bundle)
    endif()
    set(${out_link} "${link}" PARENT_SCOPE)
    set(${out_bundle} "${bundle}" PARENT_SCOPE)
endfunction()

# Create one INTERFACE imported target for a resolved (incdirs, link) pair.
function(_muse_make_target target incdirs link)
    if(target AND NOT TARGET ${target})
        add_library(${target} INTERFACE IMPORTED GLOBAL)
        target_include_directories(${target} INTERFACE ${incdirs})
        target_link_libraries(${target} INTERFACE ${link})
    endif()
endfunction()

# include dirs for an installed prefix (include + optional DEP_INCLUDE_SUBDIRS).
function(_muse_incdirs prefix out)
    set(inc "${prefix}/include")
    foreach(s ${DEP_INCLUDE_SUBDIRS})
        list(APPEND inc "${prefix}/include/${s}")
    endforeach()
    set(${out} "${inc}" PARENT_SCOPE)
endfunction()

# Windows base lib names (fall back to the unix names).
macro(_muse_libnames os out)
    if(${os} STREQUAL "windows" AND DEFINED DEP_LIBS_WINDOWS)
        set(${out} "${DEP_LIBS_WINDOWS}")
    else()
        set(${out} "${DEP_LIBS}")
    endif()
endmacro()

# Resolve <libnames> from an installed prefix into link + bundle sets, by OS
# convention. DEP_STATIC = fully static (link lib<n>.a / <n>.lib, bundle nothing);
# DEP_STATIC_WINDOWS = static on Windows only (shared elsewhere).
function(_muse_resolve_prefix_libs prefix os libnames out_link out_bundle)
    if(DEP_STATIC)
        set(link "")
        set(bundle "")
        foreach(n ${libnames})
            if(os STREQUAL "windows")
                list(APPEND link "${prefix}/lib/${n}.lib")
            else()
                list(APPEND link "${prefix}/lib/lib${n}.a")
            endif()
        endforeach()
    else()
        _muse_resolve_libs("${prefix}" "${os}" "${libnames}" link bundle)
        if(os STREQUAL "windows" AND DEP_STATIC_WINDOWS)
            set(bundle "")             # static on Windows: linked in, nothing to deploy
        endif()
    endif()
    set(${out_link} "${link}" PARENT_SCOPE)
    set(${out_bundle} "${bundle}" PARENT_SCOPE)
endfunction()

# Normalize a dep's imported targets to a list of "target|libs" entries: explicit
# DEP_TARGETS (one per line, libs space-separated), else a single entry from
# DEP_TARGET + the given lib list (per-OS DEP_LIBS for builds, DEP_SYSTEM_LIBS for
# system). Lets one dep expose several targets from one prefix (e.g. flac's
# FLAC::FLAC + FLAC::FLAC++) without a custom override.
macro(_muse_target_entries fallback_libs out)
    if(DEFINED DEP_TARGETS)
        set(${out} "${DEP_TARGETS}")
    else()
        string(REPLACE ";" " " _fl "${fallback_libs}")
        set(${out} "${DEP_TARGET}|${_fl}")
    endif()
endmacro()

# Split one "target|lib1 lib2" entry into its target name + lib list.
macro(_muse_parse_entry entry out_target out_libs)
    string(REPLACE "|" ";" _pe "${entry}")
    list(GET _pe 0 ${out_target})
    list(GET _pe 1 _pe_libs)
    string(REPLACE " " ";" ${out_libs} "${_pe_libs}")
endmacro()

function(_muse_resolve_installed name prefix os)
    _muse_incdirs("${prefix}" inc)
    _muse_libnames("${os}" libnames)
    _muse_target_entries("${libnames}" entries)
    set(_primary_link "")
    set(_allbundle "")
    set(_first TRUE)
    foreach(_e ${entries})
        _muse_parse_entry("${_e}" _tgt _libs)
        _muse_resolve_prefix_libs("${prefix}" "${os}" "${_libs}" _link _bundle)
        if(_first AND DEP_LINK_DEPS)
            list(APPEND _link ${DEP_LINK_DEPS})   # extra interface deps on the primary target
        endif()
        _muse_make_target("${_tgt}" "${inc}" "${_link}")
        list(APPEND _allbundle ${_bundle})
        if(_first)
            set(_primary_link "${_link}")
            set(_first FALSE)
        endif()
    endforeach()
    set_property(GLOBAL PROPERTY ${name}_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY ${name}_LIBRARIES ${_primary_link})
    set_property(GLOBAL PROPERTY ${name}_INSTALL_LIBRARIES ${_allbundle})
endfunction()

# Find system libraries by base name -> absolute paths (fatal if any is missing).
function(_muse_find_system_libs name libnames out)
    set(libs "")
    foreach(l ${libnames})
        find_library(${name}_LIB_${l} NAMES ${l})
        if(NOT ${name}_LIB_${l})
            message(FATAL_ERROR "[${name}] system lib '${l}' not found (USE_SYSTEM)")
        endif()
        list(APPEND libs "${${name}_LIB_${l}}")
    endforeach()
    set(${out} "${libs}" PARENT_SCOPE)
endfunction()

# SYSTEM mode: find headers + libs on the system.
function(_muse_resolve_system name)
    find_path(${name}_INC NAMES ${DEP_SYSTEM_HEADER})
    if(NOT ${name}_INC)
        message(FATAL_ERROR "[${name}] system header '${DEP_SYSTEM_HEADER}' not found (USE_SYSTEM)")
    endif()
    set(inc "${${name}_INC}")
    foreach(s ${DEP_INCLUDE_SUBDIRS})
        list(APPEND inc "${${name}_INC}/${s}")
    endforeach()
    _muse_target_entries("${DEP_SYSTEM_LIBS}" entries)
    set(_primary_libs "")
    set(_first TRUE)
    foreach(_e ${entries})
        _muse_parse_entry("${_e}" _tgt _libs)
        _muse_find_system_libs("${name}" "${_libs}" _found)
        _muse_make_target("${_tgt}" "${inc}" "${_found}")
        if(_first)
            set(_primary_libs "${_found}")
            set(_first FALSE)
        endif()
    endforeach()
    set_property(GLOBAL PROPERTY ${name}_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY ${name}_LIBRARIES ${_primary_libs})
    set_property(GLOBAL PROPERTY ${name}_INSTALL_LIBRARIES "")
endfunction()

# Build from source into local_path, using the already-fetched recipe + builder.
function(_muse_build name local_path os arch)
    set(prefixes "")
    foreach(dv ${DEP_DEPENDS})
        string(REPLACE "/" ";" _p "${dv}")
        list(GET _p 0 _dn)
        list(APPEND prefixes "${local_path}/../${_dn}")   # sibling _deps prefix (built earlier)
    endforeach()
    include("${local_path}/build_dep_lib.cmake")
    build_dep(NAME ${name} RECIPE_DIR "${local_path}/recipe" OS ${os} ARCH ${arch}
              WORK "${local_path}/work" INSTALL_DIR "${local_path}"
              DEPENDS_PREFIXES "${prefixes}")
endfunction()

# Prebuilt deps ship as ONE per-platform archive in a single release, laid out as
# <name>/include, <name>/lib, ... It is downloaded + extracted into the shared
# _deps root ONCE (the first dep that needs it), populating every dep's prefix; a
# marker guards against re-download. Each dep then just checks its own subtree.
# Sets <out> TRUE if this dep's prefix is present, else FALSE so the caller falls
# back to a source build. The release (incl. tag) is overridable via
# $MUSE_DEPS_PREBUILT_URL for mirrors / local testing.
function(_muse_fetch_prebuilt name local_path os arch version out)
    set(${out} FALSE PARENT_SCOPE)
    if(NOT os OR NOT arch)
        return()
    endif()
    get_filename_component(root "${local_path}" DIRECTORY)   # the shared _deps root
    set(marker "${root}/.prebuilt-${os}-${arch}")
    if(NOT EXISTS "${marker}")
        file(WRITE "${marker}" "")   # attempt-once: a missing release must not re-download per dep
        set(_pburl "$ENV{MUSE_DEPS_PREBUILT_URL}")
        if(NOT _pburl)
            set(_pburl "https://github.com/kryksyh/muse_deps_private/releases/download/deps-v1")
        endif()
        set(archive "${root}/prebuilt-${os}-${arch}.7z")
        file(DOWNLOAD "${_pburl}/prebuilt-${os}-${arch}.7z" "${archive}")
        if(EXISTS "${archive}")
            file(READ "${archive}" magic LIMIT 6 HEX)
            if(magic STREQUAL "377abcaf271c")   # 7z signature
                file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${root}")
            else()
                file(REMOVE "${archive}")
            endif()
        endif()
    endif()
    if(EXISTS "${local_path}/include")
        set(${out} TRUE PARENT_SCOPE)
    endif()
endfunction()

# Source-delivery (amalgamated, e.g. lv2 stack): fetch each entry of DEP_SOURCES
# ("subdir|tarball|url|sha256" or "subdir|git|repo|commit") cache-first into the
# cache, extract into local_path/<subdir>; expose <name>_SOURCE_DIR. The consumer
# compiles these in-tree.
function(_muse_populate_source name local_path version)
    include("${local_path}/build_dep_lib.cmake")   # for _bd_fetch / _bd_mirror / cache
    _bd_resolve_cache(cache)
    set(dl "${cache}/downloads/${name}")
    file(MAKE_DIRECTORY "${dl}")
    if(NOT EXISTS "${local_path}/.populated")
        find_program(GIT NAMES git REQUIRED)
        foreach(e ${DEP_SOURCES})
            string(REPLACE "|" ";" f "${e}")
            list(GET f 0 sub)
            list(GET f 1 kind)
            list(GET f 2 loc)
            list(GET f 3 ver)
            if(kind STREQUAL "tarball")
                get_filename_component(an "${loc}" NAME)
                if(NOT EXISTS "${dl}/${an}")
                    _bd_mirror(mir)
                    _bd_fetch("${dl}/${an}" "${ver}" "${loc}" "${mir}/${name}-${an}")
                endif()
                if(NOT EXISTS "${local_path}/${sub}")
                    set(ex "${local_path}/.ex_${sub}")
                    file(MAKE_DIRECTORY "${ex}")
                    file(ARCHIVE_EXTRACT INPUT "${dl}/${an}" DESTINATION "${ex}")
                    file(GLOB top LIST_DIRECTORIES true "${ex}/*")
                    list(GET top 0 root)
                    file(RENAME "${root}" "${local_path}/${sub}")
                    file(REMOVE_RECURSE "${ex}")
                endif()
            else() # git commit, verified
                set(gitdir "${dl}/${sub}.git")
                if(NOT EXISTS "${gitdir}/.git")
                    _bd_run(${GIT} clone --quiet "${loc}" "${gitdir}")
                endif()
                _bd_run_dir("${gitdir}" ${GIT} checkout --quiet "${ver}")
                execute_process(COMMAND ${GIT} -C "${gitdir}" rev-parse HEAD
                                OUTPUT_VARIABLE head OUTPUT_STRIP_TRAILING_WHITESPACE)
                if(NOT head STREQUAL "${ver}")
                    message(FATAL_ERROR "[${name}] ${sub}: HEAD ${head} != pinned ${ver}")
                endif()
                if(NOT EXISTS "${local_path}/${sub}")
                    file(COPY "${gitdir}/" DESTINATION "${local_path}/${sub}" PATTERN ".git" EXCLUDE)
                endif()
            endif()
        endforeach()
        file(WRITE "${local_path}/.populated" "${version}\n")
    endif()
    set_property(GLOBAL PROPERTY ${name}_SOURCE_DIR "${local_path}")
endfunction()

# Single entry point. The consumer pre-fetches consume.cmake + recipe (spec.cmake,
# patches, build.<os>.cmake, optional consume.cmake) into local_path, includes
# spec.cmake (for DEP_*) + this engine, then calls muse_consume(...).
function(muse_consume name version mode local_path os arch)
    # Per-dep override for non-standard layouts / multiple targets (wx, flac, openssl):
    # the dep's version-agnostic metadata file may define <name>_consume_override().
    if(COMMAND ${name}_consume_override)
        cmake_language(CALL ${name}_consume_override "${mode}" "${local_path}" "${os}" "${arch}" "${version}")
        return()
    endif()

    if(NOT DEFINED DEP_KIND OR DEP_KIND STREQUAL "library")
        if(mode STREQUAL "system")
            _muse_resolve_system("${name}")
        else()
            # rebuild: always from source. prebuilt: extract the archive, falling
            # back to source if this platform has none. Either way local_path ends
            # up populated, then we resolve it identically.
            if(mode STREQUAL "rebuild")
                _muse_build("${name}" "${local_path}" "${os}" "${arch}")
            else()
                _muse_fetch_prebuilt("${name}" "${local_path}" "${os}" "${arch}" "${version}" _ok)
                if(NOT _ok)
                    message(STATUS "[${name}] no prebuilt for ${os}/${arch}, building from source")
                    _muse_build("${name}" "${local_path}" "${os}" "${arch}")
                endif()
            endif()
            _muse_resolve_installed("${name}" "${local_path}" "${os}")
        endif()

    elseif(DEP_KIND STREQUAL "source")
        _muse_populate_source("${name}" "${local_path}" "${version}")

    elseif(DEP_KIND STREQUAL "tool")
        if(mode STREQUAL "system")
            find_program(${name}_EXE NAMES ${name})
            if(NOT ${name}_EXE)
                message(FATAL_ERROR "[${name}] system tool not found (USE_SYSTEM)")
            endif()
            get_filename_component(_d "${${name}_EXE}" DIRECTORY)
            set_property(GLOBAL PROPERTY ${name}_BIN_DIR "${_d}")
        else()
            _muse_build("${name}" "${local_path}" "${os}" "${arch}")
            set_property(GLOBAL PROPERTY ${name}_BIN_DIR "${local_path}/bin")
        endif()

    else()
        message(FATAL_ERROR "[${name}] unknown DEP_KIND: ${DEP_KIND}")
    endif()
endfunction()
