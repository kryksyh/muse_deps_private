# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.0.31)

# Consume metadata for libsndfile (read by buildtools/consume.cmake). Build recipe: libsndfile/<version>/recipe/spec.cmake.
set(DEP_TARGET SndFile::sndfile)
set(DEP_LIBS sndfile)
set(DEP_SYSTEM_HEADER sndfile.h)
set(DEP_SYSTEM_LIBS sndfile)
