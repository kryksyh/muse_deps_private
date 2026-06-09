# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.4.3)

# Consume metadata for flac. Two imported targets from one prefix: FLAC::FLAC (C)
# and FLAC::FLAC++ (C++) — au3's mod-flac uses both. Declared via the engine's
# generic DEP_TARGETS list, so no custom override is needed.
set(DEP_TARGETS "FLAC::FLAC|FLAC" "FLAC::FLAC++|FLAC++")
set(DEP_SYSTEM_HEADER FLAC/all.h)
