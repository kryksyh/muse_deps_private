# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 1.3.0)

# Consume metadata for yasm — a build-time host tool (assembler). Built from
# source (yasm/<version>/recipe/spec.cmake) and exposed on PATH via require_tool.
set(DEP_KIND tool)
