# Version lives here, not in the app; the muse_deps ref pins the whole set.
set(DEP_VERSION 2.4.0)

# Static (PIC) lib built against the extdeps nlohmann_json; built+installed so
# the mnxdom chain can find_package(nlohmann_json_schema_validator CONFIG). No
# imported target: find_package owns it (a pre-made one would collide). DEP_LIBS
# is a build-sanity check.
set(DEP_LIBS nlohmann_json_schema_validator)
set(DEP_STATIC ON)
set(DEP_SYSTEM_HEADER nlohmann/json-schema.hpp)
set(DEP_SYSTEM_LIBS nlohmann_json_schema_validator)
