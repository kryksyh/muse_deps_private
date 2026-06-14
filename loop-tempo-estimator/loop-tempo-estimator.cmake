# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 0.0.4)

# Source-delivery: the consumer compiles it in-tree (add_subdirectory of
# <root>/loop-tempo-estimator/source).
set(DEP_KIND source)

# Called by the consuming module (add_subdirectory needs a directory anchor and
# is forbidden in deferred execution; it must also run AFTER au3wrap so the
# project reuses the consumer's pffft instead of fetching its bundled fallback).
# Project CMake lives under <tree>/source.
function(loop_tempo_estimator_materialize)
    get_property(_src GLOBAL PROPERTY loop-tempo-estimator_SOURCE_DIR)
    if(NOT TARGET loop-tempo-estimator)
        add_subdirectory("${_src}/loop-tempo-estimator/source" loop-tempo-estimator EXCLUDE_FROM_ALL)
    endif()
endfunction()
