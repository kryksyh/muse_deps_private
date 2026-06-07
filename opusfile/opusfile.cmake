# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.12)

# Consume metadata for opusfile (read by buildtools/consume.cmake). Build recipe: opusfile/<version>/recipe/spec.cmake.
# Static lib that links opus; consumed as libopusfile.a / opusfile.lib.
set(DEP_TARGET opusfile::opusfile)
set(DEP_LIBS opusfile)
set(DEP_STATIC ON)
set(DEP_LINK_DEPS Opus::opus)
set(DEP_INCLUDE_SUBDIRS opus)
set(DEP_SYSTEM_HEADER opus/opusfile.h)
set(DEP_SYSTEM_LIBS opusfile)
