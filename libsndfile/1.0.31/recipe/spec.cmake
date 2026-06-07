# Build recipe for libsndfile 1.0.31 — read by buildtools/build_dep.cmake.
# 1.0.31 predates mp3/mpeg support, so deps are the Xiph codecs only.

set(DEP_SOURCE_URL    "https://github.com/libsndfile/libsndfile/releases/download/1.0.31/libsndfile-1.0.31.tar.bz2")
set(DEP_SOURCE_SHA256 "a8cfb1c09ea6e90eff4ca87322d4168cdbe5035cb48717b40bf77e751cc02163")

set(DEP_DEPENDS "ogg/1.3.5" "vorbis/1.3.7" "flac/1.4.2" "opus/1.5.2")

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_PROGRAMS=OFF
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DENABLE_EXTERNAL_LIBS=ON
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)
