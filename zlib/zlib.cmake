# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.2.13)

# Consume metadata for zlib (read by buildtools/consume.cmake). Build recipe: zlib/<version>/recipe/spec.cmake.
set(DEP_TARGET zlib::zlib)
set(DEP_LIBS z)
set(DEP_LIBS_WINDOWS zlib)
set(DEP_SYSTEM_HEADER zlib.h)
set(DEP_SYSTEM_LIBS z)
