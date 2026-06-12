# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.0.4)

# Source-delivery: the consumer compiles it in-tree (add_subdirectory of
# <root>/loop-tempo-estimator/source).
set(DEP_KIND source)

# Materialize the target: the project's CMake lives under <tree>/source.
function(loop-tempo-estimator_post_consume mode local_path os arch version)
    if(NOT TARGET loop-tempo-estimator)
        add_subdirectory("${local_path}/loop-tempo-estimator/source" loop-tempo-estimator EXCLUDE_FROM_ALL)
    endif()
endfunction()
