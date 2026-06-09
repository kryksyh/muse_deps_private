# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 2.7.1)

# Consume metadata for expat (read by buildtools/consume.cmake). Build recipe: expat/<version>/recipe/spec.cmake.
set(DEP_TARGET expat::expat)
set(DEP_LIBS expat)
set(DEP_LIBS_WINDOWS libexpat)   # MSVC build keeps the lib prefix: libexpat.lib / libexpat.dll
set(DEP_SYSTEM_HEADER expat.h)
set(DEP_SYSTEM_LIBS expat)
