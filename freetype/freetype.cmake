# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 2.14.1)

# Consume metadata for freetype (read by buildtools/consume.cmake). Build recipe: freetype/<version>/recipe/spec.cmake.
set(DEP_TARGET freetype::freetype)
set(DEP_LIBS freetype)
set(DEP_INCLUDE_SUBDIRS freetype2)
set(DEP_SYSTEM_HEADER freetype2/ft2build.h)
set(DEP_SYSTEM_LIBS freetype)
