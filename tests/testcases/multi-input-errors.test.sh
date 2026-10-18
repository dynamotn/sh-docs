# shellcheck shell=bash
# @file tests/testcases/multi-input-errors.test.sh
# @brief Testcase for the invalid uses of --output-dir.
# @description Each invalid combination fails with exit status 2 before
#   anything is written.

mkdir -p src lib
tests::put src/a.sh << 'SH'
# @file a.sh
SH
tests::put lib/a.sh << 'SH'
# @file a.sh
SH
tests::put src/b.sh << 'SH'
# @file b.sh
SH

tests::run src/a.sh src/b.sh
tests::assert_exitcode 2
tests::assert_stderr_contains 'several input files need --output-dir'

tests::run --output out.md --output-dir docs src/a.sh
tests::assert_exitcode 2
tests::assert_stderr_contains '--output and --output-dir cannot be combined'

tests::run --output-dir docs
tests::assert_exitcode 2
tests::assert_stderr_contains '--output-dir needs input files'

tests::run --output-dir docs -
tests::assert_exitcode 2
tests::assert_stderr_contains '--output-dir needs input files'

tests::run --index src/a.sh
tests::assert_exitcode 2
tests::assert_stderr_contains '--index needs --output-dir'

tests::run --source-path src/a.sh --output-dir docs src/a.sh src/b.sh
tests::assert_exitcode 2
tests::assert_stderr_contains '--source-path names one source'

tests::run --output-dir docs src/a.sh lib/a.sh
tests::assert_exitcode 2
tests::assert_stderr_contains 'src/a.sh and lib/a.sh would both be written to docs/a.md'

[[ ! -e docs && ! -e out.md ]] || tests::fail 'a failed invocation writes nothing'
