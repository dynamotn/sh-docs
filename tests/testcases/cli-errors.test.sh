# shellcheck shell=bash
# @file tests/testcases/cli-errors.test.sh
# @brief Testcase for the failure modes of the command line.
# @description Bad invocations fail loudly instead of producing an empty document,
#   with exit status 2, which sets them apart from the 1 of a stale document
#   or a --strict finding.

tests::run --nonsense
tests::assert_exitcode 2
tests::assert_stderr_contains 'unknown option: --nonsense'

tests::run --output
tests::assert_exitcode 2
tests::assert_stderr_contains 'option --output requires an argument'

tests::run missing.sh
tests::assert_exitcode 2
tests::assert_stderr_contains 'cannot read input file: missing.sh'

tests::put one.sh << 'SH'
# @file one.sh
SH
tests::put two.sh << 'SH'
# @file two.sh
SH
tests::run one.sh two.sh
tests::assert_exitcode 2
tests::assert_stderr_contains 'several input files need --output-dir'

# A failing awk program is an error of the tool, not a finding.
printf 'BEGIN { x = }\n' > broken.awk
tests::put input << 'SH'
# @file one.sh
SH
SH_DOCS_AWK=broken.awk tests::run
tests::assert_exitcode 2
