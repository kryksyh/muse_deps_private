# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 5.7.0)

# Consume metadata for wavpack (read by buildtools/consume.cmake). Build recipe: wavpack/<version>/recipe/spec.cmake.
set(DEP_TARGET wavpack::wavpack)
set(DEP_LIBS wavpack)
set(DEP_LIBS_WINDOWS wavpackdll)
set(DEP_SYSTEM_HEADER wavpack/wavpack.h)
set(DEP_SYSTEM_LIBS wavpack)
