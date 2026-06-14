# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 19.7.0)

set(DEP_TARGET portaudio::portaudio)
set(DEP_LIBS portaudio)
set(DEP_LIBS_WINDOWS portaudio_x64)
set(DEP_SYSTEM_HEADER portaudio.h)
