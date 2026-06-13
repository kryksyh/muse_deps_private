# Pinned version — single source of truth for this dep (the consumer reads it;
# the muse_deps ref pins the whole set atomically).
set(DEP_VERSION 3.12.0)

# Header-only. Built + installed only so the mnxdom chain can
# find_package(nlohmann_json CONFIG) against this prefix; the engine exposes no
# imported target on purpose — find_package owns nlohmann_json::nlohmann_json,
# and a pre-made target would clash.
set(DEP_SYSTEM_HEADER nlohmann/json.hpp)
