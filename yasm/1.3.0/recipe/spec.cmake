# Build recipe for yasm 1.3.0 — a build-time tool (host assembler), not a linked
# library. Used by mpg123's CMake port for its x86/x64 assembly decoder.

set(DEP_SOURCE_URL    "https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz")
set(DEP_SOURCE_SHA256 "3dce6601b495f5b3d45b59f7d2492a340ee7e84b5beca17e48f862502bd5603f")


# Only needed on Windows-x64 (mpg123's asm decoder); elsewhere (incl. Windows-ARM64)
# mpg123 uses gas/NEON.
set(DEP_PLATFORMS windows-x86_64)

set(DEP_LICENSE_FILES COPYING)
