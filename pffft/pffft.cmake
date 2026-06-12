# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically). Upstream has no releases;
# the version is the pinned commit, short.
set(DEP_VERSION 0979688)

# Source-delivery: au3wrap compiles it in-tree. The patch is Audacity's fork
# delta (SIMD macros split out to pfsimd_macros.h, NEON support); both upstream
# and the fork are frozen.
set(DEP_KIND source)
