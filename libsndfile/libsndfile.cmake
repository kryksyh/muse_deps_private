# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.2.2)

set(DEP_TARGET SndFile::sndfile)
set(DEP_LIBS sndfile)
set(DEP_SYSTEM_HEADER sndfile.h)
set(DEP_SYSTEM_LIBS sndfile)
