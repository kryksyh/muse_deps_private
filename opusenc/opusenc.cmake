# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 0.2.1)

# Static lib that links opus; consumed as libopusenc.a / opusenc.lib.
set(DEP_TARGET opusenc::opusenc)
set(DEP_LIBS opusenc)
set(DEP_STATIC ON)
set(DEP_LINK_DEPS Opus::opus)
set(DEP_INCLUDE_SUBDIRS opus)
set(DEP_SYSTEM_HEADER opus/opusenc.h)
set(DEP_SYSTEM_LIBS opusenc)
