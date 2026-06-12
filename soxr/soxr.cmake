# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.1.3)

# Source-delivery: au3wrap compiles it in-tree. 0.1.3 is upstream's final
# release (project dormant since 2018); AU3 carries small local fixes.
set(DEP_KIND source)
