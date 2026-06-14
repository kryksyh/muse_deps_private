# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 12.3.0)

set(DEP_TARGET harfbuzz::harfbuzz)
set(DEP_LIBS harfbuzz)
set(DEP_INCLUDE_SUBDIRS harfbuzz)
# hb-ft.h in the probe: a system harfbuzz must have been built with freetype.
set(DEP_SYSTEM_HEADER harfbuzz/hb-ft.h)
set(DEP_SYSTEM_LIBS harfbuzz)
