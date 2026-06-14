# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 3.12.0)

# Header-only; built+installed so the mnxdom chain can find_package(nlohmann_json
# CONFIG) against this prefix. No imported target: find_package owns
# nlohmann_json::nlohmann_json (a pre-made one would collide).
set(DEP_SYSTEM_HEADER nlohmann/json.hpp)
