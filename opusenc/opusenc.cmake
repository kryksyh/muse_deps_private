# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 0.2.1)

# Consume metadata for libopusenc (read by buildtools/consume.cmake). Build recipe: opusenc/<version>/recipe/spec.cmake.
# Static lib that links opus; consumed as libopusenc.a / opusenc.lib.
set(DEP_TARGET opusenc::opusenc)
set(DEP_LIBS opusenc)
set(DEP_STATIC ON)
set(DEP_LINK_DEPS Opus::opus)
set(DEP_INCLUDE_SUBDIRS opus)
set(DEP_SYSTEM_HEADER opus/opusenc.h)
set(DEP_SYSTEM_LIBS opusenc)
