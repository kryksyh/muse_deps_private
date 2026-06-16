set(DEP_VERSION 1.4.3)

# flac ships two libs and targets FLAC and FLAC++
set(DEP_TARGETS "FLAC::FLAC|FLAC" "FLAC::FLAC++|FLAC++")
set(DEP_SYSTEM_HEADER FLAC/all.h)
