# muse_deps

Dependency recipes, build tooling and prebuilt-binary index for Audacity 4.
Consumed as a git submodule: the consumer includes `buildtools/consume.cmake`
and drives it from its dependency manifest.

## Layout

```
buildtools/
  consume.cmake              consume engine: prebuilt (lock-verified) / source / system
  build_dep_lib.cmake        builder: fetch (SHA-256) -> patch -> cmake build -> install
  build_platform.cmake       producer: build all recipes for one os/arch, pack per-dep archives
  mirror_sources.cmake       stage every pinned source tarball for the release
prebuilt.lock                index of prebuilt archives: name version os arch file sha256 release
<name>/
  <name>.cmake               metadata: DEP_VERSION + consume keys (targets, libs, ...)
  <version>/recipe/
    spec.cmake               source URL + SHA-256, cmake args, deps, patches, license
    patch/*.patch            optional
    build.cmake              optional custom build for libs without upstream CMake
```

## Releases

- `deps-<timestamp>` — one release per producer run with that run's per-dep archives,
  named `<name>-<version>-<os>-<arch>-<sig>.7z` (`sig` = recipe + engine-rev
  hash). `prebuilt.lock` maps each dep/platform to archive + SHA-256 + release,
  so downloads are verified and nothing a pinned lock references is ever
  mutated. Old releases are pruned by age, never edited.
  Each release also carries every pinned pristine source tarball
  (`<name>-<archive>`): the corresponding sources of the binaries, and the
  fallback mirror when an upstream host is down. An offline kit is
  `gh release download <tag>`.

## Publishing

Dispatch the **Build prebuilt deps** workflow. Matrix jobs build every recipe per
platform and upload archives; the collect job publishes them into this run's own
release and commits the updated `prebuilt.lock`. Then bump the
submodule pin in the consumer.

Locally:

```
cmake -DOS=macos -DARCH=universal -P buildtools/build_platform.cmake
```

Archives + lock fragment land in `.build/platform/out/`.

## Adding / bumping a dep

1. Add `<name>/<version>/recipe/spec.cmake` (and metadata `<name>/<name>.cmake`
   for a new dep); set `DEP_VERSION`.
2. Build locally or via the workflow; consumers without a matching lock entry
   fall back to building from source, so a recipe is usable before any release.
3. The next producer run attaches the new source tarball to its release.
