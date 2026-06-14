# Pin is upstream SVN r331, the exact revision Audacity last synced to (Jan 2021).
# Sourceforge generates the snapshot on demand, so after the first producer run
# the release mirror is the durable source. Updating nyquist = bump the pin and
# replay the patch series; hunks that fail or turn empty were absorbed upstream.
set(DEP_VERSION r331)

# Source-delivery: Audacity's libnyquist wrapper compiles the engine subset
# in-tree (cmt cmupv ffts nyqsrc nyqstk sys tran xlisp); nyx (the Audacity
# interface) lives in the app.
set(DEP_KIND source)
