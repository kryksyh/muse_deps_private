# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 3.100)

# Shared on unix; static (mp3lame.lib) on Windows.
set(DEP_TARGET libmp3lame::libmp3lame)
set(DEP_LIBS mp3lame)
set(DEP_STATIC_WINDOWS ON)
set(DEP_SYSTEM_HEADER lame/lame.h)
set(DEP_SYSTEM_LIBS mp3lame)
