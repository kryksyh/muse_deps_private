# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 1.7.1)

# Source-delivery: au3wrap compiles it in-tree. AU3 ships this version; newer
# soundtouch changes time-stretch output, so bumps are an audio-quality decision.
set(DEP_KIND source)
