# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.0.4)

# Source-delivery: the consumer compiles it in-tree (add_subdirectory of
# <root>/loop-tempo-estimator/source).
set(DEP_KIND source)

# Materialize the target (project CMake lives under <tree>/source). Deferred to
# the end of configure: the project reuses the consumer's pffft target when one
# exists (au3wrap's) — added earlier, its bundled-pffft fallback would win and
# collide with au3wrap's. Link by name works before the target exists.
function(_loop-tempo-estimator_add local_path)
    if(NOT TARGET loop-tempo-estimator)
        add_subdirectory("${local_path}/loop-tempo-estimator/source" loop-tempo-estimator EXCLUDE_FROM_ALL)
    endif()
endfunction()
function(loop-tempo-estimator_post_consume mode local_path os arch version)
    cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL _loop-tempo-estimator_add "${local_path}")
endfunction()
