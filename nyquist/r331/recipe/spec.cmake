set(DEP_SOURCES
    "nyquist|tarball|https://sourceforge.net/code-snapshots/svn/n/ny/nyquist/code/nyquist-code-r331-trunk.zip|94bb10ec5189e07a0dc15d8e382aaa468cb0e33dce893633432931fea0113885"
)

# Replayed Audacity history: one patch per divergence commit (ref + subject in
# each header), in order, on top of the pristine upstream revision.
set(DEP_SOURCE_PATCHES
    "nyquist|patch/0001-f678aa44f9-reapply-132173badfe9315e94ab30fb19d366ad.patch"
    "nyquist|patch/0002-7e083b6ba1-reapply-ecc2138c5ca7eadb7d77151767b1ccd8.patch"
    "nyquist|patch/0003-9d61ee437a-reapply-016919a53bb8f17de2a9070fbe84ed88.patch"
    "nyquist|patch/0004-9b77109eff-reapply-e6d069787bb0c010c7afb55841754fb8.patch"
    "nyquist|patch/0005-981f41ccf4-reapply-6b2a219e2687de3eb77a888ca739151c.patch"
    "nyquist|patch/0006-19494d6277-reapply-2fec472ba2b4e8df797d7dac2528d8cc.patch"
    "nyquist|patch/0007-1f27ad932c-reapply-a3afdf80d00c68dddba6aa66829ac296.patch"
    "nyquist|patch/0008-cb810e8652-reapply-5955dbc75295997f273981224ffede70.patch"
    "nyquist|patch/0009-d8b878f163-reapply-5aa70545d56d4b53fa740afcf0667251.patch"
    "nyquist|patch/0010-5ba6072bbb-workaround-for-bug-2264.patch"
    "nyquist|patch/0011-3dfc9d6dec-fix-build-on-cygwin-557.patch"
    "nyquist|patch/0012-6181f406fd-fix-error-build-with-mingw-and-cygwin-55.patch"
    "nyquist|patch/0013-29d35e46e9-misc-changes-to-get-new-nyquist-to-build.patch"
    "nyquist|patch/0014-14b767b9eb-fix-bad-line-break-in-error-directive.patch"
    "nyquist|patch/0015-ff60f598f3-fixes-2-bugs-in-nyquist-1-bug-2706-proba.patch"
    "nyquist|patch/0016-0a085daa92-fix-build.patch"
    "nyquist|patch/0017-91a557d838-this-fixes-a-problem-with-nyquist-s-trig.patch"
    "nyquist|patch/0018-c216f46435-fix-bug-379.patch"
    "nyquist|patch/0019-72d72d120d-issue-1642-fix-by-rdb-1672.patch"
    "nyquist|patch/0020-91d64c4ed8-issue2372-nyquist-can-hang.patch"
    "nyquist|patch/0021-91850989a0-adds-a-set-of-patches-to-better-support-.patch"
    "nyquist|patch/0022-f5ac7bb104-typo-in-alpassvc-alg.patch"
    "nyquist|patch/0023-3c42a58fba-typos-in-alpassvv-c.patch"
    "nyquist|patch/0024-357aac03bc-typos-in-alpassvc-c.patch"
    "nyquist|patch/0025-56807d780b-typo-in-alpassvv-alg.patch"
    "nyquist|patch/0026-377e592e84-use-cstdint-instead-of-manually-defining.patch"
    "nyquist|patch/0027-95a2dd95a8-add-a-set-of-patches-to-better-support-o.patch"
    "nyquist|patch/0028-c4e391cfc4-move-debug-defines-after-including-stand.patch"
    "nyquist|patch/0029-4191cfb837-freebsd-compilation-fixes.patch"
    "nyquist|patch/0030-d881c57712-rename-swap-functions-to-not-conflict-wi.patch"
)
