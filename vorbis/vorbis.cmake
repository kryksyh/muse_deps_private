# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.3.7)

set(DEP_TARGET Vorbis::vorbis)
set(DEP_LIBS vorbis vorbisenc vorbisfile)
set(DEP_SYSTEM_HEADER vorbis/codec.h)
set(DEP_SYSTEM_LIBS vorbis vorbisenc vorbisfile)
