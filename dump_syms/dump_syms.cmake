# Version lives here, not in the app.
set(DEP_VERSION 2026.06.12)

# Build-time tool: breakpad's symbol dumper. Turns built binaries' debug info
# into .sym files for crash-report symbolication (sentry upload in CI).
set(DEP_KIND tool)
