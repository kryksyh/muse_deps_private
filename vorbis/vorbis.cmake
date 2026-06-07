# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.3.7)

# Consume metadata for vorbis (read by buildtools/consume.cmake). Build recipe: vorbis/<version>/recipe/spec.cmake.
set(DEP_TARGET Vorbis::vorbis)
set(DEP_LIBS vorbis vorbisenc vorbisfile)
set(DEP_SYSTEM_HEADER vorbis/codec.h)
set(DEP_SYSTEM_LIBS vorbis vorbisenc vorbisfile)
