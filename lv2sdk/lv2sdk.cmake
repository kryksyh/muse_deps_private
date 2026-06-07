# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.24.26)

# Consume metadata for the LV2 host stack (amalgamated source-delivery; the
# consumer compiles the sources in-tree). DEP_SOURCES (per-lib pins) is in
# lv2sdk/<version>/recipe/spec.cmake.
set(DEP_KIND source)
