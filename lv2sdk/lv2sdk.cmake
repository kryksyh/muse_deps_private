# Consume metadata for the LV2 host stack (source-delivery dep). Unlike the
# codecs, there is no prebuilt library and no system mode: muse_deps ships the
# pinned sources of lv2/lilv/zix/serd/sord/sratom/suil as one archive, and the
# consumer amalgamates them in-tree. Single entrypoint: _PopulateSource.

# Downloads + extracts the source bundle into local_path, then exposes the
# extracted root as the lv2sdk_SOURCE_DIR global (contains lv2/, lilv/, ...).
function(lv2sdk_PopulateSource local_path version)

    # Already populated (e.g. vendored into a release source tarball): use it.
    if (NOT EXISTS "${local_path}/.populated")
        set(name "lv2sdk-${version}-src")
        set(url "https://github.com/kryksyh/muse_deps_private/releases/download/lv2sdk-${version}/${name}.7z")

        if (NOT EXISTS "${local_path}/${name}.7z")
            file(MAKE_DIRECTORY "${local_path}")
            message(STATUS "[lv2sdk] source: ${url}")
            file(DOWNLOAD "${url}" "${local_path}/${name}.7z" STATUS st)
            list(GET st 0 code)
            if (NOT code EQUAL 0)
                message(FATAL_ERROR "[lv2sdk] source download failed (${st})")
            endif()
        endif()

        # A missing release asset yields a 404 body, not a 7z — validate the magic.
        file(READ "${local_path}/${name}.7z" magic LIMIT 6 HEX)
        if (NOT magic STREQUAL "377abcaf271c")
            file(REMOVE "${local_path}/${name}.7z")
            message(FATAL_ERROR "[lv2sdk] downloaded asset is not a 7z (release lv2sdk-${version} missing?)")
        endif()

        file(ARCHIVE_EXTRACT INPUT "${local_path}/${name}.7z" DESTINATION "${local_path}")
        file(WRITE "${local_path}/.populated" "${version}\n")
    endif()

    set_property(GLOBAL PROPERTY lv2sdk_SOURCE_DIR "${local_path}")
endfunction()
