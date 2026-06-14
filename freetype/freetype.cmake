# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 2.14.1)

set(DEP_TARGET freetype::freetype)
set(DEP_LIBS freetype)
set(DEP_INCLUDE_SUBDIRS freetype2)
set(DEP_SYSTEM_HEADER freetype2/ft2build.h)
set(DEP_SYSTEM_LIBS freetype)
