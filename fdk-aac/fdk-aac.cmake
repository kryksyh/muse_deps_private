# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 2.0.3)

set(DEP_TARGET fdk-aac::fdk-aac)
set(DEP_LIBS fdk-aac)
set(DEP_INCLUDE_SUBDIRS fdk-aac)
set(DEP_SYSTEM_HEADER fdk-aac/aacenc_lib.h)
