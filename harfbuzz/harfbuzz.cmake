# Pinned version — single source of truth for this dep.
set(DEP_VERSION 12.3.0)

# Source-delivery: the consumer compiles it in-tree.
set(DEP_KIND source)

# Called by the consumer (muse draw) after the manifest populated the sources;
# defines the harfbuzz target and sets HARFBUZZ_LIBRARIES/HARFBUZZ_INCLUDE_DIRS
# in the caller's scope.
function(harfbuzz_materialize)
    get_property(_src GLOBAL PROPERTY harfbuzz_SOURCE_DIR)
    if(NOT TARGET harfbuzz)
        set(HB_HAVE_FREETYPE ON)
        # Statically linked into the consumer; installing would drag the
        # consumer's freetype target into an export set it isn't part of.
        set(SKIP_INSTALL_ALL ON)
        add_subdirectory("${_src}/harfbuzz" harfbuzz)

        if(MSVC)
            target_compile_options(harfbuzz PRIVATE
                /wd4244 /wd4267 /wd4245 /wd4057 /wd4334   # conversion
                /wd4100                                   # unused parameter
                /wd4101 /wd4189                           # unused variable
                /wd4456 /wd4457 /wd4458 /wd4459           # hides previous
                /wd4702                                   # unreachable
            )
        else()
            target_compile_options(harfbuzz PRIVATE
                -Wno-conversion -Wno-unused-parameter -Wno-unused-variable)
        endif()
    endif()

    set(HARFBUZZ_LIBRARIES harfbuzz PARENT_SCOPE)
    set(HARFBUZZ_INCLUDE_DIRS "${_src}/harfbuzz/src" PARENT_SCOPE)
endfunction()
