# Generic dependency resolver. The caller includes the dep's metadata + recipe spec
# and calls extdeps_resolve(name version mode local_path os arch). Resolution is
# driven by DEP_* metadata; lib names are derived from the installed prefix.
#
# Prebuilt binaries are looked up in prebuilt.lock (repo root): one line per
# "<name> <version> <os> <arch> <archive> <sha256> <release>". Each producer run
# publishes into its own release, so archives are immutable. $EXTDEPS_PREBUILT_URL
# overrides the releases/download base for mirrors. SHA-verified, extracted into
# local_path; any miss or failure falls back to building from source.
#
# Metadata keys (beyond the spec's source URL/SHA, deps, patches, cmake args):
#   DEP_KIND              library | source | tool         (default: library)
#   DEP_TARGET            imported target name (e.g. Opus::opus)
#   DEP_LIBS              base lib name(s), unix (e.g. "opus", "vorbis vorbisenc vorbisfile")
#   DEP_TARGETS           multi-target deps only: a list of "target|libs" entries
#                         (libs space-separated), one imported target each from the
#                         same prefix (e.g. "FLAC::FLAC|FLAC" "FLAC::FLAC++|FLAC++").
#                         Replaces DEP_TARGET/DEP_LIBS when set.
#   DEP_LIBS_WINDOWS      base lib name(s), Windows (e.g. "wavpackdll", "portaudio_x64"); defaults to DEP_LIBS
#   DEP_STATIC_WINDOWS    ON if the Windows build is a static .lib (nothing to bundle)
#   DEP_INCLUDE_SUBDIRS   extra include subdirs under <prefix>/include (e.g. "opus")
#   DEP_SYSTEM_HEADER     find_path arg for SYSTEM mode (e.g. opus/opus.h)
# A dep may instead define <name>_resolve_override(mode local_path os arch version)
# in its <name>/<name>.cmake to fully override resolution (deps with a non-standard
# layout or system-only: wxwidgets, openssl, libcurl).

cmake_minimum_required(VERSION 3.16)

get_filename_component(_EXTDEPS_ROOT "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY)
include("${CMAKE_CURRENT_LIST_DIR}/build_dep_lib.cmake")

# Derive the link set (what to link) and bundle set (runtime libs to install)
# for <libnames> in <prefix>, by OS convention. Globs handle versioned sonames.
function(_extdeps_resolve_libs prefix os libnames out_link out_bundle)
    set(link "")
    set(bundle "")
    # The version/soname suffix always begins with a dot, so anchor globs with the
    # literal "." after the base name (else lib<vorbis>* greedily matches
    # lib<vorbisenc>). Link is the exact dev symlink / import lib.
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
function(_extdeps_make_target target incdirs link)
    if(target AND NOT TARGET ${target})
        add_library(${target} INTERFACE IMPORTED GLOBAL)
        target_include_directories(${target} INTERFACE ${incdirs})
        target_link_libraries(${target} INTERFACE ${link})
    endif()
endfunction()

# include dirs for an installed prefix (include + optional DEP_INCLUDE_SUBDIRS).
function(_extdeps_incdirs prefix out)
    set(inc "${prefix}/include")
    foreach(s ${DEP_INCLUDE_SUBDIRS})
        list(APPEND inc "${prefix}/include/${s}")
    endforeach()
    set(${out} "${inc}" PARENT_SCOPE)
endfunction()

# Windows base lib names (fall back to the unix names).
macro(_extdeps_libnames os out)
    if(${os} STREQUAL "windows" AND DEFINED DEP_LIBS_WINDOWS)
        set(${out} "${DEP_LIBS_WINDOWS}")
    else()
        set(${out} "${DEP_LIBS}")
    endif()
endmacro()

# Resolve <libnames> from an installed prefix into link + bundle sets, by OS
# convention. DEP_STATIC = fully static (link lib<n>.a / <n>.lib, bundle nothing);
# DEP_STATIC_WINDOWS = static on Windows only (shared elsewhere).
function(_extdeps_resolve_prefix_libs prefix os libnames out_link out_bundle)
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
        _extdeps_resolve_libs("${prefix}" "${os}" "${libnames}" link bundle)
        if(os STREQUAL "windows" AND DEP_STATIC_WINDOWS)
            set(bundle "")             # static on Windows: linked in, nothing to deploy
        endif()
    endif()
    set(${out_link} "${link}" PARENT_SCOPE)
    set(${out_bundle} "${bundle}" PARENT_SCOPE)
endfunction()

# Normalize a dep's imported targets to a list of "target|libs" entries: explicit
# DEP_TARGETS (one per line, libs space-separated), else a single entry from
# DEP_TARGET + the given lib list. Lets one dep expose several targets from one
# prefix (flac's FLAC::FLAC + FLAC::FLAC++) without a custom override.
macro(_extdeps_target_entries fallback_libs out)
    if(DEFINED DEP_TARGETS)
        set(${out} "${DEP_TARGETS}")
    else()
        string(REPLACE ";" " " _fl "${fallback_libs}")
        set(${out} "${DEP_TARGET}|${_fl}")
    endif()
endmacro()

# Split one "target|lib1 lib2" entry into its target name + lib list.
macro(_extdeps_parse_entry entry out_target out_libs)
    string(REPLACE "|" ";" _pe "${entry}")
    list(GET _pe 0 ${out_target})
    list(GET _pe 1 _pe_libs)
    string(REPLACE " " ";" ${out_libs} "${_pe_libs}")
endmacro()

function(_extdeps_resolve_installed name prefix os)
    _extdeps_incdirs("${prefix}" inc)
    _extdeps_libnames("${os}" libnames)
    _extdeps_target_entries("${libnames}" entries)
    set(_primary_link "")
    set(_allbundle "")
    set(_first TRUE)
    foreach(_e ${entries})
        _extdeps_parse_entry("${_e}" _tgt _libs)
        _extdeps_resolve_prefix_libs("${prefix}" "${os}" "${_libs}" _link _bundle)
        foreach(_l ${_link})
            if(NOT EXISTS "${_l}")
                message(FATAL_ERROR "[${name}] resolved lib missing: ${_l}")
            endif()
        endforeach()
        if(_first AND DEP_LINK_DEPS)
            list(APPEND _link ${DEP_LINK_DEPS})   # extra interface deps on the primary target
        endif()
        _extdeps_make_target("${_tgt}" "${inc}" "${_link}")
        list(APPEND _allbundle ${_bundle})
        if(_first)
            set(_primary_link "${_link}")
            set(_first FALSE)
        endif()
    endforeach()
    set_property(GLOBAL PROPERTY ${name}_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY ${name}_LIBRARIES ${_primary_link})
    set_property(GLOBAL PROPERTY ${name}_INSTALL_LIBRARIES ${_allbundle})
    message(STATUS "[${name}] bundle: ${_allbundle}")
endfunction()

# Find system libraries by base name -> absolute paths (fatal if any is missing).
function(_extdeps_find_system_libs name libnames out)
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
function(_extdeps_resolve_system name)
    find_path(${name}_INC NAMES ${DEP_SYSTEM_HEADER})
    if(NOT ${name}_INC)
        message(FATAL_ERROR "[${name}] system header '${DEP_SYSTEM_HEADER}' not found (USE_SYSTEM)")
    endif()
    set(inc "${${name}_INC}")
    foreach(s ${DEP_INCLUDE_SUBDIRS})
        list(APPEND inc "${${name}_INC}/${s}")
    endforeach()
    _extdeps_target_entries("${DEP_LIBS}" entries)
    set(_primary_libs "")
    set(_first TRUE)
    foreach(_e ${entries})
        _extdeps_parse_entry("${_e}" _tgt _libs)
        _extdeps_find_system_libs("${name}" "${_libs}" _found)
        _extdeps_make_target("${_tgt}" "${inc}" "${_found}")
        if(_first)
            set(_primary_libs "${_found}")
            set(_first FALSE)
        endif()
    endforeach()
    set_property(GLOBAL PROPERTY ${name}_INCLUDE_DIRS ${inc})
    set_property(GLOBAL PROPERTY ${name}_LIBRARIES ${_primary_libs})
    set_property(GLOBAL PROPERTY ${name}_INSTALL_LIBRARIES "")
endfunction()

# Build from source into local_path, using the recipe from the deps repo.
function(_extdeps_build name version local_path os arch)
    set(prefixes "")
    foreach(_dn ${DEP_DEPENDS})
        list(APPEND prefixes "${local_path}/../${_dn}")   # sibling _deps prefix (built earlier)
    endforeach()
    build_dep(NAME ${name} RECIPE_DIR "${_EXTDEPS_ROOT}/${name}/${version}/recipe"
              OS ${os} ARCH ${arch}
              WORK "${local_path}/work" INSTALL_DIR "${local_path}"
              DEPENDS_PREFIXES "${prefixes}")
endfunction()

# Look up <name version os arch> in prebuilt.lock, download the archive
# (cache-first, SHA-verified) and extract it into local_path. Sets <out> TRUE on
# success; any miss or failure returns FALSE and the caller builds from source.
# The .prebuilt stamp records the archive name (which embeds the recipe signature),
# so a lock update re-extracts and an unchanged reconfigure is a no-op.
function(_extdeps_fetch_prebuilt name local_path os arch version out)
    set(${out} FALSE PARENT_SCOPE)
    set(lock "${_EXTDEPS_ROOT}/prebuilt.lock")
    if(NOT os OR NOT arch OR NOT EXISTS "${lock}")
        return()
    endif()
    file(STRINGS "${lock}" entry REGEX "^${name} ${version} ${os} ${arch} ")
    list(LENGTH entry n)
    if(NOT n EQUAL 1 AND os STREQUAL "macos")
        # universal archives serve single-arch consumers
        file(STRINGS "${lock}" entry REGEX "^${name} ${version} ${os} universal ")
        list(LENGTH entry n)
    endif()
    if(NOT n EQUAL 1)
        return()
    endif()
    string(REPLACE " " ";" entry "${entry}")
    list(LENGTH entry _n)
    if(NOT _n EQUAL 7)
        message(STATUS "[${name}] malformed lock entry, building from source")
        return()
    endif()
    list(GET entry 2 lock_os)
    list(GET entry 3 lock_arch)
    list(GET entry 4 file)
    list(GET entry 5 sha)
    list(GET entry 6 release)

    # The archive name embeds the recipe signature, so a lock line older than the
    # local recipe must not be consumed.
    _bd_recipe_sig("${_EXTDEPS_ROOT}/${name}/${version}/recipe" "${lock_os}" "${lock_arch}" _cursig)
    string(SUBSTRING "${_cursig}" 0 12 _cursig)
    if(NOT file MATCHES "-${_cursig}\\.7z$")
        message(STATUS "[${name}] lock entry ${file} doesn't match the local recipe (${_cursig}), building from source")
        return()
    endif()

    set(stamp "${local_path}/.prebuilt")
    if(EXISTS "${stamp}")
        file(READ "${stamp}" prev)
        if(prev STREQUAL "${file}")
            set(${out} TRUE PARENT_SCOPE)
            return()
        endif()
    endif()

    _bd_resolve_cache(cache)
    set(archive "${cache}/prebuilt/${file}")
    set(ok FALSE)
    if(EXISTS "${archive}")
        file(SHA256 "${archive}" got)
        if(got STREQUAL "${sha}")
            set(ok TRUE)
        endif()
    endif()
    if(NOT ok)
        # Base of the releases/download tree (each lock line names its release).
        set(url "$ENV{EXTDEPS_PREBUILT_URL}")
        if(NOT url)
            set(url "https://github.com/kryksyh/muse_deps_private/releases/download")
        endif()
        file(MAKE_DIRECTORY "${cache}/prebuilt")
        foreach(attempt 1 2 3)
            file(DOWNLOAD "${url}/${release}/${file}" "${archive}" STATUS st)
            list(GET st 0 c)
            if(c EQUAL 0)
                file(SHA256 "${archive}" got)
                if(got STREQUAL "${sha}")
                    set(ok TRUE)
                    break()
                endif()
                message(WARNING "[${name}] prebuilt ${file}: sha256 ${got} != ${sha}")
            endif()
            file(REMOVE "${archive}")
        endforeach()
    endif()
    if(NOT ok)
        return()
    endif()

    file(REMOVE_RECURSE "${local_path}")
    file(MAKE_DIRECTORY "${local_path}")
    file(ARCHIVE_EXTRACT INPUT "${archive}" DESTINATION "${local_path}")
    file(WRITE "${stamp}" "${file}")
    set(${out} TRUE PARENT_SCOPE)
endfunction()

# Split a DEP_PATCHES entry into (apply dir, rel path). Bare "<path>" applies in
# the dep's sole source tree; "<dir>|<path>" names the apply dir (relative to
# local_path) for a dep with several trees, or a nested target. Same key as the
# build rail; the qualifier is the only source-delivery-specific bit, optional.
macro(_extdeps_patch_entry entry sole out_dir out_rel)
    string(FIND "${entry}" "|" _bar)
    if(_bar GREATER -1)
        string(REPLACE "|" ";" _pe "${entry}")
        list(GET _pe 0 ${out_dir})
        list(GET _pe 1 ${out_rel})
    elseif("${sole}" STREQUAL "")
        message(FATAL_ERROR "[${name}] DEP_PATCHES '${entry}' needs a '<dir>|' prefix (dep has multiple source trees)")
    else()
        set(${out_dir} "${sole}")
        set(${out_rel} "${entry}")
    endif()
endmacro()

# Source-delivery (amalgamated, e.g. lv2 stack): fetch each DEP_SOURCES entry
# ("subdir|tarball|url|sha256" or "subdir|git|repo|commit") cache-first, extract
# into local_path/<subdir>, expose <name>_SOURCE_DIR. The consumer compiles these
# in-tree. "subdir|local|/path/to/subdir" builds a working tree in place instead
# (no fetch, live edits) for iterating on a dep; keep it out of committed recipes.
function(_extdeps_populate_source name local_path version)
    # A "local" source (<subdir>|local|<path>) builds a working tree on disk in
    # place: no fetch, no copy, live edits. SOURCE_DIR becomes its parent so the
    # consumer's add_subdirectory(${SOURCE_DIR}/<subdir>) hits it. For iterating on
    # a dep locally; keep it out of the committed recipe.
    foreach(e ${DEP_SOURCES})
        string(REPLACE "|" ";" f "${e}")
        list(GET f 1 kind)
        if(kind STREQUAL "local")
            list(GET f 0 sub)
            list(GET f 2 loc)
            get_filename_component(base "${loc}" NAME)
            if(NOT IS_DIRECTORY "${loc}")
                message(FATAL_ERROR "[${name}] local source not found: ${loc}")
            elseif(NOT base STREQUAL sub)
                message(FATAL_ERROR "[${name}] local source dir must be named '${sub}': ${loc}")
            endif()
            get_filename_component(parent "${loc}" DIRECTORY)
            message(STATUS "[${name}] local source: ${loc}")
            set_property(GLOBAL PROPERTY ${name}_SOURCE_DIR "${parent}")
            return()
        endif()
    endforeach()

    # The dep's sole source subtree, so a bare DEP_PATCHES entry can default its
    # apply dir to it; a dep with several trees must qualify each patch.
    set(_subs "")
    foreach(e ${DEP_SOURCES})
        string(REPLACE "|" ";" f "${e}")
        list(GET f 0 _s)
        list(APPEND _subs "${_s}")
    endforeach()
    list(REMOVE_DUPLICATES _subs)
    list(LENGTH _subs _nsub)
    set(_sole "")
    if(_nsub EQUAL 1)
        set(_sole "${_subs}")
    endif()

    _bd_resolve_cache(cache)
    set(dl "${cache}/downloads/${name}")
    file(MAKE_DIRECTORY "${dl}")
    set(_recipe_dir "${_EXTDEPS_ROOT}/${name}/${version}/recipe")
    # Stamp the pins, not just presence: a version/pin/patch change (or stray
    # residue) must wipe and repopulate, never reuse stale sources.
    set(_pins "${DEP_SOURCES}")
    foreach(pe ${DEP_PATCHES})
        _extdeps_patch_entry("${pe}" "${_sole}" _pdir prel)
        file(SHA256 "${_recipe_dir}/${prel}" psha)
        list(APPEND _pins "${pe}@${psha}")
    endforeach()
    string(SHA256 want "${_pins}")
    set(have "")
    if(EXISTS "${local_path}/.populated")
        file(READ "${local_path}/.populated" have)
        string(STRIP "${have}" have)
    endif()
    if(NOT have STREQUAL want)
        file(REMOVE_RECURSE "${local_path}")
        file(MAKE_DIRECTORY "${local_path}")
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
                    _bd_mirror("${name}" "${_EXTDEPS_ROOT}" mir)
                    set(_urls "${loc}")
                    if(mir)
                        _bd_src_ext("${an}" _ext)
                        if(sub STREQUAL name)
                            list(APPEND _urls "${mir}/${name}-${version}-src.${_ext}")
                        else()
                            list(APPEND _urls "${mir}/${name}-${sub}-src.${_ext}")
                        endif()
                    endif()
                    _bd_fetch("${dl}/${an}" "${ver}" ${_urls})
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
        # DEP_PATCHES applied -p1 in the dep's source tree (the sole subtree, or
        # the "<dir>|" qualifier). GIT_DIR override: inside an enclosing repo git
        # apply silently skips the patch.
        foreach(pe ${DEP_PATCHES})
            _extdeps_patch_entry("${pe}" "${_sole}" psub prel)
            message(STATUS "[${name}] patch ${prel}")
            _bd_run(${CMAKE_COMMAND} -E env "GIT_DIR=${local_path}/.no-such-repo"
                    ${GIT} apply --whitespace=nowarn "${_recipe_dir}/${prel}"
                    WORKING_DIRECTORY "${local_path}/${psub}")
        endforeach()
        file(WRITE "${local_path}/.populated" "${want}\n")
    endif()
    set_property(GLOBAL PROPERTY ${name}_SOURCE_DIR "${local_path}")
endfunction()

# Binary-dist tools: official upstream release binaries, mirrored as immutable
# assets in our releases and pinned by per-platform sha256 in the recipe spec.
# Nothing to build, so no lock line; the spec is the pin (like DEP_SOURCE_SHA256
# pins a source build).
function(_extdeps_fetch_binary_tool name local_path os arch)
    if(NOT DEFINED DEP_BINARY_FILE_${os}-${arch})
        message(FATAL_ERROR "[${name}] no binary for ${os}/${arch}")
    endif()
    set(file "${DEP_BINARY_FILE_${os}-${arch}}")
    set(sha  "${DEP_BINARY_SHA256_${os}-${arch}}")
    set(bin "${DEP_BINARY_NAME}")
    if(os STREQUAL "windows")
        string(APPEND bin ".exe")
    endif()
    set(dest "${local_path}/bin/${bin}")
    if(EXISTS "${dest}")
        file(SHA256 "${dest}" got)
        if(got STREQUAL "${sha}")
            return()
        endif()
    endif()
    file(MAKE_DIRECTORY "${local_path}/bin")
    foreach(attempt 1 2 3)
        file(DOWNLOAD "${DEP_BINARY_URL_ROOT}/${file}" "${dest}" STATUS st)
        list(GET st 0 c)
        if(c EQUAL 0)
            file(SHA256 "${dest}" got)
            if(got STREQUAL "${sha}")
                file(CHMOD "${dest}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                     GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
                return()
            endif()
            message(WARNING "[${name}] ${file}: sha256 ${got} != ${sha}")
        endif()
        file(REMOVE "${dest}")
    endforeach()
    message(FATAL_ERROR "[${name}] binary tool fetch failed: ${DEP_BINARY_URL_ROOT}/${file}")
endfunction()

# Single entry point. The caller includes the dep's metadata (+ spec for
# non-system modes) and this engine, then calls extdeps_resolve(...).
function(extdeps_resolve name version mode local_path os arch)
    # Per-dep override for non-standard layouts / multiple targets (wx, flac,
    # openssl): the dep's metadata file may define <name>_resolve_override().
    if(COMMAND ${name}_resolve_override)
        cmake_language(CALL ${name}_resolve_override "${mode}" "${local_path}" "${os}" "${arch}" "${version}")
        return()
    endif()

    if(NOT DEFINED DEP_KIND OR DEP_KIND STREQUAL "library")
        if(mode STREQUAL "system")
            _extdeps_resolve_system("${name}")
        else()
            # rebuild: always from source. prebuilt: extract the archive, falling
            # back to source if this platform has none. Either way local_path is
            # populated, then resolved identically.
            if(mode STREQUAL "rebuild")
                _extdeps_build("${name}" "${version}" "${local_path}" "${os}" "${arch}")
            else()
                _extdeps_fetch_prebuilt("${name}" "${local_path}" "${os}" "${arch}" "${version}" _ok)
                if(NOT _ok)
                    message(WARNING "[${name}] no usable prebuilt for ${os}/${arch}, building from source")
                    _extdeps_build("${name}" "${version}" "${local_path}" "${os}" "${arch}")
                endif()
            endif()
            _extdeps_resolve_installed("${name}" "${local_path}" "${os}")
        endif()

    elseif(DEP_KIND STREQUAL "source")
        # SYSTEM mode binds the distro package (in post_resolve), nothing to fetch.
        if(NOT mode STREQUAL "system")
            _extdeps_populate_source("${name}" "${local_path}" "${version}")
        endif()

    elseif(DEP_KIND STREQUAL "tool")
        if(mode STREQUAL "system")
            find_program(${name}_EXE NAMES ${name})
            if(NOT ${name}_EXE)
                message(FATAL_ERROR "[${name}] system tool not found (USE_SYSTEM)")
            endif()
            get_filename_component(_d "${${name}_EXE}" DIRECTORY)
            set_property(GLOBAL PROPERTY ${name}_BIN_DIR "${_d}")
        elseif(DEFINED DEP_BINARY_URL_ROOT)
            # binary-dist: no source build exists, so rebuild mode also takes this path
            _extdeps_fetch_binary_tool("${name}" "${local_path}" "${os}" "${arch}")
            set_property(GLOBAL PROPERTY ${name}_BIN_DIR "${local_path}/bin")
        else()
            if(mode STREQUAL "rebuild")
                _extdeps_build("${name}" "${version}" "${local_path}" "${os}" "${arch}")
            else()
                _extdeps_fetch_prebuilt("${name}" "${local_path}" "${os}" "${arch}" "${version}" _ok)
                if(NOT _ok)
                    message(WARNING "[${name}] no usable prebuilt for ${os}/${arch}, building from source")
                    _extdeps_build("${name}" "${version}" "${local_path}" "${os}" "${arch}")
                endif()
            endif()
            set_property(GLOBAL PROPERTY ${name}_BIN_DIR "${local_path}/bin")
        endif()

    else()
        message(FATAL_ERROR "[${name}] unknown DEP_KIND: ${DEP_KIND}")
    endif()

    # Optional metadata hook: bridge work the dep needs at its consumer (zlib
    # seeds FindZLIB, source-delivery deps add_subdirectory their tree). Keeps
    # dep-internal knowledge out of app CMake.
    if(COMMAND ${name}_post_resolve)
        cmake_language(CALL ${name}_post_resolve "${mode}" "${local_path}" "${os}" "${arch}" "${version}")
    endif()
endfunction()
