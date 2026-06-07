# Build recipe for opusfile 0.12 — autotools (static lib), deps ogg + opus.
# --disable-http drops the openssl dependency (Audacity only reads opus files).

set(DEP_SOURCE_URL    "https://github.com/xiph/opusfile/archive/v0.12.tar.gz")
set(DEP_SOURCE_SHA256 "a20a1dff1cdf0719d1e995112915e9966debf1470ee26bb31b2f510ccf00ef40")

set(DEP_DEPENDS "ogg/1.3.5" "opus/1.5.2")

set(DEP_BUILD_SYSTEM autotools)
set(DEP_AUTORECONF ON)
# last --enable/--disable-shared/static wins → static (consumed as libopusfile.a)
set(DEP_CONFIGURE_ARGS --disable-shared --enable-static --disable-http --disable-examples --disable-doc)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES COPYING)

# Windows MSVC build override (autotools cannot run there) — fetched by the consumer.
set(DEP_RECIPE_FILES_WINDOWS build.windows.cmake)
