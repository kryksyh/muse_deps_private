# LV2 host stack sources, amalgamated in-tree by the consumer (Audacity's
# lv2sdk module compiles selected .c files; there is no prebuilt library).
# Pins mirror Audacity's historical FetchContent in src/au3wrap/lv2sdk.
# Bundle version tracks lilv, per convention.

set(DEP_SOURCES
    # subdir | git repository                        | ref
    "lv2|https://gitlab.com/lv2/lv2.git|4b8760cec9636a1d9757afa79ceee2111b86e98b"   # post-v1.18.10: has the Qt6 UI type
    "lilv|https://gitlab.com/lv2/lilv.git|v0.24.26"
    "zix|https://github.com/drobilla/zix.git|v0.6.2"
    "sord|https://github.com/drobilla/sord.git|v0.16.18"
    "serd|https://github.com/drobilla/serd.git|v0.32.4"
    "sratom|https://gitlab.com/lv2/sratom.git|v0.6.18"
    "suil|https://gitlab.com/lv2/suil.git|v0.10.22"
)
