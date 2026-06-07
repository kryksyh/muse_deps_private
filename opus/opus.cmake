# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.5.2)

# Consume metadata for opus (read by buildtools/consume.cmake). Build recipe: opus/<version>/recipe/spec.cmake.
set(DEP_TARGET Opus::opus)
set(DEP_LIBS opus)
set(DEP_INCLUDE_SUBDIRS opus)
set(DEP_SYSTEM_HEADER opus/opus.h)
set(DEP_SYSTEM_LIBS opus)
