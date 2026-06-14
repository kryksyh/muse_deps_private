# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 5.7.0)

set(DEP_TARGET wavpack::wavpack)
set(DEP_LIBS wavpack)
set(DEP_LIBS_WINDOWS wavpackdll)
set(DEP_SYSTEM_HEADER wavpack/wavpack.h)
