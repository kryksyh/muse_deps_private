# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 3.24.0)

# Source-delivery: the consumer calls liblouis_materialize() to get the
# `liblouis` static-lib target, then links it and installs ${liblouis_TABLES}
# (the curated braille tables) into its own resources dir. All the build glue
# (MuseScore's config, the liblouis.h generation, the table list) lives here.
set(DEP_KIND source)

# Captured at include time (CMAKE_CURRENT_LIST_DIR is this dir then); the
# function runs later in the consumer's scope where it would no longer resolve.
set_property(GLOBAL PROPERTY _liblouis_recipe "${CMAKE_CURRENT_LIST_DIR}/${DEP_VERSION}/recipe")

function(liblouis_materialize)
    if(TARGET liblouis)
        return()
    endif()
    get_property(_ll GLOBAL PROPERTY liblouis_SOURCE_DIR)
    get_property(_recipe GLOBAL PROPERTY _liblouis_recipe)
    set(_src "${_ll}/liblouis/liblouis")
    set(_gen "${CMAKE_BINARY_DIR}/_deps/liblouis-gen/liblouis")

    set(WIDECHARS_ARE_UCS4 TRUE)        # configMS.h
    set(WIDECHAR_TYPE "unsigned int")   # liblouis.h.in
    configure_file("${_recipe}/configMS.h" "${_gen}/config.h" @ONLY)
    configure_file("${_src}/liblouis.h.in" "${_gen}/liblouis.h" @ONLY)

    add_library(liblouis STATIC
        ${_src}/commonTranslationFunctions.c
        ${_src}/compileTranslationTable.c
        ${_src}/logging.c
        ${_src}/lou_backTranslateString.c
        ${_src}/lou_translateString.c
        ${_src}/maketable.c
        ${_src}/pattern.c
        ${_src}/utils.c
        ${_gen}/config.h
        ${_gen}/liblouis.h
    )
    target_compile_definitions(liblouis PRIVATE TABLESDIR=dataPathPtr)
    # braille's louis.cpp includes liblouis' internal.h + the generated liblouis.h.
    target_include_directories(liblouis PUBLIC ${_src} ${_gen})
    set_target_properties(liblouis PROPERTIES UNITY_BUILD OFF)
    if(MSVC)
        target_compile_options(liblouis PRIVATE /w)
    else()
        target_compile_options(liblouis PRIVATE -w)
    endif()

    # Expose the curated table set (absolute paths) for the consumer to install.
    include("${_recipe}/tables.cmake")  # -> LIBLOUIS_TABLE_NAMES
    list(TRANSFORM LIBLOUIS_TABLE_NAMES PREPEND "${_ll}/liblouis/tables/")
    set_property(GLOBAL PROPERTY liblouis_TABLES "${LIBLOUIS_TABLE_NAMES}")
endfunction()
