# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 3.100)

# Consume metadata for lame (read by buildtools/consume.cmake). Build recipe: lame/<version>/recipe/spec.cmake.
# Shared on unix; static (mp3lame.lib) on Windows.
set(DEP_TARGET libmp3lame::libmp3lame)
set(DEP_LIBS mp3lame)
set(DEP_STATIC_WINDOWS ON)
set(DEP_SYSTEM_HEADER lame/lame.h)
set(DEP_SYSTEM_LIBS mp3lame)
