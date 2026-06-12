# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 4.1.1)

# Source-delivery, header-only: the consumer adds <tree>/utfcpp/source to its
# include path.
set(DEP_KIND source)
