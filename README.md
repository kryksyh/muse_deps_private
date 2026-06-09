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
  build_source_bundle.cmake  offline bundle: recipes + all pinned sources in one archive
  mirror_sources.cmake       stage source tarballs for the `sources` release mirror
prebuilt.lock                index of prebuilt archives: name version os arch file sha256
<name>/
  <name>.cmake               metadata: DEP_VERSION + consume keys (targets, libs, ...)
  <version>/recipe/
    spec.cmake               source URL + SHA-256, cmake args, deps, patches, license
    patch/*.patch            optional
    build.cmake              optional custom build for libs without upstream CMake
```

## Releases

- `prebuilt` — per-dep archives, named `<name>-<version>-<os>-<arch>-<sig>.7z`
  (`sig` = recipe hash). Content-addressed and write-once; `prebuilt.lock` maps
  each dep/platform to its archive + SHA-256, so consumers verify every download
  and a recipe change can never be served stale.
- `sources` — mirror of all pinned source tarballs (fallback when upstream is
  down) + self-contained `sources-<sha>.7z` offline bundles.

## Publishing

Dispatch the **Build prebuilt deps** workflow. Matrix jobs build every recipe per
platform and upload archives; the collect job publishes new assets (existing ones
are never overwritten) and commits the updated `prebuilt.lock`. Then bump the
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
3. Run the **Mirror dependency sources** workflow to mirror the new tarball.
