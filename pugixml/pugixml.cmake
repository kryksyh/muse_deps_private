# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.15)

# Source-delivery: muse_global compiles src/pugixml.cpp in-tree.
set(DEP_KIND source)
