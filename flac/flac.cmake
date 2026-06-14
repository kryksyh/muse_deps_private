# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.4.3)

# Two imported targets from one prefix: FLAC::FLAC (C) and FLAC::FLAC++ (C++),
# both used by au3's mod-flac. The generic DEP_TARGETS list needs no override.
set(DEP_TARGETS "FLAC::FLAC|FLAC" "FLAC::FLAC++|FLAC++")
set(DEP_SYSTEM_HEADER FLAC/all.h)
