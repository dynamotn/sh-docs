# shellcheck shell=bash
# @file tests/testcases/cli-errors.test.sh
# @brief Testcase for the failure modes of the command line.
# @description Bad invocations fail loudly instead of producing an empty document.

tests::run --nonsense
tests::assert_exitcode 1
tests::assert_stderr_contains 'unknown option: --nonsense'

tests::run --output
tests::assert_exitcode 1
tests::assert_stderr_contains 'option --output requires an argument'

tests::run missing.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'cannot read input file: missing.sh'

tests::put one.sh << 'SH'
# @file one.sh
SH
tests::put two.sh << 'SH'
# @file two.sh
SH
tests::run one.sh two.sh
tests::assert_exitcode 1
tests::assert_stderr_contains 'at most one input file is accepted'
