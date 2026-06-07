# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.3.5)

# Consume metadata for ogg (read by buildtools/consume.cmake). Build recipe: ogg/<version>/recipe/spec.cmake.
set(DEP_TARGET Ogg::ogg)
set(DEP_LIBS ogg)
set(DEP_SYSTEM_HEADER ogg/ogg.h)
set(DEP_SYSTEM_LIBS ogg)
