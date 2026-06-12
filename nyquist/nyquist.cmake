# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically). Audacity tracked upstream
# SVN r331 = 3.16 release + two trivial commits; the patch carries those plus
# Audacity's accumulated local changes (BSD ports, bug fixes, msvc compat).
# Updating nyquist = bump the pin to the next nyqsrcNNN.zip and rebase the patch.
set(DEP_VERSION 3.16)

# Source-delivery: Audacity's libnyquist wrapper compiles the engine subset
# in-tree (cmt cmupv ffts nyqsrc nyqstk sys tran xlisp); nyx (the Audacity
# interface) lives in the app.
set(DEP_KIND source)
