# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 2.4.0)

# Static (PIC) lib built against the muse_deps nlohmann_json. Built + installed
# only so the mnxdom chain can find_package(nlohmann_json_schema_validator
# CONFIG); the engine exposes no imported target on purpose — find_package owns
# it, and a pre-made target would clash. DEP_LIBS is kept as a build-sanity check.
set(DEP_LIBS nlohmann_json_schema_validator)
set(DEP_STATIC ON)
set(DEP_SYSTEM_HEADER nlohmann/json-schema.hpp)
set(DEP_SYSTEM_LIBS nlohmann_json_schema_validator)
