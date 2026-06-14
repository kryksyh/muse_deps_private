# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 2.7.1)

set(DEP_TARGET expat::expat)
set(DEP_LIBS expat)
set(DEP_LIBS_WINDOWS libexpat)   # MSVC build keeps the lib prefix: libexpat.lib / libexpat.dll
set(DEP_SYSTEM_HEADER expat.h)
