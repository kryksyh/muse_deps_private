# Build recipe for freetype 2.14.1. All optional integrations pinned off so the
# build never inherits host libs (zlib falls back to the internal copy).

set(DEP_SOURCE_URL    "https://download.savannah.gnu.org/releases/freetype/freetype-2.14.1.tar.xz")
set(DEP_SOURCE_SHA256 "32427e8c471ac095853212a37aef816c60b42052d4d9e48230bab3bdf2936ccc")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DFT_DISABLE_ZLIB=TRUE
    -DFT_DISABLE_BZIP2=TRUE
    -DFT_DISABLE_PNG=TRUE
    -DFT_DISABLE_HARFBUZZ=TRUE
    -DFT_DISABLE_BROTLI=TRUE
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES LICENSE.TXT)
