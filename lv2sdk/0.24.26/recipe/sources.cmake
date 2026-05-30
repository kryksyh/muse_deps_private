# LV2 host stack sources, amalgamated in-tree by the consumer (Audacity's
# lv2sdk module compiles selected .c files; there is no prebuilt library).
# Each lib is a pristine upstream release tarball verified by SHA-256; lv2
# itself is a pinned git commit (post-v1.18.10, for the Qt6 UI type — no release
# carries it yet). Bundle version tracks lilv, per convention.
#
# Entry format: "subdir|tarball|<url>|<sha256>" or "subdir|git|<repo>|<commit>".

set(DEP_SOURCES
    "lilv|tarball|https://download.drobilla.net/lilv-0.24.26.tar.xz|22feed30bc0f952384a25c2f6f4b04e6d43836408798ed65a8a934c055d5d8ac"
    "zix|tarball|https://download.drobilla.net/zix-0.6.2.tar.xz|4bc771abf4fcf399ea969a1da6b375f0117784f8fd0e2db356a859f635f616a7"
    "serd|tarball|https://download.drobilla.net/serd-0.32.4.tar.xz|cbefb569e8db686be8c69cb3866a9538c7cb055e8f24217dd6a4471effa7d349"
    "sord|tarball|https://download.drobilla.net/sord-0.16.18.tar.xz|4f398b635894491a4774b1498959805a08e11734c324f13d572dea695b13d3b3"
    "sratom|tarball|https://download.drobilla.net/sratom-0.6.18.tar.xz|4c6a6d9e0b4d6c01cc06a8849910feceb92e666cb38779c614dd2404a9931e92"
    "suil|tarball|https://download.drobilla.net/suil-0.10.22.tar.xz|d720969e0f44a99d5fba35c733a43ed63a16b0dab867970777efca4b25387eb7"
    "lv2|git|https://gitlab.com/lv2/lv2.git|4b8760cec9636a1d9757afa79ceee2111b86e98b"
)
