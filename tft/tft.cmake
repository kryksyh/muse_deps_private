# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 0.5)

# Source-delivery: the consumer compiles it in-tree (au3wrap; the spectrogram
# module links the tft target).
set(DEP_KIND source)

function(tft_materialize)
    get_property(_src GLOBAL PROPERTY tft_SOURCE_DIR)
    if(NOT TARGET tft)
        add_subdirectory("${_src}/tft" tft EXCLUDE_FROM_ALL)
    endif()
endfunction()
