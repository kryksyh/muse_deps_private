# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.32.10)

# Consume metadata for mpg123 (read by buildtools/consume.cmake). Build recipe: mpg123/<version>/recipe/spec.cmake.
set(DEP_TARGET mpg123::libmpg123)
set(DEP_LIBS mpg123)
set(DEP_SYSTEM_HEADER mpg123.h)
set(DEP_SYSTEM_LIBS mpg123)
