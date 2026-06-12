# Pinned version — single source of truth for this dep.
set(DEP_VERSION 12.3.0)

# Source-delivery: the consumer compiles it in-tree.
set(DEP_KIND source)

# Called by the consumer (muse draw) after the manifest populated the sources;
# HB_* options are set by the caller before this.
function(harfbuzz_materialize)
    get_property(_src GLOBAL PROPERTY harfbuzz_SOURCE_DIR)
    if(NOT TARGET harfbuzz)
        # Statically linked into the consumer; installing would drag the
        # consumer's freetype target into an export set it isn't part of.
        set(SKIP_INSTALL_ALL ON)
        add_subdirectory("${_src}/harfbuzz" harfbuzz)
    endif()
endfunction()
