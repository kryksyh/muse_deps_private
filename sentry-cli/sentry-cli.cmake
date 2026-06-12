# Pinned version — single source of truth for this dep.
set(DEP_VERSION 3.5.0)

# Build-time tool: uploads breakpad symbols to sentry (crashdumps CI).
# Binary-dist: official release binaries, never built from source — a cargo
# build would pull crates.io at build time, less reproducible than the
# official versioned binaries. The recipe spec carries the per-platform pins.
set(DEP_KIND tool)
