# Build recipe for json-schema-validator 2.4.0 (pboettch). It resolves
# nlohmann_json via FetchContent's FIND_PACKAGE_ARGS (CMake >= 3.24), so with the
# engine putting nlohmann_json's prefix on CMAKE_PREFIX_PATH (DEP_DEPENDS) it
# finds it instead of fetching.

set(DEP_SOURCE_URL    https:)
set(DEP_SOURCE_SHA256 "36d7e99a73aa6076834736f0fb108fa8e232c4739aa4b3e2089fe96efb21fa8d")

set(DEP_DEPENDS nlohmann_json)

set(DEP_CMAKE_ARGS
    -DBUILD_SHARED_LIBS=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DJSON_VALIDATOR_BUILD_TESTS=OFF
    -DJSON_VALIDATOR_BUILD_EXAMPLES=OFF
    -DJSON_VALIDATOR_INSTALL=ON
)

set(DEP_MACOS_DEPLOYMENT_TARGET "12.0")
set(DEP_LICENSE_FILES LICENSE)
