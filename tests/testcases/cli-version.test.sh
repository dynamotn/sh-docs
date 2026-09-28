# shellcheck shell=bash
# @file tests/testcases/cli-version.test.sh
# @brief Testcase for --version and -V.
# @description --version and -V report the version.

tests::run --version
tests::assert_exitcode 0
tests::assert_stdout_contains 'sh-docs '

tests::run -V
tests::assert_exitcode 0
tests::assert_stdout_contains 'sh-docs '
