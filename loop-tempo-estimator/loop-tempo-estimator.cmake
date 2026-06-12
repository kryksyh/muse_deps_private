# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.0.4)

# Source-delivery: the consumer compiles it in-tree (add_subdirectory of
# <root>/loop-tempo-estimator/source).
set(DEP_KIND source)
