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
function(_loop-tempo-estimator_add)
    get_property(_src GLOBAL PROPERTY loop-tempo-estimator_SOURCE_DIR)
    if(NOT TARGET loop-tempo-estimator)
        add_subdirectory("${_src}/loop-tempo-estimator/source" loop-tempo-estimator EXCLUDE_FROM_ALL)
    endif()
endfunction()
function(loop-tempo-estimator_post_consume mode local_path os arch version)
    # NB: DEFER re-evaluates argument variables at execution time — pass nothing,
    # read the SOURCE_DIR global (set by the engine) inside the call.
    cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL _loop-tempo-estimator_add)
endfunction()
