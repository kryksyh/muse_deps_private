# Build recipe for libsndfile 1.2.2. MPEG support stays off: AU uses lame/mpg123
# directly, and ON would add them as link deps of libsndfile.

set(DEP_SOURCE_URL    "https://github.com/libsndfile/libsndfile/releases/download/1.2.2/libsndfile-1.2.2.tar.xz")
set(DEP_SOURCE_SHA256 "3799ca9924d3125038880367bf1468e53a1b7e3686a934f098b7e1d286cdb80e")

set(DEP_DEPENDS ogg vorbis flac opus)

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_PROGRAMS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_EXTERNAL_LIBS=ON
    -DENABLE_MPEG=OFF
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
