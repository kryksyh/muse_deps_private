set(DEP_SOURCES
    "nyquist|tarball|https://downloads.sourceforge.net/project/nyquist/nyquist/3.16/nyqsrc316.zip|b37fd42290d82c265ff1c733f9d08ac211460ff48b8415758ab0034ef9af7916"
)

# Replayed Audacity history: one patch per upstream-divergence commit (see each
# header for the commit ref); the series reproduces the previously vendored tree
# byte-for-byte on top of the pristine release.
set(DEP_SOURCE_PATCHES
    "nyquist|patch/0001-15b9bb96cd-update-nyquist-to-svn-r331-r3-16.patch"
    "nyquist|patch/0002-f678aa44f9-reapply-132173badfe9315e94ab30fb19d366ad.patch"
    "nyquist|patch/0003-7e083b6ba1-reapply-ecc2138c5ca7eadb7d77151767b1ccd8.patch"
    "nyquist|patch/0004-9d61ee437a-reapply-016919a53bb8f17de2a9070fbe84ed88.patch"
    "nyquist|patch/0005-9b77109eff-reapply-e6d069787bb0c010c7afb55841754fb8.patch"
    "nyquist|patch/0006-981f41ccf4-reapply-6b2a219e2687de3eb77a888ca739151c.patch"
    "nyquist|patch/0007-19494d6277-reapply-2fec472ba2b4e8df797d7dac2528d8cc.patch"
    "nyquist|patch/0008-1f27ad932c-reapply-a3afdf80d00c68dddba6aa66829ac296.patch"
    "nyquist|patch/0009-cb810e8652-reapply-5955dbc75295997f273981224ffede70.patch"
    "nyquist|patch/0010-d8b878f163-reapply-5aa70545d56d4b53fa740afcf0667251.patch"
    "nyquist|patch/0011-5ba6072bbb-workaround-for-bug-2264.patch"
    "nyquist|patch/0012-3dfc9d6dec-fix-build-on-cygwin-557.patch"
    "nyquist|patch/0013-6181f406fd-fix-error-build-with-mingw-and-cygwin-55.patch"
    "nyquist|patch/0014-29d35e46e9-misc-changes-to-get-new-nyquist-to-build.patch"
    "nyquist|patch/0015-14b767b9eb-fix-bad-line-break-in-error-directive.patch"
    "nyquist|patch/0016-ff60f598f3-fixes-2-bugs-in-nyquist-1-bug-2706-proba.patch"
    "nyquist|patch/0017-0a085daa92-fix-build.patch"
    "nyquist|patch/0018-91a557d838-this-fixes-a-problem-with-nyquist-s-trig.patch"
    "nyquist|patch/0019-c216f46435-fix-bug-379.patch"
    "nyquist|patch/0020-72d72d120d-issue-1642-fix-by-rdb-1672.patch"
    "nyquist|patch/0021-91d64c4ed8-issue2372-nyquist-can-hang.patch"
    "nyquist|patch/0022-91850989a0-adds-a-set-of-patches-to-better-support-.patch"
    "nyquist|patch/0023-f5ac7bb104-typo-in-alpassvc-alg.patch"
    "nyquist|patch/0024-3c42a58fba-typos-in-alpassvv-c.patch"
    "nyquist|patch/0025-357aac03bc-typos-in-alpassvc-c.patch"
    "nyquist|patch/0026-56807d780b-typo-in-alpassvv-alg.patch"
    "nyquist|patch/0027-377e592e84-use-cstdint-instead-of-manually-defining.patch"
    "nyquist|patch/0028-95a2dd95a8-add-a-set-of-patches-to-better-support-o.patch"
    "nyquist|patch/0029-c4e391cfc4-move-debug-defines-after-including-stand.patch"
    "nyquist|patch/0030-4191cfb837-freebsd-compilation-fixes.patch"
    "nyquist|patch/0031-d881c57712-rename-swap-functions-to-not-conflict-wi.patch"
)
