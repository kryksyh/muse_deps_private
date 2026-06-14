# Upstream's last release is from 2015; the pin is master, short sha.
set(DEP_VERSION 111c9be)

# Source-delivery, header-only single file. The patch carries muse's
# deterministic number serialization (fixed 6-digit precision, trimmed),
# which serialized settings/projects depend on.
set(DEP_KIND source)
