# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 3.24.0)

# Source-delivery: the consumer (MuseScore's braille module) compiles the
# liblouis sources + tables from liblouis_SOURCE_DIR with its own build glue
# (configMS.h, table install list). No target is created here.
set(DEP_KIND source)
