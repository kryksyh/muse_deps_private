# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 2.0.3)

# Consume metadata for fdk-aac (read by buildtools/consume.cmake). Build recipe: fdk-aac/<version>/recipe/spec.cmake.
set(DEP_TARGET fdk-aac::fdk-aac)
set(DEP_LIBS fdk-aac)
set(DEP_INCLUDE_SUBDIRS fdk-aac)
set(DEP_SYSTEM_HEADER fdk-aac/aacenc_lib.h)
set(DEP_SYSTEM_LIBS fdk-aac)
