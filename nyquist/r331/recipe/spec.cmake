set(DEP_SOURCES
    "nyquist|tarball|https://sourceforge.net/code-snapshots/svn/n/ny/nyquist/code/nyquist-code-r331-trunk.zip|94bb10ec5189e07a0dc15d8e382aaa468cb0e33dce893633432931fea0113885"
)

# Replayed Audacity history: one patch per divergence commit (ref + subject in
# each header), in order, on top of the pristine upstream revision.
set(DEP_SOURCE_PATCHES
    "nyquist|patch/0001-132173badf-cppcheck-fix-2-reports.patch"
    "nyquist|patch/0002-016919a53b-bug1223-correction-fix-new-potential-cra.patch"
    "nyquist|patch/0003-ecc2138c5c-comment-out-extra-tokens-at-end-of-endif.patch"
    "nyquist|patch/0004-e6d069787b-fix-mistake-in-commit-a1dc830-and-add-a-.patch"
    "nyquist|patch/0005-6b2a219e26-changes-to-make-xlisp-h-usable-in-c-code.patch"
    "nyquist|patch/0006-2fec472ba2-lib-src-libnyquist-eliminate-register-lo.patch"
    "nyquist|patch/0007-a3afdf80d0-lib-src-libnyquist-fix-warning-about-alw.patch"
    "nyquist|patch/0008-5955dbc752-possible-fix-for-bug-590.patch"
    "nyquist|patch/0009-5aa70545d5-use-casts-with-function-pointers-to-quie.patch"
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
