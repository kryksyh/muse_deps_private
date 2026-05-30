# muse_deps — build-CI sandbox

Private sandbox for the build-from-source dependency pipeline.

## Layout

```
buildtools/build_dep.cmake     generic driver: sources -> patch -> build -> install -> package
<name>/<version>/
  <name>.cmake                 consume metadata (downloads prebuilt .7z from the release, or system find)
  recipe/
    spec.cmake                 per-dep: source, cmake args, license, archive names, system package
    patch/*.patch              optional, applied after get-sources
    build.cmake                optional override for non-CMake libs
```

## Build a dependency

CI: dispatch the **Build dependency** workflow with `lib` (e.g. `opus/1.5.2`) and
`platforms` (`all` or a comma list of `macos,windows,linux`). Each platform job
builds and uploads the `.7z` to release tag `<name>-<version>`.

Locally:

```
cmake -DLIB=opus/1.5.2 -DOS=macos -DARCH=universal -P buildtools/build_dep.cmake
```
