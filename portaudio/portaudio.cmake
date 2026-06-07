# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 19.7.0)

# Consume metadata for portaudio (read by buildtools/consume.cmake). Build recipe: portaudio/<version>/recipe/spec.cmake.
set(DEP_TARGET portaudio::portaudio)
set(DEP_LIBS portaudio)
set(DEP_LIBS_WINDOWS portaudio_x64)
set(DEP_SYSTEM_HEADER portaudio.h)
set(DEP_SYSTEM_LIBS portaudio)
